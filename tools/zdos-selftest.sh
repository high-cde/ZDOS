#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON_BIN="${PYTHON:-python3}"
RUN_DISTRO=0
RUN_QEMU=0
FAILURES=0
SKIPPED=0

usage() {
  cat <<'EOF'
ZDOS self-test

Uso:
  tools/zdos-selftest.sh [--distro] [--qemu]

Opzioni:
  --distro  costruisce e verifica l'ISO Linux ZDOS
  --qemu    esegue anche il test QEMU della distro
EOF
}

pass() { printf 'PASS  %s\n' "$1"; }
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP  %s\n' "$1"; }
fail() { FAILURES=$((FAILURES + 1)); printf 'FAIL  %s\n' "$1" >&2; }
run_check() {
  local label="$1"
  shift
  if "$@"; then pass "$label"; else fail "$label"; fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --distro) RUN_DISTRO=1 ;;
    --qemu) RUN_QEMU=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opzione non riconosciuta: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cd "$ROOT"
printf 'ZDOS_SELFTEST_ROOT=%s\n' "$ROOT"

run_check 'shell syntax' bash -n \
  distro/build.sh distro/rootfs/init distro/test-qemu.sh \
  distro/test-organism-boot.sh distro/test-persistence-qemu.sh \
  os/x86_64/update_and_build.sh os/x86_64/tools/verify_qemu.sh \
  tools/zdos-launcher.sh tools/zdos-selftest.sh

run_check 'ZRetro unit tests' "$PYTHON_BIN" -m unittest discover -s zretro/ide -p 'test_*.py'
run_check 'ZRetro Castel Goblin manifests' bash -c '
  set -Eeuo pipefail
  for source in zretro/projects/castel-goblin/*/main.zretro; do
    "$1" zretro/ide/zretro.py build "$source" >/dev/null
  done
' bash "$PYTHON_BIN"

if [ -d ../Zlang ] && [ -f ../Zlang/tests/test_zlangc.py ]; then
  run_check 'Zlang compiler tests' bash -c 'cd ../Zlang && "$1" -m unittest discover -s tests -p "test_*.py"' bash "$PYTHON_BIN"
else
  skip 'Zlang compiler tests (checkout ../Zlang non disponibile)'
fi

if command -v make >/dev/null 2>&1 && command -v gcc >/dev/null 2>&1; then
  run_check 'x86_64 kernel verification' bash -c 'cd os/x86_64 && make verify'
else
  skip 'x86_64 kernel verification (toolchain incompleta)'
fi

if [ "$RUN_DISTRO" -eq 1 ]; then
  run_check 'Linux distro build' ./distro/build.sh
else
  skip 'Linux distro build (usa --distro)'
fi

if [ "$RUN_QEMU" -eq 1 ]; then
  run_check 'Linux distro QEMU test' ./distro/test-qemu.sh
else
  skip 'Linux distro QEMU test (usa --qemu)'
fi

printf 'ZDOS_SELFTEST_FAILURES=%s\n' "$FAILURES"
printf 'ZDOS_SELFTEST_SKIPPED=%s\n' "$SKIPPED"
[ "$FAILURES" -eq 0 ]
