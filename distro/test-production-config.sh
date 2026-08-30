#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf 'ZDOS_PRODUCTION_CONFIG_FAILED: %s\n' "$1" >&2; exit 1; }
required=(
  distro/rootfs/etc/os-release
  distro/rootfs/etc/fstab
  distro/rootfs/etc/hostname
  distro/rootfs/etc/hosts
  distro/rootfs/etc/resolv.conf
  distro/rootfs/etc/shadow
  distro/rootfs/etc/gshadow
  distro/rootfs/etc/shells
  distro/rootfs/etc/securetty
  distro/rootfs/etc/sysctl.d/99-zdos-hardening.conf
  distro/rootfs/etc/modprobe.d/zdos.conf
  distro/rootfs/etc/mdev.conf
  distro/release-policy.yaml
  config/logging.yaml
  config/backup-policy.yaml
  .github/CODEOWNERS
  .github/dependabot.yml
  .github/workflows/security.yml
  .github/workflows/sbom.yml
  distro/keys/README.md
  services/zdos-organismd.sysusers
  services/zdos-organismd.tmpfiles.conf
)
for relative in "${required[@]}"; do
  test -s "$ROOT/$relative" || fail "file mancante o vuoto: $relative"
done

grep -Eq '^ID=zdos$' "$ROOT/distro/rootfs/etc/os-release" || fail 'os-release senza ID ZDOS'
grep -Fq 'require_signed_manifest: true' "$ROOT/distro/release-policy.yaml" || fail 'firma manifest non obbligatoria'
grep -Fq 'remote_sink_enabled: false' "$ROOT/config/logging.yaml" || fail 'logging remoto non disabilitato per default'
grep -Fq 'never_store_key_in_repository: true' "$ROOT/config/backup-policy.yaml" || fail 'backup policy senza protezione chiavi'
grep -Fq 'public_key_source:' "$ROOT/distro/release-policy.yaml" || fail 'sorgente chiave release non dichiarata'
grep -Fq 'ZDOS_RELEASE_SIGNING_KEY' "$ROOT/distro/keys/README.md" || fail 'procedura chiave release non documentata'
grep -Fq 'u zdos -' "$ROOT/services/zdos-organismd.sysusers" || fail 'utente systemd non dichiarato'
grep -Fq '/var/lib/zdos/organism 0700 zdos zdos' "$ROOT/services/zdos-organismd.tmpfiles.conf" || fail 'directory stato non dichiarata'
! grep -Eq '^root::' "$ROOT/distro/rootfs/etc/passwd" || fail 'password root vuota'
! grep -Eq '^root:[^!*]' "$ROOT/distro/rootfs/etc/shadow" || fail 'account root non bloccato'
printf 'ZDOS_PRODUCTION_CONFIG_PASSED\n'
