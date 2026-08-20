#include <stddef.h>
#include <stdint.h>
#include "zlang_program.h"

extern void zlang_run(const unsigned char* bytecode, size_t length);

static void serial_putchar(char c) {
    __asm__ volatile("outb %0, %1" : : "a"((uint8_t)c), "Nd"((uint16_t)0x3F8));
}

static void serial_print(const char* str) {
    while (*str) serial_putchar(*str++);
}

void kernel_main(void) {
    serial_print("ZDOS x86_64 bootstrap (Hypervisor v2.5.1 Active)\n");
    serial_print("ZDOS: Esecuzione bytecode nativo in corso...\n");

    // Esecuzione dinamica della Calcolatrice Z-Lang tramite l'Hypervisor
    zlang_run(zlang_program, zlang_program_length);

    serial_print("ZDOS: Sessione calcolatrice completata.\n");

    while (1) {
        __asm__ volatile("hlt");
    }
}
