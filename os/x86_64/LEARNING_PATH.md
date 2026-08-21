# 🎓 Laboratorio ZDOS x86_64 + Zlang

Questa guida spiega **perché** il prototipo funziona, non soltanto come eseguirlo. L’obiettivo è trasformare la pipeline in un modello mentale: ogni file ha un ruolo, ogni confine riduce l’ambiguità e ogni test dimostra una proprietà osservabile.

## 1. Il problema: come fa un linguaggio ad arrivare alla macchina?

Un file `.zlang` è testo. Una CPU x86_64 non esegue testo e un kernel non dovrebbe interpretare input indefinito. Per questo il progetto separa il problema in passaggi piccoli e verificabili:

```text
intenzione → sintassi → bytecode → runtime → kernel → macchina
```

| Domanda | Componente | Risposta pratica |
|---|---|---|
| Cosa vuole comunicare il programma? | `programs/boot.zlang` | Usa `emit <testo>` |
| Come diventa un formato eseguibile? | `Zlang/tools/zlangc.py` | Produce ZLB2 v2.5 |
| Come si rende disponibile al kernel? | Header C generato | Il bytecode è incluso nell’immagine |
| Chi ha accesso all’hardware? | `kernel/kernel.c` | Solo il kernel controlla COM1 |
| Come verifichiamo il risultato? | `tools/verify_qemu.sh` | QEMU e output seriale obbligatorio |

## 2. Il programma: dichiarare un effetto semplice

Apri `programs/boot.zlang`:

```zlang
# Il commento non genera bytecode.
emit ZDOS: native Zlang program executed
```

L’istruzione non apre file, non invoca shell e non accede a rete. Chiede soltanto al runtime di emettere testo. Questa restrizione è educativa e architetturale: prima di offrire potere al programma, il sistema deve saperlo limitare, verificare e auditare.

## 3. Il compilatore: trasformare testo in contratto

Il compilatore Zlang produce il formato **ZLB2 v2.5**. Il buffer include magic, versione, record con opcode e lunghezza, payload e infine `HALT`.

```text
5a 4c 42 32 | 02 05 | opcode | lunghezza u16 | payload | ff 00 00
 Z  L  B  2 | v2.5  | record |               dati    | HALT
```

Il profilo corrente comprende `EMIT`, `LET`, `IF`, label e `WAIT`. Il bootstrap runtime esegue `EMIT` e valida/attraversa in sicurezza i record non ancora eseguiti.

La presenza di versione e lunghezza non è decorativa. La versione permette al runtime di rifiutare formati che non comprende; la lunghezza impedisce al runtime di leggere oltre i confini del programma.

## 4. Il runtime: validare prima di eseguire

`kernel/zlang.c` non presume che il bytecode sia corretto. Verifica, nell’ordine:

1. magic corretto;
2. versione supportata;
3. opcode noto;
4. lunghezza disponibile nel buffer;
5. presenza di `HALT` e assenza di byte dopo `HALT`.

> 🛡️ Questo è un modello **default-deny**: ciò che non è esplicitamente definito dal contratto viene rifiutato. È la base per capability sicure in una futura API di sistema.

## 5. Il kernel: mantenere il confine con l’hardware

`kernel/kernel.c` inizializza la porta seriale COM1 e passa al runtime solo una funzione di scrittura controllata. Il programma Zlang non riceve porte I/O, puntatori grezzi, comandi shell o credenziali; vede soltanto la capability che il kernel gli consegna.

Questo confine consente al sistema di crescere senza abbandonare il controllo: una futura syscall `time.now`, per esempio, potrà essere aggiunta come capability distinta e non come accesso universale al kernel.

## 6. Il boot: passare dalla firmware alla long mode

`boot/boot.S` espone un header Multiboot2 per GRUB. GRUB carica il kernel, il bootstrap prepara tabelle di pagina minime, abilita la long mode x86_64, costruisce uno stack e chiama `kernel_main`.

```text
BIOS/GRUB → Multiboot2 → bootstrap assembly → long mode → kernel_main
```

La verifica `grub-file --is-x86-multiboot2 build/zdos.elf` non avvia la macchina: dimostra solo che GRUB riconoscerà il kernel. La prova QEMU è necessaria perché dimostra l’intero passaggio fino alla console seriale.

## 7. L’esercizio fondamentale: cambiare un effetto, non il contratto

Modifica il messaggio in `programs/boot.zlang`:

```zlang
emit ZDOS: esercizio completato
```

Poi ricompila e verifica:

```sh
make clean
make all
sh tools/verify_qemu.sh
```

Il primo test di comprensione è osservare che cambia l’output della console, ma non cambiano l’architettura, gli opcode o le regole di validazione.

## 8. L’esercizio di sicurezza: provocare un rifiuto

Sostituisci temporaneamente il programma con:

```zlang
let risposta = 42
```

Esegui il compilatore:

```sh
python3 ../../../Zlang/tools/zlangc.py programs/boot.zlang --header /tmp/boot.h
```

Il comando deve fallire. Non è un bug: dimostra che il compilatore non presenta una funzione futura come se fosse disponibile oggi. Ripristina quindi l’istruzione `emit` prima di eseguire la verifica QEMU.

## 9. La traiettoria tecnica corretta

| Evoluzione | Nuovo potere | Nuova responsabilità |
|---|---|---|
| File ZLB2 esterni | Programmi non incorporati | Validazione, checksum, policy di caricamento |
| Valori e aritmetica | Calcolo locale | Limiti, overflow, gestione errore |
| Syscall capability | Osservare tempo, input o log | Scope, allowlist, audit, quota, timeout |
| Programmi multipli | Più attività | Scheduler, isolamento, risorse |
| Distribuzione | Avvio fuori da QEMU | Hardware target, installazione, recupero |

Ogni riga della tabella richiede contratto, test negativo, regressione end-to-end e documentazione prima di diventare una promessa pubblica.

## 10. Conclusione

Il prototipo non pretende di essere un OS completo. È più utile: dimostra una catena nativa reale, piccola e leggibile. Quando una base è verificabile, la complessità successiva può essere aggiunta senza perdere il controllo del sistema.

**Da un messaggio Zlang a un boot QEMU, ogni passaggio è ora visibile.** 🚀

## Riferimenti

[1] [Guida operativa ZDOS x86_64](README.md)
[2] [Architettura e contratto ZLB2 v2.5](ARCHITECTURE.md)
[3] [Profilo del compilatore Zlang](https://github.com/high-cde/Zlang/blob/main/docs/zdos-x86_64-profile.md)
[4] [Repository ZDOS](https://github.com/high-cde/ZDOS)
[5] [Repository Zlang](https://github.com/high-cde/Zlang)
