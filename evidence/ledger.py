#!/usr/bin/env python3
"""Minimal append-only Evidence Chain for ZDOS.

This is a non-monetary hash-chained event ledger. It provides integrity and
ordering proofs; it does not replace multi-node consensus or a PKI.
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

GENESIS_HASH = "0" * 64
SCHEMA = "zdos-evidence/v1"


def canonical(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def digest(previous: str, event: dict[str, Any]) -> str:
    return hashlib.sha256(previous.encode() + b"\n" + canonical(event)).hexdigest()


def sign(event_hash: str, key: str | None) -> str | None:
    if not key:
        return None
    return hmac.new(key.encode(), event_hash.encode(), hashlib.sha256).hexdigest()


def read_entries(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    entries: list[dict[str, Any]] = []
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"invalid JSON at line {line_no}: {exc}") from exc
        if not isinstance(entry, dict):
            raise ValueError(f"ledger line {line_no} is not an object")
        entries.append(entry)
    return entries


def verify(path: Path, key: str | None = None) -> tuple[bool, str]:
    try:
        entries = read_entries(path)
        if not entries:
            return False, "ledger is empty"
        previous = GENESIS_HASH
        for expected_sequence, entry in enumerate(entries):
            if entry.get("schema") != SCHEMA:
                return False, f"entry {expected_sequence}: schema mismatch"
            if entry.get("sequence") != expected_sequence:
                return False, f"entry {expected_sequence}: sequence mismatch"
            if entry.get("previous_hash") != previous:
                return False, f"entry {expected_sequence}: previous hash mismatch"
            stored_hash = entry.get("hash")
            unsigned = {k: v for k, v in entry.items() if k not in {"hash", "signature"}}
            expected_hash = digest(previous, unsigned)
            if stored_hash != expected_hash:
                return False, f"entry {expected_sequence}: hash mismatch"
            if key:
                expected_signature = sign(stored_hash, key)
                if not hmac.compare_digest(entry.get("signature") or "", expected_signature or ""):
                    return False, f"entry {expected_sequence}: signature mismatch"
            previous = stored_hash
        return True, f"verified {len(entries)} entries; head={previous}"
    except ValueError as exc:
        return False, str(exc)


def append(path: Path, payload: dict[str, Any], key: str | None = None) -> dict[str, Any]:
    entries = read_entries(path)
    ok, reason = verify(path, key=None) if entries else (True, "empty")
    if not ok:
        raise ValueError(f"refusing to append to invalid ledger: {reason}")
    previous = entries[-1]["hash"] if entries else GENESIS_HASH
    unsigned = {
        "schema": SCHEMA,
        "sequence": len(entries),
        "timestamp": int(time.time()),
        "previous_hash": previous,
        "event": payload,
    }
    entry = dict(unsigned)
    entry["hash"] = digest(previous, unsigned)
    entry["signature"] = sign(entry["hash"], key)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as stream:
        stream.write(json.dumps(entry, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n")
    return entry


def cmd_init(args: argparse.Namespace) -> int:
    path = Path(args.ledger)
    if path.exists() and path.stat().st_size:
        ok, reason = verify(path)
        print(reason)
        return 0 if ok else 1
    append(path, {"type": "ledger.genesis", "network": args.network, "purpose": "non-monetary operational evidence"}, os.getenv(args.key_env))
    print(f"initialized {path}")
    return 0


def cmd_attest(args: argparse.Namespace) -> int:
    path = Path(args.ledger)
    event = {
        "type": args.type,
        "subject": args.subject,
        "result": args.result,
        "builder": args.builder,
        "policy": args.policy,
    }
    if args.source_commit:
        event["source_commit"] = args.source_commit
    if args.toolchain:
        event["toolchain"] = args.toolchain
    if args.evidence_uri:
        event["evidence_uri"] = args.evidence_uri
    entry = append(path, event, os.getenv(args.key_env))
    print(json.dumps(entry, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


def cmd_verify(args: argparse.Namespace) -> int:
    ok, reason = verify(Path(args.ledger), os.getenv(args.key_env))
    print(reason)
    return 0 if ok else 1


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="ZDOS non-monetary Evidence Chain")
    root.add_argument("--ledger", default="evidence/ledger.jsonl")
    root.add_argument("--key-env", default="ZDOS_EVIDENCE_KEY")
    sub = root.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--network", default="local-dev")
    init.set_defaults(func=cmd_init)
    attest = sub.add_parser("attest")
    attest.add_argument("--type", default="build.attestation")
    attest.add_argument("--subject", required=True)
    attest.add_argument("--result", choices=("verified", "rejected", "revoked"), required=True)
    attest.add_argument("--builder", required=True)
    attest.add_argument("--policy", required=True)
    attest.add_argument("--source-commit")
    attest.add_argument("--toolchain")
    attest.add_argument("--evidence-uri")
    attest.set_defaults(func=cmd_attest)
    check = sub.add_parser("verify")
    check.set_defaults(func=cmd_verify)
    return root


if __name__ == "__main__":
    try:
        args = parser().parse_args()
        raise SystemExit(args.func(args))
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
