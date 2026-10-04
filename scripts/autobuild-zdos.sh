#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

BRANCH="${ZDOS_BRANCH:-feat/glass-engine-console}"
BASE="https://raw.githubusercontent.com/high-cde/ZDOS/${BRANCH}/scripts"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zdos-autobuild.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "ERRORE: esegui come utente Ubuntu normale, non come root." >&2
  exit 1
fi

for cmd in curl bash; do command -v "$cmd" >/dev/null 2>&1 || { echo "ERRORE: comando mancante: $cmd" >&2; exit 1; }; done

echo "=== ZDOS AUTOBUILD / ONE SHOT ==="
echo "branch: $BRANCH"
echo "fasi: backup → clean install → LLM/Zlang → dashboard → service → gates"

echo "[1/2] Scarico il clean installer verificato..."
curl --fail --silent --show-error --location --retry 3 "$BASE/install-zdos-clean.sh" -o "$TMP/install-zdos-clean.sh"
bash -n "$TMP/install-zdos-clean.sh"
chmod +x "$TMP/install-zdos-clean.sh"

echo "[2/2] Avvio l'intero ciclo..."
ZDOS_BRANCH="$BRANCH" bash "$TMP/install-zdos-clean.sh"

echo
echo "=== ZDOS AUTOBUILD COMPLETATO ==="
echo "Home:        http://127.0.0.1:8080/?refresh=1#desktop-home"
echo "Control:     http://127.0.0.1:8080/#dashboards-workbench"
echo "Evidence:    http://127.0.0.1:8080/#evidence-wallet"
echo "Alerts:      http://127.0.0.1:8080/#alerts-workbench"
echo "GhostNet:    http://127.0.0.1:8080/#zcomm-workbench"
echo "Service:     systemctl --user status zdos-glass-engine.service"
