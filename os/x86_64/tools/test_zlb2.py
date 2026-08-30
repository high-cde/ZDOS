#!/usr/bin/env python3
"""Validate the compiler-generated ZLB2 buffer before it reaches the kernel."""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Keep this allowlist identical to kernel/zlang.c for the bootstrap target.
KNOWN_OPCODES = {0x01, 0xFF}


def load_bytes(header: Path) -> bytes:
    text = header.read_text(encoding="utf-8")
    values = re.findall(r"0x([0-9a-fA-F]{1,2})", text)
    if not values:
        raise AssertionError("generated header contains no bytecode")
    return bytes(int(value, 16) for value in values)


def validate(program: bytes) -> None:
    assert len(program) >= 6, "ZLB2 header is truncated"
    assert program[:4] == b"ZLB2", f"unexpected magic: {program[:4]!r}"
    assert program[4:6] == bytes((2, 5)), f"unexpected version: {program[4:6]!r}"

    offset = 6
    halted = False
    while offset < len(program):
        assert len(program) - offset >= 3, "truncated ZLB2 record header"
        opcode = program[offset]
        payload_length = int.from_bytes(program[offset + 1 : offset + 3], "little")
        payload_start = offset + 3
        payload_end = payload_start + payload_length
        assert opcode in KNOWN_OPCODES, f"unknown opcode: 0x{opcode:02x}"
        assert payload_end <= len(program), "record payload exceeds bytecode buffer"
        offset = payload_end
        if opcode == 0xFF:
            assert payload_length == 0, "HALT must have an empty payload"
            assert offset == len(program), "bytes found after HALT"
            halted = True
            break

    assert halted, "ZLB2 program has no terminal HALT record"


if __name__ == "__main__":
    header = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/generated/zlang_program.h")
    validate(load_bytes(header))
    print(f"ZLB2_CONTRACT_OK bytes={header.stat().st_size} header={header}")
