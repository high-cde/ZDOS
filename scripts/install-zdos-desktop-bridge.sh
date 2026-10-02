#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

BRANCH="${ZDOS_BRANCH:-feat/glass-engine-console}"
BASE="https://raw.githubusercontent.com/high-cde/ZDOS/${BRANCH}/scripts"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zdos-desktop-bridge.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "ERRORE: esegui come utente Ubuntu normale, non come root." >&2
  exit 1
fi

for cmd in curl bash hostname; do command -v "$cmd" >/dev/null 2>&1 || { echo "ERRORE: comando mancante: $cmd" >&2; exit 1; }; done

PC_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
PC_IP="${PC_IP:-127.0.0.1}"

echo "=== ZDOS DESKTOP + ANDROID BRIDGE INSTALLER ==="
echo "branch: $BRANCH"
echo "PC LAN IP: $PC_IP"
echo "azioni: backup → Glass Engine → launcher desktop → bridge LAN → token → health checks"

echo "[1/2] Scarico autobuild verificato..."
curl --fail --silent --show-error --location --retry 3 "$BASE/autobuild-zdos.sh" -o "$TMP/autobuild-zdos.sh"
bash -n "$TMP/autobuild-zdos.sh"
chmod +x "$TMP/autobuild-zdos.sh"

echo "[2/2] Installo ZDOS desktop e bridge Android-PC..."
ZDOS_LAN=1 ZDOS_GLASS_HOST=0.0.0.0 ZDOS_BRANCH="$BRANCH" bash "$TMP/autobuild-zdos.sh"

TOKEN_FILE="${ZDOS_BRIDGE_TOKEN_FILE:-$HOME/.config/zdos/bridge.token}"
DESKTOP_FILE="$HOME/.local/share/applications/zdos-glass-engine.desktop"

echo
echo "=== INSTALLAZIONE COMPLETATA ==="
echo "Launcher desktop: $DESKTOP_FILE"
echo "Glass Engine PC:   http://127.0.0.1:8080/#desktop-home"
echo "Endpoint Android: http://$PC_IP:8080"
echo "Token pairing:    $TOKEN_FILE"
echo
echo "Nel tuo APK Microcosm apri ZComm / Videotel → ZDOS-PC BRIDGE e inserisci:"
echo "  Endpoint: http://$PC_IP:8080"
echo "  Token:    cat $TOKEN_FILE"
echo
echo "Servizio: systemctl --user status zdos-glass-engine.service"
echo "Log:     journalctl --user -u zdos-glass-engine.service -f"
