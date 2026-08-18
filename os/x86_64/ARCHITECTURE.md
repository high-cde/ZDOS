# ZDOS x86_64 — contratto del prototipo avviabile

## Scopo

Questo sottosistema crea una **immagine ISO x86_64 avviabile in QEMU**. L’immagine avvia un kernel bare-metal minimo, inizializza l’output seriale, interpreta un programma Zlang precompilato e rende l’output osservabile sulla console seriale.

> Non è ancora un sistema operativo generale: non implementa processi, protezione della memoria, filesystem, driver, rete, multitasking, ABI POSIX, loader ELF o applicazioni arbitrarie. È il nucleo verificabile necessario per costruirli senza confondere demo, runtime ospitato e sistema operativo indipendente.

## Architettura canonica

| Livello | Responsabilità | Stato nel prototipo |
|---|---|---|
| GRUB / ISO | Carica il kernel tramite Multiboot2 | Implementato dal processo di build |
| Boot x86_64 | Passa dalla modalità protetta alla long mode e prepara stack/paginazione | Implementato nel bootstrap assembly |
| Kernel ZDOS | Inizializza seriale COM1, stampa stato ed esegue il runtime | Implementato in C freestanding |
| Runtime Zlang | Valida e interpreta un formato bytecode piccolo e versionato | Implementato nel kernel |
| Programma Zlang | Dichiarazione `emit <testo>` compilata in bytecode | Un esempio verificato |
| Toolchain host | Compila lo script `.zlang` in un header C incorporato nel kernel | Implementata in Python standard library |

## Contratto del bytecode ZLB0 v1

Il formato binario è volutamente minimo e non ambiguo.

| Offset | Campo | Descrizione |
|---:|---|---|
| 0 | `ZLB0` | Magic a quattro byte |
| 4 | `1` | Versione del formato |
| 5 | `OP_EMIT` / `0x01` | Emette testo sulla console |
| 6–7 | `u16` little-endian | Lunghezza in byte UTF-8 del testo |
| 8… | payload | Testo da stampare |
| finale | `OP_HALT` / `0xff` | Fine deterministica del programma |

Il compilatore host accetta **esclusivamente** righe nella forma `emit <testo>`. Qualunque linea non vuota diversa è un errore di compilazione e produce un exit status non-zero. Il runtime rifiuta magic, versione, lunghezza e opcode non validi; non tenta di eseguire istruzioni sconosciute.

## Criterio di successo end-to-end

La build è corretta solo se il comando canonico crea un ISO e QEMU restituisce, sul canale seriale:

```text
ZDOS x86_64 bootstrap
Zlang runtime v1 ready
ZDOS: native Zlang program executed
ZDOS: Zlang halted cleanly
```

## Percorso futuro controllato

L’estensione del formato deve procedere per compatibilità di versione: valori e variabili, controllo di flusso, funzioni, capability syscall a default-deny, programmi multipli e un loader persistente. Qualunque syscall futura dovrà dichiarare soggetto, capability, scope, quota, timeout, limite di risposta, evento di audit, comportamento di fallimento e test negativo.
