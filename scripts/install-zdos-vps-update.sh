#!/usr/bin/env bash
# Aggiornamento ZDOS per VPS Ubuntu/Debian: installa console web + servizio ZDOS-SIP Videotel.
# Non distruttivo: backup datato, nessuna modifica ad altri siti/servizi, nginx solo se assente.
# Uso: sudo ./scripts/install-zdos-vps-update.sh [--dry-run] [--prefix /srv/zdos]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX=/srv/zdos
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --prefix) shift; PREFIX="${1:?--prefix richiede un percorso assoluto}" ;;
    *) echo "Argomento sconosciuto: $1" >&2; exit 2 ;;
  esac
  shift
done
case "$PREFIX" in /*) ;; *) echo "--prefix deve essere assoluto" >&2; exit 2 ;; esac
case "$PREFIX" in /|/usr|/etc|/var|/home|/root) echo "prefix non sicuro: $PREFIX" >&2; exit 2 ;; esac

say() { printf '\n[ZDOS-VPS] %s\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then printf '  (dry-run) %s\n' "$*"; else "$@"; fi; }

if [ "$DRY" = 0 ] && [ "$(id -u)" -ne 0 ]; then echo "Eseguire come root (sudo) oppure usare --dry-run." >&2; exit 1; fi
command -v node >/dev/null || { echo "Node.js >= 20 richiesto" >&2; exit 1; }
[ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] || { echo "Node.js >= 20 richiesto" >&2; exit 1; }
command -v rsync >/dev/null || { echo "rsync richiesto" >&2; exit 1; }

say "Validazione sorgenti"
node --check "$ROOT/interface/web/server/server.js"
node --check "$ROOT/interface/web/server/videotel.js"

if [ -d "$PREFIX" ]; then
  BACKUP="$PREFIX.backup-$(date -u +%Y%m%dT%H%M%SZ)"
  say "Backup: $BACKUP"
  run cp -a "$PREFIX" "$BACKUP"
fi

say "Sincronizzazione in $PREFIX"
run mkdir -p "$PREFIX"
run rsync -a --delete --exclude .git --exclude node_modules --exclude 'evidence/*.jsonl' "$ROOT/" "$PREFIX/"

say "Utente di servizio e dipendenze"
if ! id zdos-web >/dev/null 2>&1; then run useradd --system --no-create-home --shell /usr/sbin/nologin zdos-web; fi
run chown -R root:root "$PREFIX"
if [ "$DRY" = 1 ]; then echo "  (dry-run) npm ci --omit=dev in $PREFIX/interface/web"; else (cd "$PREFIX/interface/web" && npm ci --omit=dev --ignore-scripts); fi

say "Configurazione (preservata se esistente)"
if [ ! -f /etc/default/zdos-web ]; then
  if [ "$DRY" = 1 ]; then echo "  (dry-run) crea /etc/default/zdos-web"; else printf 'HOST=127.0.0.1\nPORT=3000\n' > /etc/default/zdos-web; fi
fi

say "Servizi systemd"
run install -m 0644 "$ROOT/deploy/systemd/zdos-web.service" /etc/systemd/system/zdos-web.service
run install -m 0644 "$ROOT/deploy/systemd/zdos-web.socket" /etc/systemd/system/zdos-web.socket
run systemctl daemon-reload
run systemctl enable --now zdos-web.socket
run systemctl restart zdos-web.service || true

if [ ! -e /etc/nginx/conf.d/zdos.conf ] && [ ! -e /etc/nginx/sites-enabled/zdos.conf ] && [ -d /etc/nginx ]; then
  say "nginx: installo solo il template (richiede certificati e server_name reali prima del reload)"
  run install -m 0644 "$ROOT/deploy/nginx/zdos.conf" /etc/nginx/conf.d/zdos.conf.disabled
else
  say "nginx: configurazione esistente non toccata"
fi

say "Verifica ZDOS-SIP Videotel"
if [ "$DRY" = 1 ]; then echo "  (dry-run) curl http://127.0.0.1:3000/api/videotel/status"; else
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -fsS http://127.0.0.1:3000/api/videotel/status; then echo; say "Videotel IN LINEA: apri il pannello ☎ ZDOS-SIP Videotel e premi ACCENDI."; exit 0; fi
    sleep 1
  done
  echo "Videotel non risponde: journalctl -u zdos-web.service" >&2; exit 1
fi
