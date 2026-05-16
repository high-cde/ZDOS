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
