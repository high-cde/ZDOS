"""Local-only ZRetro terminal bus.

The bus is deliberately filesystem-scoped: no sockets, no credentials and no
implicit network access. Two ZDOS terminals interconnect by sharing a bus
folder (for example on a mounted disk or a local serial-file bridge).
"""
from __future__ import annotations

import hashlib
import json
import os
import time
from pathlib import Path

SCHEMA = "zdos-zretro-bus/v1"


def bus_root(project_root: Path) -> Path:
    configured = os.environ.get("ZDOS_ZRETRO_BUS_DIR")
    root = Path(configured).expanduser() if configured else project_root / "build" / "bus"
    root.mkdir(parents=True, exist_ok=True)
    return root


def _safe(value: str, label: str, limit: int) -> str:
    clean = value.strip()
    if not clean or len(clean) > limit or any(ord(char) < 32 for char in clean):
        raise ValueError(f"{label} non valido")
    return clean


def link_terminal(project_root: Path, terminal_id: str, peer_id: str) -> Path:
    terminal = _safe(terminal_id, "terminal", 48)
    peer = _safe(peer_id, "peer", 48)
    path = bus_root(project_root) / "links.json"
    links = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"schema": SCHEMA, "links": []}
    pair = sorted([terminal, peer])
    if pair not in links["links"]:
        links["links"].append(pair)
        links["links"].sort()
        path.write_text(json.dumps(links, indent=2) + "\n", encoding="utf-8")
    return path


def _is_linked(root: Path, sender: str, recipient: str) -> bool:
    path = root / "links.json"
    if not path.exists():
        return False
    links = json.loads(path.read_text(encoding="utf-8"))
    return sorted([sender, recipient]) in links.get("links", [])


def send_message(project_root: Path, sender: str, recipient: str, channel: str, body: str) -> dict:
    sender = _safe(sender, "sender", 48)
    recipient = _safe(recipient, "recipient", 48)
    channel = _safe(channel, "channel", 32)
    body = _safe(body, "message", 512)
    root = bus_root(project_root)
    if not _is_linked(root, sender, recipient):
        raise ValueError("terminali non collegati: eseguire link prima di inviare")
    timestamp = str(time.time_ns())
    message = {"schema": SCHEMA, "id": "msg-" + hashlib.sha256(f"{sender}|{recipient}|{timestamp}|{body}".encode()).hexdigest()[:16], "sender": sender, "recipient": recipient, "channel": channel, "body": body, "created_at": timestamp}
    with (root / "messages.jsonl").open("a", encoding="utf-8") as stream:
        stream.write(json.dumps(message, ensure_ascii=False, sort_keys=True) + "\n")
    return message


def receive_messages(project_root: Path, terminal_id: str, after: str | None = None) -> list[dict]:
    terminal = _safe(terminal_id, "terminal", 48)
    path = bus_root(project_root) / "messages.jsonl"
    if not path.exists():
        return []
    messages = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    if after:
        ids = [message["id"] for message in messages]
        if after in ids:
            messages = messages[ids.index(after) + 1 :]
    return [message for message in messages if message["recipient"] == terminal]
