#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD="${ZDOS_BUILD_DIR:-$ROOT/distro/build}"
ISO_KERNEL="$BUILD/iso/boot/vmlinuz"
INITRAMFS="$BUILD/iso/boot/initramfs.cpio.gz"
DATA_IMAGE="$BUILD/zdos-persistent-data.img"
DATA_UUID="11111111-2222-4333-8444-555555555555"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
for tool in qemu-img mkfs.ext4 qemu-system-x86_64 timeout; do need "$tool"; done

"$ROOT/distro/build.sh" >/tmp/zdos-persistence-build.log
mkdir -p "$BUILD"
rm -f "$DATA_IMAGE"
qemu-img create -f raw "$DATA_IMAGE" 128M >/dev/null
mkfs.ext4 -F -U "$DATA_UUID" "$DATA_IMAGE" >/tmp/zdos-persistence-mkfs.log 2>&1

boot_and_expect() {
  local mode="$1"
  local expected="$2"
  local log
  log=$(mktemp)
  set +e
  timeout 20s qemu-system-x86_64 \
    -m 512M \
    -kernel "$ISO_KERNEL" \
    -initrd "$INITRAMFS" \
    -append "console=ttyS0,115200n8 init=/init zdos.data_uuid=$DATA_UUID zdos.persistence_test=$mode" \
    -drive "file=$DATA_IMAGE,format=raw,if=ide" \
    -serial "file:$log" -display none -no-reboot -monitor none >/dev/null 2>&1
  local status=$?
  set -e
  if [ "$status" -ne 124 ] || ! grep -Fq "$expected" "$log"; then
    cat "$log" >&2
    rm -f "$log"
    echo "ZDOS_PERSISTENCE_${mode^^}_FAILED" >&2
    exit 1
  fi
  rm -f "$log"
}

boot_and_expect write ZDOS_PERSISTENCE_WRITE_OK
boot_and_expect read ZDOS_PERSISTENCE_READ_OK
printf 'ZDOS_PERSISTENCE_QEMU_TEST_PASSED uuid=%s\n' "$DATA_UUID"
