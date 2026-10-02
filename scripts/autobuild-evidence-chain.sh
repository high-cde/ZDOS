#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

REPO="${ZDOS_REPO:-$HOME/ZDOS}"
WALLET_PATCH_URL="https://files.manuscdn.com/user_upload_by_module/session_file/310519663994341469/QNFtEheBGEIOobbX.patch"
INDUSTRIAL_PATCH_URL="https://files.manuscdn.com/user_upload_by_module/session_file/310519663994341469/gxWBReXRkdWgRapT.patch"
TMP_DIR="${TMPDIR:-/tmp}/zdos-autobuild"
mkdir -p "$TMP_DIR"

on_error() {
  echo
  echo "[ERROR] Autobuild interrotto alla riga $1" >&2
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user --no-pager --full status zdos-glass-engine.service 2>/dev/null | sed -n '1,24p' || true
    journalctl --user -u zdos-glass-engine.service -n 30 --no-pager 2>/dev/null || true
  fi
}
trap 'on_error $LINENO' ERR

need() { command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] comando mancante: $1" >&2; exit 2; }; }
need git; need wget; need curl; need python3; need npm; need systemctl

cd "$REPO"
[[ -d .git ]] || { echo "[ERROR] repository non trovato: $REPO" >&2; exit 1; }

backup_once() {
  local name="backup-before-evidence-autobuild-$(date +%Y%m%d-%H%M%S)"
  git branch "$name"
  echo "Backup branch: $name"
}

apply_patch_if_missing() {
  local marker="$1" url="$2" file="$3"
  if grep -q "$marker" "$file" 2>/dev/null; then
    echo "OK già presente: $marker"
    return 0
  fi
  local patch="$TMP_DIR/$(basename "$file").patch"
  echo "Scarico patch: $url"
  wget -q --show-progress -O "$patch" "$url"
  test -s "$patch"
  echo "Applico patch: $patch"
  git am --3way "$patch"
}

echo "=== ZDOS EVIDENCE CHAIN AUTOBUILD ==="
echo "Repository: $REPO"
echo "Branch: $(git branch --show-current)"
echo "Commit iniziale: $(git rev-parse --short HEAD)"

if [ -n "$(git status --porcelain)" ]; then
  echo "[ERROR] repository con modifiche locali; nessun reset distruttivo verrà eseguito:" >&2
  git status --short >&2
  exit 1
fi

backup_once

# 1. Evidence Wallet e route locale read-only.
apply_patch_if_missing "/api/local/evidence/wallet" "$WALLET_PATCH_URL" "interface/web/server/server.js"

# 2. Blueprint/schema industriale CTE/KDE.
apply_patch_if_missing "Industrial Traceability Platform" "$INDUSTRIAL_PATCH_URL" "docs/EVIDENCE-CHAIN-INDUSTRIAL-PLATFORM.md"

# 3. Gate sorgente.
echo "[1/7] Controllo artefatti:"
test -s interface/web/server/server.js
test -s interface/web/web/index.html
test -s docs/EVIDENCE-WALLET.md
test -s docs/EVIDENCE-CHAIN-INDUSTRIAL-PLATFORM.md
test -s supply-chain/zdos-trace-event.schema.json
test -s supply-chain/zdos-trace-event.example.json
test -x tools/validate-zdos-trace-event.py

echo "[2/7] Verifico evento CTE/KDE:"
python3 tools/validate-zdos-trace-event.py supply-chain/zdos-trace-event.example.json

echo "[3/7] Verifico JSON:"
python3 -m json.tool supply-chain/zdos-trace-event.schema.json >/dev/null
python3 -m json.tool supply-chain/zdos-trace-event.example.json >/dev/null

echo "[4/7] Controllo JavaScript:"
npm --prefix interface/web ci --ignore-scripts
npm --prefix interface/web run check

echo "[5/7] Installo la console e il servizio:"
bash scripts/install-glass-engine-ubuntu.sh

echo "[6/7] Installo launcher desktop e riavvio il processo:"
bash scripts/install-glass-engine-desktop.sh
systemctl --user daemon-reload
systemctl --user restart zdos-glass-engine.service
sleep 3

echo "[7/7] Verifiche HTTP:"
curl --fail-with-body -sS http://127.0.0.1:8080/status
printf '\n'
curl --fail-with-body -sS http://127.0.0.1:8080/api/local/evidence/wallet | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["schema"] == "zdos.evidence-wallet.v1"
assert data["wallet_type"] == "NON_CUSTODIAL_READ_ONLY"
assert data["monetary_assets"] is False
assert "wallet.transfer-v1" in data["denied"]
assert "wallet.sign-transaction-v1" in data["denied"]
print("EVIDENCE_WALLET_READONLY_OK")
print("CHAIN_STATUS=" + data["ledger"]["verification"]["status"])
print("IDENTITY_STATUS=" + data["identity"]["status"])
'
curl --fail-with-body -sS "http://127.0.0.1:8080/api/local/browser?url=https%3A%2F%2Fapp.x-zdos.it%2F" | head -c 400
printf '\n'

echo
echo "=== AUTOBUILD COMPLETATO ==="
echo "Console: http://127.0.0.1:8080"
echo "Evidence Wallet: http://127.0.0.1:8080/#evidence-wallet"
echo "Traceability blueprint: docs/EVIDENCE-CHAIN-INDUSTRIAL-PLATFORM.md"
echo "Desktop launcher: ZDOS Glass Engine"
echo "Servizio: systemctl --user status zdos-glass-engine.service"
echo "Sicurezza: loopback only; routing/firewall/subnet non modificati"
