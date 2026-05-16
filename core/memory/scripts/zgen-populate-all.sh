#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME"

echo ">>> Z‑GENESIS — root"
cd "$BASE/Z-GENESIS"
mkdir -p docs meta

cat > README.md << 'EOF'
# 🧬 Z‑GENESIS  
Sistema Cognitivo Distribuito · DSN‑PALACE · Z‑CORTEX · DSN‑LIVE

Z‑GENESIS è l’orchestratore centrale dell’intero ecosistema cognitivo distribuito.
Non contiene codice applicativo: funge da radice, documentazione e coordinamento.

## Moduli
- Z‑GENESIS‑PALACE — memoria strutturata
- Z‑GENESIS‑CORTEX — motore cognitivo
- Z‑GENESIS‑LIVE — interfaccia visiva
- Z‑GENESIS‑AAAK — compressione cognitiva
- Z‑GENESIS‑CLI — rituali e comandi
- Z‑GENESIS‑NODES — agenti VPS/Kali/Termux
- Z‑GENESIS‑DOCS — documentazione tecnica

## Visione
Z‑GENESIS è progettato come un organismo distribuito, capace di crescere,
adattarsi e orchestrare nodi eterogenei.
EOF

cat > docs/architecture.md << 'EOF'
# Architettura Z‑GENESIS
EOF

cat > docs/roadmap.md << 'EOF'
# Roadmap Z‑GENESIS
EOF

cat > docs/modules.md << 'EOF'
# Moduli Z‑GENESIS
EOF

echo "0.0.1" > meta/VERSION
cat > meta/CHANGELOG.md << 'EOF'
# Changelog Z‑GENESIS
EOF

cat > meta/LICENSE << 'EOF'
MIT License (placeholder)
EOF

echo ">>> Z‑GENESIS‑PALACE"
cd "$BASE/Z-GENESIS-PALACE"
mkdir -p palace zaaak tests

cat > README.md << 'EOF'
# 🧩 DSN‑PALACE  
Sistema di memoria strutturata per Z‑GENESIS.

## Componenti
- SQLite: memoria verbatim
- ChromaDB: memoria semantica
- Z‑AAAK: compressione cognitiva

## Struttura
Wings → Halls → Rooms → Drawers → Closets
EOF

cat > palace/schema.sql << 'EOF'
CREATE TABLE wings(id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE halls(id INTEGER PRIMARY KEY, wing_id INTEGER, name TEXT);
CREATE TABLE rooms(id INTEGER PRIMARY KEY, hall_id INTEGER, name TEXT);
CREATE TABLE drawers(id INTEGER PRIMARY KEY, room_id INTEGER, content TEXT, timestamp TEXT);
CREATE TABLE closets(id INTEGER PRIMARY KEY, room_id INTEGER, zaaak TEXT, timestamp TEXT);
EOF

cat > palace/palace_indexer.py << 'EOF'
import sqlite3
from datetime import datetime

class PalaceIndexer:
    def __init__(self, db="DSN-PALACE.db"):
        self.db = db

    def add_drawer(self, room_id, content):
        conn = sqlite3.connect(self.db)
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO drawers(room_id, content, timestamp) VALUES (?, ?, ?)",
            (room_id, content, datetime.utcnow().isoformat())
        )
        conn.commit()
        conn.close()
EOF

cat > palace/palace_query.py << 'EOF'
import sqlite3

class PalaceQuery:
    def __init__(self, db="DSN-PALACE.db"):
        self.db = db

    def search_drawers(self, text):
        conn = sqlite3.connect(self.db)
        cur = conn.cursor()
        cur.execute(
            "SELECT id, room_id, content, timestamp FROM drawers WHERE content LIKE ?",
            (f"%{text}%",)
        )
        rows = cur.fetchall()
        conn.close()
        return rows
EOF

cat > palace/palace_utils.py << 'EOF'
import sqlite3

def init_db(db="DSN-PALACE.db", schema="palace/schema.sql"):
    conn = sqlite3.connect(db)
    with open(schema, "r") as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()
EOF

cat > zaaak/encoder.py << 'EOF'
def encode(text: str) -> str:
    # Placeholder Z‑AAAK encoder
    return text[::-1]
EOF

cat > zaaak/decoder.py << 'EOF'
def decode(blob: str) -> str:
    # Placeholder Z‑AAAK decoder
    return blob[::-1]
EOF

cat > zaaak/utils.py << 'EOF'
def chunk(text: str, size: int = 256):
    for i in range(0, len(text), size):
        yield text[i:i+size]
EOF

touch tests/test_indexer.py tests/test_query.py tests/test_zaaak.py

echo ">>> Z‑GENESIS‑CORTEX"
cd "$BASE/Z-GENESIS-CORTEX"
mkdir -p cortex/controllers cortex/utils tests

cat > README.md << 'EOF'
# 🧠 Z‑CORTEX  
Motore cognitivo centrale di Z‑GENESIS.

## Funzioni
- API REST
- orchestrazione DSN‑PALACE
- generazione Z‑AAAK
- routing cognitivo
EOF

cat > cortex/server.py << 'EOF'
from fastapi import FastAPI
from router import router

app = FastAPI(title="Z‑CORTEX")
app.include_router(router)

@app.get("/")
def root():
    return {"status": "Z‑CORTEX online"}
EOF

cat > cortex/router.py << 'EOF'
from fastapi import APIRouter
from controllers import add, query, zaaak, rooms

router = APIRouter()

router.include_router(add.router)
router.include_router(query.router)
router.include_router(zaaak.router)
router.include_router(rooms.router)
EOF

cat > cortex/controllers/add.py << 'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/add", tags=["add"])

@router.post("/")
def add_item(payload: dict):
    return {"status": "ok", "received": payload}
EOF

cat > cortex/controllers/query.py << 'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/query", tags=["query"])

@router.post("/")
def query_item(payload: dict):
    return {"status": "ok", "results": []}
EOF

cat > cortex/controllers/zaaak.py << 'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/zaaak", tags=["zaaak"])

@router.post("/encode")
def encode(payload: dict):
    return {"encoded": "TODO"}

@router.post("/decode")
def decode(payload: dict):
    return {"decoded": "TODO"}
EOF

cat > cortex/controllers/rooms.py << 'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/rooms", tags=["rooms"])

@router.get("/")
def list_rooms():
    return {"rooms": []}
EOF

cat > cortex/utils/config.py << 'EOF'
ZCORTEX_CONFIG = {
    "palace_db": "DSN-PALACE.db"
}
EOF

cat > cortex/utils/db.py << 'EOF'
def get_db():
    # placeholder
    return None
EOF

cat > cortex/utils/logging.py << 'EOF'
def log(msg: str):
    print(f"[Z‑CORTEX] {msg}")
EOF

echo ">>> Z‑GENESIS‑LIVE"
cd "$BASE/Z-GENESIS-LIVE"
mkdir -p server web/css web/js web/assets tests

cat > README.md << 'EOF'
# 🌐 DSN‑LIVE  
Interfaccia visiva e pannello operativo di Z‑GENESIS.

## Componenti
- Node.js server
- Web UI
- Feed live dei nodi
EOF

cat > server/server.js << 'EOF'
const express = require("express");
const app = express();
app.use(express.json());
app.use(express.static("web"));

app.get("/status", (req, res) => {
  res.json({ status: "DSN‑LIVE online" });
});

app.listen(8080, () => console.log("DSN‑LIVE running on 8080"));
EOF

cat > server/api.js << 'EOF'
const express = require("express");
const router = express.Router();

router.get("/ping", (req, res) => {
  res.json({ pong: true });
});

module.exports = router;
EOF

cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DSN‑LIVE · Z‑GENESIS</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <h1>DSN‑LIVE · Z‑GENESIS</h1>
  <div id="status"></div>
  <script src="js/app.js"></script>
</body>
</html>
EOF

cat > web/css/style.css << 'EOF'
body {
  background: #02030a;
  color: #e0f7ff;
  font-family: system-ui, sans-serif;
}
EOF

cat > web/js/app.js << 'EOF'
fetch("/status")
  .then(r => r.json())
  .then(d => {
    document.getElementById("status").innerText = JSON.stringify(d);
  });
EOF

cat > web/js/palace.js << 'EOF'
// Placeholder DSN‑PALACE UI bindings
EOF

cat > web/js/cortex.js << 'EOF'
// Placeholder Z‑CORTEX UI bindings
EOF

echo ">>> Z‑GENESIS‑CLI"
cd "$BASE/Z-GENESIS-CLI"
mkdir -p zgenctl/commands zgenctl/utils completions

cat > README.md << 'EOF'
# 🔧 Z‑GENESIS CLI  
Strumenti rituali e comandi operativi per Z‑GENESIS.
EOF

cat > zgenctl/zgenctl.sh << 'EOF'
#!/bin/bash
CMD=$1
shift

case $CMD in
  add) ./commands/add.sh "$@" ;;
  query) ./commands/query.sh "$@" ;;
  palace) ./commands/palace.sh ;;
  cortex) ./commands/cortex.sh ;;
  live) ./commands/live.sh ;;
  *)
    echo "Z‑GENESIS CLI — comandi disponibili: add, query, palace, cortex, live"
  ;;
esac
EOF

chmod +x zgenctl/zgenctl.sh

cat > zgenctl/commands/add.sh << 'EOF'
#!/bin/bash
echo "[zgenctl] add — TODO"
EOF

cat > zgenctl/commands/query.sh << 'EOF'
#!/bin/bash
echo "[zgenctl] query — TODO"
EOF

cat > zgenctl/commands/palace.sh << 'EOF'
#!/bin/bash
echo "[zgenctl] palace — TODO"
EOF

cat > zgenctl/commands/cortex.sh << 'EOF'
#!/bin/bash
echo "[zgenctl] cortex — TODO"
EOF

cat > zgenctl/commands/live.sh << 'EOF'
#!/bin/bash
echo "[zgenctl] live — TODO"
EOF

chmod +x zgenctl/commands/*.sh

cat > zgenctl/utils/colors.sh << 'EOF'
RED="\033[0;31m"
NC="\033[0m"
EOF

cat > zgenctl/utils/network.sh << 'EOF'
ping_node() {
  echo "Pinging $1..."
}
EOF

cat > completions/zgenctl.bash << 'EOF'
# Placeholder bash completion for zgenctl
EOF

echo ">>> Z‑GENESIS‑NODES"
cd "$BASE/Z-GENESIS-NODES"
mkdir -p nodes/vps nodes/kali nodes/termux configs

cat > README.md << 'EOF'
# 🛰️ Z‑GENESIS NODES  
Agenti remoti per VPS, Kali e Termux.
EOF

cat > nodes/vps/agent.py << 'EOF'
import json

class NodeAgent:
    def __init__(self, config):
        self.config = json.load(open(config))

    def heartbeat(self):
        return {"node": self.config["name"], "status": "online"}
EOF

cp nodes/vps/agent.py nodes/kali/agent.py
cp nodes/vps/agent.py nodes/termux/agent.py

cat > configs/vps.json << 'EOF'
{"name": "vps-node"}
EOF

cat > configs/kali.json << 'EOF'
{"name": "kali-node"}
EOF

cat > configs/termux.json << 'EOF'
{"name": "termux-node"}
EOF

echo ">>> Z‑GENESIS‑DOCS"
cd "$BASE/Z-GENESIS-DOCS"
mkdir -p docs/api

cat > README.md << 'EOF'
# 📚 Z‑GENESIS DOCS  
Documentazione tecnica completa del sistema cognitivo distribuito.
EOF

cat > docs/overview.md << 'EOF'
# Overview Z‑GENESIS
EOF

cat > docs/palace.md << 'EOF'
# DSN‑PALACE
EOF

cat > docs/cortex.md << 'EOF'
# Z‑CORTEX
EOF

cat > docs/live.md << 'EOF'
# DSN‑LIVE
EOF

cat > docs/zaaak.md << 'EOF'
# Z‑AAAK
EOF

cat > docs/cli.md << 'EOF'
# Z‑GENESIS CLI
EOF

cat > docs/nodes.md << 'EOF'
# Z‑GENESIS NODES
EOF

cat > docs/api/add.md << 'EOF'
# API /add
EOF

cat > docs/api/query.md << 'EOF'
# API /query
EOF

cat > docs/api/rooms.md << 'EOF'
# API /rooms
EOF

cat > docs/api/zaaak.md << 'EOF'
# API /zaaak
EOF

echo ">>> COMPLETATO — struttura e file popolati."
