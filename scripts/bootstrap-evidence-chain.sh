#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LEDGER=$(mktemp "${TMPDIR:-/tmp}/zdos-evidence.XXXXXX.jsonl")
trap 'rm -f "$LEDGER"' EXIT

cd "$ROOT"
python3 -m py_compile evidence/ledger.py
python3 -m json.tool evidence/policy.release.json >/dev/null

python3 evidence/ledger.py --ledger "$LEDGER" init --network local-dev
python3 evidence/ledger.py --ledger "$LEDGER" attest \
  --type build.attestation \
  --subject "git:$(git rev-parse HEAD)" \
  --result verified \
  --builder did:zdos:ci-local \
  --policy policy://release/production-v1 \
  --source-commit "$(git rev-parse HEAD)" \
  --toolchain zlang-zlb2-2.5
python3 evidence/ledger.py --ledger "$LEDGER" attest \
  --type boot.attestation \
  --subject "git:$(git rev-parse HEAD)" \
  --result verified \
  --builder did:zdos:qemu-local \
  --policy policy://release/production-v1 \
  --source-commit "$(git rev-parse HEAD)" \
  --toolchain qemu-x86_64
python3 evidence/ledger.py --ledger "$LEDGER" verify
printf 'ZDOS_EVIDENCE_CHAIN_READY ledger=%s\n' "$LEDGER"
