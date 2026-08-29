#!/usr/bin/env python3
"""Minimal ZDOS command console: short aliases, native Zlang read capability."""
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / "commands" / "command-library.json"
IDENTITY_TOOL = ROOT / "identity" / "zdos_identity.py"
BRIDGE = ROOT / "identity" / "zdos_zlang_bridge.py"


def load_library() -> dict:
    return json.loads(LIBRARY.read_text(encoding="utf-8"))


def safe_object(value: str) -> str:
    path = Path(value)
    if not value or path.is_absolute() or "\x00" in value or ".." in path.parts:
        raise ValueError("oggetto fuori dal namespace ZSpace")
    return value


def run(identity_dir: Path, zroot: Path, command: str) -> int:
    parts = shlex.split(command)
    if not parts:
        return 0
    key, *args = parts
    library = load_library()["commands"]
    if key not in library:
        print(f"comando sconosciuto: {key}; usa h", file=sys.stderr)
        return 2
    if key == "h":
        for item in library.values():
            print(f"{item['usage']:<12} {item['description']}")
        return 0
    if key == "q":
        return 10
    if key == "i":
        return subprocess.run([sys.executable, str(IDENTITY_TOOL), "verify", "--state-dir", str(identity_dir)], check=False).returncode
    if key == "s":
        profile = json.loads((identity_dir / "identity.json").read_text(encoding="utf-8"))
        print(f"ZDOS=READY ZLANG=CONNECTED ROLE={profile['role']} NAMESPACE={zroot}")
        return 0
    if key == "z":
        if not zroot.is_dir():
            print("ZSPACE=UNAVAILABLE", file=sys.stderr)
            return 3
        for item in sorted(zroot.iterdir(), key=lambda path: path.name):
            kind = "DIR" if item.is_dir() else "OBJ"
            print(f"{kind:<4} {item.name}")
        return 0
    if key == "r":
        if len(args) != 1:
            print("uso: r <oggetto>", file=sys.stderr)
            return 2
        target = safe_object(args[0])
        with tempfile.NamedTemporaryFile("w", suffix=".zlang", encoding="utf-8", delete=False) as source:
            source.write(f'storage.read "{target}"\n')
            source_path = Path(source.name)
        try:
            return subprocess.run(
                [sys.executable, str(BRIDGE), str(source_path), "--identity-dir", str(identity_dir), "--root", str(zroot), "--max-bytes", "4096"],
                check=False,
            ).returncode
        finally:
            source_path.unlink(missing_ok=True)
    return 2


def main() -> int:
    parser = argparse.ArgumentParser(description="ZDOS minimal native command console")
    parser.add_argument("--identity-dir", required=True)
    parser.add_argument("--root", required=True)
    parser.add_argument("--once", help="esegue un comando e termina")
    args = parser.parse_args()
    identity_dir = Path(args.identity_dir).expanduser().resolve()
    zroot = Path(args.root).expanduser().resolve()
    if args.once is not None:
        result = run(identity_dir, zroot, args.once)
        return 0 if result == 10 else result
    print("ZDOS NATIVE CONSOLE | ZLANG CONNECTED | usa h per aiuto")
    while True:
        try:
            command = input("Z> ")
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        result = run(identity_dir, zroot, command)
        if result == 10:
            return 0


if __name__ == "__main__":
    raise SystemExit(main())
