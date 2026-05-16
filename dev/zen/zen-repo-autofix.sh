#!/bin/bash

echo "=== ZEN REPOSITORY ANALYZER & AUTO-FIXER ==="

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

# ---------------------------------------------------------
# 2) CONTROLLO CARTELLE CORE
# ---------------------------------------------------------

echo "[CHECK] Verifica cartelle core..."

for dir in "${CORE_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "[MISSING] $dir → CREATA"
    mkdir -p "$dir"
  else
    echo "[OK] $dir"
  fi
done

# ---------------------------------------------------------
# 3) CONTROLLO MODULI
# ---------------------------------------------------------

echo
echo "[CHECK] Verifica moduli..."

mkdir -p modules

for module in "${MODULES_EXPECTED[@]}"; do
  if [ ! -d "modules/$module" ]; then
    echo "[MISSING] modules/$module → CREATO"
    mkdir -p "modules/$module/src"
    mkdir -p "modules/$module/docs"
    mkdir -p "modules/$module/tests"
    mkdir -p "modules/$module/examples"
  else
    echo "[OK] modules/$module"
  fi

  # build.sh mancante
  if [ ! -f "modules/$module/build.sh" ]; then
    echo "[MISSING] build.sh per $module → CREATO PLACEHOLDER"
    cat > modules/$module/build.sh << EOF
#!/bin/bash
echo "Building module: $module (placeholder)"
EOF
    chmod +x modules/$module/build.sh
  fi
done

# ---------------------------------------------------------
# 4) CONTROLLO AUTOBUILD
# ---------------------------------------------------------

echo
echo "[CHECK] Verifica autobuild..."

if [ ! -f "autobuild-modules.sh" ]; then
  echo "[MISSING] autobuild-modules.sh → CREATO"
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
# 5) CONTROLLO DOCUMENTAZIONE
# ---------------------------------------------------------

echo
echo "[CHECK] Documentazione..."

if [ ! -f "docs/build-system/specification.md" ]; then
  echo "[MISSING] specification.md → CREATO"
  mkdir -p docs/build-system
  cat > docs/build-system/specification.md << EOF
# ZEN Build System Specification
Documentazione generata automaticamente.
EOF
else
  echo "[OK] specification.md"
fi

# ---------------------------------------------------------
# 6) GIT AUTO-ATTACH
# ---------------------------------------------------------

echo
echo "[GIT] Allego tutto automaticamente..."

git add .
git commit -m "ZEN AUTO-FIX: repository completato automaticamente"
git push

echo
echo "=== AUTO-FIX COMPLETATO ==="
