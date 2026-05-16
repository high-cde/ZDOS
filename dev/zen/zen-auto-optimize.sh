#!/bin/bash

echo "=== ZEN AUTO-OPTIMIZATION SYSTEM ==="

# ---------------------------------------------------------
# 1) NORMALIZZAZIONE PERMESSI
# ---------------------------------------------------------

echo "[OPT] Normalizzazione permessi..."

find . -type f -name "*.sh" -exec chmod +x {} \;
find . -type f -name "*.zc" -exec chmod 644 {} \;

echo "[OK] Permessi normalizzati"

# ---------------------------------------------------------
# 2) RIMOZIONE FILE INUTILI
# ---------------------------------------------------------

echo "[OPT] Rimozione file inutili..."

UNUSED=$(find . -type f -name "*.tmp" -o -name "*.bak" -o -name "*~")

if [ -n "$UNUSED" ]; then
  echo "$UNUSED" | xargs rm -f
  echo "[OK] File inutili rimossi"
else
  echo "[OK] Nessun file inutile trovato"
fi

# ---------------------------------------------------------
# 3) VERIFICA STRUTTURA MODULI
# ---------------------------------------------------------

echo "[OPT] Verifica struttura moduli..."

for module in modules/*; do
  if [ -d "$module" ]; then
    for dir in src docs tests examples; do
      if [ ! -d "$module/$dir" ]; then
        echo "[FIX] Mancava $module/$dir → creato"
        mkdir -p "$module/$dir"
      fi
    done

    if [ ! -f "$module/build.sh" ]; then
      echo "[FIX] Mancava build.sh in $module → creato placeholder"
      cat > "$module/build.sh" << EOF
#!/bin/bash
echo "Building module: $(basename $module) (auto-generated)"
EOF
      chmod +x "$module/build.sh"
    fi
  fi
done

echo "[OK] Moduli verificati e completati"

# ---------------------------------------------------------
# 4) OTTIMIZZAZIONE AUTOBUILD
# ---------------------------------------------------------

echo "[OPT] Ottimizzazione autobuild..."

if ! grep -q "modules/*" autobuild-modules.sh 2>/dev/null; then
  echo "[FIX] autobuild-modules.sh non gestiva autodiscovery → aggiornato"
  cat > autobuild-modules.sh << 'EOF'
#!/bin/bash
echo "=== BUILDING ALL ZEN MODULES ==="
for module in modules/*; do
  if [ -f "$module/build.sh" ]; then
    echo "Building module: $module"
    bash "$module/build.sh"
  fi
done
echo "=== ALL MODULES BUILT ==="
EOF
  chmod +x autobuild-modules.sh
else
  echo "[OK] autobuild-modules.sh già ottimizzato"
fi

# ---------------------------------------------------------
# 5) OTTIMIZZAZIONE DOCUMENTAZIONE
# ---------------------------------------------------------

echo "[OPT] Ottimizzazione documentazione..."

if [ ! -f docs/README.md ]; then
  echo "[FIX] Mancava docs/README.md → creato"
  cat > docs/README.md << EOF
# ZEN Documentation
Documentazione generata automaticamente.
EOF
fi

for module in modules/*; do
  if [ -d "$module" ] && [ ! -f "$module/docs/overview.md" ]; then
    echo "[FIX] Documentazione mancante per $(basename $module) → creata"
    cat > "$module/docs/overview.md" << EOF
# $(basename $module)
Documentazione generata automaticamente.
EOF
  fi
done

echo "[OK] Documentazione ottimizzata"

# ---------------------------------------------------------
# 6) VERIFICA COERENZA FILE
# ---------------------------------------------------------

echo "[OPT] Verifica coerenza file..."

for module in modules/*; do
  if [ -d "$module/src" ]; then
    for file in "$module/src"/*.zc; do
      if [ ! -s "$file" ]; then
        echo "[FIX] File vuoto: $file → aggiunto placeholder"
        echo "# Auto-generated placeholder" > "$file"
      fi
    done
  fi
done

echo "[OK] Coerenza file garantita"

# ---------------------------------------------------------
# 7) GIT AUTO-COMMIT
# ---------------------------------------------------------

echo "[GIT] Allego tutto automaticamente..."

git add .
git commit -m "ZEN AUTO-OPTIMIZATION: repository ottimizzato automaticamente"
git push

echo
echo "=== AUTO-OPTIMIZZAZIONE COMPLETATA ==="
