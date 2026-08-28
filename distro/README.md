# ZDOS Linux

## Obiettivo

`distro/` è la prima base concreta della distribuzione ZDOS. La milestone iniziale usa il kernel Linux e BusyBox per produrre una ISO x86_64 avviabile in QEMU con initramfs, shell e console seriale. Il kernel bare-metal sperimentale in `os/x86_64` resta conservato come laboratorio separato e non viene usato come base della distro.

## Milestone 0.1

La prima immagine deve fornire:

| Componente | Implementazione |
|---|---|
| Kernel | Linux x86_64, configurazione minimale derivata da `defconfig` |
| Userspace | BusyBox statico |
| Init | `/init` POSIX shell con mount di `/proc`, `/sys`, `/dev` e `/run` |
| Console | `ttyS0` per QEMU e `tty1` per console virtuale |
| Boot | GRUB BIOS con kernel e initramfs |
| Test | Boot automatico in QEMU e controllo del marker `ZDOS_READY` |

Questa è una distro reale minimale, non ancora una distro general-purpose. Le milestone successive aggiungeranno gestione pacchetti, installer, aggiornamenti firmati e immagini UEFI.

## Build

Dalla radice del repository:

```sh
./distro/build.sh
```

Il processo scarica sorgenti versionate di Linux e BusyBox, compila il kernel e BusyBox in modo statico, genera l'initramfs e crea `build/zdos-linux-x86_64.iso`.

Per il test automatico:

```sh
./distro/test-qemu.sh
```

Il test termina quando rileva `ZDOS_READY` sulla console seriale oppure restituisce errore se il guest non esegue il percorso di init.

## Milestone 0.2

La milestone 0.2 aggiunge una base userspace più reale. Sono presenti gli account `root` e `zdos`, i gruppi di sistema, il tentativo automatico DHCP su `eth0` tramite BusyBox `udhcpc` e il mount opzionale di `/dev/vda1` su `/mnt/data`. L'immagine live continua ad avviarsi anche quando non è disponibile una scheda di rete o un disco persistente.

## Persistent storage v1

La prima capacità persistente verificabile usa un volume ext4 dedicato, identificato da UUID e montato su `/mnt/data`. Il boot resta in modalità live-only se il volume è assente, se `blkid` non è disponibile o se l’UUID non corrisponde. Il sistema non formatta automaticamente il volume e non sovrascrive dati esistenti.

Il test riproducibile crea un disco QEMU, lo formatta con un UUID noto, esegue un primo boot che scrive un marker, quindi esegue un secondo boot che verifica la rilettura del marker:

```sh
./distro/test-persistence-qemu.sh
```

Il risultato atteso è:

```text
ZDOS_PERSISTENCE_QEMU_TEST_PASSED uuid=11111111-2222-4333-8444-555555555555
```

Il contratto di boot utilizza `zdos.data_uuid=<UUID>` e, per il test, `zdos.persistence_test=write|read`. La capacità è limitata alla distro Linux in QEMU: non è ancora un filesystem nativo del kernel bare-metal e non espone accesso storage a Zlang.

La milestone 0.3 introdurrà un package manager iniziale basato su pacchetti tar firmati e un repository dichiarativo. La milestone 0.4 introdurrà installer BIOS/UEFI, logging persistente, aggiornamenti atomici e test hardware più estesi.

## Fondazione e maturità

La distro fa parte dell’ecosistema ZDOS e segue un criterio di capacità verificabile: codice, contratto, test e limite dichiarato. La governance tecnica, la separazione tra runtime, Evidence Chain e portale SEC, oltre al modello M0–M5, sono descritti in [`docs/FOUNDATION.md`](../docs/FOUNDATION.md) e [`docs/MATURITY.md`](../docs/MATURITY.md).

La milestone Linux corrente è classificata **M2 — Reproducible**: produce una ISO e raggiunge il boot QEMU in modo verificabile, ma non è ancora una distro general-purpose. Package manager, installer, aggiornamenti con rollback, rete completa e hardening restano milestone successive.

## Requisiti

Sono necessari `gcc`, `make`, `bc`, `bison`, `flex`, `openssl`, `elfutils`, `cpio`, `gzip`, `xorriso`, `mtools`, `grub-mkrescue`, `qemu-img`, `mkfs.ext4` e `qemu-system-x86_64`.
