# ZDOS

ZDOS è un sistema operativo sperimentale con una distribuzione Linux live x86_64 avviabile. L'immagine usa un kernel Linux versionato, BusyBox statico e initramfs; include console seriale e virtuale, account operatore non privilegiato, rete DHCP opzionale e volume dati ext4 montato solo dopo la verifica dell'UUID.

## Avvio in QEMU

Requisiti principali: `curl`, `gcc`, `make`, `cpio`, `xorriso`, `grub-mkrescue`, `qemu-system-x86_64`, `qemu-img` e gli strumenti ext4. La build scarica solo artefatti HTTPS fissati in `distro/sources.lock` e ne verifica gli hash.

```sh
./distro/build.sh
./distro/test-qemu.sh
```

Su Ubuntu è disponibile anche il pacchetto OCI rootless con Podman (o Docker):
vedere [`distro/container/README.md`](distro/container/README.md). Esegue il
guest ZDOS con QEMU/TCG e include un servizio opzionale per la CLI Rust ZLang.

Per entrare in QEMU con la console seriale:

```sh
qemu-system-x86_64 \
  -cdrom distro/build/zdos-linux-x86_64.iso \
  -serial stdio -display none
```

La persistenza live è opt-in. Il sistema monta `/dev/vda1` o `/dev/vda` solo quando la riga di comando specifica un UUID corrispondente con `zdos.data_uuid=<UUID>`. Il test end-to-end scrive un marker, riavvia il guest, lo rilegge e controlla il filesystem:

```sh
./distro/test-persistence-qemu.sh
```

## Installazione BIOS e pacchetti

La ISO include `zdos-install.sh`. L’installer BIOS richiede un host Linux con `sfdisk`, `mkfs.ext4`, `grub-install`, `cpio`, `chroot` e gli strumenti `util-linux`; non si avvia ancora dall’ambiente live. Cancella l’intero disco selezionato, rifiuta dischi montati o usati come swap, chiede di digitare il suo percorso esatto e richiede di impostare una password root. Supporta BIOS legacy su MBR, non UEFI/Secure Boot.

```sh
sudo ./distro/install.sh --iso distro/build/zdos-linux-x86_64.iso --device /dev/sdX
```

Nel sistema installato l’initramfs verifica l’UUID `zdos.root_uuid` e passa al root filesystem ext4 persistente. Dalla console `zdos` si può amministrare il sistema autenticandosi con `su -` e la password impostata nell’installer.

Il gestore locale `zdos-pkg` installa archivi `.tar.gz` costruiti da un albero di file, registra i file posseduti e supporta `list`, `verify` e `remove`. Nel sistema live serve la recovery root esplicita; nel sistema installato si usa la password amministrativa con `su`. Per esempio:

```sh
distro/pkg/build.sh --name hello --version 1.0 --root ./hello-tree --output hello-1.0.tar.gz
sha256sum hello-1.0.tar.gz
su -c '/usr/sbin/zdos-pkg install ./hello-1.0.tar.gz <sha256>' root
```

Il checksum rileva errori e confronta il pacchetto con un valore atteso; non autentica da solo il mittente. Repository firmati, aggiornamenti atomici/rollback e installazione UEFI restano da implementare.

## Kernel bare-metal

`os/x86_64/` contiene un prototipo separato: GRUB Multiboot2 avvia un kernel freestanding che esegue un programma Zlang incorporato tramite il runtime ZLB2. Per costruirlo servono il checkout adiacente `../Zlang` e la toolchain x86_64 documentata in [`os/x86_64/README.md`](os/x86_64/README.md).

```sh
cd os/x86_64
make verify
sh tools/verify_qemu.sh
```

## Stato e limiti

La distro live è la base testata oggi; è stato aggiunto un percorso installabile BIOS iniziale e un package manager locale, ma non sono ancora validati su hardware fisico. Restano assenti UEFI/Secure Boot, repository con firme, aggiornamenti atomici/rollback, ambiente grafico e una matrice hardware certificata. Non usare l'immagine come unico sistema di una macchina né per dati senza backup.

Il gate locale riproducibile è:

```sh
./tools/zdos-selftest.sh --all
```

Documentazione: [`distro/README.md`](distro/README.md), [`docs/OPERATIONS.md`](docs/OPERATIONS.md), [`docs/MATURITY.md`](docs/MATURITY.md) e [`ARCHITECTURE.md`](ARCHITECTURE.md).
