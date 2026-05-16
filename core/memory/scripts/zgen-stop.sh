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
