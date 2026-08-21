# ZDOS x86_64 Architecture

## Scopo

Questo sottosistema crea una **immagine ISO x86_64 avviabile in QEMU**. L’immagine avvia un kernel bare-metal minimo, inizializza l’output seriale, valida un programma Zlang precompilato in formato ZLB2 v2.5 e rende l’output osservabile sulla console seriale.

> Non è ancora un sistema operativo generale: non implementa processi, protezione della memoria, filesystem, driver, rete, multitasking, ABI POSIX, loader ELF o applicazioni arbitrarie. È il nucleo verificabile necessario per costruirli senza confondere demo, runtime ospitato e sistema operativo indipendente.

## Architettura canonica

| Livello | Responsabilità | Stato nel prototipo |
|---|---|---|
| GRUB / ISO | Carica il kernel tramite Multiboot2 | Implementato dal processo di build |
| Boot x86_64 | Passa dalla modalità protetta alla long mode e prepara stack/paginazione | Implementato nel bootstrap assembly |
| Kernel ZDOS | Inizializza seriale COM1, stampa stato ed esegue il runtime | Implementato in C freestanding |
| Runtime Zlang | Valida e interpreta record ZLB2 con controlli bounds-checked | Implementato nel kernel |
| Programma Zlang | Usa `emit`, `let`, `if`, label e `wait` secondo il compilatore v2.5 | Esempio verificato |
| Toolchain host | Compila lo script `.zlang` in bytecode e header C | Implementata in Python standard library |

## Contratto del bytecode ZLB2 v2.5

Il formato binario è versionato e ogni record ha una lunghezza esplicita.

| Offset/record | Campo | Descrizione |
|---:|---|---|
| 0–3 | `ZLB2` | Magic a quattro byte |
| 4 | `0x02` | Major version |
| 5 | `0x05` | Minor version |
| record | `opcode` | Tipo di istruzione |
| record + 1–2 | `u16` little-endian | Lunghezza del payload |
| record + 3… | payload | Dati dell’istruzione |
| finale | `0xff` + lunghezza `0` | HALT obbligatorio |

| Opcode | Nome | Payload |
|---:|---|---|
| `0x01` | `EMIT` | Testo UTF-8 stampato sulla seriale |
| `0x02` | `LET` | Espressione assegnata alla virtual RAM; validata e saltata dal bootstrap runtime |
| `0x03` | `IF` | Condizione; validata e saltata dal bootstrap runtime |
| `0x04` | `LABEL` | Nome label; validato e saltato dal bootstrap runtime |
| `0x05` | `WAIT` | Segnale asincrono; validato e saltato dal bootstrap runtime |
| `0xff` | `HALT` | Payload vuoto e fine esatta del buffer |

Il runtime verifica magic, versione, lunghezza di ogni record, opcode riconosciuto, HALT e assenza di trailing bytes. Il bootstrap esegue `EMIT`; i record v2.5 non ancora eseguiti sono attraversati in sicurezza senza effetti. Un bytecode malformato viene rifiutato, non interpretato parzialmente.

## Criterio di successo end-to-end

La build è corretta solo se il comando canonico crea un ISO e QEMU restituisce, sul canale seriale:

```text
ZDOS x86_64 bootstrap
Zlang runtime ZLB2 v2.5 ready
ZDOS: native Zlang program executed
ZDOS: Zlang halted cleanly
```

Il controllo è implementato in [`tools/verify_qemu.sh`](tools/verify_qemu.sh) ed è eseguito anche dalla GitHub Actions.

## Percorso futuro controllato

L’estensione del formato deve procedere per compatibilità di versione: esecuzione reale di `LET`, controllo di flusso, funzioni, capability syscall a default-deny, programmi multipli e loader persistente. Qualunque syscall futura dovrà dichiarare soggetto, capability, scope, quota, timeout, limite di risposta, evento di audit, comportamento di fallimento e test negativo.
