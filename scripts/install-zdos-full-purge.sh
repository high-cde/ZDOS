#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

BRANCH="${ZDOS_BRANCH:-feat/glass-engine-console}"
REPO="${ZDOS_REPO:-$HOME/ZDOS}"
SOURCE="https://github.com/high-cde/ZDOS.git"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${ZDOS_BACKUP_ROOT:-$HOME/ZDOS-backups}/full-purge-$STAMP"
SERVICE="zdos-glass-engine.service"

say(){ printf '\n==> %s\n' "$*"; }
fail(){ echo "ERRORE: $*" >&2; exit 1; }
for cmd in git curl tar npm python3 systemctl; do command -v "$cmd" >/dev/null 2>&1 || fail "comando mancante: $cmd"; done
[ "${EUID:-$(id -u)}" -ne 0 ] || fail "esegui come utente Ubuntu normale, non come root"

TARGETS=(
  "$HOME/ZDOS"
  "$HOME/zdos-organism"
  "$HOME/ZDOS-lab-v1"
  "$HOME/x-zdos-complete"
)

say "Backup prima della pulizia"
mkdir -p "$BACKUP"
for target in "${TARGETS[@]}"; do
  if [ -d "$target" ]; then
    name="$(basename "$target")"
    tar --exclude='.git' --exclude='interface/web/node_modules' \
      -czf "$BACKUP/$name.tgz" -C "$(dirname "$target")" "$name"
  fi
done
if [ -d "$HOME/.local/share/zdos-glass-engine" ]; then
  tar -czf "$BACKUP/installed-app.tgz" -C "$HOME/.local/share" zdos-glass-engine
fi
cp -a "$HOME/.config/systemd/user/$SERVICE" "$BACKUP/" 2>/dev/null || true

printf '%s\n' "Saranno rimosse le vecchie copie ZDOS:" >&2
printf ' - %s\n' "${TARGETS[@]}" >&2
printf '%s\n' "Microcosm Android ($HOME/zdos-microcosm-beta) NON verrà rimosso." >&2
read -r -p "Digita ELIMINA per continuare: " confirmation
[ "$confirmation" = "ELIMINA" ] || { say "Operazione annullata"; exit 0; }

say "Arresto del servizio"
systemctl --user stop "$SERVICE" 2>/dev/null || true
systemctl --user disable "$SERVICE" 2>/dev/null || true

say "Rimozione copie e artefatti desktop precedenti"
cd "$HOME"
rm -rf \
  "${TARGETS[@]}" \
  "$HOME/.local/share/zdos-glass-engine" \
  "$HOME/.local/share/applications/zdos-glass-engine.desktop" \
  "$HOME/.config/systemd/user/$SERVICE"
systemctl --user daemon-reload

say "Clone della nuova release"
git clone --branch "$BRANCH" --single-branch "$SOURCE" "$REPO"
cd "$REPO"

say "Dipendenze e controlli"
npm --prefix interface/web ci --ignore-scripts
npm --prefix interface/web run check
python3 -m py_compile ai/zdos_llm_bridge.py tools/validate-zdos-trace-event.py tools/evaluate-hydro-telemetry.py
python3 -m json.tool release/zdos-release.json >/dev/null
bash -n scripts/install-glass-engine-ubuntu.sh scripts/install-glass-engine-desktop.sh scripts/autobuild-evidence-chain.sh

say "Installazione Glass Engine, launcher e servizio"
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

say "ZDOS FULL PURGE INSTALL COMPLETATA"
echo "Home:     http://127.0.0.1:8080/?refresh=1#desktop-home"
echo "GhostNet: http://127.0.0.1:8080/#zcomm-workbench"
echo "Backup:   $BACKUP"
echo "Service:  systemctl --user status $SERVICE"
