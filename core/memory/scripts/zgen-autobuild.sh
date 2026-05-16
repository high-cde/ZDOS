#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$HOME"

echo ""
echo "========================================="
echo "   🧬 Z‑GENESIS — AUTOBUILD SYSTEM"
echo "========================================="
echo ""

############################################
# 0) PREP: installazioni minime
############################################
echo ">>> Installazione dipendenze minime"
pkg install -y python nodejs sqlite git

pip install starlette uvicorn --break-system-packages

echo ""

############################################
# 1) REBUILD Z‑CORTEX (Starlette version)
############################################
echo ">>> Ricostruzione Z‑CORTEX (Starlette‑Safe)"

cd "$BASE/Z-GENESIS-CORTEX"

mkdir -p cortex/controllers cortex/utils

cat > cortex/server.py << 'EOF'
from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.responses import JSONResponse
from starlette.routing import Mount
from middleware import RequestLogger
from router import cortex_routes

app = Starlette(
    debug=True,
    routes=[Mount("/", routes=cortex_routes)],
    middleware=[Middleware(RequestLogger)]
)

@app.route("/")
async def root(request):
    return JSONResponse({"status": "Z‑CORTEX online"})
EOF

cat > cortex/middleware.py << 'EOF'
from starlette.middleware.base import BaseHTTPMiddleware
from utils.logging import log

class RequestLogger(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        log(f"{request.method} {request.url.path}")
        response = await call_next(request)
        return response
EOF

cat > cortex/router.py << 'EOF'
from starlette.routing import Route
from controllers.add import add_item
from controllers.query import query_item
from controllers.rooms import list_rooms
from controllers.zaaak import encode_data, decode_data

cortex_routes = [
    Route("/add", add_item, methods=["POST"]),
    Route("/query", query_item, methods=["POST"]),
    Route("/rooms", list_rooms, methods=["GET"]),
    Route("/zaaak/encode", encode_data, methods=["POST"]),
    Route("/zaaak/decode", decode_data, methods=["POST"]),
]
EOF

mkdir -p cortex/utils

cat > cortex/utils/logging.py << 'EOF'
def log(msg: str):
    print(f"[Z‑CORTEX] {msg}")
EOF

cat > cortex/utils/palace.py << 'EOF'
import sqlite3

DB = "/data/data/com.termux/files/home/Z-GENESIS-PALACE/DSN-PALACE.db"

def palace_query(text):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute(
        "SELECT id, room_id, content, timestamp FROM drawers WHERE content LIKE ?",
        (f"%{text}%",)
    )
    rows = cur.fetchall()
    conn.close()
    return rows

def palace_add(room_id, content):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO drawers(room_id, content, timestamp) VALUES (?, ?, datetime('now'))",
        (room_id, content)
    )
    conn.commit()
    conn.close()
EOF

cat > cortex/utils/zaaak.py << 'EOF'
def encode(text: str) -> str:
    return text[::-1]

def decode(blob: str) -> str:
    return blob[::-1]
EOF

cat > cortex/utils/nodes.py << 'EOF'
import json

def load_node(config_path):
    with open(config_path) as f:
        return json.load(f)

def heartbeat(node):
    return {"node": node["name"], "status": "online"}
EOF

mkdir -p cortex/controllers

cat > cortex/controllers/add.py << 'EOF'
from starlette.responses import JSONResponse
from utils.palace import palace_add

async def add_item(request):
    data = await request.json()
    room = data.get("room_id")
    content = data.get("content")
    palace_add(room, content)
    return JSONResponse({"status": "ok", "added": content})
EOF

cat > cortex/controllers/query.py << 'EOF'
from starlette.responses import JSONResponse
from utils.palace import palace_query

async def query_item(request):
    data = await request.json()
    text = data.get("text")
    results = palace_query(text)
    return JSONResponse({"status": "ok", "results": results})
EOF

cat > cortex/controllers/rooms.py << 'EOF'
from starlette.responses import JSONResponse

async def list_rooms(request):
    return JSONResponse({"rooms": ["W1-H1-R1", "W1-H1-R2"]})
EOF

cat > cortex/controllers/zaaak.py << 'EOF'
from starlette.responses import JSONResponse
from utils.zaaak import encode, decode

async def encode_data(request):
    data = await request.json()
    return JSONResponse({"encoded": encode(data.get("text", ""))})

async def decode_data(request):
    data = await request.json()
    return JSONResponse({"decoded": decode(data.get("blob", ""))})
EOF

echo ">>> Z‑CORTEX ricostruito."
echo ""

############################################
# 2) DSN‑PALACE — init DB
############################################
echo ">>> Inizializzazione DSN‑PALACE"

cd "$BASE/Z-GENESIS-PALACE"

if [ ! -f "DSN-PALACE.db" ]; then
    python3 - << 'EOF'
from palace.palace_utils import init_db
init_db()
print("DB creato.")
EOF
else
    echo "DB già presente."
fi

echo ""

############################################
# 3) AVVIO Z‑CORTEX
############################################
echo ">>> Avvio Z‑CORTEX"
pkill -f uvicorn || true
nohup uvicorn cortex.server:app --host 0.0.0.0 --port 7001 >/dev/null 2>&1 &
echo "CORTEX → http://localhost:7001"
echo ""

############################################
# 4) AVVIO DSN‑LIVE
############################################
echo ">>> Avvio DSN‑LIVE"

cd "$BASE/Z-GENESIS-LIVE"
npm list express >/dev/null 2>&1 || npm install express --silent

pkill -f server.js || true
nohup node server/server.js >/dev/null 2>&1 &
echo "LIVE → http://localhost:8080"
echo ""

############################################
# 5) AVVIO NODES
############################################
echo ">>> Avvio NODES"

cd "$BASE/Z-GENESIS-NODES"

pkill -f agent.py || true

nohup python3 nodes/vps/agent.py >/dev/null 2>&1 &
nohup python3 nodes/kali/agent.py >/dev/null 2>&1 &
nohup python3 nodes/termux/agent.py >/dev/null 2>&1 &

echo "NODES → attivi"
echo ""

############################################
# REPORT FINALE
############################################
echo "========================================="
echo "   🧬 Z‑GENESIS — AUTOBUILD COMPLETATO"
echo "========================================="
echo ""
echo "PALACE  → OK"
echo "CORTEX  → http://localhost:7001"
echo "LIVE    → http://localhost:8080"
echo "NODES   → OK"
echo ""
echo "Sistema completamente operativo."
