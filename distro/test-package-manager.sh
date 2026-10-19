#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/source/usr/bin"
cat > "$TMP/source/usr/bin/hello-zdos" <<'EOF'
#!/bin/sh
printf 'hello from package\n'
EOF
chmod 4755 "$TMP/source/usr/bin/hello-zdos"
hash_line=$("$ROOT/distro/pkg/build.sh" --name hello-zdos --version 1.0 --root "$TMP/source" --output "$TMP/hello-zdos.tar.gz")
expected=${hash_line%% *}

ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" install "$TMP/hello-zdos.tar.gz" "$expected"
test -x "$TMP/root/usr/bin/hello-zdos"
test "$(stat -c '%a' "$TMP/root/usr/bin/hello-zdos")" = 755
ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" verify
ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" list | grep -q 'hello-zdos.*1.0'
ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" remove hello-zdos
test ! -e "$TMP/root/usr/bin/hello-zdos"

if ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" install "$TMP/hello-zdos.tar.gz" "$(printf '0%.0s' {1..64})" >/dev/null 2>&1; then
  echo 'package manager accepted an incorrect digest' >&2
  exit 1
fi

mkdir -p "$TMP/linked/control" "$TMP/linked/payload/usr/bin"
printf 'linked-test\n' > "$TMP/linked/control/name"
printf '1.0\n' > "$TMP/linked/control/version"
ln -s ../../../../etc/passwd "$TMP/linked/payload/usr/bin/escape"
tar -czf "$TMP/linked.tar.gz" -C "$TMP/linked" control payload
linked_hash=$(sha256sum "$TMP/linked.tar.gz" | awk '{print $1}')
if ZDOS_PKG_ROOT="$TMP/root" "$ROOT/distro/rootfs/usr/sbin/zdos-pkg" install "$TMP/linked.tar.gz" "$linked_hash" >/dev/null 2>&1; then
  echo 'package manager accepted a symbolic link' >&2
  exit 1
fi

echo 'ZDOS_PACKAGE_MANAGER_TEST_PASSED'
