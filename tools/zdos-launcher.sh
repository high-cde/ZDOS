#!/usr/bin/env bash
# ZDOS Launcher — entrypoint operativo per ZDOS, Zlang e ZRetro.
# Non formatta dischi, non modifica servizi e non cancella file.
set -Eeuo pipefail

VERSION="1.0.0"

first_dir() {
  local d
  for d in "$@"; do
    if [[ -d "$d" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  return 1
}

ZDOS_ROOT="${ZDOS_ROOT:-$(first_dir \
  /opt/zdos-work/ZDOS \
  /srv/zdos/src/ZDOS \
  "$HOME/ZDOS" \
  "$(pwd)/ZDOS" || true)}"
ZLANG_ROOT="${ZLANG_ROOT:-$(first_dir \
  /opt/zdos-work/Zlang \
  /srv/zdos/src/Zlang \
  "$HOME/Zlang" \
  "$(pwd)/Zlang" || true)}"

log()  { printf '[ZDOS] %s\n' "$*"; }
ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERR ] %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
ZDOS Launcher 1.0.0

Uso:
  zdos-launcher status                 Mostra ambiente e servizi rilevati
  zdos-launcher doctor                 Esegue controlli non distruttivi
  zdos-launcher zlang FILE.zlang       Compila un programma Zlang in /tmp
  zdos-launcher zretro FILE.zretro     Avvia un progetto ZRetro
  zdos-launcher build                   Esegue la build ZDOS se disponibile
  zdos-launcher verify                  Esegue i test ZDOS/Zlang disponibili
  zdos-launcher selftest [--distro]     Esegue la verifica integrata del checkout
  zdos-launcher qemu ISO                Avvia una ISO in QEMU, se installato
  zdos-launcher help                   Mostra questo aiuto

Variabili opzionali:
  ZDOS_ROOT=/percorso/ZDOS
  ZLANG_ROOT=/percorso/Zlang
  ZDOS_QEMU_EXTRA='opzioni QEMU aggiuntive'

Il launcher è read-mostly: non formatta dischi, non installa pacchetti,
non riavvia servizi e non sovrascrive sorgenti.
EOF
}

status() {
  printf 'ZDOS Launcher %s\n' "$VERSION"
  printf 'ZDOS_ROOT=%s\n' "${ZDOS_ROOT:-NON_TROVATO}"
  printf 'ZLANG_ROOT=%s\n' "${ZLANG_ROOT:-NON_TROVATO}"
  printf 'HOST='; hostname 2>/dev/null || true
  printf 'OS='; . /etc/os-release 2>/dev/null && printf '%s\n' "${PRETTY_NAME:-sconosciuto}" || echo sconosciuto
  printf 'KERNEL='; uname -sr 2>/dev/null || true
  printf 'CPU='; nproc 2>/dev/null || echo sconosciuta
  printf 'MEM='; free -h 2>/dev/null | awk 'NR==2 {print $2 " total / " $7 " available"}' || echo sconosciuta
  printf 'QEMU='; command -v qemu-system-x86_64 2>/dev/null || echo NON_TROVATO
  printf 'GRUB='; command -v grub-mkrescue 2>/dev/null || echo NON_TROVATO
  printf 'ZLANGC='
  if [[ -n "${ZLANG_ROOT:-}" && -f "$ZLANG_ROOT/tools/zlangc.py" ]]; then
    echo "$ZLANG_ROOT/tools/zlangc.py"
  else
    echo NON_TROVATO
  fi
}

doctor() {
  status
  echo
  [[ -n "${ZDOS_ROOT:-}" && -d "$ZDOS_ROOT" ]] && ok 'root ZDOS rilevata' || warn 'root ZDOS non rilevata'
  [[ -n "${ZLANG_ROOT:-}" && -d "$ZLANG_ROOT" ]] && ok 'root Zlang rilevata' || warn 'root Zlang non rilevata'
  if [[ -n "${ZDOS_ROOT:-}" && -f "$ZDOS_ROOT/zretro/ide/zretro.py" ]]; then ok 'IDE ZRetro rilevato'; else warn 'IDE ZRetro non rilevato'; fi
  if [[ -n "${ZDOS_ROOT:-}" && -d "$ZDOS_ROOT/zretro/projects" ]]; then
    printf 'Progetti ZRetro:\n'
    find "$ZDOS_ROOT/zretro/projects" -mindepth 1 -maxdepth 2 -type f \
      \( -name '*.zretro' -o -name 'main.zretro' \) -print 2>/dev/null | sort | sed 's#^#  #'
  fi
  if command -v systemctl >/dev/null 2>&1; then
    for svc in zdos-first-node.service zdos-social.service zdos-organismd.service; do
      if systemctl list-unit-files "$svc" --no-legend 2>/dev/null | grep -q "$svc"; then
        printf '%-32s' "$svc"
        systemctl is-active "$svc" 2>/dev/null || true
      fi
    done
  fi
}

compile_zlang() {
  local source="$1"
  [[ -f "$source" ]] || die "file Zlang non trovato: $source"
  [[ -n "${ZLANG_ROOT:-}" && -f "$ZLANG_ROOT/tools/zlangc.py" ]] || die 'zlangc.py non rilevato; imposta ZLANG_ROOT'
  local stem out
  stem="$(basename "$source" .zlang)"
  out="${TMPDIR:-/tmp}/zdos-zlang-$stem-$$"
  mkdir -p "$out"
  python3 "$ZLANG_ROOT/tools/zlangc.py" "$source" --bytecode "$out/$stem.zlb" --header "$out/$stem.h"
  ok "bytecode Zlang: $out/$stem.zlb"
  ok "header C: $out/$stem.h"
}

run_zretro() {
  local source="$1"
  [[ -f "$source" ]] || die "file ZRetro non trovato: $source"
  [[ -n "${ZDOS_ROOT:-}" && -f "$ZDOS_ROOT/zretro/ide/zretro.py" ]] || die 'zretro.py non rilevato; imposta ZDOS_ROOT'
  log "avvio ZRetro per $source"
  exec python3 "$ZDOS_ROOT/zretro/ide/zretro.py" run "$source"
}

build_zdos() {
  [[ -n "${ZDOS_ROOT:-}" && -f "$ZDOS_ROOT/distro/build.sh" ]] || die 'distro/build.sh non rilevato'
  log 'avvio build ZDOS; nessun disco viene modificato'
  (cd "$ZDOS_ROOT" && bash distro/build.sh)
}

verify() {
  local ran=0
  if [[ -n "${ZLANG_ROOT:-}" && -d "$ZLANG_ROOT/tests" ]]; then
    (cd "$ZLANG_ROOT" && python3 -m unittest discover -s tests -p 'test_*.py' -v)
    ran=1
  fi
  if [[ -n "${ZDOS_ROOT:-}" && -f "$ZDOS_ROOT/zretro/ide/test_zretro.py" ]]; then
    (cd "$ZDOS_ROOT" && python3 -m unittest zretro.ide.test_zretro -v)
    ran=1
  fi
  (( ran == 1 )) || die 'nessuna suite disponibile'
}

qemu() {
  local iso="$1"
  [[ -f "$iso" ]] || die "ISO non trovata: $iso"
  command -v qemu-system-x86_64 >/dev/null 2>&1 || die 'qemu-system-x86_64 non installato'
  # QEMU è esplicito e interattivo: non viene eseguito automaticamente.
  # shellcheck disable=SC2086
  exec qemu-system-x86_64 -cdrom "$iso" -serial stdio ${ZDOS_QEMU_EXTRA:-}
}

command="${1:-help}"
case "$command" in
  help|-h|--help) usage ;;
  status) status ;;
  doctor) doctor ;;
  zlang) [[ $# -eq 2 ]] || die 'uso: zdos-launcher zlang FILE.zlang'; compile_zlang "$2" ;;
  zretro) [[ $# -eq 2 ]] || die 'uso: zdos-launcher zretro FILE.zretro'; run_zretro "$2" ;;
  build) build_zdos ;;
  verify|test) verify ;;
  selftest) [[ -n "${ZDOS_ROOT:-}" && -x "$ZDOS_ROOT/tools/zdos-selftest.sh" ]] || die 'zdos-selftest.sh non rilevato'; exec "$ZDOS_ROOT/tools/zdos-selftest.sh" "${@:2}" ;;
  qemu) [[ $# -eq 2 ]] || die 'uso: zdos-launcher qemu FILE.iso'; qemu "$2" ;;
  *) die "comando sconosciuto: $command" ;;
esac
