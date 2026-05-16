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
