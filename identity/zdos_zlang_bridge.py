#!/usr/bin/env python3
"""Authorize a Zlang capability from a ZDOS identity and run it read-only."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ALLOWED = {
    "standard": {"storage.read-v1"},
    "operator": {"storage.read-v1", "evidence.append-v1"},
    "administrator": {"storage.read-v1", "evidence.append-v1", "identity.manage-v1", "policy.manage-v1"},
}


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"oggetto JSON non valido: {path}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description="ZDOS identity-bound Zlang read-only bridge")
    parser.add_argument("source", help="programma Zlang con capability storage.read-v1")
    parser.add_argument("--identity-dir", required=True)
    parser.add_argument("--root", required=True, help="namespace esplicito, ad esempio /mnt/data")
    parser.add_argument("--max-bytes", type=int, default=4096)
    args = parser.parse_args()
    if args.max_bytes < 1 or args.max_bytes > 1024 * 1024:
        parser.error("--max-bytes deve essere tra 1 e 1048576")

    identity_dir = Path(args.identity_dir).expanduser().resolve()
    profile = load_json(identity_dir / "identity.json")
    if profile.get("schema") != "zdos-identity/v1" or profile.get("network_identity") != "none":
        raise ValueError("identità non valida o non locale")
    role = profile.get("role")
    capability = "storage.read-v1"
    if capability not in ALLOWED.get(role, set()):
        raise PermissionError(f"ruolo {role!r} non autorizzato per {capability}")

    subject = profile.get("identity")
    grant = profile.get("role_grant", {}).get("payload", {})
    if grant.get("subject") != subject or grant.get("role") != role:
        raise PermissionError("role grant non corrisponde all'identità")

    tool = Path(__file__).resolve().parents[2] / "Zlang" / "tools" / "zlang_storage_read.py"
    if not tool.is_file():
        raise FileNotFoundError(f"tool Zlang non disponibile: {tool}")
    result = subprocess.run(
        [sys.executable, str(tool), str(Path(args.source).resolve()), "--root", str(Path(args.root).resolve()), "--max-bytes", str(args.max_bytes)],
        text=True,
        capture_output=True,
        check=False,
    )
    sys.stdout.write(result.stdout)
    sys.stderr.write(f"ZDOS_ZLANG_CAPABILITY subject={subject} capability={capability} mode=read-only\n")
    sys.stderr.write(result.stderr)
    return result.returncode


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, PermissionError, ValueError, json.JSONDecodeError) as exc:
        print(f"ZDOS_ZLANG_BRIDGE_DENIED: {exc}", file=sys.stderr)
        raise SystemExit(1)
