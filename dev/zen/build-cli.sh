#!/bin/bash

echo "Building ZEN CLI"

mkdir -p src/cli
mkdir -p docs/cli

cat > src/cli/zen.sh << 'EOF'
#!/bin/bash

case $1 in
  run)
    echo "Running ZEN program: $2"
    ;;
  compile)
    echo "Compiling ZEN program: $2"
    ;;
  debug)
    echo "Debugging ZEN program: $2"
    ;;
  transpile)
    echo "Transpiling to $2: $3"
    ;;
  *)
    echo "ZEN CLI"
    echo "Commands: run, compile, debug, transpile"
    ;;
esac
EOF

chmod +x src/cli/zen.sh

echo "ZEN CLI Build Complete"
