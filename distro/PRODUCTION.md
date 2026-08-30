# ZDOS Linux — Release e readiness operativa

ZDOS Linux è una distribuzione minimale a initramfs destinata a QEMU e a laboratori controllati. Il repository implementa controlli riproducibili per l’immagine e per la persistenza, ma **non dichiara ancora l’idoneità come sistema operativo general-purpose o come immagine da installare su hardware di produzione**.

## Garanzie incluse nella build

| Area | Controllo applicato |
|---|---|
| Input della build | `sources.lock` fissa URL HTTPS e SHA-256 di BusyBox, kernel e pacchetto moduli. |
| Kernel e moduli | La build rifiuta ABI diversi e prepara automaticamente il set minimo di moduli coerenti con il kernel bloccato. |
| Persistenza | Il test a due boot usa un volume ext4 virtuale, verifica scrittura, lettura e filesystem pulito. |
| Console | La console predefinita viene avviata come utente `zdos` non privilegiato. Una shell root richiede l’opzione di boot esplicita `zdos.insecure_root_shell=1`. |
| Organismo residente | Il runtime conserva l’approccio default-deny e registra stato ed eventi, senza azioni nodo arbitrarie. |
| Release | La release GitHub genera checksum e manifesto per le ISO Linux e bare-metal dopo i rispettivi test QEMU. |

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

Una release GitHub contiene inoltre `SHA256SUMS`, che copre le ISO Linux e bare-metal. Gli utilizzatori devono validare gli hash sul canale di distribuzione prima di avviare l’immagine.

## Recovery esplicito

L’eventuale shell root è pensata solo per recovery locale o debugging controllato. Per richiederla aggiungere al comando kernel:

```text
zdos.insecure_root_shell=1
```

Questa opzione riduce deliberatamente il livello di sicurezza: non deve essere usata su VM o host esposti, né rappresentata come un meccanismo di autenticazione.

## Limiti bloccanti per produzione general-purpose

| Capacità assente o sperimentale | Impatto |
|---|---|
| Installer BIOS/UEFI, secure boot e recovery guidata | Non esiste un percorso d’installazione certificato su disco fisico. |
| Aggiornamenti firmati, atomici e rollback | Non è disponibile una gestione sicura del ciclo di patch. |
| Gestione completa di utenti, credenziali e sessioni | La console non è un sostituto di PAM/SSHD/autenticazione amministrativa. |
| Rete, firewall, Wi-Fi e supporto hardware certificato | Non è appropriata l’esposizione Internet o l’uso su laptop general-purpose. |
| SBOM, firme di release e attestazioni indipendenti | Gli hash migliorano l’integrità, ma non sostituiscono una catena di firma e provenienza completa. |

> La milestone appropriata resta quindi una **preview verificabile per QEMU**. La promozione a distribuzione installabile richiede almeno gli elementi della tabella precedente, oltre a una revisione di sicurezza indipendente.
