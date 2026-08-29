#!/usr/bin/env python3
"""Authorize a Zlang capability from a ZDOS identity and run it read-only."""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import subprocess
import sys
import tempfile
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
    grant_data = profile.get("role_grant", {})
    grant = grant_data.get("payload", {})
    if grant.get("subject") != subject or grant.get("role") != role:
        raise PermissionError("role grant non corrisponde all'identità")
    public_key = identity_dir / profile["public_key"]
    expected = "did:zdos:" + hashlib.sha256(public_key.read_bytes()).hexdigest()
    if expected != subject or grant_data.get("algorithm") != "Ed25519":
        raise PermissionError("fingerprint o algoritmo identità non valido")
    with tempfile.TemporaryDirectory() as temp:
        payload = Path(temp) / "grant.json"
        signature = Path(temp) / "grant.sig"
        payload.write_bytes(json.dumps(grant, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8"))
        signature.write_bytes(base64.b64decode(grant_data["signature_base64"]))
        verified = subprocess.run(
            ["openssl", "pkeyutl", "-verify", "-pubin", "-inkey", str(public_key), "-rawin", "-in", str(payload), "-sigfile", str(signature)],
            text=True, capture_output=True, check=False,
        )
        if verified.returncode != 0:
            raise PermissionError("firma del role grant non valida")

    zlang_root = Path(os.environ.get("ZDOS_ZLANG_ROOT", str(Path(__file__).resolve().parents[2] / "Zlang"))).expanduser().resolve()
    tool = zlang_root / "tools" / "zlang_storage_read.py"
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
