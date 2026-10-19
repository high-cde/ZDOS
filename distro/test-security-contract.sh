#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LOCKFILE="$ROOT/distro/sources.lock"
INIT="$ROOT/distro/rootfs/init"
PASSWD="$ROOT/distro/rootfs/etc/passwd"
SHADOW="$ROOT/distro/rootfs/etc/shadow"
INITTAB="$ROOT/distro/rootfs/etc/inittab"
INSTALLER="$ROOT/distro/install.sh"
BUILD_SCRIPT="$ROOT/distro/build.sh"

fail() { printf 'ZDOS_SECURITY_CONTRACT_FAILED: %s\n' "$1" >&2; exit 1; }

test -r "$LOCKFILE" || fail 'sources.lock assente'
test -r "$INIT" || fail 'init assente'
test -r "$PASSWD" || fail 'passwd assente'
test -r "$SHADOW" || fail 'shadow assente'
test -r "$INITTAB" || fail 'inittab assente'
# shellcheck source=sources.lock
. "$LOCKFILE"
for hash in "$ZDOS_LOCK_BUSYBOX_SHA256" "$ZDOS_LOCK_KERNEL_SHA256" "$ZDOS_LOCK_KERNEL_PACKAGE_SHA256"; do
  [[ "$hash" =~ ^[0-9a-f]{64}$ ]] || fail 'hash lockfile non valido'
done
[[ "$ZDOS_LOCK_BUSYBOX_URL" == https://* ]] || fail 'URL BusyBox non HTTPS'
[[ "$ZDOS_LOCK_KERNEL_URL" == https://* ]] || fail 'URL kernel non HTTPS'
[[ "$ZDOS_LOCK_KERNEL_PACKAGE_URL" == https://* ]] || fail 'URL pacchetto kernel non HTTPS'
grep -Fqx 'root:x:0:0:root:/root:/bin/sh' "$PASSWD" || fail 'account root non configurato via shadow'
grep -Eq '^root:!:' "$SHADOW" || fail 'password root live non bloccata'
! grep -Fq 'root::' "$PASSWD" || fail 'password root vuota rilevata'
grep -Fq 'chroot "$target" /usr/sbin/chpasswd' "$INSTALLER" || fail 'installer non configura password amministratore'
grep -Fq 'set_string CONFIG_FEATURE_DEFAULT_PASSWD_ALGO sha512' "$BUILD_SCRIPT" || fail 'algoritmo password non robusto'
grep -Fq 'ZDOS_CONSOLE_USER=zdos mode=unprivileged' "$INIT" || fail 'console non privilegiata assente'
grep -Fq 'exec su -p -s /bin/sh zdos' "$INIT" || fail 'drop privilegi console assente'
grep -Fq 'refusing root shell' "$INIT" || fail 'fallback senza drop privilegi non fail-closed'
grep -Fq 'exec poweroff -f' "$INIT" || fail 'arresto sicuro senza drop privilegi assente'
[[ $(grep -Fc 'exec /bin/sh' "$INIT") -eq 1 ]] || fail 'shell root fuori dalla recovery esplicita rilevata'
grep -Fq 'zdos.insecure_root_shell' "$INIT" || fail 'recovery root esplicito assente'
grep -Fq '::respawn:/bin/su -p -s /bin/sh zdos' "$INITTAB" || fail 'fallback init privilegiato'
printf 'ZDOS_SECURITY_CONTRACT_PASSED\n'
