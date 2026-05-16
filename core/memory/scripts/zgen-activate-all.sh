#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME"

echo ""
echo "========================================="
echo "   🧬 Z‑GENESIS — FULL SYSTEM ACTIVATION"
echo "========================================="
echo ""

############################################
# 1) DSN‑PALACE — init + DB bootstrap
############################################
echo ">>> [1/5] Attivazione DSN‑PALACE"

cd "$BASE/Z-GENESIS-PALACE"

# crea DB se non esiste
if [ ! -f "DSN-PALACE.db" ]; then
    echo ">>> Inizializzo database DSN‑PALACE..."
    python3 - << 'EOF'
from palace.palace_utils import init_db
init_db()
print("DB creato.")
EOF
else
    echo ">>> DB già presente."
fi

echo ">>> DSN‑PALACE attivo."
echo ""

############################################
# 2) Z‑CORTEX — avvio server FastAPI
############################################
echo ">>> [2/5] Attivazione Z‑CORTEX"

cd "$BASE/Z-GENESIS-CORTEX"

# installa dipendenze minime
pip install fastapi uvicorn --quiet

# avvia server in background
nohup uvicorn cortex.server:app --host 0.0.0.0 --port 7001 >/dev/null 2>&1 &

echo ">>> Z‑CORTEX avviato su :7001"
echo ""

############################################
# 3) DSN‑LIVE — avvio server Node.js
############################################
echo ">>> [3/5] Attivazione DSN‑LIVE"

cd "$BASE/Z-GENESIS-LIVE"

# installa express se manca
npm list express >/dev/null 2>&1 || npm install express --silent

nohup node server/server.js >/dev/null 2>&1 &

echo ">>> DSN‑LIVE avviato su :8080"
echo ""

############################################
# 4) Z‑GENESIS‑CLI — attivazione CLI
############################################
echo ">>> [4/5] Attivazione Z‑GENESIS‑CLI"

cd "$BASE/Z-GENESIS-CLI"

chmod +x zgenctl/zgenctl.sh
chmod +x zgenctl/commands/*.sh

echo ">>> CLI pronta: usa 'zgenctl/zgenctl.sh'"
echo ""

############################################
# 5) Z‑GENESIS‑NODES — avvio agenti
############################################
echo ">>> [5/5] Attivazione Z‑GENESIS‑NODES"

cd "$BASE/Z-GENESIS-NODES"

# avvia agenti in background
nohup python3 nodes/vps/agent.py >/dev/null 2>&1 &
nohup python3 nodes/kali/agent.py >/dev/null 2>&1 &
nohup python3 nodes/termux/agent.py >/dev/null 2>&1 &

echo ">>> NODES attivi (VPS, Kali, Termux)"
echo ""

############################################
# REPORT FINALE
############################################
echo "========================================="
echo "   🧬 Z‑GENESIS — ATTIVAZIONE COMPLETA"
echo "========================================="
echo ""
echo "PALACE  → OK (DB pronto)"
echo "CORTEX  → http://localhost:7001"
echo "LIVE    → http://localhost:8080"
echo "CLI     → zgenctl/zgenctl.sh"
echo "NODES   → attivi in background"
echo ""
echo "Sistema completamente operativo."
