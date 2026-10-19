#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD=${ZDOS_BUILD_DIR:-$ROOT/distro/build}
UUID=22222222-3333-4444-8555-666666666666
TMP=$(mktemp -d)
LOG=$TMP/serial.log
trap 'rm -rf "$TMP"' EXIT

for tool in qemu-system-x86_64 mke2fs timeout; do
  command -v "$tool" >/dev/null || { echo "missing required command: $tool" >&2; exit 2; }
done
[[ -f $BUILD/vmlinuz && -f $BUILD/initramfs.cpio.gz && -d $BUILD/rootfs ]] || "$ROOT/distro/build.sh" >/dev/null
cp -a "$BUILD/rootfs" "$TMP/rootfs"
printf 'installed\n' > "$TMP/rootfs/etc/zdos/installed"
truncate -s 256M "$TMP/root.img"
mke2fs -q -t ext4 -F -U "$UUID" -d "$TMP/rootfs" "$TMP/root.img"

set +e
timeout 60s qemu-system-x86_64 \
  -m 512M -kernel "$BUILD/vmlinuz" -initrd "$BUILD/initramfs.cpio.gz" \
  -append "console=ttyS0,115200n8 loglevel=3 init=/init zdos.root_uuid=$UUID" \
  -drive "file=$TMP/root.img,format=raw,if=none,id=zdosroot" \
  -device virtio-blk-pci,drive=zdosroot \
  -serial "file:$LOG" -display none -no-reboot -monitor none >/dev/null 2>&1
status=$?
set -e
if grep -Fq "ZDOS_ROOT_PIVOT uuid=$UUID" "$LOG" && grep -Fq 'ZDOS_READY' "$LOG" && grep -Fq 'ZDOS_CONSOLE_USER=zdos mode=unprivileged' "$LOG"; then
  printf 'ZDOS_INSTALLED_ROOT_QEMU_TEST_PASSED uuid=%s\n' "$UUID"
else
  cat "$LOG" >&2
  printf 'ZDOS_INSTALLED_ROOT_QEMU_TEST_FAILED status=%s\n' "$status" >&2
  exit 1
fi
