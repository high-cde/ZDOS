#!/data/data/com.termux/files/usr/bin/bash
echo "🔧 Modalità sviluppo — CORTEX in foreground"
cd ~/Z-GENESIS-CORTEX
uvicorn cortex.server:app --host 0.0.0.0 --port 7001
