# ⛓️ ZDOS Evidence Chain

La **ZDOS Evidence Chain** è un ledger append-only non monetario per attestare eventi operativi: build, boot, policy, revoche e audit. Non contiene token, saldi o dati personali. Memorizza eventi JSON canonici, hash SHA-256 concatenati e, quando configurata, una firma HMAC del nodo emittente.

## Uso rapido

```sh
python3 evidence/ledger.py --ledger /tmp/zdos-ledger.jsonl init --network local-dev
python3 evidence/ledger.py --ledger /tmp/zdos-ledger.jsonl attest \
  --subject sha256:example-artifact \
  --result verified \
  --builder did:zdos:ci-local \
  --policy policy://release/production-v1 \
  --source-commit "$(git rev-parse HEAD)" \
  --toolchain zlang-zlb2-2.5
python3 evidence/ledger.py --ledger /tmp/zdos-ledger.jsonl verify
```

Per aggiungere una firma condivisa al nodo di sviluppo:

```sh
export ZDOS_EVIDENCE_KEY='use-a-secret-from-your-secret-manager'
```

In produzione la chiave non deve essere salvata nel repository o nella shell history. HMAC dimostra l’integrità rispetto a un segreto condiviso; non è ancora una PKI multi-organizzazione.

## Contratto di evento

Ogni evento contiene `schema`, `sequence`, `timestamp`, `previous_hash`, `event`, `hash` e `signature`. Il campo `event.type` identifica il contratto applicativo, per esempio `build.attestation`, `boot.attestation`, `policy.revocation` o `incident.timeline`.

Il ledger garantisce ordine e rilevazione della manomissione locale. Non garantisce da solo che l’asserzione originaria sia vera, né sostituisce consenso BFT, identità hardware-backed, storage delle prove o governance tra organizzazioni.

## Integrazione dell’ecosistema

**ZDOS** ospita il ledger e il verificatore. **Zlang** è il livello previsto per contratti deterministici che validano eventi e transizioni. **ZDOS-SEC** può emettere policy, gestire revoche e inviare soltanto attestazioni firmate al ledger; segreti, password e dati sensibili restano fuori catena.

La prima applicazione è la provenienza delle release: commit → compilazione → test → boot QEMU → attestazione → verifica prima dell’installazione.

## Magia evolutiva Zlang–ZDOS

L’orchestratore [`scripts/evolve-zlang-evidence.sh`](../scripts/evolve-zlang-evidence.sh) realizza la prima catena end-to-end verificabile dell’ecosistema:

```text
sorgente Zlang → bytecode ZLB2 → header C → kernel ZDOS → boot QEMU → Evidence Chain
```

Eseguirlo dalla radice del repository:

```sh
ZLANG_ROOT=../Zlang ./scripts/evolve-zlang-evidence.sh
```

Lo script ricompila il programma di boot, verifica il kernel Multiboot2, esegue il controllo seriale in QEMU e registra un evento `zlang.zdos.evolution` solo se tutte le prove precedenti hanno successo. L’evento include gli hash SHA-256 del sorgente, del bytecode, dell’header generato e del log di boot, oltre ai commit dei repository Zlang e ZDOS.

Il ledger resta append-only: se il file esiste viene verificato prima dell’aggiunta; se è corrotto, l’operazione viene rifiutata. Il comando non apre porte di rete, non salva segreti e non dichiara consenso distribuito o esecuzione remota.
