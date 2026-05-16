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
