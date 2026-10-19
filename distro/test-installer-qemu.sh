#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ISO=${1:-$ROOT/distro/build/zdos-linux-x86_64.iso}
[[ $EUID -eq 0 ]] || { echo 'run as root: this test uses a disposable loop device' >&2; exit 2; }
for tool in losetup qemu-system-x86_64 timeout; do
  command -v "$tool" >/dev/null || { echo "missing required command: $tool" >&2; exit 2; }
done
[[ -f $ISO ]] || { echo "ISO not found: $ISO" >&2; exit 2; }
TMP=$(mktemp -d)
IMAGE=$TMP/installer-test.img
LOG=$TMP/serial.log
LOOP=
cleanup() {
  [[ -z $LOOP ]] || losetup -d "$LOOP" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT
truncate -s 1G "$IMAGE"
LOOP=$(losetup --find --show --partscan "$IMAGE")
printf 'zdos-test-password-42\nzdos-test-password-42\n' | \
  ZDOS_INSTALL_TEST=1 "$ROOT/distro/install.sh" --iso "$ISO" --device "$LOOP" --yes
losetup -d "$LOOP"
LOOP=

set +e
timeout 60s qemu-system-x86_64 \
  -m 512M -drive "file=$IMAGE,format=raw,if=ide" \
  -serial "file:$LOG" -display none -no-reboot -monitor none >/dev/null 2>&1
status=$?
set -e
if grep -Fq 'ZDOS_ROOT_PIVOT' "$LOG" && grep -Fq 'ZDOS_READY' "$LOG" && grep -Fq 'ZDOS_CONSOLE_USER=zdos mode=unprivileged' "$LOG"; then
  printf 'ZDOS_INSTALLER_QEMU_TEST_PASSED\n'
else
  cat "$LOG" >&2
  printf 'ZDOS_INSTALLER_QEMU_TEST_FAILED status=%s\n' "$status" >&2
  exit 1
fi
