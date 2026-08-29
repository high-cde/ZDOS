#!/usr/bin/env bash
set -u
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
set -e
if grep -Fq 'ZDOS_READY' "$LOG" && grep -Fq 'x@zdos / #' "$LOG"; then
  echo 'ZDOS_QEMU_TEST_PASSED'
  exit 0
fi
cat "$LOG" >&2
echo 'ZDOS_QEMU_TEST_FAILED' >&2
exit 1
