#!/usr/bin/env python3
"""Bounded Hydro Guard evaluator: JSON in, JSON out, no network or hardware."""
from __future__ import annotations
import argparse, json, sys
from datetime import datetime, timezone
from pathlib import Path


def evaluate(data: dict) -> dict:
    water = data.get("water_level_cm")
    flow = data.get("flow_speed_mm_s")
    if not isinstance(water, (int, float)) or water < 0:
        raise ValueError("INVALID_SENSOR_DATA: water_level_cm")
    if not isinstance(flow, (int, float)) or flow < 0:
        raise ValueError("INVALID_SENSOR_DATA: flow_speed_mm_s")
    if water > 150 or flow > 2500:
        level, reason = "ELEVATA_FLASH_FLOOD", "critical threshold exceeded"
    elif water > 80:
        level, reason = "MODERATA", "moderate threshold exceeded"
    elif water > 30:
        level, reason = "ORDINARIA", "ordinary threshold exceeded"
    else:
        level, reason = "ASSENTE", "within baseline"
    return {
        "schema": "hydro.evaluation.v1",
        "evaluated_at": datetime.now(timezone.utc).isoformat(),
        "alert_level": level,
        "reason": reason,
        "sensor": {"water_level_cm": water, "flow_speed_mm_s": flow},
        "actions": {"mode": "READ_ONLY", "local_operator_review": True, "evidence_append": False, "radio_tx": False, "siren_actuation": False, "flipper_tx": False, "esp32_command": False},
        "policy": "DEFAULT-DENY",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="JSON telemetry file")
    args = parser.parse_args()
    try:
        result = evaluate(json.loads(Path(args.input).read_text(encoding="utf-8")))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"HYDRO_GUARD_DENIED: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
