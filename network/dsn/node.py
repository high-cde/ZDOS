#!/usr/bin/env python3
"""
Nodo DSN ZDOS con record tipizzati (M1+).

Supporta payload opachi (compatibilità) e record JSON strutturati.
Tipi: security-event, esim-profile, onion-message, heartbeat,
fee-paid, governance-vote, policy-update, soft-pop.
"""

import argparse
import hashlib
import json
import os
import socket
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

DEFAULT_PORT = 7777
RECORD_MARKER = b"ZDOS_DSN_RECORD_V1"
TYPED_MARKER = b"ZDOS_DSN_TYPED_V1"
SOFT_POP_LOCK_DAYS = 7

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

class DSNNode:
    def __init__(self, node_id: str, listen_addr: str, peers_path: str):
        self.node_id = node_id
        self.listen_addr = listen_addr
        self.peers = self._load_peers(peers_path)
        self.local_records = {}
        self.sock = None
        # Soft PoP / governance state (lab)
        self.votes = {}
        self.fees = []
        self.soft_pop = {}  # node_id -> lock_until

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
                    self._process_record(record)
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

    def _process_record(self, record):
        rtype = record.get("type")
        payload = record.get("payload", {})
        if rtype == "governance-vote":
            pid = payload.get("proposal_id")
            if pid:
                self.votes.setdefault(pid, []).append(payload)
                print(f"[{self.node_id}] voto registrato per {pid}")
        elif rtype == "fee-paid":
            self.fees.append(payload)
            print(f"[{self.node_id}] fee registrata: {payload.get('amount')} $DSN per {payload.get('service')}")
        elif rtype == "soft-pop":
            nid = payload.get("node_id")
            lock = payload.get("lock_until")
            if nid and lock:
                self.soft_pop[nid] = lock
                print(f"[{self.node_id}] Soft PoP registrato per {nid}")

    def register_soft_pop(self):
        """Registra Soft PoP con time-lock (laboratorio)."""
        lock_until = (datetime.utcnow() + timedelta(days=SOFT_POP_LOCK_DAYS)).isoformat() + "Z"
        payload = {
            "node_id": self.node_id,
            "lock_until": lock_until,
            "binding": "pubkey-lab"
        }
        self.propagate_record("soft-pop", payload)
        return lock_until

    def is_soft_pop_valid(self, node_id: str = None) -> bool:
        nid = node_id or self.node_id
        lock = self.soft_pop.get(nid)
        if not lock:
            return False
        return datetime.utcnow() < datetime.fromisoformat(lock.replace("Z", ""))

    def propagate_record(self, record_type: str, payload: dict, src: str = None):
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
        self._process_record(record)
        print(f"[{self.node_id}] propago typed {record_type} id={record['id']}")
        msg = TYPED_MARKER + raw
        self._send_to_peers(msg)

    def cast_vote(self, proposal_id: str, vote: str, weight: float):
        if not self.is_soft_pop_valid():
            print(f"[{self.node_id}] Soft PoP non valido, voto rifiutato")
            return
        payload = {
            "proposal_id": proposal_id,
            "vote": vote,
            "weight": weight,
            "voter_node": self.node_id
        }
        self.propagate_record("governance-vote", payload)

    def pay_fee(self, amount: float, service: str, chain: str = "solana"):
        payload = {
            "amount": amount,
            "service": service,
            "chain": chain,
            "wallet": "lab-wallet"
        }
        self.propagate_record("fee-paid", payload)

    def calculate_quorum(self, proposal_id: str, total_weight: float = 100.0) -> dict:
        votes = self.votes.get(proposal_id, [])
        yes_weight = sum(v.get("weight", 0) for v in votes if v.get("vote") == "yes")
        no_weight = sum(v.get("weight", 0) for v in votes if v.get("vote") == "no")
        total_voted = yes_weight + no_weight
        quorum_pct = (total_voted / total_weight) * 100 if total_weight > 0 else 0
        approved = quorum_pct >= 15 and yes_weight > no_weight
        return {
            "proposal_id": proposal_id,
            "yes": yes_weight,
            "no": no_weight,
            "quorum_pct": round(quorum_pct, 2),
            "approved": approved,
            "votes_count": len(votes)
        }

    def propagate(self, payload: bytes):
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
    parser.add_argument("--demo-typed", action="store_true")
    parser.add_argument("--demo-governance", action="store_true")
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

    if args.demo_governance:
        time.sleep(0.5)
        node.register_soft_pop()
        node.pay_fee(0.1, "z-onion-hop")
        node.cast_vote("sec-policy-001", "yes", 25.0)
        node.cast_vote("sec-policy-001", "no", 10.0)
        result = node.calculate_quorum("sec-policy-001", total_weight=100.0)
        print(f"[{args.node_id}] Soft PoP valido: {node.is_soft_pop_valid()}")
        print(f"[{args.node_id}] Quorum result: {result}")

    print(f"[{args.node_id}] in esecuzione. Ctrl+C per uscire.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"[{args.node_id}] arresto.")

if __name__ == "__main__":
    main()
