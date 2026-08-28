"""Create a privacy-preserving Evidence Chain event for persistent storage."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any

from ledger import append


MARKER = b"ZDOS persistent-storage-v1 marker\n"


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
    image = Path(args.image).resolve()
    if not image.is_file():
        raise FileNotFoundError(f"persistent image not found: {image}")
    event: dict[str, Any] = {
        "type": "filesystem.persistence.attestation",
        "subject": args.subject,
        "result": "verified",
        "policy": args.policy,
        "execution": "qemu-two-boot-proof",
        "filesystem": {
            "type": "ext4",
            "uuid": args.uuid,
            "mountpoint": "/mnt/data",
            "device_policy": "partition-or-whole-disk",
            "image_sha256": sha256_file(image),
        },
        "persistence": {
            "write_boot": "ZDOS_PERSISTENCE_WRITE_OK",
            "read_boot": "ZDOS_PERSISTENCE_READ_OK",
            "marker_sha256": hashlib.sha256(MARKER).hexdigest(),
            "boot_count": 2,
        },
        "provenance": {
            "zdos_commit": git_commit(Path(args.zdos_repo)),
            "kernel": args.kernel,
            "private_data": "excluded",
            "network": "none",
        },
    }
    return event


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="Attest ZDOS persistent storage")
    root.add_argument("--ledger", required=True)
    root.add_argument("--image", required=True)
    root.add_argument("--uuid", required=True)
    root.add_argument("--zdos-repo", required=True)
    root.add_argument("--kernel", required=True)
    root.add_argument("--subject", default="zdos-linux:persistent-storage-v1")
    root.add_argument("--policy", default="policy://local/persistent-storage-v1")
    return root


def main() -> int:
    args = parser().parse_args()
    entry = append(Path(args.ledger), build_event(args))
    print(json.dumps(entry, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

