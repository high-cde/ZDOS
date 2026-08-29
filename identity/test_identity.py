from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IDENTITY = ROOT / "identity" / "zdos_identity.py"
BRIDGE = ROOT / "identity" / "zdos_zlang_bridge.py"


class IdentityBridgeTests(unittest.TestCase):
    def run_command(self, command: list[str], *, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        merged = os.environ.copy()
        if env:
            merged.update(env)
        return subprocess.run(command, text=True, capture_output=True, env=merged, check=False)

    def test_bootstrap_signs_role_and_verifies_recovery_without_ip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp) / "identity"
            created = self.run_command(
                [sys.executable, str(IDENTITY), "init", "--nick", "alice", "--role", "administrator", "--state-dir", str(state)],
                env={"ZDOS_IDENTITY_PASSPHRASE": "test-passphrase"},
            )
            self.assertEqual(created.returncode, 0, created.stderr)
            match = re.search(r"ZDOS_RECOVERY_CODE=([A-Za-z0-9]{36})", created.stdout)
            self.assertIsNotNone(match)
            code = match.group(1)
            profile = json.loads((state / "identity.json").read_text(encoding="utf-8"))
            self.assertEqual(profile["schema"], "zdos-identity/v1")
            self.assertEqual(profile["role"], "administrator")
            self.assertEqual(profile["network_identity"], "none")
            self.assertNotIn("network_address", profile)
            self.assertEqual(profile["network_identity"], "none")
            self.assertFalse((state / ".private-key.plain.pem").exists())
            verified = self.run_command([sys.executable, str(IDENTITY), "verify", "--state-dir", str(state)])
            self.assertEqual(verified.returncode, 0, verified.stderr)
            recovery = self.run_command(
                [sys.executable, str(IDENTITY), "verify-recovery", "--state-dir", str(state)],
                env={"ZDOS_RECOVERY_CODE": code},
            )
            self.assertEqual(recovery.returncode, 0, recovery.stderr)

    def test_zlang_bridge_requires_identity_and_reads_only_authorized_namespace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            state = root / "identity"
            data = root / "data"
            data.mkdir()
            (data / "marker").write_text("native-zlang-data\n", encoding="utf-8")
            program = root / "read.zlang"
            program.write_text('storage.read "marker"\n', encoding="utf-8")
            created = self.run_command(
                [sys.executable, str(IDENTITY), "init", "--nick", "reader", "--role", "standard", "--state-dir", str(state)],
                env={"ZDOS_IDENTITY_PASSPHRASE": "test-passphrase"},
            )
            self.assertEqual(created.returncode, 0, created.stderr)
            result = self.run_command([sys.executable, str(BRIDGE), str(program), "--identity-dir", str(state), "--root", str(data)])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("native-zlang-data", result.stdout)
            self.assertIn("ZDOS_ZLANG_CAPABILITY", result.stderr)
            denied = root / "denied.zlang"
            denied.write_text('storage.read "../outside"\n', encoding="utf-8")
            result = self.run_command([sys.executable, str(BRIDGE), str(denied), "--identity-dir", str(state), "--root", str(data)])
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("denied", result.stderr)


if __name__ == "__main__":
    unittest.main()
