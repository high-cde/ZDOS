#include <stddef.h>
#include <stdint.h>
#include "zlang_program.h"

// Porte Seriali (COM1)
#define PORT_COM1 0x3F8

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

void serial_init(void) {
    outb(PORT_COM1 + 1, 0x00); // Disable interrupts
    outb(PORT_COM1 + 3, 0x80); // Enable DLAB
    outb(PORT_COM1 + 0, 0x03); // Set divisor to 3 (38400 baud)
    outb(PORT_COM1 + 1, 0x00);
    outb(PORT_COM1 + 3, 0x03); // 8 bits, no parity, one stop bit
    outb(PORT_COM1 + 2, 0xC7); // Enable FIFO
    outb(PORT_COM1 + 4, 0x0B); // IRQs enabled, RTS/DSR set
}

void serial_write_char(char c) {
    outb(PORT_COM1, (uint8_t)c);
}

void serial_write_string(const char* str) {
    while (*str) {
        serial_write_char(*str++);
    }
}

extern void zlang_run(void);

void kernel_main(void) {
    serial_init();
    serial_write_string("\n=========================================\n");
    serial_write_string(" ZDOS x86_64 bootstrap (Verified Boot v2.5)\n");
    serial_write_string("=========================================\n");
    
    // Esecuzione dell'Hypervisor con verifica crittografica
    zlang_run();

    serial_write_string("\nZDOS: Sessione operativa completata.\n");
    while (1) {
        __asm__ volatile ("hlt");
    }
}
