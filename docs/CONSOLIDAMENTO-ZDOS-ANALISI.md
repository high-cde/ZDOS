# ZDOS · Analisi di consolidamento

**Data:** 2026-10-02  
**Perimetro:** `high-cde/ZDOS`, `high-cde/zdos-microcosm-beta`, clone locale di `zdos-organism` rappresentato da `zdos-hybrid`, superficie pubblica `https://app.x-zdos.it/`.

> Questa fase è **solo analisi**. Non sono stati cancellati repository, effettuati merge, eseguiti push o attivati servizi remoti.

## 1. Decisione architetturale

La fonte primaria da consolidare deve essere **`ZDOS`**. Il repository è già il contenitore più adatto:

* ha il branch `main` e la storia più recente (`9d29e58`, messaggio: contratti di servizio pubblico, nginx, security, systemd, auth);
* include già il catalogo Microcosm, il contratto `default-deny`, il controller `microcosm/zdos-microctl`, Evidence Chain, identità ZDOS, bridge Zlang, resident organism, distro Linux, target bare-metal e ZRetro;
* possiede già un workflow `connected-microcosm.yml` che verifica ZDOS insieme a Zlang e ai componenti esterni;
* contiene già una console web locale read-only, ma attualmente è soltanto una base minima (`/status` e `/ping`).

`zdos-hybrid` non deve diventare una seconda fonte primaria: contiene soprattutto una workstation Tkinter/web e il layer Rust/Python di `zdos-organism`, più artefatti di sviluppo, generatori duplicati e stato locale. Le modifiche visive Parrot possono essere portate in ZDOS in modo selettivo; il repository hybrid non va eliminato prima di aver creato un archivio/tag o prima di aver verificato che nulla di utile sia rimasto fuori.

`zdos-microcosm-beta` deve rimanere una **app client Expo/React Native separata**, collegata a ZDOS mediante contratti e API read-only. Non conviene copiare l'intera app dentro ZDOS: significherebbe mescolare toolchain Node/Expo, backend template, migrazioni Drizzle e runtime OS in un monorepo più difficile da verificare.

## 2. Stato verificato dei tre repository

| Repository | Branch/commit osservato | Dimensione checkout esclusi artefatti | Ruolo corretto |
|---|---|---:|---|
| `ZDOS` | `main` · `9d29e58` | ~3.5 MB di file sorgente | **fonte primaria / runtime e contratti** |
| `zdos-microcosm-beta` | `main` · `8b6cfd9` | ~8.4 MB di file sorgente | app Expo, ZComm local-first, client Node Pulse |
| `zdos-hybrid` | `feat/parrot-os-identity` · `b298e12` | ~0.7 MB filtrati, 746 MB checkout completo | workstation ibrida + clone evoluto di organism |

Non risultano duplicati esatti di file di dimensione significativa fra i tre checkout: la migrazione non può essere fatta con una semplice copia cieca o con una sola sovrascrittura.

## 3. Cosa esiste già dentro ZDOS

### Runtime e sistema

* `distro/`: Linux minimale, BusyBox, initramfs, storage persistente ext4 e test QEMU;
* `os/x86_64/`: target bare-metal e runtime ZLB2;
* `evidence/`: ledger JSONL append-only, attestazioni e policy release;
* `identity/`: identità Ed25519 locale, grant firmati, recovery e bridge `storage.read-v1`;
* `services/zdos-organismd.py`: supervisor bounded, validate-only, default-deny e fail-closed;
* `microcosm/catalog.json` e `microcosm/contract.json`: contratti di source-of-truth, invarianti, gate e sincronizzazione fast-forward-only;
* `interface/web/`: server Express read-only, pagina HTML minima e `/status`;
* `deploy/systemd/` e `deploy/nginx/`: superficie di deployment già prevista.

### Integrazione già dichiarata

`connected-microcosm.yml` esegue checkout pinned di Zlang, `zdos-organism`, `ZDOS-SEC-PORTAL` e `Z-CYBERCORE`, poi esegue test e gate. È già l'embrione della soluzione richiesta, ma non include ancora il repository `zdos-microcosm-beta` come client Expo da testare né un adapter verso l'app pubblica `app.x-zdos.it`.

Il catalogo dichiara `zdos-organism` come `EXPERIMENTAL`, coerentemente con l'analisi precedente: nel checkout corrente della sandbox il percorso adiacente `../Zlang` manca e il runtime Rust del clone hybrid non era compilabile. Questo deve restare **EXPERIMENTAL**, non essere promosso automaticamente a runtime attivo.

## 4. Risultati dei gate eseguiti

### ZDOS

| Gate | Risultato |
|---|---|
| `./microcosm/zdos-microctl gate` | **PASS** |
| `python3 -m unittest microcosm/test_microcosm.py identity/test_identity.py services/test_organismd.py` | **FAIL 2/9**: manca `../Zlang/tools/zlang_storage_read.py` e manca `../Zlang/tools/zlangc.py` |
| `./tools/zdos-selftest.sh --strict` | **FAIL**: integrazione Zlang, PHP telemetry e toolchain x86_64 mancanti; gli altri controlli eseguiti sono passati |
| shell/Python resident organism, security contract, Evidence Chain, ZRetro | **PASS** nel self-test strict |

Il fallimento non indica che il contratto Microcosm locale sia rotto: indica che il checkout di integrazione non è completo e che la modalità strict correttamente rifiuta dipendenze mancanti invece di dichiarare verde.

### Microcosm app

Dopo `pnpm install --frozen-lockfile --ignore-scripts`:

| Gate | Risultato |
|---|---|
| Vitest | **23 passati, 1 skipped** (`auth.logout` richiede ambiente auth) |
| `pnpm exec tsc --noEmit` | **PASS** |
| repository | nessun `android/` nativo; contiene export Android in `dist-android/` |

La app è realmente local-first: terminale bounded, ZComm con coda persistente, sync HTTPS solo se configurato, `remoteExecution: false`, `networkExposure: false`.

### `zdos-hybrid`

Il clone contiene il lavoro Parrot OS già preparato: `parrot_theme.py`, token, strumenti di verifica, GUI Tkinter, webapp, launcher e README/analisi. Tuttavia il workspace Rust non compilava nel branch analizzato: `cortex` usa una API rinominata e `core`/`organism-bin` hanno dipendenze/import mancanti (`zdos-zlang`, `zdos-core`, `zdos-zvm`, `tokio`). Non va importato dentro ZDOS come runtime funzionante senza prima selezionare e correggere i componenti.

## 5. App pubblica `app.x-zdos.it`

La pagina pubblica non è solo HTML statico: risponde con una SPA React e un backend tRPC sotto `/api/trpc`.

### Procedure pubbliche osservate

| Procedure | Stato osservato | Funzione |
|---|---|---|
| `GET /api/trpc/ecosystem.list` | **200** | catalogo pubblico delle superfici ZDOS |
| `GET /api/trpc/evidence.list` | **200** | release, contratti, prove e riferimenti |
| `GET /api/trpc/zcomm.catalog` | **200** | catalogo CEPT/ZComm read-only, nodo `core-01` |
| `GET /api/trpc/zlang.validate` | **200** con input valido | validazione server-side del profilo, esecuzione negata |
| `GET /api/trpc/node.status` | **200**, payload `null`, stato `OFFLINE` | tenta un heartbeat HTTPS ma il backend non raggiunge il nodo |
| `/api/v1/`, `/api/health` | fallback SPA HTML | **non** sono API JSON operative |
| `/api/oauth/callback` | **400** senza parametri | route auth presente, non una route ZDOS pubblica |

Il bundle pubblico usa tRPC e chiama esattamente `evidence.list`, `ecosystem.list`, `node.status`, `zcomm.catalog`, `zlang.validate`. La pagina dichiara `DEFAULT-DENY`, `READ-ONLY BY DEFAULT`, `BYTECODE EXECUTION DENIED` e `HTTPS-READ-ONLY`.

> **Conclusione di connessione:** una console ZDOS può collegarsi subito alle procedure read-only sopra elencate. Non esiste invece, allo stato verificato, un endpoint pubblico per eseguire comandi, appendere eventi o inviare messaggi ZComm. Questa è una protezione corretta: non va aggirata aggiungendo un POST generico.

## 6. Cosa importare da `zdos-hybrid`

### Importare in ZDOS

1. **Identità visiva Parrot**, non la gerarchia completa: token palette, tipografia e stile per `interface/web` e per eventuali dashboard;
2. **strumenti di coerenza** (`apply-parrot-theme.py` e `sync-autobuild-heredocs.py`) solo se adattati alla struttura ZDOS;
3. **launcher e messaggi utili** soltanto dopo averli ricondotti agli entrypoint ufficiali ZDOS;
4. documentazione di migrazione e il riepilogo dei rischi, ma senza trasferire promesse non verificate;
5. eventualmente singoli widget/visualizzazioni Tkinter se hanno un caso d'uso concreto e non duplicano la console web.

### Non importare

* `zdos-llm/` virtualenv committato, `target/`, `var/`, `time`, immagini ISO/boot e audit di macchina;
* gli script `autobuild-*` duplicati senza una fonte unica;
* i percorsi `/home/ruby/...` e i riferimenti alla vecchia root `zdos-organism`;
* il bridge HTTP su `0.0.0.0:8888` con CORS wildcard;
* nomi e branding `z_kali_*` se l'identità ufficiale diventa ZDOS / Parrot Edition;
* il runtime Rust di hybrid prima di correggere i gate di compilazione e prima di decidere se appartiene al percorso organism o al core ZDOS.

## 7. Console di connessione proposta

La console deve essere un **adapter read-only e capability-gated**, non una shell remota.

### Pannello locale ZDOS

Espone dalla console web locale:

* `GET /status`: stato del servizio, versione schema e policy;
* stato del ledger locale con hash e ultimo evento, senza contenuti sensibili;
* stato del resident organism tramite `status.json` ed eventi autenticati read-only;
* esito dei gate locali e hash del manifest.

### Pannello remoto app.x-zdos.it

Configura un endpoint `APP_X_ZDOS_URL` con allowlist rigida dell'origine `https://app.x-zdos.it`, timeout breve e schema validation. Mostra:

* ecosystem; release/evidence; catalogo ZComm; stato del nodo;
* validazione Zlang tramite `zlang.validate`, con limite di dimensione e profilo esplicito;
* stato di connessione, timestamp, latenza e risposta `OFFLINE` senza retry aggressivi.

La console non deve permettere di scegliere URL arbitrari dall'interfaccia e non deve passare input a shell, `subprocess`, QEMU o filesystem remoto. Le operazioni di mutazione, quando e se servissero, devono avere una capability distinta, autenticazione forte, audit e un endpoint specifico: non vanno inventate nella prima integrazione.

### Pannello Microcosm

Il client `zdos-microcosm-beta` può usare un adapter dedicato:

* configurazione `EXPO_PUBLIC_ZDOS_API_BASE=https://app.x-zdos.it`;
* lettura delle procedure tRPC pubbliche per catalogo, evidence, node e validazione;
* mantenimento locale della coda ZComm;
* nessun invio alla console finché non esiste un endpoint server-side documentato per `zcomm.sync.push`;
* fallback offline invariato quando `node.status` è `OFFLINE`.

Il codice attuale di `syncZCommState` accetta qualunque URL HTTPS passato dal chiamante. Prima di attivarlo contro un servizio reale va ristretto a un endpoint allowlisted e va definito il contratto di risposta/idempotenza; altrimenti l'app è tecnicamente HTTPS ma non ancora integrata in modo verificabile.

## 8. Piano di lavoro sicuro

### Fase A — preparazione, senza cancellazioni

* salvare un tag/branch di archivio di `zdos-hybrid` e conservare la PR Parrot già aperta;
* aggiungere `zdos-microcosm-beta` come checkout di test/fixture nel workflow ZDOS, non come copia dentro al runtime;
* aggiungere un manifest con commit pinned, URL, stato e scope di verifica;
* installare Zlang affiancato e portare i gate ZDOS da `PREPARED` a verificabili.

### Fase B — console read-only

* estendere `interface/web/server/api.js` con adapter server-side per le cinque procedure pubbliche;
* aggiungere allowlist URL, timeout, schema validation, caching breve e redazione dei payload;
* aggiungere test mockati per online, offline, timeout, JSON non valido e schema incompatibile;
* aggiungere la UI Parrot all'interfaccia web esistente, senza aprire porte pubbliche di default.

### Fase C — Microcosm

* aggiungere client typed e configurazione endpoint in `zdos-microcosm-beta`;
* integrare solo lettura e validazione inizialmente;
* progettare separatamente un eventuale `zcomm.sync.push`, con autenticazione, rate limit, idempotency key, ledger e revoca capability.

### Fase D — rimozione controllata di hybrid

* dopo la migrazione e i gate verdi, creare un tag archivio e una PR che rimuova dal workspace locale i file trasferiti/non più usati;
* non cancellare il repository GitHub `zdos-hybrid` automaticamente: prima deve esistere un periodo di reversibilità e una decisione esplicita;
* aggiornare `microcosm/catalog.json`, README, CI e riferimenti pubblici per indicare ZDOS come fonte primaria.

## 9. Decisioni che richiedono conferma prima dell'implementazione

1. **Consolidamento:** importare in `ZDOS` soltanto identità Parrot + console + adapter, oppure trasferire anche qualche componente GUI Tkinter di hybrid?
2. **API pubblica:** limitarsi alla connessione read-only già disponibile, oppure vuoi progettare anche `zcomm.sync.push` autenticato?
3. **Cancellazione:** dopo la migrazione vuoi solo rimuovere `hybrid` dal workspace/manifest oppure anche archiviare/eliminare il repository GitHub? La seconda opzione è distruttiva e non viene eseguita senza conferma esplicita.
4. **Attivazione:** per “attiviamo” intendo inizialmente avviare la console locale e verificare la connessione HTTPS; deployment pubblico su `app.x-zdos.it` o modifica di dati remoti richiede un passaggio separato.

## 10. Implementazione iniziale completata

Sul branch di consolidamento è stata implementata la prima versione della console senza rimuovere le superfici del Glass Engine originale:

* `interface/web/web/index.html` conserva xCLOUD, dashboard, Cloud File Manager, Zlang Studio, Evidence Chain, browser, webapp, audit e terminale;
* `interface/web/web/css/style.css` porta il layout al livello estetico della preview Glass Engine, con palette Parrot OS;
* `interface/web/web/js/app.js` aggiunge modali, health remoto, validator e terminale bounded;
* `interface/web/server/server.js` aggiunge adapter server-side allowlisted verso `app.x-zdos.it`, timeout, schema envelope e risposta `OFFLINE` fail-closed;
* `interface/web/README.md` documenta route, sicurezza e comandi ammessi;
* preview verificata: `docs/theme/preview/glass-engine-zdos-console.webp`.

Verifiche eseguite:

```text
npm run check                                      PASS
GET /status                                        PASS
GET /api/ping                                      PASS
GET /api/remote/zcomm                              ONLINE
GET /api/remote/validate?source=emit%20hello      ONLINE / execution DENIED
UI: 9 superfici originali conservate               PASS
security scan: no shell, no CORS wildcard          PASS
```

La verifica visuale mostra `REMOTE 4/4 ONLINE`, `EVIDENCE 5 RECORDS` e il nodo dichiarato `OFFLINE`, senza mascherare lo stato reale.

## 11. Raccomandazione

Procedere con una prima PR su `ZDOS` che:

* adotti la palette Parrot sulla console web;
* aggiunga un adapter read-only alle cinque procedure tRPC già esistenti;
* aggiunga test offline/timeout/schema;
* aggiunga `zdos-microcosm-beta` al perimetro di test pinned;
* mantenga `zdos-organism` `EXPERIMENTAL` finché i gate Rust/Zlang non sono verdi;
* non cancelli ancora `zdos-hybrid`.

È il percorso più coerente con l'architettura già presente e mantiene la proprietà fondamentale del progetto: **ogni capacità deve avere contratto, test, policy e prova osservabile**.
