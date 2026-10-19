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

Questa è una distro Linux avviabile e minimale. Sono ora presenti un package manager locale iniziale e un installer BIOS su host Linux; repository autenticati, UEFI e aggiornamenti firmati restano capacità successive.

## Build

Dalla radice del repository:

```sh
./distro/build.sh
```

Il processo verifica contro `sources.lock` il kernel Debian, il pacchetto dei moduli ABI-coerenti e BusyBox; compila BusyBox in modo statico, genera l'initramfs e crea `build/zdos-linux-x86_64.iso` con il relativo checksum SHA-256. Il kernel è un input binario bloccato: non viene compilato localmente. Quando i moduli vengono preparati dal pacchetto bloccato, `depmod` raccoglie anche le dipendenze dei driver selezionati.

Per il gate completo di build, gestore pacchetti, root persistente, storage live e boot:

```sh
./tools/zdos-selftest.sh --all
```

Il gate verifica il boot in console non privilegiata, il pivot QEMU a un root ext4 persistente, due boot live con persistenza ext4 e la pulizia del filesystem. Non esegue il partizionamento distruttivo o `grub-install` dell'installer. Il test isolato di console resta disponibile con `./distro/test-qemu.sh`.

## Milestone 0.2

La milestone 0.2 aggiunge una base userspace più reale. Sono presenti gli account `root` e `zdos`, i gruppi di sistema, il tentativo automatico DHCP sulle interfacce Ethernet rilevate tramite BusyBox `udhcpc` e il mount opzionale di `/dev/vda1` su `/mnt/data`. La preparazione dei moduli include, se disponibili nel kernel bloccato, driver comuni per SATA/AHCI, NVMe, controller USB, tastiere e archiviazione USB, oltre a schede Ethernet Intel, Realtek e virtio. L’account root è bloccato e la console live viene avviata come `zdos`; una shell root è consentita solo tramite l’opzione esplicita di recovery `zdos.insecure_root_shell=1`. L'immagine live continua ad avviarsi anche quando non è disponibile una scheda di rete o un disco persistente.

Questa selezione è un primo baseline, non una matrice di compatibilità: non comprende firmware Wi-Fi, un supplicant, un desktop grafico né la certificazione dei singoli PC. Il profilo hardware reale va ancora verificato su macchine fisiche; i test automatici coprono QEMU.

## Persistent storage v1

La prima capacità persistente verificabile usa un volume ext4 dedicato, identificato da UUID e montato su `/mnt/data`. Su un disco partizionato viene usata `/dev/vda1`; nelle immagini QEMU del test può essere usato direttamente `/dev/vda` quando non esiste una tabella partizioni. Il boot resta in modalità live-only se il volume è assente, se `blkid` non è disponibile o se l’UUID non corrisponde. Il sistema non formatta automaticamente il volume e non sovrascrive dati esistenti.

Il test riproducibile crea un disco QEMU, lo formatta con un UUID noto, esegue un primo boot che scrive un marker, quindi esegue un secondo boot che verifica la rilettura del marker:

```sh
./distro/test-persistence-qemu.sh
```

Il risultato atteso è:

```text
ZDOS_PERSISTENCE_QEMU_TEST_PASSED uuid=11111111-2222-4333-8444-555555555555
```

Il contratto di boot utilizza `zdos.data_uuid=<UUID>` e, per il test, `zdos.persistence_test=write|read`. La capacità è limitata alla distro Linux in QEMU: non è ancora un filesystem nativo del kernel bare-metal e non espone accesso storage a Zlang.

## Installer BIOS e root persistente

`distro/install.sh` installa la rootfs contenuta nell'initramfs della ISO su una partizione ext4 MBR, installa GRUB per BIOS e configura l'UUID root nel menu di avvio. Il boot verifica il filesystem marcato dall'installer e usa `switch_root` per passare dall'initramfs al sistema installato. L'installer richiede un host Linux con gli strumenti elencati nello script; non è ancora invocabile dalla console live. Prima di scrivere chiede la password amministrativa e la conferma digitando il percorso esatto del disco; `--yes` salta soltanto la conferma del dispositivo. L'intero disco scelto viene cancellato.

La versione corrente installa solo BIOS legacy su MBR e dischi fino a 2 TiB. Non offre ancora UEFI, Secure Boot, resize o recovery automatica. `distro/test-installer-qemu.sh` esercita partizionamento, formattazione, GRUB e boot su un’immagine temporanea tramite loop device; richiede root. Nessun test formatta un disco fisico.

## Package manager locale

`distro/pkg/build.sh` crea archivi tar.gz riproducibili da un albero di file. `zdos-pkg install ARCHIVE SHA256` controlla un digest atteso, rifiuta link e percorsi non ammessi, registra i file installati e non sovrascrive file già presenti. `list`, `verify` e `remove` operano sul database locale. Nella ISO live i pacchetti persistono sotto `/mnt/data`; nel sistema installato sono collocati nel root filesystem.

Il digest deve arrivare da un canale fidato: non è una firma digitale. Il sistema non ha ancora repository, chiavi di firma, risoluzione dipendenze, aggiornamenti o rollback. Il test `distro/test-package-manager.sh` copre build/install/list/verify/remove e digest errati su un root temporaneo.

## Fondazione e maturità

La distro fa parte dell’ecosistema ZDOS e segue un criterio di capacità verificabile: codice, contratto, test e limite dichiarato. La governance tecnica, la separazione tra runtime ed Evidence Chain, oltre al modello M0–M5, sono descritti in [`docs/FOUNDATION.md`](../docs/FOUNDATION.md) e [`docs/MATURITY.md`](../docs/MATURITY.md).

La milestone Linux corrente resta **M2 — Reproducible**: la ISO e i test live QEMU sono riproducibili. Installer e gestore pacchetti hanno implementazioni iniziali ma non hanno ancora un gate QEMU end-to-end o prove su hardware. UEFI, autenticazione repository, rollback, rete completa e hardening restano necessari prima di una distribuzione general-purpose.

## Requisiti

Sono necessari `bzip2`, `curl`, `gcc`, `make`, `cpio`, `gzip`, `file`, `sha256sum`, `xorriso`, `mtools`, `grub-mkrescue`, `qemu-img`, `mkfs.ext4`, `e2fsck`, `debugfs` e `qemu-system-x86_64`. `kmod` è necessario quando la build deve preparare il set di moduli dal pacchetto kernel. Per limiti e procedura di verifica dell'artefatto, consultare [`PRODUCTION.md`](PRODUCTION.md).
