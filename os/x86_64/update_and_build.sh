#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT"
ZLANGC="${ZLANGC:-$ROOT/../../../Zlang/tools/zlangc.py}"
MODULE_NAME="${1:-boot}"

case "$MODULE_NAME" in
  boot) MODULE="programs/boot.zlang" ;;
  license|zdos_license) MODULE="userland/zdos_license.zlang" ;;
  calc) MODULE="userland/calc.zlang" ;;
  notes) MODULE="userland/notes.zlang" ;;
  security|security_core) MODULE="userland/security_core.zlang" ;;
  *)
    echo "Modulo non supportato: $MODULE_NAME" >&2
    echo "Uso: $0 [boot|license|calc|notes|security]" >&2
    exit 2
    ;;
esac

if [ ! -f "$ZLANGC" ]; then
  echo "Compilatore Zlang non trovato: $ZLANGC" >&2
  echo "Imposta ZLANGC=/percorso/zlangc.py oppure clona Zlang in ../Zlang." >&2
  exit 2
fi
if [ ! -f "$MODULE" ]; then
  echo "Modulo Zlang non trovato: $MODULE" >&2
  exit 2
fi

if [ "$MODULE" != "programs/boot.zlang" ]; then
  cp "$MODULE" programs/boot.zlang
fi

make clean
make ZLANGC="$ZLANGC" all
printf 'ZDOS_BUILD_OK module=%s iso=%s\n' "$MODULE_NAME" "$ROOT/build/zdos-x86_64.iso"
