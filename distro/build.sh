#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DISTRO="$ROOT/distro"
BUILD="${ZDOS_BUILD_DIR:-$DISTRO/build}"
SOURCES="$BUILD/sources"
ROOTFS="$BUILD/rootfs"
JOBS="${JOBS:-$(nproc)}"
ZDOS_BUNDLE_ORGANISM="${ZDOS_BUNDLE_ORGANISM:-1}"
ZDOS_ZLANG_ROOT="${ZDOS_ZLANG_ROOT:-$ROOT/../Zlang}"
BUSYBOX_VERSION="${BUSYBOX_VERSION:-1.36.1}"
BUSYBOX_TARBALL="$SOURCES/busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
# Bootstrap kernel: small, prebuilt Debian netboot kernel. Replace with a locally
# built Linux bzImage using ZDOS_KERNEL for a fully source-reproducible release.
ZDOS_KERNEL="${ZDOS_KERNEL:-$BUILD/vmlinuz}"
ZDOS_KERNEL_URL="${ZDOS_KERNEL_URL:-https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux}"
ZDOS_MODULES_DIR="${ZDOS_MODULES_DIR:-/lib/modules/$(uname -r)}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
for tool in curl make gcc cpio gzip file xorriso grub-mkrescue; do need "$tool"; done
mkdir -p "$SOURCES" "$BUILD"

if [ ! -s "$ZDOS_KERNEL" ]; then
  echo "Downloading bootstrap Linux kernel"
  curl --fail --location --retry 3 --output "$ZDOS_KERNEL" "$ZDOS_KERNEL_URL"
fi
KERNEL_RELEASE=$(file "$ZDOS_KERNEL" | sed -n 's/.*version \([^ ]*\).*/\1/p')
if [ -n "$KERNEL_RELEASE" ] && [ -d "$ZDOS_MODULES_DIR" ]; then
  MODULES_RELEASE=$(basename "$ZDOS_MODULES_DIR")
  if [ "$KERNEL_RELEASE" != "$MODULES_RELEASE" ]; then
    echo "kernel/modules mismatch: kernel=$KERNEL_RELEASE modules=$MODULES_RELEASE" >&2
    echo "set ZDOS_MODULES_DIR to modules matching ZDOS_KERNEL" >&2
    exit 1
  fi
fi

fetch() {
  local url="$1" out="$2"
  [ -s "$out" ] || curl --fail --location --retry 3 --output "$out" "$url"
}
fetch "$BUSYBOX_URL" "$BUSYBOX_TARBALL"
if [ ! -d "$BUILD/busybox-${BUSYBOX_VERSION}" ]; then tar -xf "$BUSYBOX_TARBALL" -C "$BUILD"; fi
BUSYBOX="$BUILD/busybox-${BUSYBOX_VERSION}"
if [ ! -f "$BUSYBOX/.zdos-configured" ] || ! grep -q '^CONFIG_BLKID=y' "$BUSYBOX/.config" || ! grep -q '^CONFIG_FEATURE_VOLUMEID_EXT=y' "$BUSYBOX/.config" || ! grep -q '^CONFIG_MODPROBE_SMALL=y' "$BUSYBOX/.config" || ! grep -q '^CONFIG_MDEV=y' "$BUSYBOX/.config" || grep -q '^CONFIG_TC=y' "$BUSYBOX/.config"; then
  make -C "$BUSYBOX" distclean
  make -C "$BUSYBOX" defconfig
  set_bool() {
    local option="$1"
    if grep -q "^# $option is not set" "$BUSYBOX/.config"; then
      sed -i "s/^# $option is not set/$option=y/" "$BUSYBOX/.config"
    elif grep -q "^$option=" "$BUSYBOX/.config"; then
      sed -i "s/^$option=.*/$option=y/" "$BUSYBOX/.config"
    else
      printf '%s=y\n' "$option" >> "$BUSYBOX/.config"
    fi
  }
  set_unbool() {
    local option="$1"
    if grep -q "^$option=" "$BUSYBOX/.config"; then
      sed -i "s/^$option=.*/# $option is not set/" "$BUSYBOX/.config"
    elif ! grep -q "^# $option is not set" "$BUSYBOX/.config"; then
      printf '# %s is not set\n' "$option" >> "$BUSYBOX/.config"
    fi
  }
  set_bool CONFIG_STATIC
  set_bool CONFIG_BLKID
  set_bool CONFIG_FEATURE_VOLUMEID_EXT
  set_bool CONFIG_MODPROBE_SMALL
  set_bool CONFIG_MDEV
  # tc depends on host kernel traffic-control headers and is not needed by ZDOS.
  set_unbool CONFIG_TC
  make -C "$BUSYBOX" oldconfig </dev/null
  touch "$BUSYBOX/.zdos-configured"
fi
make -C "$BUSYBOX" -j"$JOBS"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"
make -C "$BUSYBOX" CONFIG_PREFIX="$ROOTFS" install
if [ -d "$ZDOS_MODULES_DIR" ]; then
  mkdir -p "$ROOTFS/lib/modules"
  cp -a "$ZDOS_MODULES_DIR" "$ROOTFS/lib/modules/"
  if command -v depmod >/dev/null 2>&1; then
    depmod -b "$ROOTFS" "$(basename "$ZDOS_MODULES_DIR")" 2>/dev/null || true
  fi
fi
mkdir -p "$ROOTFS/etc" "$ROOTFS/etc/zdos" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" "$ROOTFS/tmp" "$ROOTFS/root"
cp "$DISTRO/rootfs/init" "$ROOTFS/init"
cp "$DISTRO/rootfs/etc/inittab" "$ROOTFS/etc/inittab"
cp "$DISTRO/rootfs/etc/motd" "$ROOTFS/etc/motd"
cp "$DISTRO/rootfs/etc/passwd" "$ROOTFS/etc/passwd"
cp "$DISTRO/rootfs/etc/group" "$ROOTFS/etc/group"
cp "$DISTRO/rootfs/etc/profile" "$ROOTFS/etc/profile"
cp "$DISTRO/rootfs/etc/zdos/organism.conf" "$ROOTFS/etc/zdos/organism.conf"

if [ "$ZDOS_BUNDLE_ORGANISM" = 1 ]; then
  need python3
  test -f "$ZDOS_ZLANG_ROOT/tools/zlangc.py" || { echo "missing Zlang compiler: $ZDOS_ZLANG_ROOT/tools/zlangc.py" >&2; exit 1; }
  PYTHON_BIN=$(readlink -f "$(command -v python3)")
  PYTHON_STDLIB=$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')
  mkdir -p "$ROOTFS/usr/bin" "$ROOTFS/usr/lib/zdos/Zlang/tools" "$ROOTFS/usr/share" "$ROOTFS/var/lib/zdos/organism"
  cp -L "$PYTHON_BIN" "$ROOTFS/usr/bin/python3"
  cp -a "$PYTHON_STDLIB" "$ROOTFS/usr/lib/"
  cp "$ROOT/services/zdos-organismd.py" "$ROOTFS/usr/lib/zdos/zdos-organismd.py"
  cp "$ROOT/services/main.zlang" "$ROOTFS/usr/share/zdos-main.zlang"
  cp "$ZDOS_ZLANG_ROOT/tools/zlangc.py" "$ROOTFS/usr/lib/zdos/Zlang/tools/zlangc.py"
  ldd "$PYTHON_BIN" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^\/.*\.so/) print $i}' | sort -u | while read -r library; do
    [ -f "$library" ] || continue
    mkdir -p "$ROOTFS$(dirname "$library")"
    cp -L "$library" "$ROOTFS$library"
  done
fi
chmod 0755 "$ROOTFS/init"
ln -sf /proc/mounts "$ROOTFS/etc/mtab"
rm -f "$BUILD/initramfs.cpio.gz"
( cd "$ROOTFS" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$BUILD/initramfs.cpio.gz" )
ISO_DIR="$BUILD/iso"
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot/grub"
cp "$ZDOS_KERNEL" "$ISO_DIR/boot/vmlinuz"
cp "$BUILD/initramfs.cpio.gz" "$ISO_DIR/boot/initramfs.cpio.gz"
cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set timeout=0
set default=0
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry "ZDOS Linux" {
  linux /boot/vmlinuz console=ttyS0,115200n8 init=/init
  initrd /boot/initramfs.cpio.gz
}
EOF
grub-mkrescue -o "$BUILD/zdos-linux-x86_64.iso" "$ISO_DIR" >/dev/null
printf 'ZDOS_ISO=%s\n' "$BUILD/zdos-linux-x86_64.iso"
