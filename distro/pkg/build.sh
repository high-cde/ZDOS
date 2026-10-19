#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: distro/pkg/build.sh --name NAME --version VERSION --root TREE --output FILE.tar.gz

TREE contains the paths to install, for example TREE/usr/bin/hello.
EOF
}

name= version= tree= output=
while (($#)); do
  case $1 in
    --name) name=${2:?missing name}; shift 2 ;;
    --version) version=${2:?missing version}; shift 2 ;;
    --root) tree=${2:?missing root}; shift 2 ;;
    --output) output=${2:?missing output}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ $name =~ ^[A-Za-z0-9._+-]+$ ]] || { echo 'invalid package name' >&2; exit 2; }
[[ $version =~ ^[A-Za-z0-9._+-]+$ ]] || { echo 'invalid package version' >&2; exit 2; }
[[ -d $tree && -n $output ]] || { usage >&2; exit 2; }
tree=$(cd "$tree" && pwd -P)
mkdir -p "$(dirname "$output")"
output=$(cd "$(dirname "$output")" && pwd -P)/$(basename "$output")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/control" "$stage/payload"
printf '%s\n' "$name" > "$stage/control/name"
printf '%s\n' "$version" > "$stage/control/version"

while IFS= read -r -d '' path; do
  relative=${path#"$tree"/}
  [[ $relative =~ ^[A-Za-z0-9._+/-]+$ ]] || { echo "unsupported package path: $relative" >&2; exit 1; }
  [[ $relative != /* && $relative != *..* && $relative != *//* ]] || { echo "unsafe package path: $relative" >&2; exit 1; }
  [[ ! -L $path ]] || { echo "package symlinks are not supported: $relative" >&2; exit 1; }
  [[ -f $path || -d $path ]] || { echo "package special file is not supported: $relative" >&2; exit 1; }
done < <(find "$tree" -mindepth 1 -print0)
cp -a "$tree/." "$stage/payload/"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -C "$stage" -cf - control payload | gzip -n -9 > "$output"
sha256sum "$output"
printf 'ZDOS_PACKAGE=%s\n' "$output"
