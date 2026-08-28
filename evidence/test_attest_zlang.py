from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from attest_zlang import build_event


class AttestZlangTests(unittest.TestCase):
    def test_event_contains_artifact_hashes_and_execution_proof(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "program.zlang"
            bytecode = root / "program.zlb"
            header = root / "program.h"
            boot_log = root / "boot.log"
            source.write_text("emit hello\n", encoding="utf-8")
            bytecode.write_bytes(b"ZLB2\x02\x05\xff\x00\x00")
            header.write_text("static const unsigned char program[] = { 0xff };\n", encoding="utf-8")
            boot_log.write_text("ZDOS: native Zlang program executed\nZDOS: Zlang halted cleanly\n", encoding="utf-8")

            with patch("attest_zlang.git_commit", side_effect=["zlang-commit", "zdos-commit"]):
                event = build_event(
                    type("Args", (), {
                        "source": source,
                        "bytecode": bytecode,
                        "header": header,
                        "boot_log": boot_log,
                        "zlang_repo": root,
                        "zdos_repo": root,
                        "subject": "zlang-zdos:test",
                        "compiler": "zlang-zlb2-2.5",
                        "policy": "policy://test/evolution-v1",
                    })()
                )

            self.assertEqual(event["type"], "zlang.zdos.evolution")
            self.assertEqual(event["result"], "verified")
            self.assertEqual(event["execution"], "qemu-serial-proof")
            self.assertEqual(event["zlang"]["source_commit"], "zlang-commit")
            self.assertEqual(event["zdos"]["repository_commit"], "zdos-commit")
            self.assertEqual(len(event["zlang"]["source_sha256"]), 64)
            self.assertEqual(len(event["zdos"]["bytecode_sha256"]), 64)
            self.assertEqual(event["evidence"]["network"], "none")


if __name__ == "__main__":
    unittest.main()
