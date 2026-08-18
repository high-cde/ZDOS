#include <stddef.h>
#include <stdint.h>

#include "zlang.h"
#include "zlang_program.h"

#define COM1 0x3f8

static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void serial_init(void) {
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x80);
    outb(COM1 + 0, 0x03);
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03);
    outb(COM1 + 2, 0xc7);
    outb(COM1 + 4, 0x0b);
}

static void serial_putc(char value) {
    while ((inb(COM1 + 5) & 0x20) == 0) {
    }
    outb(COM1, (uint8_t)value);
}

static void serial_write(const char *data, size_t length) {
    for (size_t index = 0; index < length; ++index) {
        if (data[index] == '\n') {
            serial_putc('\r');
        }
        serial_putc(data[index]);
    }
}

static void serial_print(const char *text) {
    size_t length = 0;
    while (text[length] != '\0') {
        ++length;
    }
    serial_write(text, length);
}

void kernel_main(void) {
    serial_init();
    serial_print("ZDOS x86_64 bootstrap\n");
    serial_print("Zlang runtime v1 ready\n");

    int result = zlang_run(zlang_program, zlang_program_length, serial_write);
    serial_print("\n");
    if (result == ZLANG_OK) {
        serial_print("ZDOS: Zlang halted cleanly\n");
    } else {
        serial_print("ZDOS: Zlang runtime rejected program\n");
    }

    for (;;) {
        __asm__ volatile ("hlt");
    }
}
