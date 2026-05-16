#!/bin/bash

echo "=== BUILDING ALL ZEN MODULES ==="

for module in modules/*; do
  if [ -f "$module/build.sh" ]; then
    echo "Building module: $module"
    bash "$module/build.sh"
  fi
done

echo "=== ALL MODULES BUILT ==="
