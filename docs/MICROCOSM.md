# ZDOS Connected Microcosm

Il **micro-mondo connesso** è un perimetro source-first e minimale composto da ZDOS, Zlang e `zdos-organism`. ZDOS rimane il nucleo che costruisce, avvia, testa e attesta; il catalogo dichiara le sole fonti primarie necessarie e rende visibile lo stato reale di ogni collegamento.

> La connessione non è una promessa generica: è una relazione dichiarata tra repository, comandi, prove osservabili e criteri di promozione.

## Architettura

```mermaid
flowchart LR
    ZD[ZDOS: build, QEMU, Evidence Chain]
    ZL[Zlang: compilatore e ZLB2]
    ORG[zdos-organism: runtime locale]
    PS[Prova ext4 a due boot]
    LE[Ledger locale verificabile]

    ZL -. checkout adiacente .-> ZD
    ORG -. checkout adiacente .-> ZD
    ZD --> PS --> LE
    ZL --> ZD
```

Il catalogo [`microcosm/catalog.json`](../microcosm/catalog.json) è l'unica mappa operativa della fusione. Il contratto [`microcosm/contract.json`](../microcosm/contract.json) vieta la promozione automatica dei mirror e richiede che lo stato sia proporzionato alla prova disponibile.

| Area | Sede | Stato nella fusione | Criterio |
|---|---|---:|---|
| Distro Linux, bare metal, QEMU ed Evidence Chain | Questo repository | **VERIFIED** | Build, boot e attestazione locale sono versionati in ZDOS. |
| Persistenza ext4 | Questo repository | **VERIFIED** | Due boot QEMU, clean shutdown, evento attestato e ledger valido. |
| Zlang e ZLB2 | Repository primario adiacente | **VERIFIED** | Checkout pulito e allineato; storage bridge e suite unittest della fonte primaria superati localmente. |
| zdos-organism | Repository primario adiacente | **EXPERIMENTAL** | Richiede le verifiche Rust dichiarate nel catalogo. |

## Prova principale: persistenza attestata

Il secondo contenuto fornito corrisponde al percorso già materializzato in ZDOS: la distro crea un'immagine ext4, avvia QEMU in modalità `write`, poi in modalità `read`, controlla il filesystem con `e2fsck` e registra un evento `filesystem.persistence.attestation`. L'evidenza non contiene il contenuto del volume, ma UUID, hash dell'immagine, hash del marker, commit, kernel e risultato.

```text
build ISO → crea volume ext4 → boot QEMU write → boot QEMU read
→ clean shutdown → attestazione JSONL → verifica hash-chain
```

Questa prova dichiara esattamente ciò che mostra: **persistenza locale della distro Linux in QEMU**. Non certifica un filesystem nativo bare-metal, hardware fisico, consenso distribuito o pubblicazione remota.

## Comandi del micro-mondo

```sh
# Verifica dichiarativa e fotografia read-only dei checkout
./microcosm/zdos-microctl inspect

# Report con hash di catalogo, contratto e commit osservati
./microcosm/zdos-microctl manifest

# Controllo di sincronizzazione senza modificare nulla
./microcosm/zdos-microctl sync --check

# Aggiornamento consentito solo con working tree puliti e fast-forward
./microcosm/zdos-microctl sync --apply

# Gate locale di contratto, policy e entrypoint
./microcosm/zdos-microctl gate

# Esecuzione della prova completa e attestazione nel ledger scelto
LEDGER=/var/lib/zdos-node/evidence.jsonl \
ZDOS_KERNEL=/boot/vmlinuz-$(uname -r) \
ZDOS_MODULES_DIR=/lib/modules/$(uname -r) \
./microcosm/zdos-microctl attest-persistence
```

`sync --check` non modifica i repository. `sync --apply` non esegue reset, force-push, sovrascrittura di modifiche locali o merge non fast-forward. Se un checkout esterno è assente o sporco, l'operazione termina con una diagnosi e senza inventare uno stato positivo.

## Disposizione del workspace

Il micro-mondo assume checkout adiacenti, non copie interne alla tree ZDOS. È una convenzione intenzionale: conserva identità, commit e policy del repository di origine.

```text
workspace/
├── ZDOS/                 # nucleo e orchestratore del micro-mondo
├── Zlang/                # opzionale: fonte primaria
└── zdos-organism/        # opzionale: fonte primaria
```

Il micro-mondo operativo è limitato a tre componenti. Questa scelta riduce la superficie di sincronizzazione, evita dipendenze fantasma e rende il gate riproducibile anche senza servizi web esterni.

| Regola di struttura | Applicazione |
|---|---|
| Una fonte autorevole | ZDOS coordina build, boot, Evidence Chain e promozione |
| Una toolchain dichiarata | Zlang viene fissato come checkout adiacente e verificato |
| Un runtime bounded | `zdos-organism` opera con `default-deny` e capability esplicite |
| Nessuna integrazione fantasma | Componenti rimossi non compaiono in catalogo, workflow o sync |

## Criterio di promozione

Una release del micro-mondo è dichiarabile **VERIFIED** soltanto se il catalogo e il contratto sono validi, il gate locale è verde e la prova di persistenza è stata eseguita nel contesto di build interessato. I componenti esterni devono inoltre superare i controlli della propria fonte primaria. L'assenza di prova comporta sempre uno stato inferiore, mai un'approvazione implicita.

## Riferimenti

[1] [ZDOS — repository primario](https://github.com/high-cde/ZDOS)

[2] [Zlang — compilatore e contratto ZLB2](https://github.com/high-cde/Zlang)

[3] [ZDOS Lab v1 — modello di forge coordinato](https://github.com/high-cde/ZDOS-lab-v1)
