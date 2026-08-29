#!/usr/bin/env python3
"""Resident ZDOS organism supervisor: bounded, observable and fail-closed."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "zdos-organism-event/v1"
FORBIDDEN = {"shell", "network", "exec", "write-node", "delete", "credential-access"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(temp, path)


def append_event(path: Path, event: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")


def load_program(path: Path) -> str:
    if not path.is_file():
        raise FileNotFoundError(f"programma Zlang assente: {path}")
    source = path.read_text(encoding="utf-8")
    if len(source.encode("utf-8")) > 65536:
        raise ValueError("programma Zlang oltre il limite di 65536 byte")
    lowered = source.lower()
    for operation in FORBIDDEN:
        if operation in lowered:
            raise PermissionError(f"operazione vietata nel programma Zlang: {operation}")
    return source


def emit(state_dir: Path, state: str, event_type: str, detail: dict) -> None:
    status = {"schema": "zdos-organism-status/v1", "state": state, "updated_at": now(), **detail}
    write_json(state_dir / "status.json", status)
    append_event(state_dir / "events.jsonl", {"schema": SCHEMA, "at": status["updated_at"], "type": event_type, "state": state, **detail})


def tick(args: argparse.Namespace) -> int:
    state_dir = Path(args.state_dir).expanduser().resolve()
    program = Path(args.program).expanduser().resolve()
    try:
        source = load_program(program)
    except (FileNotFoundError, PermissionError, ValueError) as exc:
        emit(state_dir, "HALT", "organism.guard.denied", {"reason": str(exc)})
        print(f"ZDOS_ORGANISM_HALTED reason={exc}", file=sys.stderr)
        return 1

    source_hash = hashlib.sha256(source.encode("utf-8")).hexdigest()
    emit(state_dir, "OBSERVE", "organism.tick.started", {"program_sha256": source_hash, "guard": "fail-closed"})
    zlang_root = Path(os.environ.get("ZDOS_ZLANG_ROOT", str(Path(__file__).resolve().parents[2] / "Zlang"))).expanduser().resolve()
    compiler = zlang_root / "tools" / "zlangc.py"
    if not compiler.is_file():
        emit(state_dir, "HALT", "organism.guard.denied", {"reason": f"Zlang compiler assente: {compiler}"})
        print(f"ZDOS_ORGANISM_HALTED reason=Zlang compiler assente: {compiler}", file=sys.stderr)
        return 1

    # The first resident milestone validates the program and records the decision;
    # it does not execute arbitrary node actions or invoke a shell.
    emit(state_dir, "DECIDE", "organism.guard.allowed", {"capability": "observe", "action": "zlang.validate-only"})
    bytecode = state_dir / "tick.zlb2"
    header = state_dir / "tick.h"
    result = subprocess.run(
        [sys.executable, str(compiler), str(program), "--bytecode", str(bytecode), "--header", str(header)],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        emit(state_dir, "HALT", "organism.zlang.rejected", {"stderr": result.stderr[-2048:]})
        print(result.stderr, file=sys.stderr, end="")
        return result.returncode
    emit(state_dir, "STANDBY", "organism.tick.completed", {"program_sha256": source_hash, "result": "validated", "stdout": result.stdout[-2048:]})
    print(f"ZDOS_ORGANISM_TICK_OK program_sha256={source_hash} state=STANDBY")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="ZDOS resident organism supervisor")
    parser.add_argument("--state-dir", default=os.environ.get("ZDOS_ORGANISM_STATE_DIR", "./var/organism"))
    parser.add_argument("--program", default=os.environ.get("ZDOS_ORGANISM_PROGRAM", "./main.zlang"))
    parser.add_argument("--once", action="store_true", help="esegue un solo tick")
    parser.add_argument("--interval", type=int, default=5)
    args = parser.parse_args()
    if args.interval < 1 or args.interval > 3600:
        parser.error("--interval deve essere tra 1 e 3600 secondi")
    if args.once:
        return tick(args)
    while True:
        result = tick(args)
        if result:
            return result
        time.sleep(args.interval)


if __name__ == "__main__":
    raise SystemExit(main())
