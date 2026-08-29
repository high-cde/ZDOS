#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
INIT="$ROOT/distro/rootfs/init"
CONF="$ROOT/distro/rootfs/etc/zdos/organism.conf"
sh -n "$INIT"
test -s "$CONF"
grep -q 'zdos.organism=\*)' "$INIT"
grep -q 'organism_state=disabled' "$INIT"
grep -q 'runtime-not-packaged' "$INIT"
grep -q 'cp "\$DISTRO/rootfs/etc/zdos/organism.conf"' "$ROOT/distro/build.sh"
grep -q 'ZDOS_BUNDLE_ORGANISM' "$ROOT/distro/build.sh"
grep -q 'zdos-organismd.py' "$ROOT/distro/build.sh"
grep -q 'zdos-main.zlang' "$ROOT/distro/build.sh"
printf 'ZDOS_ORGANISM_BOOT_HOOK_OK\n'
