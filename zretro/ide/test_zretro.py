from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "zretro" / "ide" / "zretro.py"
DEMO = ROOT / "zretro" / "projects" / "meteor-patrol" / "main.zretro"


class ZRetroTests(unittest.TestCase):
    def test_demo_builds_three_target_manifests(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "main.zretro"
            source.write_text(DEMO.read_text(encoding="utf-8"), encoding="utf-8")
            result = subprocess.run([sys.executable, str(CLI), "build", str(source)], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            manifest = json.loads((source.parent / "build" / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual([item["id"] for item in manifest["targets"]], ["c64", "atari8", "amiga"])
            self.assertEqual(manifest["native_language"], "zlang-by-zdos")

    def test_terminal_preview_is_c64_shaped(self) -> None:
        result = subprocess.run([sys.executable, str(CLI), "run", str(DEMO)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("METEOR PATROL", result.stdout)
        self.assertIn("ZLANG RUNTIME // ZDOS NATIVE", result.stdout)

    def test_project_init_is_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run([sys.executable, str(CLI), "init", "Nebula Run", "--root", tmp], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((Path(tmp) / "nebula-run" / "main.zretro").is_file())

    def test_console_uses_native_prompt_and_help(self) -> None:
        result = subprocess.run([sys.executable, str(CLI), "console"], input="h\nq\n", text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("x@zdos /zretro", result.stdout)
        self.assertIn("b <sorgente>", result.stdout)

    def test_hub_manifest_is_explicit_and_safe(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "main.zretro"
            source.write_text(DEMO.read_text(encoding="utf-8"), encoding="utf-8")
            build = subprocess.run([sys.executable, str(CLI), "build", str(source)], text=True, capture_output=True)
            self.assertEqual(build.returncode, 0, build.stderr)
            result = subprocess.run([sys.executable, str(CLI), "console"], input=f"p {source}\nq\n", text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            hub_manifest = source.parent / "build" / "hub-manifest.json"
            self.assertTrue(hub_manifest.is_file())
            payload = json.loads(hub_manifest.read_text(encoding="utf-8"))
            self.assertEqual(payload["hub"], "https://zdos-hub.it/")
            self.assertTrue(payload["security"]["publish_requires_human_confirmation"])

    def test_unknown_instruction_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "bad.zretro"
            source.write_text("project Bad\ntarget c64\nexplode everything\n", encoding="utf-8")
            result = subprocess.run([sys.executable, str(CLI), "build", str(source)], text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("parola ZRetro non ammessa", result.stderr)


if __name__ == "__main__":
    unittest.main()
