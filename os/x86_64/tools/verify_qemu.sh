#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

if [ -n "${ZLANGC:-}" ]; then
    make -C "$ROOT" ZLANGC="$ZLANGC" all
else
    make -C "$ROOT" all
fi

set +e
timeout 20s qemu-system-x86_64 \
    -cdrom "$ROOT/build/zdos-x86_64.iso" \
    -serial "file:$LOG" \
    -display none \
    -no-reboot \
    -no-shutdown >/dev/null 2>&1
STATUS=$?
set -e

if [ "$STATUS" -ne 124 ]; then
    cat "$LOG"
    echo "ZDOS: QEMU ha terminato in modo inatteso (status $STATUS)" >&2
    exit 1
fi

for EXPECTED in \
    'ZDOS x86_64 bootstrap' \
    'Zlang runtime ZLB2 v2.5 ready' \
    'ZDOS: native Zlang program executed' \
    'ZDOS: Zlang halted cleanly'
do
    if ! grep -Fq "$EXPECTED" "$LOG"; then
        cat "$LOG"
        echo "ZDOS: output di boot incompleto: $EXPECTED" >&2
        exit 1
    fi
done

cat "$LOG"
echo 'ZDOS: verifica end-to-end superata'
