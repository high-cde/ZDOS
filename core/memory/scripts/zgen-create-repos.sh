#!/data/data/com.termux/files/usr/bin/bash

REPOS=(
  "Z-GENESIS"
  "Z-GENESIS-PALACE"
  "Z-GENESIS-CORTEX"
  "Z-GENESIS-LIVE"
  "Z-GENESIS-AAAK"
  "Z-GENESIS-CLI"
  "Z-GENESIS-NODES"
  "Z-GENESIS-DOCS"
)

for repo in "${REPOS[@]}"; do
  echo ">>> Creazione repo locale: $repo"
  mkdir -p ~/$repo
  cd ~/$repo

  git init
  git remote add origin git@github.com:High-cde/$repo.git

  echo "# $repo" > README.md

  git add README.md
  git commit -m "Initial README for $repo"
  git push -u origin main

  echo ">>> $repo creato e sincronizzato."
  echo ""
done

echo ">>> TUTTI I REPO SONO STATI CREATI E PUSHATI."
