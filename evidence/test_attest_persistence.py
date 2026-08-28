from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "evidence"))

from attest_persistence import MARKER, build_event  # noqa: E402
from ledger import read_entries, verify  # noqa: E402


def test_event_excludes_marker_content_and_contains_hash(tmp_path: Path) -> None:
    image = tmp_path / "data.img"
    image.write_bytes(b"virtual-ext4-image")
    args = type("Args", (), {
        "image": str(image),
        "uuid": "11111111-2222-4333-8444-555555555555",
        "zdos_repo": str(ROOT),
        "kernel": "5.15.0-test",
        "subject": "zdos-linux:persistent-storage-v1",
        "policy": "policy://local/persistent-storage-v1",
    })()
    event = build_event(args)
    assert event["type"] == "filesystem.persistence.attestation"
    assert event["result"] == "verified"
    assert event["persistence"]["boot_count"] == 2
    assert event["persistence"]["marker_sha256"]
    assert MARKER.decode().strip() not in json.dumps(event)


def test_ledger_append_and_verify(tmp_path: Path) -> None:
    image = tmp_path / "data.img"
    image.write_bytes(b"virtual-ext4-image")
    ledger = tmp_path / "evidence.jsonl"
    args = type("Args", (), {
        "image": str(image),
        "uuid": "11111111-2222-4333-8444-555555555555",
        "zdos_repo": str(ROOT),
        "kernel": "5.15.0-test",
        "subject": "zdos-linux:persistent-storage-v1",
        "policy": "policy://local/persistent-storage-v1",
    })()
    from ledger import append

    append(ledger, build_event(args))
    ok, reason = verify(ledger)
    assert ok, reason
    assert len(read_entries(ledger)) == 1
