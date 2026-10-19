# ZDOS Linux — Release e readiness operativa

ZDOS Linux è una distribuzione minimale a initramfs destinata a QEMU e a laboratori controllati. Il repository implementa controlli riproducibili per l’immagine e per la persistenza, ma **non dichiara ancora l’idoneità come sistema operativo general-purpose o come immagine da installare su hardware di produzione**.

## Garanzie incluse nella build

| Area | Controllo applicato |
|---|---|
| Input della build | `sources.lock` fissa URL HTTPS e SHA-256 di BusyBox, kernel e pacchetto moduli. |
| Kernel e moduli | La build rifiuta ABI diversi e prepara moduli coerenti con il kernel bloccato, incluse dipendenze per un baseline di storage SATA/NVMe, USB e Ethernet cablata. |
| Persistenza | Il test a due boot usa un volume ext4 virtuale, verifica scrittura, lettura e filesystem pulito. |
| Console | La ISO live avvia la console come `zdos`; la recovery root live richiede `zdos.insecure_root_shell=1`. L'installer imposta una password root per l'accesso amministrativo nel sistema installato. |
| Installazione | L'installer BIOS formatta il disco scelto solo dopo la conferma del suo percorso esatto e imposta una password root per il sistema installato. L'installer non è ancora testato end-to-end in QEMU o su hardware. |
| Pacchetti | Il gestore locale valida SHA-256, rifiuta link e path traversal, registra i file e testa rimozione/verifica. Il digest non autentica l'origine e non esiste un repository firmato. |
| Organismo residente | Il runtime conserva l’approccio default-deny e registra stato ed eventi, senza azioni nodo arbitrarie. |
| Release | Il workflow `.github/workflows/release-distro.yml` pubblica ISO Linux e SHA-256 nelle release `zdos-v*` dopo il boot QEMU. Il prototipo bare-metal resta fuori da questo workflow. |

## Gate obbligatorio

Per una build candidata al rilascio, eseguire da una checkout pulita con Zlang alla revisione dichiarata dai workflow:

```sh
./tools/zdos-selftest.sh --all
```

Il comando richiede gli strumenti indicati in `README.md` e scarica esclusivamente gli input bloccati da `distro/sources.lock`. Qualsiasi mismatch SHA-256, ABI kernel/moduli incompatibile o regressione delle prove deve arrestare la pipeline.

## Verifica dell’artefatto

Dopo la build, verificare l’ISO Linux prima di distribuirla:

```sh
cd distro/build
sha256sum -c zdos-linux-x86_64.iso.sha256
```

Una release GitHub `zdos-v*` contiene `SHA256SUMS` per la ISO Linux. Gli utilizzatori devono validare l'hash sul canale di distribuzione prima di avviare l’immagine. Il download dal sito è un collegamento a questi asset del repository ufficiale, non una copia ospitata dal sito.

## Recovery esplicito

L’eventuale shell root è pensata solo per recovery locale o debugging controllato. Per richiederla aggiungere al comando kernel:

```text
zdos.insecure_root_shell=1
```

Questa opzione riduce deliberatamente il livello di sicurezza: non deve essere usata su VM o host esposti, né rappresentata come un meccanismo di autenticazione.

## Limiti bloccanti per produzione general-purpose

| Capacità assente o sperimentale | Impatto |
|---|---|
| Installer UEFI, secure boot e recovery guidata | Il solo installer BIOS iniziale non è testato su hardware e non supporta UEFI né recovery guidata. |
| Aggiornamenti firmati, atomici e rollback | Non è disponibile una gestione sicura del ciclo di patch. |
| Gestione completa di utenti, credenziali e sessioni | La console non è un sostituto di PAM/SSHD/autenticazione amministrativa. |
| Firmware Wi-Fi, desktop grafico, rete/firewall completi e supporto hardware certificato | Il baseline di driver cablati e periferiche non certifica alcun PC; non è appropriata l’esposizione Internet o l’uso su laptop general-purpose. |
| SBOM, firme di release e attestazioni indipendenti | Gli hash migliorano l’integrità, ma non sostituiscono una catena di firma e provenienza completa. |

> La milestone appropriata resta quindi una **preview verificabile per QEMU**. La promozione a distribuzione installabile richiede almeno gli elementi della tabella precedente, oltre a una revisione di sicurezza indipendente.
