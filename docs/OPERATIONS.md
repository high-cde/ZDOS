# 🛠️ ZDOS Operations Guide

## Prerequisiti

Per la distro Linux servono `bash`, `curl`, `make`, `gcc`, `cpio`, `gzip`, `xorriso`, `grub-mkrescue` e `qemu-system-x86_64`. Per il prototipo Zlang servono inoltre `python3`, `binutils` e il repository Zlang affiancato oppure la variabile `ZLANGC`.

## Build della distro Linux

```sh
./distro/build.sh
```

Il processo scarica un kernel Linux bootstrap e BusyBox, crea un root filesystem, copia `init`, account e gruppi, genera un initramfs e costruisce l’ISO GRUB in `distro/build/zdos-linux-x86_64.iso`.

Il kernel bootstrap è deliberatamente esplicito nello script. Per una release riproducibile, fornire un kernel costruito localmente:

```sh
ZDOS_KERNEL=/path/to/bzImage ./distro/build.sh
```

## Boot e test

```sh
./distro/test-qemu.sh
```

Il test cerca il marker `ZDOS_READY`. Per una sessione interattiva:

```sh
qemu-system-x86_64 \
  -cdrom distro/build/zdos-linux-x86_64.iso \
  -serial stdio -display none -no-reboot
```

Per provare il disco dati opzionale:

```sh
qemu-img create -f raw distro/build/zdos-data.img 128M
qemu-system-x86_64 \
  -cdrom distro/build/zdos-linux-x86_64.iso \
  -drive file=distro/build/zdos-data.img,format=raw,if=virtio \
  -serial stdio -display none
```

Il supporto `/dev/vda1` richiede una partizione e un filesystem validi; un file raw vuoto viene documentato come esempio di laboratorio, non come installer completo.

## Build bare-metal Zlang

```sh
git clone https://github.com/high-cde/Zlang.git ../Zlang
cd os/x86_64
make clean
make verify
sh tools/verify_qemu.sh
```

Con un compilatore in un percorso diverso:

```sh
ZLANGC=/path/to/zlangc.py sh tools/verify_qemu.sh
```

## CI

Il workflow [`validate-x86_64.yml`](../.github/workflows/validate-x86_64.yml) esegue checkout di ZDOS e Zlang, installa gli strumenti, verifica Multiboot2, crea la ISO e controlla l’output seriale in QEMU. Un fallimento va diagnosticato distinguendo tra dipendenze, compilazione, packaging GRUB e marker runtime.

## Troubleshooting

| Sintomo | Causa probabile | Azione |
|---|---|---|
| `zlangc.py not found` | Zlang non è affiancato o `ZLANGC` è errato | Clonare Zlang in `../Zlang` o impostare `ZLANGC` |
| `grub-mkrescue: command not found` | Mancano GRUB/xorriso | Installare `grub-pc-bin`, `grub-common` e `xorriso` |
| `ZDOS: output di boot incompleto` | Programma Zlang o runtime non emette il marker | Confrontare `boot.zlang`, `kernel.c` e il log QEMU |
| ISO non avviabile | Packaging GRUB o immagine incompleta | Eseguire `make clean`, ricostruire e verificare Multiboot2 |
| `Network: not configured` | QEMU non ha una NIC disponibile o DHCP non risponde | Controllare `eth0`, `udhcpc` e la rete del guest |
| `Persistence: live-only` | `/dev/vda1` assente o non montabile | Collegare un disco con partizione e filesystem validi |

## Checklist di release

Prima di pubblicare una release, eseguire `git diff --check`, la build Linux, il test QEMU, la verifica bare-metal, il workflow CI e un controllo manuale dei link Markdown. Non includere `distro/build/`, ISO, initramfs o file generati nel commit: gli artefatti devono essere prodotti dalla pipeline, non trattati come sorgenti.

## Policy di verità

La documentazione deve usare verbi proporzionati alla prova: “implementato” quando il codice esiste, “verificato” quando un test riproducibile passa, “sperimentale” quando il percorso è incompleto e “roadmap” quando non è ancora disponibile. Questa policy è parte dell’architettura ZDOS.
