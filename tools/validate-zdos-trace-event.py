#!/usr/bin/env python3
"""Validate a ZDOS trace event locally; no network and no ledger mutation."""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import re
import sys
from pathlib import Path

HEX64 = re.compile(r"^sha256:[0-9a-fA-F]{64}$")
REQUIRED = {"event_id", "event_type", "event_time", "what", "where", "who", "why", "proof"}
TYPES = {"ObjectEvent", "AggregationEvent", "TransformationEvent", "TransactionEvent"}


def validate(data: dict) -> list[str]:
    errors = []
    missing = sorted(REQUIRED - data.keys())
    if missing: errors.append(f"missing: {','.join(missing)}")
    if data.get("event_type") not in TYPES: errors.append("invalid event_type")
    if not isinstance(data.get("what"), list) or not data.get("what"): errors.append("what must be a non-empty array")
    for key in ("event_id", "where", "who", "why"):
        if not isinstance(data.get(key), str) or not data.get(key): errors.append(f"invalid {key}")
    try: dt.datetime.fromisoformat(str(data.get("event_time", "")).replace("Z", "+00:00"))
    except ValueError: errors.append("event_time must be ISO-8601")
    proof = data.get("proof")
    if not isinstance(proof, dict) or proof.get("schema") != "zdos.proof.v1": errors.append("invalid proof schema")
    elif not HEX64.fullmatch(str(proof.get("object_hash", ""))): errors.append("invalid proof object_hash")
    elif not isinstance(proof.get("issuer"), str) or len(proof["issuer"]) < 8: errors.append("invalid proof issuer")
    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} EVENT.json", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    data = json.loads(path.read_text(encoding="utf-8"))
    errors = validate(data)
    if errors:
        for error in errors: print(f"FAIL {error}")
        return 1
    canonical = json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    print(f"PASS zdos-trace-event.v1 event_id={data['event_id']}")
    print(f"PAYLOAD_SHA256={hashlib.sha256(canonical).hexdigest()}")
    print("ACTION=VALIDATE_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
