#include <stddef.h>
#include <stdint.h>

// Funzione interna per scrivere sulla seriale QEMU (0x3F8)
static void zlang_serial_putchar(char c) {
    __asm__ volatile("outb %0, %1" : : "a"((uint8_t)c), "Nd"((uint16_t)0x3F8));
}

static void zlang_serial_print(const char* str) {
    while (*str) {
        zlang_serial_putchar(*str++);
    }
}

// Hypervisor v2.5.1 - Interprete bytecode Z-Lang con supporto ALU e RAM virtuale
void zlang_run(const unsigned char* bytecode, size_t length) {
    size_t pc = 0;
    int64_t vram[16] = {0}; // 16 registri di memoria virtuale

    zlang_serial_print("[Z-LANG VM] Avvio interprete Hypervisor v2.5.1...\n");

    while (pc < length) {
        uint8_t op = bytecode[pc++];

        // Opcode 0x01: EMIT (Stampa stringa letterale incorporata nel bytecode)
        if (op == 0x01) {
            uint16_t str_len = bytecode[pc] | (bytecode[pc+1] << 8);
            pc += 2;
            
            // Stampa carattere per carattere la stringa emessa dallo script
            for (int i = 0; i < str_len && pc < length; i++) {
                zlang_serial_putchar((char)bytecode[pc++]);
            }
            zlang_serial_putchar('\n');
        }
        // Opcode 0x02: LET / ALLOCAZIONE REGISTRO
        else if (op == 0x02) {
            uint8_t reg_id = bytecode[pc++];
            int64_t val = *(int64_t*)(bytecode + pc);
            pc += 8;
            if (reg_id < 16) {
                vram[reg_id] = val;
            }
        }
        // Opcode 0x03: OPERAZIONI ALU (Addizioni, Moltiplicazioni, ecc.)
        else if (op == 0x03) {
            uint8_t dest = bytecode[pc++];
            uint8_t src1 = bytecode[pc++];
            uint8_t op_type = bytecode[pc++];
            uint8_t src2 = bytecode[pc++];
            
            if (op_type == 1) { // Addizione (+)
                vram[dest] = vram[src1] + vram[src2];
            } else if (op_type == 2) { // Moltiplicazione (*)
                vram[dest] = vram[src1] * vram[src2];
            }
        }
        else {
            // Opcode sconosciuto o fine flusso
            break;
        }
    }
    zlang_serial_print("[Z-LANG VM] Esecuzione bytecode terminata.\n");
}
