#!/usr/bin/env bash
set -Eeuo pipefail

APP=/opt/zdos-cybercore-warroom
PUBLIC="$APP/public"
INDEX="$PUBLIC/index.html"
SERVICE=zdos-cybercore-warroom.service
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT=/root/warroom-backups/$STAMP
ROLLBACK_INDEX="$BACKUP_ROOT/index.html.before"

fail() { echo "[AUTOBUILD][FAIL] $*" >&2; exit 1; }
trap 'rc=$?; if [ "$rc" -ne 0 ] && [ -f "$ROLLBACK_INDEX" ]; then echo "[AUTOBUILD] rollback automatico" >&2; cp -f "$ROLLBACK_INDEX" "$INDEX"; systemctl restart "$SERVICE" >/dev/null 2>&1 || true; fi; exit "$rc"' EXIT

[ "$(id -u)" -eq 0 ] || fail "eseguire come root"
[ -d "$APP" ] || fail "directory assente: $APP"
[ -f "$INDEX" ] || fail "file assente: $INDEX"
command -v node >/dev/null || fail "node non trovato"
command -v systemctl >/dev/null || fail "systemctl non trovato"

mkdir -p "$BACKUP_ROOT"
cp -a "$INDEX" "$ROLLBACK_INDEX"
[ -f "/etc/systemd/system/$SERVICE" ] && cp -a "/etc/systemd/system/$SERVICE" "$BACKUP_ROOT/$SERVICE"
[ -d "$APP/.git" ] && git -C "$APP" rev-parse HEAD > "$BACKUP_ROOT/git-before.txt" 2>/dev/null || true

# Il file corrente mostrato dalla VPS è una mock UI senza login. Se presente,
# ripristina l’ultimo backup che conserva il flusso autenticato originale.
if ! grep -qE "/api/auth/login|autocomplete=\"current-password\"|type=[\"']password" "$INDEX"; then
  AUTH_BACKUP=$(find "$PUBLIC" -maxdepth 1 -type f -name 'index.html.backup.*' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {sub(/^[^ ]+ /,"",$0); print}')
  [ -n "$AUTH_BACKUP" ] || fail "index corrente non autenticato e nessun backup disponibile"
  grep -qE "/api/auth/login|autocomplete=\"current-password\"|type=[\"']password" "$AUTH_BACKUP" \
    || fail "il backup più recente non contiene il flusso autenticato"
  cp -f "$AUTH_BACKUP" "$INDEX"
  echo "[AUTOBUILD] ripristinata UI autenticata da $AUTH_BACKUP"
fi

# Aggiorna esclusivamente il menu esistente: nessun endpoint nuovo,
# nessuna shell nel browser e nessuna capability offensiva.
python3 - "$INDEX" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s = p.read_text()
old = "const nav=['overview','toolbox','programs','scopes','assets','reports','evidence','jobs','audit'];"
new = "const nav=['overview','toolbox','programs','scopes','assets','reports','evidence','jobs','audit'];const zdosLabels={overview:'CONTROL PLANE',toolbox:'ZLANG OPERATIONS',programs:'PROGRAMS',scopes:'AUTHORIZED SCOPES',assets:'ASSETS',reports:'FINDINGS',evidence:'EVIDENCE CHAIN',jobs:'EVIDENCE JOBS',audit:'AUDIT LEDGER'};"
if old in s and 'zdosLabels' not in s:
    s = s.replace(old, new, 1)
    s = s.replace("(x==='overview'?'CONTROL PLANE':labels[x]).toUpperCase()", "zdosLabels[x]||labels[x]")
else:
    if 'zdosLabels' not in s:
        raise SystemExit('menu source non riconosciuto: nessuna modifica applicata')
p.write_text(s)
PY

# Verifica che la pagina protetta e il menu ZDOS siano realmente presenti.
grep -qE "/api/auth/login|autocomplete=\"current-password\"|type=[\"']password" "$INDEX" \
  || fail "flusso autenticato non presente dopo la patch"
grep -q 'zdosLabels' "$INDEX" || fail "menu ZDOS non presente dopo la patch"

# Il backup resta fuori dal repository; si committa solo il sorgente reale.
if [ -d "$APP/.git" ]; then
  git -C "$APP" add public/index.html
  git -C "$APP" diff --cached --check
  if ! git -C "$APP" diff --cached --quiet; then
    git -C "$APP" commit -m 'feat(warroom): align menu with ZLang by ZDOS'
  fi
fi

systemctl restart "$SERVICE"
sleep 2
systemctl is-active --quiet "$SERVICE" || fail "servizio non attivo dopo il riavvio"

curl -fsS --max-time 10 -o /tmp/warroom-autobuild.html -w '%{http_code}\n' http://127.0.0.1:3021/ | grep -qx '200' \
  || fail "smoke test HTTP locale fallito"
grep -qE '/api/auth/login|current-password' /tmp/warroom-autobuild.html \
  || fail "smoke test: pagina non autenticata"

rm -f /tmp/warroom-autobuild.html
trap - EXIT
echo "[AUTOBUILD][OK] War Room ZDOS/ZLang aggiornata"
echo "[AUTOBUILD] backup: $BACKUP_ROOT"
echo "[AUTOBUILD] commit: $(git -C "$APP" log -1 --oneline 2>/dev/null || echo n/a)"
echo "[AUTOBUILD] rollback: cp '$ROLLBACK_INDEX' '$INDEX' && systemctl restart '$SERVICE'"
