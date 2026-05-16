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
