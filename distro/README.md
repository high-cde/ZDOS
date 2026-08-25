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

Questa è una distro reale minimale, non ancora una distro general-purpose. Le milestone successive aggiungeranno rete, persistenza su disco, gestione pacchetti, installer, aggiornamenti firmati e immagini UEFI.

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

Per provare la persistenza in QEMU è possibile aggiungere un disco vuoto:

```sh
qemu-img create -f raw distro/build/zdos-data.img 128M
qemu-system-x86_64 -cdrom distro/build/zdos-linux-x86_64.iso \
  -drive file=distro/build/zdos-data.img,format=raw,if=virtio \
  -serial stdio -display none
```

La milestone 0.3 introdurrà un package manager iniziale basato su pacchetti tar firmati e un repository dichiarativo. La milestone 0.4 introdurrà installer BIOS/UEFI, logging persistente, aggiornamenti atomici e test hardware più estesi.

## Fondazione e maturità

La distro fa parte dell’ecosistema ZDOS e segue un criterio di capacità verificabile: codice, contratto, test e limite dichiarato. La governance tecnica, la separazione tra runtime, Evidence Chain e portale SEC, oltre al modello M0–M5, sono descritti in [`docs/FOUNDATION.md`](../docs/FOUNDATION.md) e [`docs/MATURITY.md`](../docs/MATURITY.md).

La milestone Linux corrente è classificata **M2 — Reproducible**: produce una ISO e raggiunge il boot QEMU in modo verificabile, ma non è ancora una distro general-purpose. Package manager, installer, aggiornamenti con rollback, rete completa e hardening restano milestone successive.

## Requisiti

Sono necessari `gcc`, `make`, `bc`, `bison`, `flex`, `openssl`, `elfutils`, `cpio`, `gzip`, `xorriso`, `grub-mkrescue` e `qemu-system-x86_64`.
