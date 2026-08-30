#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DISTRO="$ROOT/distro"
BUILD="${ZDOS_BUILD_DIR:-$DISTRO/build}"
KERNEL="${ZDOS_KERNEL:-$BUILD/vmlinuz}"
OUT="${ZDOS_MODULES_DIR:-$BUILD/kernel-modules-slim}"
LOCKFILE="$DISTRO/sources.lock"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
for tool in file curl dpkg-deb cp mkdir rm sha256sum; do need "$tool"; done
test -r "$LOCKFILE" || { echo "missing source lockfile: $LOCKFILE" >&2; exit 1; }
# shellcheck source=sources.lock
. "$LOCKFILE"
test -s "$KERNEL" || { echo "missing kernel: $KERNEL" >&2; exit 1; }

verify_sha256() {
  local path="$1" expected="$2" actual
  [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "invalid SHA-256 for $path" >&2; exit 1; }
  actual=$(sha256sum "$path" | awk '{print $1}')
  [ "$actual" = "$expected" ] || {
    echo "SHA-256 mismatch for $path" >&2
    echo "expected=$expected actual=$actual" >&2
    exit 1
  }
}

release=$(file "$KERNEL" | sed -n 's/.*version \([^ ]*\).*/\1/p')
[ "$release" = "$ZDOS_LOCK_KERNEL_RELEASE" ] || {
  echo "kernel ABI not covered by sources.lock: ${release:-unknown}" >&2
  echo "provide ZDOS_MODULES_DIR explicitly for a custom kernel" >&2
  exit 1
}

cache="$BUILD/sources/debian"
mkdir -p "$cache"
package="$cache/$(basename "$ZDOS_LOCK_KERNEL_PACKAGE_URL")"
if [ ! -s "$package" ]; then
  temporary="${package}.tmp.$$"
  trap 'rm -f "$temporary"' EXIT
  curl --fail --location --retry 3 --proto '=https' --tlsv1.2 --output "$temporary" "$ZDOS_LOCK_KERNEL_PACKAGE_URL"
  verify_sha256 "$temporary" "$ZDOS_LOCK_KERNEL_PACKAGE_SHA256"
  mv "$temporary" "$package"
  trap - EXIT
fi
verify_sha256 "$package" "$ZDOS_LOCK_KERNEL_PACKAGE_SHA256"

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
