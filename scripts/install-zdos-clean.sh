#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
REPO="${ZDOS_REPO:-$HOME/ZDOS}"
BRANCH="${ZDOS_BRANCH:-feat/glass-engine-console}"
SOURCE="https://github.com/high-cde/ZDOS.git"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/ZDOS-backups/zdos-$STAMP"
SERVICE="zdos-glass-engine.service"
ORIGINAL_PWD="$(pwd -P 2>/dev/null || printf '%s' "$HOME")"

say(){ printf '\n==> %s\n' "$*"; }
fail(){ echo "ERRORE: $*" >&2; exit 1; }
for cmd in git curl tar npm python3 systemctl; do command -v "$cmd" >/dev/null 2>&1 || fail "comando mancante: $cmd"; done

say "Backup della vecchia installazione"
mkdir -p "$BACKUP"
systemctl --user stop "$SERVICE" 2>/dev/null || true
systemctl --user disable "$SERVICE" 2>/dev/null || true
if [ -d "$REPO" ]; then tar --exclude='.git' --exclude='interface/web/node_modules' -czf "$BACKUP/ZDOS-worktree.tgz" -C "$(dirname "$REPO")" "$(basename "$REPO")"; fi
if [ -d "$HOME/.local/share/zdos-glass-engine" ]; then tar -czf "$BACKUP/installed-app.tgz" -C "$HOME/.local/share" zdos-glass-engine; fi
cp -a "$HOME/.config/systemd/user/$SERVICE" "$BACKUP/" 2>/dev/null || true
# Il chiamante può aver eseguito l'autobuild da ~/ZDOS. Dopo rm -rf quella
# directory non esisterebbe più come cwd e Git fallirebbe con "remote helper aborted".
# Spostiamoci prima in una directory stabile, senza cambiare la destinazione finale.
cd "$HOME"
rm -rf "$HOME/.local/share/zdos-glass-engine" "$HOME/.local/share/applications/zdos-glass-engine.desktop" "$HOME/.config/systemd/user/$SERVICE" "$REPO"
systemctl --user daemon-reload

say "Clone pulito del nuovo ZDOS"
git clone --branch "$BRANCH" --single-branch "$SOURCE" "$REPO"
cd "$REPO"

say "Installazione dipendenze e verifiche"
npm --prefix interface/web ci --ignore-scripts
npm --prefix interface/web run check
python3 -m py_compile ai/zdos_llm_bridge.py tools/validate-zdos-trace-event.py tools/evaluate-hydro-telemetry.py
python3 -m json.tool release/zdos-release.json >/dev/null
bash -n scripts/install-glass-engine-ubuntu.sh scripts/install-glass-engine-desktop.sh scripts/autobuild-evidence-chain.sh

say "Installazione console, launcher e servizio"
chmod +x scripts/install-glass-engine-ubuntu.sh scripts/install-glass-engine-desktop.sh ai/zdos_llm_bridge.py
bash scripts/install-glass-engine-ubuntu.sh
bash scripts/install-glass-engine-desktop.sh
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE"
sleep 3
systemctl --user is-active --quiet "$SERVICE" || { journalctl --user -u "$SERVICE" -n 60 --no-pager; exit 1; }

say "Verifica finale"
curl --fail-with-body -sS http://127.0.0.1:8080/status >/dev/null
curl --fail-with-body -sS http://127.0.0.1:8080/ | grep -q 'desktop-home'
python3 ai/zdos_llm_bridge.py "health check" | python3 -m json.tool >/dev/null

if command -v xdg-open >/dev/null 2>&1; then xdg-open http://127.0.0.1:8080/#desktop-home >/dev/null 2>&1 & fi
say "ZDOS CLEAN INSTALL COMPLETATA"
echo "Home: http://127.0.0.1:8080"
echo "Backup: $BACKUP"
echo "Release: $REPO/release/zdos-release.json"
echo "LLM bridge: $REPO/ai/zdos_llm_bridge.py"
echo "Service: systemctl --user status $SERVICE"
