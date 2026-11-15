#!/usr/bin/env python3
"""
Nodo DSN ZDOS con record tipizzati (M1+).

Supporta payload opachi (compatibilità) e record JSON strutturati.
Tipi: security-event, esim-profile, onion-message, heartbeat.
"""

import argparse
import hashlib
import json
import os
import socket
import threading
import time
from datetime import datetime
from pathlib import Path

DEFAULT_PORT = 7777
RECORD_MARKER = b"ZDOS_DSN_RECORD_V1"
TYPED_MARKER = b"ZDOS_DSN_TYPED_V1"

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

class DSNNode:
    def __init__(self, node_id: str, listen_addr: str, peers_path: str):
        self.node_id = node_id
        self.listen_addr = listen_addr
        self.peers = self._load_peers(peers_path)
        self.local_records = {}
        self.sock = None

    def _load_peers(self, path: str):
        if not os.path.exists(path):
            print(f"[WARN] peers file non trovato: {path}")
            return []
        with open(path) as f:
            return json.load(f)

    def start(self):
        host, port = self.listen_addr.split(":")
        port = int(port)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((host, port))
        self.sock.listen(5)
        print(f"[{self.node_id}] in ascolto su {self.listen_addr}")
        threading.Thread(target=self._accept_loop, daemon=True).start()

    def _accept_loop(self):
        while True:
            conn, addr = self.sock.accept()
            threading.Thread(target=self._handle_client, args=(conn, addr), daemon=True).start()

    def _handle_client(self, conn, addr):
        try:
            data = conn.recv(16384)
            if data.startswith(TYPED_MARKER):
                payload = data[len(TYPED_MARKER):]
                try:
                    record = json.loads(payload.decode())
                    h = sha256(payload)
                    self.local_records[h] = record
                    print(f"[{self.node_id}] typed record type={record.get('type')} hash={h[:12]}... da {addr}")
                    conn.sendall(b"OK")
                except Exception as e:
                    print(f"[{self.node_id}] record malformato: {e}")
                    conn.sendall(b"BAD")
            elif data.startswith(RECORD_MARKER):
                payload = data[len(RECORD_MARKER):]
                h = sha256(payload)
                self.local_records[h] = payload
                print(f"[{self.node_id}] opaque record hash={h[:12]}... da {addr}")
                conn.sendall(b"OK")
            else:
                conn.sendall(b"UNKNOWN")
        except Exception as e:
            print(f"[{self.node_id}] errore client: {e}")
        finally:
            conn.close()

    def propagate_record(self, record_type: str, payload: dict, src: str = None):
        """Propaga un record tipizzato."""
        record = {
            "v": 1,
            "type": record_type,
            "id": sha256(json.dumps(payload, sort_keys=True).encode())[:16],
            "ts": datetime.utcnow().isoformat() + "Z",
            "src": src or self.node_id,
            "payload": payload
        }
        raw = json.dumps(record).encode()
        h = sha256(raw)
        self.local_records[h] = record
        print(f"[{self.node_id}] propago typed {record_type} id={record['id']}")
        msg = TYPED_MARKER + raw
        self._send_to_peers(msg)

    def propagate(self, payload: bytes):
        """Compatibilità opaca."""
        h = sha256(payload)
        self.local_records[h] = payload
        msg = RECORD_MARKER + payload
        self._send_to_peers(msg)

    def _send_to_peers(self, msg: bytes):
        for peer in self.peers:
            if peer.get("node_id") == self.node_id:
                continue
            addr = peer.get("addr")
            if not addr:
                continue
            try:
                host, port = addr.split(":")
                with socket.create_connection((host, int(port)), timeout=5) as s:
                    s.sendall(msg)
                    resp = s.recv(16)
                    if resp == b"OK":
                        print(f"[{self.node_id}] -> {peer['node_id']} OK")
                    else:
                        print(f"[{self.node_id}] -> {peer['node_id']} resp={resp}")
            except Exception as e:
                print(f"[{self.node_id}] -> {peer.get('node_id', '?')} fallito: {e}")

    def has_record(self, h: str) -> bool:
        return h in self.local_records

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--node-id", required=True)
    parser.add_argument("--listen", default="0.0.0.0:7777")
    parser.add_argument("--peers", default="peers.json")
    parser.add_argument("--propagate", help="Payload opaco")
    parser.add_argument("--demo-typed", action="store_true", help="Invia record di esempio")
    args = parser.parse_args()

    node = DSNNode(args.node_id, args.listen, args.peers)
    node.start()

    if args.propagate:
        time.sleep(0.5)
        node.propagate(args.propagate.encode())

    if args.demo_typed:
        time.sleep(0.5)
        node.propagate_record("security-event", {
            "src_ip": "203.0.113.42",
            "anomaly_score": 0.92,
            "action": "log_and_monitor"
        })
        node.propagate_record("onion-message", {
            "circuit_id": "demo-circuit-1",
            "hops": 3,
            "payload_hint": "private-comm"
        })

    print(f"[{args.node_id}] in esecuzione. Ctrl+C per uscire.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"[{args.node_id}] arresto.")

if __name__ == "__main__":
    main()
