#!/bin/sh
set -eu

container_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
engine=${CONTAINER_ENGINE:-}
if [ -z "$engine" ]; then
  if command -v podman >/dev/null 2>&1; then engine=podman
  elif command -v docker >/dev/null 2>&1; then engine=docker
  else echo 'Install Podman or Docker first.' >&2; exit 1
  fi
fi

if ! "$engine" image exists localhost/zdos:latest 2>/dev/null; then
  "$container_dir/build-image.sh"
fi
exec "$engine" run --rm -it --name zdos localhost/zdos:latest
