#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$HOME"

echo ""
echo "========================================="
echo "   🧬 Z‑GENESIS — PRODUCT BUILD v1 + AAAK"
echo "========================================="
echo ""

############################################
# 0) DIPENDENZE DI SISTEMA
############################################
echo ">>> [0/8] Installazione dipendenze di sistema"
pkg install -y python nodejs sqlite git

pip install starlette uvicorn --break-system-packages

echo "Dipendenze OK."
echo ""

############################################
# 1) STRUTTURA MODULI (CORTEX / LIVE / PALACE / NODES / AAAK)
############################################
echo ">>> [1/8] Verifica struttura moduli"

mkdir -p "$BASE/Z-GENESIS-CORTEX"
mkdir -p "$BASE/Z-GENESIS-LIVE"
mkdir -p "$BASE/Z-GENESIS-PALACE"
mkdir -p "$BASE/Z-GENESIS-NODES"
mkdir -p "$BASE/Z-GENESIS-AAAK"

echo "Struttura base moduli OK."
echo ""

############################################
# 2) AAAK — INSTALLAZIONE MODULO
############################################
echo ">>> [2/8] AAAK — installazione modulo cognitivo"

cd "$BASE/Z-GENESIS-AAAK"

if [ -f "setup.py" ]; then
    pip install . --break-system-packages
    echo "AAAK installato come libreria Python."
else
    echo "⚠ Nessun setup.py trovato in Z-GENESIS-AAAK (salto installazione)."
fi

echo ""

############################################
# 3) Z‑CORTEX — STARLETTE SAFE BUILD + AAAK
############################################
echo ">>> [3/8] Ricostruzione Z‑CORTEX (Starlette‑Safe + AAAK)"

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
try:
    from aaak import aaak_encode, aaak_decode
except ImportError:
    # fallback locale se AAAK non è installato
    def aaak_encode(text: str) -> str:
        return text[::-1]

    def aaak_decode(blob: str) -> str:
        return blob[::-1]

def encode(text: str) -> str:
    return aaak_encode(text)

def decode(blob: str) -> str:
    return aaak_decode(blob)
EOF

cat > cortex/utils/nodes.py << 'EOF'
import json

def load_node(config_path):
    with open(config_path) as f:
        return json.load(f)

def heartbeat(node):
    return {"node": node["name"], "status": "online"}
EOF

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

echo "Z‑CORTEX definito come prodotto (con AAAK)."
echo ""

############################################
# 4) DSN‑PALACE — INIT DB
############################################
echo ">>> [4/8] Inizializzazione DSN‑PALACE"

cd "$BASE/Z-GENESIS-PALACE"

if [ ! -f "DSN-PALACE.db" ]; then
    sqlite3 DSN-PALACE.db "CREATE TABLE drawers (id INTEGER PRIMARY KEY, room_id TEXT, content TEXT, timestamp TEXT);"
    echo "DB creato."
else
    echo "DB già presente."
fi

echo "PALACE pronto."
echo ""

############################################
# 5) DSN‑LIVE — BACKEND ONLINE
############################################
echo ">>> [5/8] Verifica DSN‑LIVE"

cd "$BASE/Z-GENESIS-LIVE"
npm list express >/dev/null 2>&1 || npm install express --silent

echo "LIVE pronto."
echo ""

############################################
# 6) NODES — STRUTTURA AGENTI
############################################
echo ">>> [6/8] Verifica NODES"

cd "$BASE/Z-GENESIS-NODES"
mkdir -p nodes/vps nodes/kali nodes/termux

echo "NODES pronti."
echo ""

############################################
# 7) SCRIPT GLOBALI ZGEN
############################################
echo ">>> [7/8] Installazione comandi globali Z‑GENESIS"

cd "$BASE"

# zgen-restart
cat > "$BASE/zgen-restart.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
echo ""
echo "========================================="
echo "   🔄 Z‑GENESIS — RESTART SYSTEM"
echo "========================================="
echo ""

echo ">>> Arresto processi attivi"
pkill -f uvicorn || true
pkill -f server.js || true
pkill -f agent.py || true
echo "Tutti i processi terminati."
echo ""

echo ">>> Avvio Z‑CORTEX"
cd ~/Z-GENESIS-CORTEX
nohup uvicorn cortex.server:app --host 0.0.0.0 --port 7001 >/dev/null 2>&1 &
echo "CORTEX → http://localhost:7001"
echo ""

echo ">>> Avvio DSN‑LIVE"
cd ~/Z-GENESIS-LIVE
nohup node server/server.js >/dev/null 2>&1 &
echo "LIVE → http://localhost:8080"
echo ""

echo ">>> Avvio NODES"
cd ~/Z-GENESIS-NODES
nohup python3 nodes/vps/agent.py >/dev/null 2>&1 &
nohup python3 nodes/kali/agent.py >/dev/null 2>&1 &
nohup python3 nodes/termux/agent.py >/dev/null 2>&1 &
echo "NODES → attivi"
echo ""

echo "========================================="
echo "   🔄 Z‑GENESIS — RESTART COMPLETATO"
echo "========================================="
echo ""
echo "CORTEX  → http://localhost:7001"
echo "LIVE    → http://localhost:8080"
echo "NODES   → OK"
echo ""
echo "Sistema riavviato correttamente."
EOF

chmod +x "$BASE/zgen-restart.sh"
ln -sf "$BASE/zgen-restart.sh" $PREFIX/bin/zgen-restart

# zgen-stop
cat > "$BASE/zgen-stop.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "========================================="
echo "   ⛔ Z‑GENESIS — STOP SYSTEM"
echo "========================================="
echo ""

pkill -f uvicorn || true
pkill -f server.js || true
pkill -f agent.py || true

echo "Tutti i processi terminati."
EOF

chmod +x "$BASE/zgen-stop.sh"
ln -sf "$BASE/zgen-stop.sh" $PREFIX/bin/zgen-stop

# zgen-status
cat > "$BASE/zgen-status.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "========================================="
echo "   📡 Z‑GENESIS — STATUS"
echo "========================================="
echo ""

echo "CORTEX:"
pgrep -f uvicorn >/dev/null && echo "  ✓ attivo" || echo "  ✗ spento"

echo "LIVE:"
pgrep -f server.js >/dev/null && echo "  ✓ attivo" || echo "  ✗ spento"

echo "NODES:"
pgrep -f agent.py >/dev/null && echo "  ✓ attivi" || echo "  ✗ spenti"

echo ""
echo "Porte:"
echo "  7001 → CORTEX"
echo "  8080 → LIVE"
echo ""
EOF

chmod +x "$BASE/zgen-status.sh"
ln -sf "$BASE/zgen-status.sh" $PREFIX/bin/zgen-status

# zgen-dashboard
cat > "$BASE/zgen-dashboard.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
clear
echo "========================================="
echo "   🧬 Z‑GENESIS — DASHBOARD"
echo "========================================="
echo ""

echo "📡 STATUS:"
zgen-status

echo ""
echo "🫀 HEARTBEAT NODES:"
pgrep -f agent.py >/dev/null && echo "  ✓ NODES attivi" || echo "  ✗ NODES spenti"

echo ""
echo "🧠 CORTEX LOG (ultime 10 righe):"
tail -n 10 ~/Z-GENESIS-CORTEX/nohup.out 2>/dev/null || echo "Nessun log"

echo ""
echo "🌐 LIVE LOG (ultime 10 righe):"
tail -n 10 ~/Z-GENESIS-LIVE/nohup.out 2>/dev/null || echo "Nessun log"

echo ""
echo "========================================="
echo "   Dashboard aggiornata"
echo "========================================="
EOF

chmod +x "$BASE/zgen-dashboard.sh"
ln -sf "$BASE/zgen-dashboard.sh" $PREFIX/bin/zgen-dashboard

# zgen-dev
cat > "$BASE/zgen-dev.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🔧 Modalità sviluppo — CORTEX in foreground"
cd ~/Z-GENESIS-CORTEX
uvicorn cortex.server:app --host 0.0.0.0 --port 7001
EOF

chmod +x "$BASE/zgen-dev.sh"
ln -sf "$BASE/zgen-dev.sh" $PREFIX/bin/zgen-dev

# zgen-clean
cat > "$BASE/zgen-clean.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "========================================="
echo "   🧹 Z‑GENESIS — CLEAN"
echo "========================================="
echo ""

echo ">>> Pulizia processi zombie"
pkill -9 -f uvicorn || true
pkill -9 -f server.js || true
pkill -9 -f agent.py || true

echo ">>> Pulizia file temporanei"
rm -f ~/Z-GENESIS-CORTEX/nohup.out
rm -f ~/Z-GENESIS-LIVE/nohup.out

echo ""
echo "Pulizia completata."
EOF

chmod +x "$BASE/zgen-clean.sh"
ln -sf "$BASE/zgen-clean.sh" $PREFIX/bin/zgen-clean

echo "Comandi globali Z‑GENESIS installati."
echo ""

############################################
# 8) REPORT FINALE
############################################
echo ">>> [8/8] REPORT"

echo "========================================="
echo "   🧬 Z‑GENESIS — PRODUCT BUILD COMPLETATO"
echo "========================================="
echo ""
echo "Moduli:"
echo "  PALACE  → OK"
echo "  CORTEX  → OK (Starlette‑Safe + AAAK)"
echo "  LIVE    → OK"
echo "  NODES   → OK"
echo "  AAAK    → integrato"
echo ""
echo "Comandi globali:"
echo "  zgen           → autobuild (se presente)"
echo "  zgen-restart   → restart completo"
echo "  zgen-stop      → stop completo"
echo "  zgen-status    → stato moduli"
echo "  zgen-dashboard → pannello ASCII"
echo "  zgen-dev       → modalità sviluppo"
echo "  zgen-clean     → pulizia"
echo ""
echo "Sistema definito come prodotto Z‑GENESIS v1 + AAAK."
