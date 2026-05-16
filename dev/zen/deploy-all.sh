#!/bin/bash

echo "=== ZEN FULL DEPLOY ==="

bash autobuild.sh
bash build-cli.sh
bash build-zpm.sh
bash build-zsl.sh
bash build-zdsn.sh
bash build-genesis.sh

git add .
git commit -m "ZEN FULL ECOSYSTEM DEPLOY"
git push

echo "=== DEPLOY COMPLETE ==="
