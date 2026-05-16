#!/bin/bash

echo "Building full ZEN ecosystem and deploying to GitHub"

if [ -f build.sh ]; then
  bash build.sh
fi

if [ -f build-core.sh ]; then
  bash build-core.sh
fi

if [ -f build-debugger.sh ]; then
  bash build-debugger.sh
fi

git add .
git commit -m "ZEN ecosystem autobuild complete"
git push

echo "Deployment complete"
