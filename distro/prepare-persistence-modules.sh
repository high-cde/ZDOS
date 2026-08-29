#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD="${ZDOS_BUILD_DIR:-$ROOT/distro/build}"
KERNEL="${ZDOS_KERNEL:-$BUILD/vmlinuz}"
OUT="${ZDOS_MODULES_DIR:-$BUILD/kernel-modules-slim}"
DEBIAN_MIRROR="${ZDOS_DEBIAN_MIRROR:-https://deb.debian.org/debian}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
for tool in file curl xz dpkg-deb cp mkdir rm; do need "$tool"; done
test -s "$KERNEL" || { echo "missing kernel: $KERNEL" >&2; exit 1; }

release=$(file "$KERNEL" | sed -n 's/.*version \([^ ]*\).*/\1/p')
case "$release" in
  6.1.0-50-amd64) ;;
  *) echo "unsupported Debian kernel ABI: ${release:-unknown}" >&2; exit 1 ;;
esac

cache="$BUILD/sources/debian"
mkdir -p "$cache"
index="$cache/Packages.xz"
package="$cache/linux-image-${release}-unsigned.deb"
if [ ! -s "$index" ]; then
  curl --fail --location --retry 3 --output "$index" \
    "$DEBIAN_MIRROR/dists/bookworm/main/binary-amd64/Packages.xz"
fi
filename=$(xz -dc "$index" | awk -v pkg="linux-image-${release}-unsigned" '
  BEGIN { RS="" }
  $0 ~ ("^Package: " pkg "\\n") {
    for (i = 1; i <= NF; i++) if ($i == "Filename:") print $(i + 1)
  }')
test -n "$filename" || { echo "Debian package not found for $release" >&2; exit 1; }
if [ ! -s "$package" ]; then
  curl --fail --location --retry 3 --output "$package" "$DEBIAN_MIRROR/$filename"
fi

extract="$cache/extracted-${release}"
if [ ! -d "$extract/lib/modules/$release" ]; then
  rm -rf "$extract"
  mkdir -p "$extract"
  dpkg-deb -x "$package" "$extract"
fi

module_root="$OUT/lib/modules/$release"
rm -rf "$OUT"
mkdir -p \
  "$module_root/kernel/drivers/virtio" \
  "$module_root/kernel/drivers/block" \
  "$module_root/kernel/fs/mbcache" \
  "$module_root/kernel/fs/jbd2" \
  "$module_root/kernel/fs/ext4" \
  "$module_root/kernel/lib" \
  "$module_root/kernel/crypto"
source_root="$extract/lib/modules/$release"
for path in \
  kernel/drivers/virtio/virtio.ko \
  kernel/drivers/virtio/virtio_pci_modern_dev.ko \
  kernel/drivers/virtio/virtio_pci_legacy_dev.ko \
  kernel/drivers/virtio/virtio_pci.ko \
  kernel/drivers/virtio/virtio_ring.ko \
  kernel/drivers/block/virtio_blk.ko \
  kernel/lib/crc16.ko \
  kernel/crypto/crc32c_generic.ko \
  kernel/lib/libcrc32c.ko \
  kernel/fs/mbcache.ko \
  kernel/fs/jbd2/jbd2.ko \
  kernel/fs/ext4/ext4.ko; do
  test -f "$source_root/$path" || { echo "missing required module: $path" >&2; exit 1; }
  mkdir -p "$module_root/$(dirname "$path")"
  cp "$source_root/$path" "$module_root/$path"
done
printf 'ZDOS_PERSISTENCE_MODULES_READY release=%s path=%s bytes=' "$release" "$OUT"
du -sh "$OUT" | cut -f1
