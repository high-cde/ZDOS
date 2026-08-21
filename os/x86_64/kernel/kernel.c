#include <stddef.h>
#include <stdint.h>
#include "zlang.h"
#include "zlang_program.h"

static void serial_putchar(char value) {
    __asm__ volatile("outb %0, %1" : : "a"((uint8_t)value), "Nd"((uint16_t)0x3f8));
}

static void serial_print(const char *text) {
    while (*text != '\0') {
        serial_putchar(*text++);
    }
}

void kernel_main(void) {
    int result;

    serial_print("ZDOS x86_64 bootstrap (Hypervisor v2.5.1 Active)\n");
    serial_print("ZDOS: Esecuzione bytecode nativo in corso...\n");
    result = zlang_run(zlang_bytecode, sizeof(zlang_bytecode));
    if (result == ZLANG_OK) {
        serial_print("ZDOS: native Zlang program executed\n");
        serial_print("ZDOS: Zlang halted cleanly\n");
    } else {
        serial_print("ZDOS: Zlang runtime rejected program\n");
    }

    for (;;) {
        __asm__ volatile("hlt");
    }
}
