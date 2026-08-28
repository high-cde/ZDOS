"""Create a tamper-evident Zlang -> ZDOS integration attestation.

The attestation records hashes and repository commits only. It does not execute
untrusted code and it does not put secrets or private data in the ledger.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any

from ledger import append


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_commit(repo: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def build_event(args: argparse.Namespace) -> dict[str, Any]:
    source = Path(args.source).resolve()
    bytecode = Path(args.bytecode).resolve()
    header = Path(args.header).resolve()
    boot_log = Path(args.boot_log).resolve()
    for path in (source, bytecode, header, boot_log):
        if not path.is_file():
            raise FileNotFoundError(f"required evidence file not found: {path}")

    event: dict[str, Any] = {
        "type": "zlang.zdos.evolution",
        "subject": args.subject,
        "result": "verified",
        "policy": args.policy,
        "execution": "qemu-serial-proof",
        "zlang": {
            "source_sha256": sha256_file(source),
            "source_commit": git_commit(Path(args.zlang_repo)),
            "compiler": args.compiler,
        },
        "zdos": {
            "repository_commit": git_commit(Path(args.zdos_repo)),
            "bytecode_sha256": sha256_file(bytecode),
            "header_sha256": sha256_file(header),
            "boot_log_sha256": sha256_file(boot_log),
        },
        "evidence": {
            "boot_log": str(boot_log),
            "private_data": "excluded",
            "network": "none",
        },
    }
    return event


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="Attest Zlang to ZDOS Evidence Chain integration")
    root.add_argument("--ledger", required=True)
    root.add_argument("--source", required=True)
    root.add_argument("--bytecode", required=True)
    root.add_argument("--header", required=True)
    root.add_argument("--boot-log", required=True)
    root.add_argument("--zlang-repo", required=True)
    root.add_argument("--zdos-repo", required=True)
    root.add_argument("--subject", default="zlang-zdos:boot")
    root.add_argument("--compiler", default="zlang-zlb2-2.5")
    root.add_argument("--policy", default="policy://local/evolution-v1")
    return root


def main() -> int:
    args = parser().parse_args()
    event = build_event(args)
    entry = append(Path(args.ledger), event)
    print(json.dumps(entry, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
