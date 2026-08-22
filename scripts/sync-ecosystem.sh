#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=${ZDOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
ZLANG_ROOT=${ZLANG_ROOT:-"$ROOT/../Zlang"}
SEC_ROOT=${SEC_ROOT:-"$ROOT/../ZDOS-SEC-PORTAL"}
BRANCH=${BRANCH:-main}

say() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

for repo in "$ROOT" "$ZLANG_ROOT" "$SEC_ROOT"; do
  [ -d "$repo/.git" ] || fail "repository mancante: $repo"
  dirty=$(git -C "$repo" status --porcelain | grep -v -E '^\?\? scripts/sync-ecosystem\.sh$' || true)
  [ -z "$dirty" ] || fail "working tree non pulito: $repo"
  git -C "$repo" fetch origin "$BRANCH" --quiet
  git -C "$repo" pull --ff-only origin "$BRANCH" --quiet
 done

say "Verifica Zlang"
if [ -f "$ZLANG_ROOT/Cargo.toml" ]; then
  if command -v cargo >/dev/null 2>&1; then
    cargo test --locked --manifest-path "$ZLANG_ROOT/Cargo.toml"
  else
    printf 'WARN: Cargo non installato; test Rust Zlang non eseguito localmente.\n' >&2
  fi
fi
if [ -f "$ZLANG_ROOT/tests/test_zlangc.py" ]; then
  python3 "$ZLANG_ROOT/tests/test_zlangc.py"
fi

say "Verifica contratto ZLB2 e bare-metal ZDOS"
if [ -f "$ROOT/os/x86_64/tools/test_zlb2.py" ] && [ -f "$ROOT/os/x86_64/Makefile" ]; then
  (cd "$ROOT" && ZLANGC="$ZLANG_ROOT/tools/zlangc.py" make -C os/x86_64 clean verify)
  (cd "$ROOT" && sh os/x86_64/tools/verify_qemu.sh)
fi

say "Verifica distro Linux"
if [ -x "$ROOT/distro/build.sh" ]; then
  (cd "$ROOT" && ./distro/build.sh)
fi
if [ -x "$ROOT/distro/test-qemu.sh" ]; then
  (cd "$ROOT" && ./distro/test-qemu.sh)
fi

say "Verifica Evidence Chain"
if [ -x "$ROOT/scripts/bootstrap-evidence-chain.sh" ]; then
  (cd "$ROOT" && ./scripts/bootstrap-evidence-chain.sh)
fi

say "Verifica ZDOS-SEC-PORTAL"
if [ -f "$SEC_ROOT/package-lock.json" ]; then
  (cd "$SEC_ROOT" && npm ci --ignore-scripts)
fi
if [ -f "$SEC_ROOT/server.js" ]; then
  node --check "$SEC_ROOT/server.js"
fi

say "Controlli documentali e stato repository"
for repo in "$ROOT" "$ZLANG_ROOT" "$SEC_ROOT"; do
  git -C "$repo" diff --check
  printf '%s %s\n' "$(basename "$repo")" "$(git -C "$repo" rev-parse --short HEAD)"
done

say "Sincronizzazione completata"
printf 'ZDOS=%s\nZLANG=%s\nZDOS_SEC_PORTAL=%s\n' \
  "$(git -C "$ROOT" rev-parse HEAD)" \
  "$(git -C "$ZLANG_ROOT" rev-parse HEAD)" \
  "$(git -C "$SEC_ROOT" rev-parse HEAD)"
