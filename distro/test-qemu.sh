#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ISO="${1:-$ROOT/distro/build/zdos-linux-x86_64.iso}"
if [ ! -f "$ISO" ]; then
  echo "ISO non trovata: $ISO" >&2
  exit 2
fi
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT
set +e
timeout 30s qemu-system-x86_64 -m 512M -cdrom "$ISO" -serial "file:$LOG" -display none -no-reboot -monitor none >/dev/null 2>&1
status=$?
set -e
if grep -Fq 'ZDOS_READY' "$LOG" && grep -Fq 'ZDOS_CONSOLE_USER=zdos mode=unprivileged' "$LOG" && grep -Fq 'x@zdos / $' "$LOG"; then
  printf 'ZDOS_QEMU_TEST_PASSED iso=%s\n' "$ISO"
  exit 0
fi
cat "$LOG" >&2
printf 'ZDOS_QEMU_TEST_FAILED status=%s\n' "$status" >&2
exit 1
