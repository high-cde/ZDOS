from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "services" / "zdos-organismd.py"
ZLANG = Path(os.environ.get("ZDOS_ZLANG_ROOT", str(ROOT.parent / "Zlang"))).expanduser().resolve()


class ResidentOrganismTests(unittest.TestCase):
    def run_service(self, state: Path, program: Path) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.setdefault("ZDOS_ZLANG_ROOT", str(ZLANG))
        return subprocess.run(
            [sys.executable, str(SERVICE), "--once", "--state-dir", str(state), "--program", str(program)],
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )

    def test_tick_compiles_zlang_and_persists_observable_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            state = root / "state"
            program = root / "main.zlang"
            program.write_text("emit heartbeat\n", encoding="utf-8")
            result = self.run_service(state, program)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("ZDOS_ORGANISM_TICK_OK", result.stdout)
            status = json.loads((state / "status.json").read_text(encoding="utf-8"))
            self.assertEqual(status["state"], "STANDBY")
            self.assertEqual(status["result"], "validated")
            self.assertTrue((state / "tick.zlb2").is_file())
            events = (state / "events.jsonl").read_text(encoding="utf-8").splitlines()
            self.assertEqual([json.loads(line)["type"] for line in events], [
                "organism.tick.started", "organism.guard.allowed", "organism.tick.completed"
            ])

    def test_forbidden_program_halts_and_never_compiles(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            state = root / "state"
            program = root / "main.zlang"
            program.write_text("network connect\n", encoding="utf-8")
            result = self.run_service(state, program)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("ZDOS_ORGANISM_HALTED", result.stderr)
            status = json.loads((state / "status.json").read_text(encoding="utf-8"))
            self.assertEqual(status["state"], "HALT")
            self.assertFalse((state / "tick.zlb2").exists())


if __name__ == "__main__":
    unittest.main()
