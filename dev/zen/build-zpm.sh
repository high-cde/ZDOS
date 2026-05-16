#!/bin/bash

echo "Building ZPM (ZEN Package Manager)"

mkdir -p src/zpm
mkdir -p docs/zpm
mkdir -p packages

cat > src/zpm/zpm.zc << 'EOF'
def install(pkg):
    print("Installing package:", pkg)

def publish(pkg):
    print("Publishing package:", pkg)

def list_packages():
    print("Available packages:")
    print(" - core")
    print(" - std")
EOF

echo "ZPM Build Complete"
