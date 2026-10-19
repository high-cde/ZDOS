# ZDOS su Ubuntu tramite container

Questo pacchetto avvia il kernel e l'initramfs Linux di ZDOS in QEMU, dentro
un container OCI. Ubuntu resta l'host: il container non sostituisce il kernel
host e non richiede accesso privilegiato, dispositivi host o `/dev/kvm`.
QEMU usa TCG (emulazione software), perciò l'avvio è più lento di una VM con
KVM. La console ZDOS è collegata al terminale.

## Installazione

Installare Podman (consigliato per l'esecuzione rootless) o Docker con i
pacchetti/repository ufficiali adatti alla propria versione di Ubuntu. Da
questa directory, creare l'immagine OCI e avviare la console:

```sh
./build-image.sh
./run.sh
```

Per usare Compose, creare prima l'immagine ZDOS e poi avviare il servizio:

```sh
./build-image.sh
podman compose up
# oppure: docker compose up
```

La CLI Rust di ZLang è disponibile come servizio Compose opzionale. Creare
l'immagine e invocarla su un file nella directory corrente:

```sh
podman compose --profile cli run --build --rm zlang esempio.zlang
```

La directory corrente viene montata in sola lettura. La CLI Rust e il
compilatore Python ZLB2 sono strumenti distinti; questa immagine contiene
solo la CLI Rust. Per il compilatore ZLB2 si può usare il Python già presente
sull'host o un container Python dedicato.

Per uscire, premere `Ctrl-A`, poi `X` nella console QEMU.

## Aggiornamento

Dopo aver ricostruito la ISO con `../../build.sh`, eseguire
`./build-image.sh` per incorporare kernel e initramfs aggiornati.
L'immagine contiene soltanto questi artefatti necessari al boot, non l'intera
ISO né l'installer su disco.

## Limiti

Questa è una sessione live senza persistenza: i dati guest vengono persi
quando il container termina. Non passare dischi host o abilitare il container
privilegiato per aggirare questo limite. Per installare ZDOS su un disco
virtuale, usare l'installer ISO e un hypervisor VM tradizionale; l'installer
BIOS attuale è sperimentale e cancella il disco selezionato.

`ZDOS_MEMORY` imposta la RAM QEMU, per esempio `ZDOS_MEMORY=1G ./run.sh`.
L'immagine `localhost/zdos:latest` è locale e non autenticata; distribuirla
solo attraverso un registry fidato con verifica delle credenziali e digest.
