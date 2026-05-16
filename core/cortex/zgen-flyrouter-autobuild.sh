#!/bin/bash
set -e
MODULE_DIR="z-cortex/modules/flyrouter"
mkdir -p $MODULE_DIR

cat > "$MODULE_DIR/metadata.json" << 'EOM'
{
  "name": "FLY-ROUTER",
  "version": "0.1.0",
  "source": "FlyWire / flyconnectome",
  "description": "Drosophila brain connectome module for Z-CORTEX"
}
EOM

cat > "$MODULE_DIR/__init__.py" << 'EOM'
from .loader import load_connectome
from .graph import build_graph
from .compress import compress_graph
from .router import FlyRouter
EOM

cat > "$MODULE_DIR/loader.py" << 'EOM'
# loader code here
EOM

cat > "$MODULE_DIR/graph.py" << 'EOM'
# graph code here
EOM

cat > "$MODULE_DIR/compress.py" << 'EOM'
# compress code here
EOM

cat > "$MODULE_DIR/router.py" << 'EOM'
# router code here
EOM

echo "[FLY-ROUTER] Module installed."
