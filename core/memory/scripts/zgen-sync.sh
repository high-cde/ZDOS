#!/data/data/com.termux/files/usr/bin/bash
set -e

echo ""
echo "========================================="
echo "   🔄 Z‑GENESIS — SYNC TO GITHUB"
echo "========================================="
echo ""

REPOS=(
  "$HOME/Z-GENESIS-CORTEX"
  "$HOME/Z-GENESIS-LIVE"
  "$HOME/Z-GENESIS-PALACE"
  "$HOME/Z-GENESIS-NODES"
)

for repo in "${REPOS[@]}"; do
  echo ">>> Sync: $repo"
  cd "$repo"

  # Se non è un repo git, salta
  if [ ! -d ".git" ]; then
    echo "   ⚠ Non è un repository git, salto."
    continue
  fi

  # Aggiungi tutto
  git add -A

  # Se non ci sono modifiche, salta
  if git diff --cached --quiet; then
    echo "   ✓ Nessuna modifica da sincronizzare."
    continue
  fi

  # Commit intelligente
  MSG="Z‑GENESIS Sync — $(date '+%Y-%m-%d %H:%M:%S')"
  git commit -m "$MSG"

  # Push
  git push

  echo "   ✓ Sincronizzato."
  echo ""
done

echo "========================================="
echo "   🔄 SYNC COMPLETATO"
echo "========================================="
echo ""
echo "Tutti i moduli sono stati sincronizzati con GitHub."
