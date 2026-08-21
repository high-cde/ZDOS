#include <stddef.h>
#include <stdint.h>
#include "zlang.h"

#define ZLB2_HEADER_SIZE 6U

static void serial_putchar(char value) {
    __asm__ volatile("outb %0, %1" : : "a"((uint8_t)value), "Nd"((uint16_t)0x3f8));
}

static void serial_text(const char *text) {
    while (*text != '\0') {
        serial_putchar(*text++);
    }
}

static uint16_t read_u16(const uint8_t *data) {
    return (uint16_t)data[0] | ((uint16_t)data[1] << 8);
}

static int has_bytes(size_t pc, size_t length, size_t needed) {
    return pc <= length && needed <= length - pc;
}

int zlang_run(const uint8_t *program, size_t length) {
    size_t pc;

    if (!has_bytes(0, length, ZLB2_HEADER_SIZE)) {
        return ZLANG_ERR_TRUNCATED;
    }
    if (program[0] != 'Z' || program[1] != 'L' ||
        program[2] != 'B' || program[3] != '2') {
        return ZLANG_ERR_MAGIC;
    }
    if (program[4] != 0x02 || program[5] != 0x05) {
        return ZLANG_ERR_VERSION;
    }

    pc = ZLB2_HEADER_SIZE;
    serial_text("Zlang runtime ZLB2 v2.5 ready\n");
    while (pc < length) {
        uint8_t opcode;
        uint16_t payload_length;
        const uint8_t *payload;

        if (!has_bytes(pc, length, 3)) {
            return ZLANG_ERR_TRUNCATED;
        }
        opcode = program[pc++];
        payload_length = read_u16(program + pc);
        pc += 2;
        if (!has_bytes(pc, length, payload_length)) {
            return ZLANG_ERR_TRUNCATED;
        }
        payload = program + pc;

        if (opcode == 0xff) {
            if (payload_length != 0 || pc + payload_length != length) {
                return ZLANG_ERR_TRAILING;
            }
            serial_text("Zlang HALT accepted\n");
            return ZLANG_OK;
        }
        if (opcode == 0x01) {
            for (uint16_t index = 0; index < payload_length; ++index) {
                serial_putchar((char)payload[index]);
            }
            serial_putchar('\n');
        } else if (opcode == 0x02 || opcode == 0x03 || opcode == 0x04 || opcode == 0x05) {
            /* Bootstrap runtime: validate and skip non-EMIT records safely. */
        } else {
            return ZLANG_ERR_OPCODE;
        }
        pc += payload_length;
    }
    return ZLANG_ERR_TRUNCATED;
}
