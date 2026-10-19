#!/bin/sh
set -eu

container_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
zdos_root=$(CDPATH= cd -- "$container_dir/../.." && pwd)
engine=${CONTAINER_ENGINE:-}

if [ -z "$engine" ]; then
  if command -v podman >/dev/null 2>&1; then engine=podman
  elif command -v docker >/dev/null 2>&1; then engine=docker
  else
    echo 'Install Podman or Docker first (see distro/container/README.md).' >&2
    exit 1
  fi
fi

for artifact in "$zdos_root/distro/build/vmlinuz" "$zdos_root/distro/build/initramfs.cpio.gz"; do
  if [ ! -s "$artifact" ]; then
    echo "Missing $artifact; build the ZDOS ISO first with ./distro/build.sh" >&2
    exit 1
  fi
done

context=$(mktemp -d)
trap 'rm -rf "$context"' EXIT HUP INT TERM
mkdir -p "$context/distro/build" "$context/distro/container"
cp "$zdos_root/distro/build/vmlinuz" "$zdos_root/distro/build/initramfs.cpio.gz" "$context/distro/build/"
cp "$container_dir/Dockerfile" "$container_dir/zdos-entrypoint" "$context/distro/container/"
"$engine" build --tag localhost/zdos:latest \
  --file "$context/distro/container/Dockerfile" "$context"
echo 'Built localhost/zdos:latest'
