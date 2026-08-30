#!/usr/bin/env bash
# Verify that the ZDOS source repository contains source and contracts only.
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

fail() {
  printf 'ZDOS_HYGIENE_FAILED: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || fail 'git is required'
git diff --check || fail 'whitespace errors detected'

forbidden=$(git ls-files | grep -E '(^|/)node_modules/|^target/|^distro/build/|^os/x86_64/build/|(^|/)__pycache__/|\.py[co]$|(^|/)\.pytest_cache/|\.(iso|img|zlb)$' || true)
if [[ -n "$forbidden" ]]; then
  printf '%s\n' "$forbidden" >&2
  fail 'generated or vendor artifacts are tracked'
fi

git check-ignore -q --no-index interface/web/node_modules/.sentinel || fail 'node_modules is not ignored'
git check-ignore -q --no-index distro/build/.sentinel || fail 'distro build output is not ignored'
git check-ignore -q --no-index os/x86_64/build/.sentinel || fail 'bare-metal build output is not ignored'
printf 'ZDOS_HYGIENE_OK\n'
