from __future__ import annotations

import unittest

from test_zlb2 import validate


class Zlb2BootstrapContractTests(unittest.TestCase):
    def test_accepts_emit_and_terminal_halt(self) -> None:
        validate(b"ZLB2\x02\x05\x01\x02\x00ok\xff\x00\x00")

    def test_rejects_opcode_without_bootstrap_semantics(self) -> None:
        with self.assertRaisesRegex(AssertionError, "unknown opcode"):
            validate(b"ZLB2\x02\x05\x02\x01\x00x\xff\x00\x00")

    def test_rejects_non_terminal_halt(self) -> None:
        with self.assertRaisesRegex(AssertionError, "bytes found after HALT"):
            validate(b"ZLB2\x02\x05\xff\x00\x00\x01\x01\x00x")

    def test_rejects_truncated_record(self) -> None:
        with self.assertRaisesRegex(AssertionError, "truncated ZLB2 record header"):
            validate(b"ZLB2\x02\x05\x01")


if __name__ == "__main__":
    unittest.main()
