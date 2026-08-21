#ifndef ZDOS_ZLANG_H
#define ZDOS_ZLANG_H

#include <stddef.h>
#include <stdint.h>

enum {
    ZLANG_OK = 0,
    ZLANG_ERR_MAGIC = -1,
    ZLANG_ERR_VERSION = -2,
    ZLANG_ERR_TRUNCATED = -3,
    ZLANG_ERR_OPCODE = -4,
    ZLANG_ERR_TRAILING = -5,
};

int zlang_run(const uint8_t *program, size_t length);

#endif
