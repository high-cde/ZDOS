#!/usr/bin/env python3
"""Validate the declarative 80.24 network profile; never changes networking."""
from __future__ import annotations

import ipaddress
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "network" / "subnet-8024.json"
EXPECTED = ipaddress.ip_network("80.24.0.0/16")

def main() -> int:
    profile = json.loads(PROFILE.read_text(encoding="utf-8"))
    network = ipaddress.ip_network(profile["cidr"], strict=True)
    checks = {
        "schema": profile.get("schema") == "zdos.network.profile.v1",
        "cidr": network == EXPECTED,
        "design_only": profile.get("activation") == "DESIGN_ONLY",
        "default_deny": profile.get("policy") == "DEFAULT_DENY",
        "no_gateway": profile.get("gateway") is None,
        "no_interface": profile.get("interface") is None,
        "dhcp_disabled": profile.get("dhcp") is False,
        "nat_disabled": profile.get("nat") is False,
        "route_apply_denied": "network.route.apply-v1" in profile.get("denied_capabilities", []),
        "firewall_apply_denied": "network.firewall.apply-v1" in profile.get("denied_capabilities", []),
    }
    for name, passed in checks.items():
        print(f"{'PASS' if passed else 'FAIL'} {name}")
    if not all(checks.values()):
        return 1
    print(f"ZDOS_SUBNET_PROFILE_VALIDATED cidr={network} hosts={network.num_addresses - 2} activation=DESIGN_ONLY")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
