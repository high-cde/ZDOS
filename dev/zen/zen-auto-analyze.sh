#!/bin/bash

echo "=== ZEN UNIVERSAL REPOSITORY ANALYZER ==="

# ---------------------------------------------------------
# 1) DEFINIZIONE STRUTTURA ATTESA
# ---------------------------------------------------------

CORE_DIRS=(
  "src"
  "src/runtime"
  "src/compiler"
  "src/debugger"
  "src/transpilers"
  "src/zcore"
  "docs"
  "modules"
)

MODULES_EXPECTED=(
  "zvm"
  "zasm"
  "znet"
  "zsec"
  "zboot"
  "zai"
  "zdb"
  "zfs"
  "zui"
  "zos"
  "zos_services"
)

echo "[STEP] Analisi struttura repository..."

# ---------------------------------------------------------
# 2) CREAZIONE CARTELLE CORE MANCANTI
# ---------------------------------------------------------

for dir in "${CORE_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "[FIX] Creata cartella mancante: $dir"
    mkdir -p "$dir"
  else
    echo "[OK] $dir"
  fi
done

# ---------------------------------------------------------
# 3) ANALISI E RIPARAZIONE MODULI
# ---------------------------------------------------------

echo
echo "[STEP] Analisi moduli..."

mkdir -p modules

for module in "${MODULES_EXPECTED[@]}"; do
  if [ ! -d "modules/$module" ]; then
    echo "[FIX] Modulo mancante: $module → creato"
    mkdir -p "modules/$module/src"
    mkdir -p "modules/$module/docs"
    mkdir -p "modules/$module/tests"
    mkdir -p "modules/$module/examples"
  else
    echo "[OK] Modulo presente: $module"
  fi

  if [ ! -f "modules/$module/build.sh" ]; then
    echo "[FIX] build.sh mancante per $module → creato placeholder"
    cat > modules/$module/build.sh << EOF
#!/bin/bash
echo "Building module: $module (auto-generated placeholder)"
EOF
    chmod +x modules/$module/build.sh
  fi
done

# ---------------------------------------------------------
# 4) VERIFICA E RIPARAZIONE AUTOBUILD
# ---------------------------------------------------------

echo
echo "[STEP] Verifica autobuild..."

if [ ! -f "autobuild-modules.sh" ]; then
  echo "[FIX] autobuild-modules.sh mancante → creato"
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
  echo "[OK] autobuild-modules.sh"
fi

# ---------------------------------------------------------
# 5) DOCUMENTAZIONE
# ---------------------------------------------------------

echo
echo "[STEP] Verifica documentazione..."

mkdir -p docs/build-system

if [ ! -f docs/build-system/specification.md ]; then
  echo "[FIX] Creata documentazione base"
  cat > docs/build-system/specification.md << EOF
# ZEN Build System Specification
Documentazione generata automaticamente.
EOF
fi

# ---------------------------------------------------------
# 6) NORMALIZZAZIONE PERMESSI
# ---------------------------------------------------------

echo
echo "[STEP] Normalizzazione permessi..."

find . -type f -name "*.sh" -exec chmod +x {} \;
find . -type f -name "*.zc" -exec chmod 644 {} \;

echo "[OK] Permessi normalizzati"

# ---------------------------------------------------------
# 7) GIT AUTO-COMMIT
# ---------------------------------------------------------

echo
echo "[GIT] Commit automatico..."

git add .
git commit -m "ZEN AUTO-ANALYZE: repository analizzato e completato automaticamente"
git push

echo
echo "=== ANALISI E AUTO-FIX COMPLETATI ==="
