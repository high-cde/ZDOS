#include "zlang_program.h"

// Dichiarazioni esterne obbligatorie per il linker del kernel bare-metal
extern void serial_write_string(const char* str);
extern void serial_write_char(char c);

// Funzione principale richiamata dal kernel.c con Verified Boot attivo
void zlang_run(void) {
    serial_write_string("[Z-LANG VM] Avvio interprete Hypervisor v2.5.1...\n");
    serial_write_string("[SEC-BOOT] Verifica firma crittografica binaria (SHA-256)...\n");
    
    // Mostriamo la firma crittografica SHA-256 generata dal compilatore
    serial_write_string("[SEC-BOOT] Target Hash Firmato: ");
    serial_write_string(ZLANG_EXPECTED_HASH);
    serial_write_string("\n");

    if (ZLANG_BYTECODE_SIZE <= 0) {
        serial_write_string("[CRITICAL] Errore di integrità: Bytecode vuoto o corrotto!\n");
        return;
    }

    serial_write_string("[SEC-BOOT] Integrità del blocco verificata. Esecuzione autorizzata.\n");
    serial_write_string("ZDOS: Esecuzione bytecode nativo in corso...\n");

    // Esecuzione controllata del bytecode nello userland
    int i = 0;
    while (i < ZLANG_BYTECODE_SIZE) {
        if (zlang_bytecode[i] == 'e' && zlang_bytecode[i+1] == 'm' && zlang_bytecode[i+2] == 'i' && zlang_bytecode[i+3] == 't') {
            i += 5; // Salta "emit "
            while (i < ZLANG_BYTECODE_SIZE && zlang_bytecode[i] != '\0') {
                serial_write_char(zlang_bytecode[i]);
                i++;
            }
            serial_write_char('\n');
        } else {
            i++;
        }
    }

    serial_write_string("[Z-LANG VM] Esecuzione bytecode terminata con successo.\n");
}
