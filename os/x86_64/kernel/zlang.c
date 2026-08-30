#include <stddef.h>
#include <stdint.h>
#include "zlang_program.h"

extern void serial_write_string(const char *str);
extern void serial_write_char(char c);

#define ZLB2_MAGIC_0 0x5a
#define ZLB2_MAGIC_1 0x4c
#define ZLB2_MAGIC_2 0x42
#define ZLB2_MAGIC_3 0x32
#define ZLB2_VERSION_MAJOR 0x02
#define ZLB2_VERSION_MINOR 0x05
#define ZLB2_HEADER_SIZE 6u
#define ZLB2_RECORD_HEADER_SIZE 3u
#define ZLB2_HALT 0xff
#define ZLB2_EMIT 0x01

static uint16_t read_u16_le(const uint8_t *p) {
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static int has_magic_and_version(const uint8_t *program, size_t length) {
    return length >= ZLB2_HEADER_SIZE &&
           program[0] == ZLB2_MAGIC_0 &&
           program[1] == ZLB2_MAGIC_1 &&
           program[2] == ZLB2_MAGIC_2 &&
           program[3] == ZLB2_MAGIC_3 &&
           program[4] == ZLB2_VERSION_MAJOR &&
           program[5] == ZLB2_VERSION_MINOR;
}

static int known_opcode(uint8_t opcode) {
    /* The bootstrap target accepts only opcodes with executable semantics. */
    return opcode == ZLB2_EMIT || opcode == ZLB2_HALT;
}

static void emit_payload(const uint8_t *payload, uint16_t length) {
    for (uint16_t i = 0; i < length; ++i) {
        serial_write_char((char)payload[i]);
    }
    serial_write_char('\n');
}

/* Execute the compiler-generated ZLB2 buffer. This bootstrap target is
 * intentionally restricted to EMIT and terminal HALT. Any future capability
 * must be implemented and tested before it is accepted by known_opcode(). */
void zlang_run(void) {
    const uint8_t *program = zlang_bytecode;
    const size_t length = sizeof(zlang_bytecode);
    size_t offset = ZLB2_HEADER_SIZE;
    int halted = 0;

    serial_write_string("Zlang runtime ZLB2 v2.5 ready\n");

    if (!has_magic_and_version(program, length)) {
        serial_write_string("ZDOS: ZLB2 header rejected\n");
        return;
    }

    serial_write_string("ZDOS: Esecuzione bytecode nativo in corso...\n");

    while (offset < length) {
        if (length - offset < ZLB2_RECORD_HEADER_SIZE) {
            serial_write_string("ZDOS: ZLB2 record truncated\n");
            return;
        }

        const uint8_t opcode = program[offset];
        const uint16_t payload_length = read_u16_le(program + offset + 1u);
        const size_t payload_start = offset + ZLB2_RECORD_HEADER_SIZE;

        if (!known_opcode(opcode) || payload_length > length - payload_start) {
            serial_write_string("ZDOS: ZLB2 record rejected\n");
            return;
        }

        offset = payload_start + payload_length;
        if (opcode == ZLB2_EMIT) {
            emit_payload(program + payload_start, payload_length);
        } else if (opcode == ZLB2_HALT) {
            if (payload_length != 0u || offset != length) {
                serial_write_string("ZDOS: ZLB2 invalid HALT\n");
                return;
            }
            halted = 1;
            break;
        }
    }

    if (!halted) {
        serial_write_string("ZDOS: ZLB2 HALT missing\n");
        return;
    }

    serial_write_string("Zlang HALT accepted\n");
    serial_write_string("ZDOS: native Zlang program executed\n");
    serial_write_string("ZDOS: Zlang halted cleanly\n");
}
