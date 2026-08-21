#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ZLANGC="${ZLANGC:-$ROOT/../Zlang/tools/zlangc.py}"

required=(bash curl make gcc ld python3 cpio gzip xorriso grub-mkrescue qemu-system-x86_64)
missing=()
for command_name in "${required[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

printf 'ZDOS setup root: %s\n' "$ROOT"
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'Missing commands: %s\n' "${missing[*]}" >&2
  printf 'Install the build prerequisites described in docs/OPERATIONS.md.\n' >&2
  exit 2
fi

if [ -f "$ZLANGC" ]; then
  printf 'Zlang compiler: %s\n' "$ZLANGC"
else
  printf 'Zlang compiler: not found (%s)\n' "$ZLANGC"
  printf 'Bare-metal builds require ZLANGC or a sibling ../Zlang checkout.\n' >&2
fi

printf 'Distro build entrypoint: %s\n' "$ROOT/distro/build.sh"
printf 'Bare-metal entrypoint: %s\n' "$ROOT/os/x86_64/update_and_build.sh"
printf 'Setup checks passed. No services were started.\n'
