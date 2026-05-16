#!/bin/bash

echo "Building ZEN Standard Library"

mkdir -p src/std
mkdir -p docs/std

cat > src/std/io.zc << 'EOF'
def print_line(x):
    print(x)
EOF

cat > src/std/math.zc << 'EOF'
def add(a,b):
    return a+b
EOF

echo "ZSL Build Complete"
