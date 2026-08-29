from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IDENTITY = ROOT / "identity" / "zdos_identity.py"
CONSOLE = ROOT / "commands" / "zdoscmd.py"


class CommandLibraryTests(unittest.TestCase):
    def run_command(self, command: list[str], *, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        merged = os.environ.copy()
        if env:
            merged.update(env)
        return subprocess.run(command, text=True, capture_output=True, env=merged, check=False)

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.state = root / "identity"
        self.data = root / "data"
        self.data.mkdir()
        (self.data / "marker").write_text("zlang command data\n", encoding="utf-8")
        created = self.run_command(
            [sys.executable, str(IDENTITY), "init", "--nick", "alice", "--role", "administrator", "--state-dir", str(self.state)],
            env={"ZDOS_IDENTITY_PASSPHRASE": "test-passphrase"},
        )
        self.assertEqual(created.returncode, 0, created.stderr)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def console(self, command: str) -> subprocess.CompletedProcess[str]:
        return self.run_command(
            [sys.executable, str(CONSOLE), "--identity-dir", str(self.state), "--root", str(self.data), "--once", command]
        )

    def test_short_command_library(self) -> None:
        help_result = self.console("h")
        self.assertEqual(help_result.returncode, 0)
        self.assertIn("r <oggetto>", help_result.stdout)
        self.assertIn("storage.read", help_result.stdout)
        identity_result = self.console("i")
        self.assertEqual(identity_result.returncode, 0, identity_result.stderr)
        self.assertIn("ZDOS_IDENTITY_VERIFIED", identity_result.stdout)
        status_result = self.console("s")
        self.assertEqual(status_result.returncode, 0)
        self.assertIn("ZLANG=CONNECTED", status_result.stdout)
        zspace_result = self.console("z")
        self.assertEqual(zspace_result.returncode, 0)
        self.assertIn("OBJ  marker", zspace_result.stdout)
        read_result = self.console("r marker")
        self.assertEqual(read_result.returncode, 0, read_result.stderr)
        self.assertIn("zlang command data", read_result.stdout)
        self.assertIn("ZLANG_STORAGE_READ_OK", read_result.stderr)

    def test_prompt_and_invalid_input_are_native(self) -> None:
        source = (CONSOLE).read_text(encoding="utf-8")
        self.assertIn('input("x@zdos / ")', source)
        invalid = self.console("r 'unterminated")
        self.assertEqual(invalid.returncode, 2)
        self.assertIn("input non valido", invalid.stderr)

    def test_short_commands_do_not_bypass_path_policy(self) -> None:
        denied = self.console("r ../outside")
        self.assertNotEqual(denied.returncode, 0)
        self.assertIn("namespace ZSpace", denied.stderr)
        unknown = self.console("rm marker")
        self.assertEqual(unknown.returncode, 2)
        self.assertIn("comando sconosciuto", unknown.stderr)


if __name__ == "__main__":
    unittest.main()
