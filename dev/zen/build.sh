#!/bin/bash
echo "Building ZEN base system"

mkdir -p src/std src/compiler src/runtime src/distributed examples tests docs site/assets

echo "node.start" > examples/hello.zen

echo "ZEN base build complete"
