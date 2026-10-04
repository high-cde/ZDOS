#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ZDOS_GLASS_APP_DIR:-$HOME/.local/share/zdos-glass-engine}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT="$UNIT_DIR/zdos-glass-engine.service"
PORT="${ZDOS_GLASS_PORT:-8080}"
HOST="${ZDOS_GLASS_HOST:-127.0.0.1}"
BRIDGE_TOKEN_FILE="${ZDOS_BRIDGE_TOKEN_FILE:-$HOME/.config/zdos/bridge.token}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] comando assente: $1" >&2; exit 2; }; }
need node
need npm
need systemctl
[[ -f "$ROOT/interface/web/package-lock.json" ]] || { echo "[ERROR] package-lock.json mancante" >&2; exit 1; }

mkdir -p "$APP_DIR" "$UNIT_DIR"
if [[ "${ZDOS_LAN:-0}" == "1" ]]; then
  mkdir -p "$(dirname "$BRIDGE_TOKEN_FILE")"
  if [[ ! -s "$BRIDGE_TOKEN_FILE" ]]; then
    umask 077
    head -c 32 /dev/urandom | base64 | tr -d '\n' > "$BRIDGE_TOKEN_FILE"
  fi
  chmod 600 "$BRIDGE_TOKEN_FILE"
fi
rm -rf "$APP_DIR/interface"
mkdir -p "$APP_DIR"
cp -a "$ROOT/interface" "$APP_DIR/"

cd "$APP_DIR/interface/web"
npm ci --omit=dev --ignore-scripts
npm run check

NODE_BIN="$(command -v node)"
cat > "$UNIT" <<EOF
[Unit]
Description=ZDOS Glass Engine local read-only console
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/interface/web
ExecStart=$NODE_BIN server/server.js
Environment=HOST=$HOST
Environment=PORT=$PORT
Environment=ZDOS_BRIDGE_TOKEN_FILE=$BRIDGE_TOKEN_FILE
Restart=on-failure
RestartSec=3
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$APP_DIR

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now zdos-glass-engine.service

echo "ZDOS Glass Engine installato."
echo "URL: http://127.0.0.1:$PORT"
echo "Host: $HOST"
if [[ -s "$BRIDGE_TOKEN_FILE" ]]; then echo "Bridge token: $BRIDGE_TOKEN_FILE (da inserire nell'APK Microcosm)"; fi
echo "Unit: $UNIT"
echo "Stato: systemctl --user status zdos-glass-engine.service"
echo "Log: journalctl --user -u zdos-glass-engine.service -f"
