from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MICRO = ROOT / "microcosm"
CONTROL = MICRO / "zdos-microctl"


class ConnectedMicrocosmTests(unittest.TestCase):
    def run_control(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        runtime_env = os.environ.copy()
        if env:
            runtime_env.update(env)
        return subprocess.run(
            [str(CONTROL), *args],
            cwd=ROOT,
            env=runtime_env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_catalog_and_contract_are_complete(self) -> None:
        catalog = json.loads((MICRO / "catalog.json").read_text(encoding="utf-8"))
        contract = json.loads((MICRO / "contract.json").read_text(encoding="utf-8"))
        self.assertEqual(catalog["schema"], "zdos-microcosm/v1")
        self.assertEqual(contract["schema"], "zdos-microcosm-contract/v1")
        self.assertEqual(catalog["policy"], "default-deny")
        self.assertEqual(contract["policy"], "default-deny")
        self.assertEqual(catalog["components"][0]["id"], "zdos")
        self.assertEqual(catalog["components"][0]["local_path"], ".")
        self.assertEqual(catalog["components"][0]["status"], "VERIFIED")
        statuses = {"VERIFIED", "PREPARED", "EXPERIMENTAL", "NOT_VERIFIED"}
        for component in catalog["components"]:
            self.assertIn(component["status"], statuses)
            self.assertTrue(component["remote"].startswith("https://github.com/"))
            self.assertTrue(component["checks"])

    def test_persistence_flow_requires_all_observable_markers(self) -> None:
        catalog = json.loads((MICRO / "catalog.json").read_text(encoding="utf-8"))
        flow = next(item for item in catalog["flows"] if item["id"] == "persistent-storage-evidence-v1")
        self.assertEqual(flow["status"], "VERIFIED")
        self.assertEqual(flow["proof"]["execution"], "qemu-two-boot-proof")
        self.assertEqual(
            flow["proof"]["required_markers"],
            [
                "ZDOS_PERSISTENCE_WRITE_OK",
                "ZDOS_PERSISTENCE_READ_OK",
                "ZDOS_PERSISTENCE_CLEAN_SHUTDOWN_OK",
                "ZDOS_PERSISTENCE_QEMU_TEST_PASSED",
            ],
        )
        self.assertEqual(flow["proof"]["ledger_event"], "filesystem.persistence.attestation")

    def test_inspect_is_read_only_for_the_zdos_checkout(self) -> None:
        before = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
        result = self.run_control("inspect")
        after = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ZDOS Connected Microcosm inspection", result.stdout)
        self.assertIn("zdos: status=VERIFIED", result.stdout)
        self.assertEqual(before, after)

    def test_manifest_has_source_hashes_and_no_external_side_effects(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            artifact_dir = Path(directory) / "artifacts"
            result = self.run_control("manifest", env={"ZDOS_MICROCOSM_ARTIFACTS": str(artifact_dir)})
            self.assertEqual(result.returncode, 0, result.stderr)
            output = artifact_dir / "microcosm-state.json"
            state = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(state["schema"], "zdos-microcosm-state/v1")
        self.assertEqual(len(state["source_hashes"]["catalog_sha256"]), 64)
        self.assertEqual(len(state["source_hashes"]["contract_sha256"]), 64)
        self.assertEqual(len(state["state_sha256"]), 64)
        zdos = next(item for item in state["components"] if item["id"] == "zdos")
        self.assertTrue(zdos["present"])
        self.assertEqual(len(zdos["commit"]), 40)

    def test_gate_validates_local_entrypoints(self) -> None:
        result = self.run_control("gate")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("gate superato", result.stdout)


if __name__ == "__main__":
    unittest.main()
