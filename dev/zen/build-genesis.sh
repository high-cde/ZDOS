#!/bin/bash

echo "Building Z-GENESIS-OS"

mkdir -p src/genesis
mkdir -p docs/genesis

cat > src/genesis/kernel.zc << 'EOF'
class Kernel:
    def __init__(self):
        self.services = []

    def start(self):
        print("GENESIS OS Kernel Booting")
EOF

cat > src/genesis/shell.zc << 'EOF'
def shell():
    print("GENESIS Shell Ready")
EOF

echo "GENESIS OS Build Complete"
