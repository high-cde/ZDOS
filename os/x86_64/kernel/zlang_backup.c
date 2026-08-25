#include "zlang.h"

enum {
    ZLANG_MAGIC_0 = 'Z',
    ZLANG_MAGIC_1 = 'L',
    ZLANG_MAGIC_2 = 'B',
    ZLANG_MAGIC_3 = '0',
    ZLANG_VERSION_1 = 1,
    ZLANG_OP_EMIT = 0x01,
    ZLANG_OP_HALT = 0xff,
};

int zlang_run(const uint8_t *program, size_t length, zlang_write_fn write) {
    size_t cursor = 0;

    if (length < 6) {
        return ZLANG_ERR_TRUNCATED;
    }
    if (program[0] != ZLANG_MAGIC_0 || program[1] != ZLANG_MAGIC_1 ||
        program[2] != ZLANG_MAGIC_2 || program[3] != ZLANG_MAGIC_3) {
        return ZLANG_ERR_MAGIC;
    }
    if (program[4] != ZLANG_VERSION_1) {
        return ZLANG_ERR_VERSION;
    }

    cursor = 5;
    while (cursor < length) {
        uint8_t opcode = program[cursor++];
        if (opcode == ZLANG_OP_HALT) {
            return cursor == length ? ZLANG_OK : ZLANG_ERR_TRAILING;
        }
        if (opcode != ZLANG_OP_EMIT) {
            return ZLANG_ERR_OPCODE;
        }
        if (cursor + 2 > length) {
            return ZLANG_ERR_TRUNCATED;
        }

        uint16_t text_length = (uint16_t)program[cursor] |
                               ((uint16_t)program[cursor + 1] << 8);
        cursor += 2;
        if ((size_t)text_length > length - cursor) {
            return ZLANG_ERR_TRUNCATED;
        }

        write((const char *)&program[cursor], text_length);
        cursor += text_length;
    }

    return ZLANG_ERR_TRUNCATED;
}
