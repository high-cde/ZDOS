#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

REPO="${ZDOS_REPO:-$HOME/ZDOS}"
PATCH_URL="https://files.manuscdn.com/user_upload_by_module/session_file/310519663994341469/echkABxkaaxhtPLb.patch"
SOURCE_REPO="https://github.com/high-cde/ZDOS.git"
SOURCE_BRANCH="feat/glass-engine-console"
TMP="${TMPDIR:-/tmp}/zdos-install-all"
mkdir -p "$TMP"

fail() { echo "ERRORE: $*" >&2; exit 1; }
trap 'echo "Autobuild fallito alla riga $LINENO" >&2; systemctl --user --no-pager status zdos-glass-engine.service 2>/dev/null || true' ERR

for cmd in git wget curl python3 npm systemctl; do command -v "$cmd" >/dev/null 2>&1 || fail "comando mancante: $cmd"; done

echo "=== ZDOS ALL-IN-ONE INSTALLER ==="

if [ ! -d "$REPO/.git" ]; then
  echo "[1/8] Clono ZDOS in $REPO..."
  git clone https://github.com/high-cde/ZDOS.git "$REPO"
fi
cd "$REPO"

# Se un'esecuzione precedente è rimasta dentro git am, la chiudiamo. Se Git
# ha lasciato solo conflitti unmerged, ripristiniamo esclusivamente quei file
# dalla revisione HEAD: nessun altro file viene modificato o cancellato.
git am --abort >/dev/null 2>&1 || true
while IFS= read -r conflicted; do
  [ -z "$conflicted" ] && continue
  git restore --source=HEAD --staged --worktree -- "$conflicted"
done < <(git diff --name-only --diff-filter=U)

if [ -n "$(git status --porcelain)" ]; then
  echo "Repository con modifiche locali; non eseguo reset o cancellazioni:"
  git status --short
  fail "salva le modifiche locali e rilancia"
fi

if ! grep -q 'xcloud-workbench' interface/web/web/index.html 2>/dev/null || \
   ! grep -q '/api/local/evidence/wallet' interface/web/server/server.js 2>/dev/null || \
   ! test -f hydro/zdos_hydro_guard.zlang; then
  echo "[2/8] Sincronizzo i componenti dal branch GitHub..."
  git branch "backup-before-zdos-all-$(date +%Y%m%d-%H%M%S)"
  git fetch --depth=1 "$SOURCE_REPO" "$SOURCE_BRANCH"
  git checkout FETCH_HEAD -- \
    interface/web/server/server.js \
    interface/web/web/index.html \
    interface/web/web/js/app.js \
    interface/web/web/css/style.css \
    docs/EVIDENCE-WALLET.md \
    docs/EVIDENCE-CHAIN-INDUSTRIAL-PLATFORM.md \
    docs/HYDRO-GUARD-SAFE-MODULE.md \
    supply-chain/zdos-trace-event.schema.json \
    supply-chain/zdos-trace-event.example.json \
    tools/validate-zdos-trace-event.py \
    tools/evaluate-hydro-telemetry.py \
    scripts/autobuild-evidence-chain.sh \
    scripts/install-glass-engine-desktop.sh \
    hydro/zdos_hydro_guard.zlang \
    hydro/telemetry.example.json
  chmod +x scripts/autobuild-evidence-chain.sh tools/evaluate-hydro-telemetry.py
  git add interface/web docs supply-chain tools scripts hydro
  git -c user.name="ZDOS Installer" -c user.email="installer@zdos.local" commit -m "chore: install ZDOS Glass Engine suite"
else
  echo "[2/8] Componenti già presenti; salto la patch."
fi

chmod +x scripts/autobuild-evidence-chain.sh tools/evaluate-hydro-telemetry.py

echo "[3/8] Verifico Hydro Guard..."
python3 tools/evaluate-hydro-telemetry.py hydro/telemetry.example.json | tee "$TMP/hydro.json"
grep -q '"policy": "DEFAULT-DENY"' "$TMP/hydro.json"
grep -q '"radio_tx": false' "$TMP/hydro.json"
grep -q '"siren_actuation": false' "$TMP/hydro.json"

echo "[4/8] Verifico filiera CTE/KDE..."
python3 tools/validate-zdos-trace-event.py supply-chain/zdos-trace-event.example.json
python3 -m json.tool supply-chain/zdos-trace-event.schema.json >/dev/null

echo "[5/8] Controllo JavaScript..."
npm --prefix interface/web ci --ignore-scripts
npm --prefix interface/web run check

echo "[6/8] Installa console, servizio e launcher..."
bash scripts/install-glass-engine-ubuntu.sh
bash scripts/install-glass-engine-desktop.sh
systemctl --user daemon-reload
systemctl --user restart zdos-glass-engine.service
sleep 3

if ! systemctl --user is-active --quiet zdos-glass-engine.service; then
  echo "Servizio non persistente: eseguo il repair dell'unità."
  APP_DIR=$(systemctl --user show zdos-glass-engine.service -p WorkingDirectory --value 2>/dev/null || true)
  APP_DIR=${APP_DIR:-$HOME/.local/share/zdos-glass-engine/interface/web}
  test -f "$APP_DIR/server/server.js"
  UNIT_FILE=$(systemctl --user show zdos-glass-engine.service -p FragmentPath --value)
  cat > "$UNIT_FILE" <<EOF
[Unit]
Description=ZDOS Glass Engine local read-only console
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/server/server.js
Environment=HOST=127.0.0.1
Environment=PORT=8080
Environment=NODE_ENV=production
Restart=always
RestartSec=2
KillMode=control-group
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$APP_DIR
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user reset-failed zdos-glass-engine.service || true
  systemctl --user restart zdos-glass-engine.service
  sleep 3
fi
systemctl --user is-active --quiet zdos-glass-engine.service

echo "[7/8] Verifico API e dashboard..."
curl --fail-with-body -sS http://127.0.0.1:8080/status | python3 -m json.tool | head -30
curl --fail-with-body -sS http://127.0.0.1:8080/api/local/evidence/wallet | python3 -c '
import json, sys
d=json.load(sys.stdin)
assert d["schema"] == "zdos.evidence-wallet.v1"
assert d["wallet_type"] == "NON_CUSTODIAL_READ_ONLY"
assert d["monetary_assets"] is False
print("EVIDENCE_WALLET_OK")
'
curl --fail-with-body -sS http://127.0.0.1:8080/ | grep -q 'id="dashboards-workbench"'
curl --fail-with-body -sS http://127.0.0.1:8080/ | grep -q 'id="evidence-wallet"'

echo "[8/8] Avvio interfaccia..."
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://127.0.0.1:8080/#top >/dev/null 2>&1 &
fi

echo
echo "=== ZDOS INSTALLATO E AVVIATO ==="
echo "Home:          http://127.0.0.1:8080"
echo "Control Tower: http://127.0.0.1:8080/#dashboards-workbench"
echo "Evidence:      http://127.0.0.1:8080/#evidence-wallet"
echo "PC Analysis:   http://127.0.0.1:8080/#system-workbench"
echo "Audit:         http://127.0.0.1:8080/#audit-workbench"
echo "Hydro Guard:   $REPO/hydro/zdos_hydro_guard.zlang"
echo "Service:       systemctl --user status zdos-glass-engine.service"
echo "Policy:        DEFAULT-DENY / loopback only / no radio TX"
