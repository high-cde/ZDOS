#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ZLANG_ROOT=${ZLANG_ROOT:-"$ROOT/../Zlang"}
LEDGER=${LEDGER:-"$ROOT/evidence/ledger.jsonl"}
BOOT_LOG=$(mktemp "${TMPDIR:-/tmp}/zdos-zlang-boot.XXXXXX.log")
WORK_LEDGER=$(mktemp "${TMPDIR:-/tmp}/zdos-evolution.XXXXXX.jsonl")
trap 'rm -f "$BOOT_LOG" "$WORK_LEDGER"' EXIT

if [[ ! -d "$ZLANG_ROOT" ]]; then
  echo "ZLANG_ROOT non trovato: $ZLANG_ROOT" >&2
  exit 1
fi

cd "$ROOT"
python3 -m py_compile evidence/ledger.py evidence/attest_zlang.py
python3 -m json.tool evidence/policy.release.json >/dev/null

make -C os/x86_64 clean
make -C os/x86_64 verify ZLANGC="$ZLANG_ROOT/tools/zlangc.py"
ZLANGC="$ZLANG_ROOT/tools/zlangc.py" sh os/x86_64/tools/verify_qemu.sh >"$BOOT_LOG"

python3 evidence/ledger.py --ledger "$WORK_LEDGER" init --network local-dev
python3 evidence/attest_zlang.py \
  --ledger "$WORK_LEDGER" \
  --source os/x86_64/programs/boot.zlang \
  --bytecode os/x86_64/build/programs/boot.zlb \
  --header os/x86_64/build/generated/zlang_program.h \
  --boot-log "$BOOT_LOG" \
  --zlang-repo "$ZLANG_ROOT" \
  --zdos-repo "$ROOT"
python3 evidence/ledger.py --ledger "$WORK_LEDGER" verify

mkdir -p "$(dirname "$LEDGER")"
if [[ -s "$LEDGER" ]]; then
  python3 evidence/ledger.py --ledger "$LEDGER" verify >/dev/null
else
  python3 evidence/ledger.py --ledger "$LEDGER" init --network local-dev >/dev/null
fi
python3 evidence/attest_zlang.py \
  --ledger "$LEDGER" \
  --source os/x86_64/programs/boot.zlang \
  --bytecode os/x86_64/build/programs/boot.zlb \
  --header os/x86_64/build/generated/zlang_program.h \
  --boot-log "$BOOT_LOG" \
  --zlang-repo "$ZLANG_ROOT" \
  --zdos-repo "$ROOT" >/dev/null
python3 evidence/ledger.py --ledger "$LEDGER" verify
printf 'ZDOS_ZLANG_EVOLUTION_READY ledger=%s\n' "$LEDGER"
