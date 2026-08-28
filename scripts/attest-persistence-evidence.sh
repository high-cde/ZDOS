#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ZLANG_ROOT=${ZLANG_ROOT:-"$ROOT/../Zlang"}
LEDGER=${LEDGER:-"$ROOT/evidence/ledger.jsonl"}
BUILD=${ZDOS_BUILD_DIR:-"$ROOT/distro/build"}
DATA_IMAGE="$BUILD/zdos-persistent-data.img"
DATA_UUID=${DATA_UUID:-"11111111-2222-4333-8444-555555555555"}
KERNEL_VERSION="${ZDOS_KERNEL_VERSION:-unspecified}"
if [[ "$KERNEL_VERSION" == "unspecified" && -n "${ZDOS_KERNEL:-}" ]]; then
  KERNEL_VERSION=$(basename "$ZDOS_KERNEL" | sed 's/^vmlinuz-//')
fi

cd "$ROOT"
"$ROOT/distro/test-persistence-qemu.sh"

python3 "$ROOT/evidence/attest_persistence.py" \
  --ledger "$LEDGER" \
  --image "$DATA_IMAGE" \
  --uuid "$DATA_UUID" \
  --zdos-repo "$ROOT" \
  --kernel "$KERNEL_VERSION"

python3 "$ROOT/evidence/ledger.py" --ledger "$LEDGER" verify
printf 'ZDOS_PERSISTENCE_EVIDENCE_READY ledger=%s\n' "$LEDGER"
