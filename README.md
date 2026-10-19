# ZDOS

ZDOS è un sistema operativo sperimentale con una distribuzione Linux live x86_64 avviabile. L'immagine usa un kernel Linux versionato, BusyBox statico e initramfs; include console seriale e virtuale, account operatore non privilegiato, rete DHCP opzionale e volume dati ext4 montato solo dopo la verifica dell'UUID.

## Avvio in QEMU

Requisiti principali: `curl`, `gcc`, `make`, `cpio`, `xorriso`, `grub-mkrescue`, `qemu-system-x86_64`, `qemu-img` e gli strumenti ext4. La build scarica solo artefatti HTTPS fissati in `distro/sources.lock` e ne verifica gli hash.

```sh
./distro/build.sh
./distro/test-qemu.sh
```

Per entrare in QEMU con la console seriale:

```sh
qemu-system-x86_64 \
  -cdrom distro/build/zdos-linux-x86_64.iso \
  -serial stdio -display none
```

La persistenza è opt-in. Il sistema non formatta dischi e monta `/dev/vda1` o `/dev/vda` solo quando la riga di comando specifica un UUID corrispondente con `zdos.data_uuid=<UUID>`. Il test end-to-end scrive un marker, riavvia il guest, lo rilegge e controlla il filesystem:

```sh
./distro/test-persistence-qemu.sh
```

## Kernel bare-metal

`os/x86_64/` contiene un prototipo separato: GRUB Multiboot2 avvia un kernel freestanding che esegue un programma Zlang incorporato tramite il runtime ZLB2. Per costruirlo servono il checkout adiacente `../Zlang` e la toolchain x86_64 documentata in [`os/x86_64/README.md`](os/x86_64/README.md).

```sh
cd os/x86_64
make verify
sh tools/verify_qemu.sh
```

## Stato e limiti

La distro Linux live è la base utilizzabile oggi; il kernel bare-metal è un prototipo. ZDOS non è ancora una distribuzione general-purpose: mancano installer, package manager, aggiornamenti firmati con rollback, supporto UEFI verificato, ambiente grafico e una matrice hardware certificata. La persistenza verificata è limitata a un volume dati ext4 dedicato. Non usare l'immagine come unico sistema di una macchina né per dati senza backup.

Il gate locale riproducibile è:

```sh
./tools/zdos-selftest.sh --all
```

Documentazione: [`distro/README.md`](distro/README.md), [`docs/OPERATIONS.md`](docs/OPERATIONS.md), [`docs/MATURITY.md`](docs/MATURITY.md) e [`ARCHITECTURE.md`](ARCHITECTURE.md).
