#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON_BIN="${PYTHON:-python3}"
ZLANG_ROOT="${ZDOS_ZLANG_ROOT:-$ROOT/../Zlang}"
RUN_DISTRO=0
RUN_QEMU=0
STRICT=0
FAILURES=0
SKIPPED=0

usage() {
  cat <<'EOF'
ZDOS self-test

Uso:
  tools/zdos-selftest.sh [--distro] [--qemu] [--strict] [--all]

Opzioni:
  --distro  costruisce e verifica l'ISO Linux ZDOS
  --qemu    esegue i test QEMU di boot console e persistenza ext4 (implica --distro)
  --strict  tratta ogni dipendenza mancante come FAIL invece di SKIP
  --all     equivale a --distro --qemu --strict
EOF
}

pass() { printf 'PASS  %s\n' "$1"; }
fail() { FAILURES=$((FAILURES + 1)); printf 'FAIL  %s\n' "$1" >&2; return 0; }
skip() {
  if [ "$STRICT" -eq 1 ]; then
    fail "$1 (dipendenza mancante in modalità strict)"
  else
    SKIPPED=$((SKIPPED + 1))
    printf 'SKIP  %s\n' "$1"
  fi
  return 0
}
run_check() {
  local label="$1"
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
  return 0
}
has_commands() {
  local tool
  for tool in "$@"; do command -v "$tool" >/dev/null 2>&1 || return 1; done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --distro) RUN_DISTRO=1 ;;
    --qemu) RUN_QEMU=1; RUN_DISTRO=1 ;;
    --strict) STRICT=1 ;;
    --all) RUN_DISTRO=1; RUN_QEMU=1; STRICT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opzione non riconosciuta: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cd "$ROOT"
printf 'ZDOS_SELFTEST_ROOT=%s\n' "$ROOT"
printf 'ZDOS_SELFTEST_ZLANG_ROOT=%s\n' "$ZLANG_ROOT"

run_check 'shell syntax' bash -n \
  distro/build.sh distro/prepare-persistence-modules.sh distro/rootfs/init \
  distro/test-qemu.sh distro/test-organism-boot.sh distro/test-persistence-qemu.sh distro/test-security-contract.sh distro/test-production-config.sh \
  microcosm/zdos-microctl os/x86_64/tools/verify_qemu.sh distro/build.sh \
  tools/zdos-launcher.sh tools/zdos-selftest.sh
run_check 'Python syntax' "$PYTHON_BIN" -m compileall -q commands evidence identity microcosm services zretro/ide
run_check 'resident organism boot contract' bash distro/test-organism-boot.sh
run_check 'distro security contract' bash distro/test-security-contract.sh
run_check 'production configuration contract' bash distro/test-production-config.sh
run_check 'ZRetro unit tests' "$PYTHON_BIN" -m unittest discover -s zretro/ide -p 'test_*.py'
run_check 'ZRetro Castel Goblin manifests' bash -c '
  set -Eeuo pipefail
  for source in zretro/projects/castel-goblin/*/main.zretro; do
    "$1" zretro/ide/zretro.py build "$source" >/dev/null
  done
' bash "$PYTHON_BIN"
run_check 'Evidence Chain tests' bash -c '"$1" evidence/test_attest_persistence.py && "$1" evidence/test_attest_zlang.py' bash "$PYTHON_BIN"
run_check 'Microcosm tests' "$PYTHON_BIN" microcosm/test_microcosm.py

if [ -d "$ZLANG_ROOT" ] && [ -f "$ZLANG_ROOT/tools/zlangc.py" ] && [ -f "$ZLANG_ROOT/tools/zlang_storage_read.py" ]; then
  run_check 'command library tests' env ZDOS_ZLANG_ROOT="$ZLANG_ROOT" "$PYTHON_BIN" commands/test_commands.py
  run_check 'identity bridge tests' env ZDOS_ZLANG_ROOT="$ZLANG_ROOT" "$PYTHON_BIN" identity/test_identity.py
  run_check 'resident organism tests' env ZDOS_ZLANG_ROOT="$ZLANG_ROOT" "$PYTHON_BIN" services/test_organismd.py
  if [ -d "$ZLANG_ROOT/tests" ]; then
    run_check 'Zlang compiler tests' bash -c 'cd "$1" && "$2" -m unittest discover -s tests -p "test_*.py"' bash "$ZLANG_ROOT" "$PYTHON_BIN"
  else
    skip 'Zlang compiler tests (directory tests non disponibile)'
  fi
else
  skip 'integrazione Zlang (checkout o toolchain non disponibili)'
fi

if has_commands php; then
  run_check 'PHP telemetry syntax' php -l web/backend/api.php
else
  skip 'PHP telemetry syntax'
fi
if has_commands node; then
  run_check 'Node interface syntax' node --check interface/web/server/server.js
else
  skip 'Node interface syntax'
fi

if has_commands make gcc grub-file; then
  if [ -d "$ZLANG_ROOT" ] && [ -f "$ZLANG_ROOT/tools/zlangc.py" ]; then
    run_check 'x86_64 kernel verification' env ZLANGC="$ZLANG_ROOT/tools/zlangc.py" bash -c 'cd os/x86_64 && make clean verify'
  else
    skip 'x86_64 kernel verification (Zlang non disponibile)'
  fi
else
  skip 'x86_64 kernel verification (toolchain incompleta)'
fi

if [ "$RUN_DISTRO" -eq 1 ]; then
  run_check 'Linux distro build' ./distro/build.sh
else
  printf 'INFO  Linux distro build non richiesto (usa --distro o --all)\n'
fi
if [ "$RUN_QEMU" -eq 1 ]; then
  run_check 'Linux distro persistence QEMU test' ./distro/test-persistence-qemu.sh
  run_check 'Linux distro console QEMU test' ./distro/test-qemu.sh
else
  printf 'INFO  Linux distro QEMU test non richiesto (usa --qemu o --all)\n'
fi

printf 'ZDOS_SELFTEST_FAILURES=%s\n' "$FAILURES"
printf 'ZDOS_SELFTEST_SKIPPED=%s\n' "$SKIPPED"
[ "$FAILURES" -eq 0 ]
