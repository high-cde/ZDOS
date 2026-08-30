#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DISTRO="$ROOT/distro"
BUILD="${ZDOS_BUILD_DIR:-$DISTRO/build}"
SOURCES="$BUILD/sources"
ROOTFS="$BUILD/rootfs"
LOCKFILE="$DISTRO/sources.lock"
JOBS="${JOBS:-$(nproc)}"
ZDOS_BUNDLE_ORGANISM="${ZDOS_BUNDLE_ORGANISM:-1}"
ZDOS_ZLANG_ROOT="${ZDOS_ZLANG_ROOT:-$ROOT/../Zlang}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
for tool in bzip2 curl make gcc cpio gzip file xorriso grub-mkrescue sha256sum; do need "$tool"; done
test -r "$LOCKFILE" || { echo "missing source lockfile: $LOCKFILE" >&2; exit 1; }
# shellcheck source=sources.lock
. "$LOCKFILE"

BUSYBOX_VERSION="${BUSYBOX_VERSION:-$ZDOS_LOCK_BUSYBOX_VERSION}"
BUSYBOX_TARBALL="$SOURCES/busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_URL="${BUSYBOX_URL:-$ZDOS_LOCK_BUSYBOX_URL}"
BUSYBOX_SHA256="${BUSYBOX_SHA256:-$ZDOS_LOCK_BUSYBOX_SHA256}"
# Bootstrap kernel is intentionally locked. A release build must update the
# lockfile with reviewed hashes rather than silently accepting moving inputs.
ZDOS_KERNEL="${ZDOS_KERNEL:-$BUILD/vmlinuz}"
ZDOS_KERNEL_URL="${ZDOS_KERNEL_URL:-$ZDOS_LOCK_KERNEL_URL}"
ZDOS_KERNEL_SHA256="${ZDOS_KERNEL_SHA256:-$ZDOS_LOCK_KERNEL_SHA256}"
ZDOS_MODULES_DIR="${ZDOS_MODULES_DIR:-}"

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

fetch_verified() {
  local url="$1" out="$2" expected="$3" temporary
  if [ -s "$out" ]; then
    verify_sha256 "$out" "$expected"
    return
  fi
  temporary="${out}.tmp.$$"
  trap 'rm -f "$temporary"' RETURN
  curl --fail --location --retry 3 --proto '=https' --tlsv1.2 --output "$temporary" "$url"
  verify_sha256 "$temporary" "$expected"
  mv "$temporary" "$out"
  trap - RETURN
}

mkdir -p "$SOURCES" "$BUILD"
fetch_verified "$ZDOS_KERNEL_URL" "$ZDOS_KERNEL" "$ZDOS_KERNEL_SHA256"
KERNEL_RELEASE=$(file "$ZDOS_KERNEL" | sed -n 's/.*version \([^ ]*\).*/\1/p')
test -n "$KERNEL_RELEASE" || { echo "unable to determine kernel release: $ZDOS_KERNEL" >&2; exit 1; }

if [ -z "$ZDOS_MODULES_DIR" ]; then
  host_modules="/lib/modules/$KERNEL_RELEASE"
  if [ -d "$host_modules" ]; then
    ZDOS_MODULES_DIR="$host_modules"
  elif [ "$KERNEL_RELEASE" = "$ZDOS_LOCK_KERNEL_RELEASE" ]; then
    auto_modules_root="$BUILD/kernel-modules-slim"
    auto_modules_dir="$auto_modules_root/lib/modules/$KERNEL_RELEASE"
    if [ ! -d "$auto_modules_dir" ]; then
      ZDOS_KERNEL="$ZDOS_KERNEL" ZDOS_MODULES_DIR="$auto_modules_root" "$DISTRO/prepare-persistence-modules.sh"
    fi
    ZDOS_MODULES_DIR="$auto_modules_dir"
  else
    echo "kernel modules are unavailable for kernel=$KERNEL_RELEASE" >&2
    echo "set ZDOS_MODULES_DIR to a matching module directory" >&2
    exit 1
  fi
fi

if [ ! -d "$ZDOS_MODULES_DIR" ]; then
  echo "kernel modules directory not found: $ZDOS_MODULES_DIR" >&2
  exit 1
fi
MODULES_RELEASE=$(basename "$ZDOS_MODULES_DIR")
if [ "$KERNEL_RELEASE" != "$MODULES_RELEASE" ]; then
  echo "kernel/modules mismatch: kernel=$KERNEL_RELEASE modules=$MODULES_RELEASE" >&2
  echo "set ZDOS_MODULES_DIR to modules matching ZDOS_KERNEL" >&2
  exit 1
fi

fetch_verified "$BUSYBOX_URL" "$BUSYBOX_TARBALL" "$BUSYBOX_SHA256"
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
mkdir -p "$ROOTFS/lib/modules"
cp -a "$ZDOS_MODULES_DIR" "$ROOTFS/lib/modules/"
if command -v depmod >/dev/null 2>&1; then
  depmod -b "$ROOTFS" "$KERNEL_RELEASE" 2>/dev/null || true
fi
mkdir -p "$ROOTFS/etc" "$ROOTFS/etc/zdos" "$ROOTFS/etc/sysctl.d" "$ROOTFS/etc/modprobe.d" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" "$ROOTFS/tmp" "$ROOTFS/root" "$ROOTFS/home/zdos" "$ROOTFS/var/lib/zdos/organism"
cp "$DISTRO/rootfs/init" "$ROOTFS/init"
cp "$DISTRO/rootfs/etc/inittab" "$ROOTFS/etc/inittab"
cp "$DISTRO/rootfs/etc/motd" "$ROOTFS/etc/motd"
cp "$DISTRO/rootfs/etc/passwd" "$ROOTFS/etc/passwd"
cp "$DISTRO/rootfs/etc/group" "$ROOTFS/etc/group"
cp "$DISTRO/rootfs/etc/shadow" "$ROOTFS/etc/shadow"
cp "$DISTRO/rootfs/etc/gshadow" "$ROOTFS/etc/gshadow"
cp "$DISTRO/rootfs/etc/profile" "$ROOTFS/etc/profile"
cp "$DISTRO/rootfs/etc/shells" "$ROOTFS/etc/shells"
cp "$DISTRO/rootfs/etc/securetty" "$ROOTFS/etc/securetty"
cp "$DISTRO/rootfs/etc/os-release" "$ROOTFS/etc/os-release"
cp "$DISTRO/rootfs/etc/fstab" "$ROOTFS/etc/fstab"
cp "$DISTRO/rootfs/etc/hostname" "$ROOTFS/etc/hostname"
cp "$DISTRO/rootfs/etc/hosts" "$ROOTFS/etc/hosts"
cp "$DISTRO/rootfs/etc/resolv.conf" "$ROOTFS/etc/resolv.conf"
cp "$DISTRO/rootfs/etc/mdev.conf" "$ROOTFS/etc/mdev.conf"
cp "$DISTRO/rootfs/etc/sysctl.d/99-zdos-hardening.conf" "$ROOTFS/etc/sysctl.d/99-zdos-hardening.conf"
cp "$DISTRO/rootfs/etc/modprobe.d/zdos.conf" "$ROOTFS/etc/modprobe.d/zdos.conf"
cp "$DISTRO/rootfs/etc/zdos/organism.conf" "$ROOTFS/etc/zdos/organism.conf"
chmod 0755 "$ROOTFS/init"
chmod 0755 "$ROOTFS/home/zdos"
chmod 0700 "$ROOTFS/var/lib/zdos/organism"
chmod 0644 "$ROOTFS/etc/inittab" "$ROOTFS/etc/motd" "$ROOTFS/etc/passwd" "$ROOTFS/etc/group" "$ROOTFS/etc/shadow" "$ROOTFS/etc/gshadow" "$ROOTFS/etc/profile" "$ROOTFS/etc/shells" "$ROOTFS/etc/securetty" "$ROOTFS/etc/os-release" "$ROOTFS/etc/fstab" "$ROOTFS/etc/hostname" "$ROOTFS/etc/hosts" "$ROOTFS/etc/resolv.conf" "$ROOTFS/etc/mdev.conf" "$ROOTFS/etc/sysctl.d/99-zdos-hardening.conf" "$ROOTFS/etc/modprobe.d/zdos.conf" "$ROOTFS/etc/zdos/organism.conf"

if [ "$ZDOS_BUNDLE_ORGANISM" = 1 ]; then
  need python3
  test -f "$ZDOS_ZLANG_ROOT/tools/zlangc.py" || { echo "missing Zlang compiler: $ZDOS_ZLANG_ROOT/tools/zlangc.py" >&2; exit 1; }
  PYTHON_BIN=$(readlink -f "$(command -v python3)")
  PYTHON_STDLIB=$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')
  mkdir -p "$ROOTFS/usr/bin" "$ROOTFS/usr/lib/zdos/Zlang/tools" "$ROOTFS/usr/share"
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
ln -sf /proc/mounts "$ROOTFS/etc/mtab"
rm -f "$BUILD/initramfs.cpio.gz"
( cd "$ROOTFS" && find . -print0 | LC_ALL=C sort -z | cpio --null -ov --owner=0:0 --format=newc 2>/dev/null | gzip -n -9 > "$BUILD/initramfs.cpio.gz" )
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
printf 'ZDOS_KERNEL_RELEASE=%s\n' "$KERNEL_RELEASE"
printf 'ZDOS_MODULES_DIR=%s\n' "$ZDOS_MODULES_DIR"
sha256sum "$BUILD/zdos-linux-x86_64.iso" > "$BUILD/zdos-linux-x86_64.iso.sha256"
