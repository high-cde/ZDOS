#!/usr/bin/env bash
# zdos-dsn-code-align v1 — contract test: /etc/zdos/dsn-release è canonico e finisce nell'ISO.
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REL="$ROOT/distro/rootfs/etc/zdos/dsn-release"
BUILD="$ROOT/distro/build.sh"
fail() { printf 'ZDOS_DSN_RELEASE_CONTRACT_FAILED: %s\n' "$1" >&2; exit 1; }
test -r "$REL" || fail 'dsn-release assente'
grep -Fqx 'DSN_CONTRACT=0xfc90516a1f736FaC557e09D8853dB80dA192c296' "$REL" || fail 'contratto non canonico'
grep -Fqx 'DSN_CHAIN_ID=137' "$REL" || fail 'chain id non 137'
grep -Fqx 'DSN_DECIMALS=18' "$REL" || fail 'decimali non 18'
grep -Fqx 'DSN_REQUIRED_TO_BOOT=no' "$REL" || fail 'il boot non deve dipendere da $DSN'
! grep -Eiq '(private|secret|mnemonic|seed)' "$REL" || fail 'materiale segreto in dsn-release'
grep -Fq '"$DISTRO/rootfs/etc/zdos/dsn-release" "$ROOTFS/etc/zdos/dsn-release"' "$BUILD" || fail 'build.sh non copia dsn-release'
printf 'ZDOS_DSN_RELEASE_CONTRACT_OK\n'
