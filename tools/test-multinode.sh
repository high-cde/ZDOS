#!/usr/bin/env bash
# Test locale del prototipo DSN (2 nodi sulla stessa macchina).
# Uso: ./tools/test-multinode.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PEERS="network/dsn/peers.example.json"
NODE="network/dsn/node.py"

echo "=== Avvio nodo-01 ==="
python3 "$NODE" --node-id node-01 --listen 127.0.0.1:7777 --peers "$PEERS" &
PID1=$!
sleep 1

echo "=== Avvio nodo-02 ==="
python3 "$NODE" --node-id node-02 --listen 127.0.0.1:7778 --peers "$PEERS" &
PID2=$!
sleep 1

echo "=== Propagazione da nodo-01 ==="
python3 "$NODE" --node-id node-01 --listen 127.0.0.1:0 --peers "$PEERS" --propagate "hello-from-node-01-$(date +%s)" || true

sleep 2

echo "=== Arresto nodi ==="
kill $PID1 $PID2 2>/dev/null || true
wait $PID1 $PID2 2>/dev/null || true

echo "=== Test completato (controlla i log sopra per conferma ricezione) ==="
