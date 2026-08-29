from __future__ import annotations

import hashlib
import json
from pathlib import Path

HUB_URL = "https://zdos-hub.it/"


def prepare_manifest(project_root: Path, build_manifest: Path) -> Path:
    data = json.loads(build_manifest.read_text(encoding="utf-8"))
    payload = {
        "schema": "zdos-hub-zretro/v1",
        "hub": HUB_URL,
        "mode": "explicit-review",
        "project": data["name"],
        "source_sha256": data["source_sha256"],
        "targets": data["targets"],
        "status": "READY_FOR_AUTHENTICATED_REVIEW",
        "security": {
            "network_default": "disabled",
            "no_rom_bios_upload": True,
            "no_credentials_in_payload": True,
            "publish_requires_human_confirmation": True,
        },
    }
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    payload["manifest_sha256"] = hashlib.sha256(canonical).hexdigest()
    output = project_root / "build" / "hub-manifest.json"
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return output
