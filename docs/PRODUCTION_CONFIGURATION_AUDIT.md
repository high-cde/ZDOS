# ZDOS — Audit dei file di configurazione mancanti per la production readiness

**Data:** 30 agosto 2026

**Repository analizzato:** `high-cde/ZDOS`

**Commit osservato:** `21ffcc7`

**Obiettivo:** distinguere ciò che è già configurato, ciò che manca realmente e ciò che deve essere aggiunto prima di presentare ZDOS come sistema production-ready.

## Sintesi esecutiva

ZDOS possiede già una buona base per una **preview Linux riproducibile in QEMU**: `distro/sources.lock`, i workflow CI, il contratto del rootfs, il servizio systemd dell’organismo, il manifest Node e le configurazioni JSON di ecosistema sono presenti. Il gate locale e quello CI verificano build, boot bare-metal, boot Linux, persistenza ext4, web e microcosmo.

Tuttavia, il repository non contiene ancora la configurazione necessaria per un sistema installabile, aggiornabile, autenticato, osservabile e recuperabile su hardware o su una VPS esposta. Il problema principale non è un singolo file mancante, ma l’assenza di interi **contratti operativi**: installazione, identità di host, segreti, aggiornamenti firmati, rollback, rete, logging persistente, backup e gestione hardware.

> **Conclusione:** per il perimetro attuale manca soprattutto la configurazione di produzione; la milestone corretta resta “M2 — Reproducible preview”. Non è sufficiente aggiungere file vuoti: ogni file deve essere collegato a un consumer, a un test positivo e a un test negativo.

## Configurazioni già presenti

| Area | File presenti | Valutazione |
|---|---|---|
| Build Linux | `distro/build.sh`, `distro/sources.lock` | Buona base: input binari e hash sono espliciti. Manca però la firma crittografica delle release. |
| Rootfs | `distro/rootfs/etc/passwd`, `group`, `inittab`, `profile`, `zdos/organism.conf`, `init` | Sufficiente per QEMU minimale. Non sufficiente per login, rete e gestione host reali. |
| Runtime residente | `services/zdos-organismd.service` | Hardening significativo, ma mancano installazione, directory dichiarative e gestione dei log. |
| CI | `.github/workflows/validate-x86_64.yml`, `connected-microcosm.yml`, `release-x86_64.yml` | Build e gate presenti. Mancano policy di ownership, dependency update automatizzato e security scanning dedicato. |
| Web | `interface/web/package.json`, `package-lock.json`, `server/server.js` | Servizio locale read-only verificato. Non esiste una configurazione per esposizione pubblica sicura. |
| Ecosistema | `microcosm/catalog.json`, `contract.json`, `identity/contract.json`, `evidence/policy.release.json` | Contratti applicativi presenti. Mancano policy operative per segreti, firma release e retention. |

## Priorità P0 — necessarie prima di una release di produzione

| File/configurazione proposta | Perché manca | Rischio se assente | Consumer da implementare |
|---|---|---|---|
| `distro/rootfs/etc/os-release` | Il sistema non dichiara in modo standard nome, versione, ID e build. | Tool di inventario, supporto e aggiornamento non possono identificare con certezza l’immagine. | `/init`, support bundle, script di update e diagnostica. |
| `distro/rootfs/etc/fstab` | `/init` invoca `mount -a`, ma il contratto dei mount non è versionato in un file dedicato. | Boot non deterministico e configurazione storage implicita. | `/init`, test di boot e test persistent-storage. |
| `distro/rootfs/etc/hostname` | Nessuna identità persistente di host è definita nel rootfs. | Log, rete e attestazioni non distinguono correttamente i nodi. | Init, DHCP, Evidence Chain e support bundle. |
| `distro/rootfs/etc/hosts` e `distro/rootfs/etc/resolv.conf` | Non esiste una baseline di risoluzione nomi. | Networking incompleto o comportamento dipendente dal contenuto casuale del rootfs. | Init/network setup e test di rete. |
| `distro/rootfs/etc/shadow` e `distro/rootfs/etc/gshadow` | `passwd` contiene account bloccati, ma non esiste un modello completo per credenziali e gruppi protetti. | Impossibilità di introdurre login amministrativo, rotazione e policy password in modo standard. | `login`, `su`, installer e gestione utenti. |
| `distro/rootfs/etc/securetty` e `distro/rootfs/etc/shells` | Console autorizzate e shell ammesse non sono dichiarate. | Superficie di login non controllata. | Login, recovery e test di policy. |
| `distro/rootfs/etc/sysctl.d/99-zdos-hardening.conf` | Non esiste baseline kernel runtime per ASLR, dmesg, symlink/hardlink e networking. | Hardening lasciato ai default del kernel o dell’ambiente. | Init, `sysctl`, security contract. |
| `distro/rootfs/etc/modprobe.d/zdos.conf` | I moduli sono selezionati, ma non esiste policy per opzioni, blacklist e caricamento automatico. | Driver o moduli inattesi possono aumentare la superficie d’attacco. | `modprobe`, init e test dei moduli. |
| `distro/rootfs/etc/mdev.conf` | BusyBox device management non ha una policy versionata per nodi e permessi. | Permessi `/dev` dipendenti dai default. | `mdev`, init e test device. |
| `distro/keys/release-signing.pub` | `sources.lock` verifica integrità ma non autenticità della provenienza. | Un lockfile modificato insieme alla sorgente non prova l’autorità della release. | Verificatore release, CI e installer. |
| `distro/release-policy.yaml` | La policy di release è distribuita nei workflow e nel testo, non in un contratto unico. | Tag, artefatti, chiavi, versioni e approvazioni possono divergere. | Workflow release, verifier e documentazione. |
| `.github/CODEOWNERS` | Non risultano owner obbligatori per kernel, rootfs, workflow e release. | Cambiamenti critici possono essere approvati senza revisione competente. | Branch protection e pull request. |
| `.github/dependabot.yml` | Non risulta una configurazione per aggiornare dipendenze Actions e npm. | Pin e dipendenze possono invecchiare senza segnalazione. | Dependabot e PR automatiche. |
| `.github/workflows/security.yml` | I workflow eseguono test applicativi, ma non esiste un gate dedicato per secret scan, CodeQL/SAST e dipendenze Python. | Vulnerabilità o segreti committati possono raggiungere il branch principale. | GitHub Advanced Security disponibile o scanner open source equivalente. |

## Priorità P1 — necessarie per un host o servizio operativo

| File/configurazione proposta | Scopo production | Lacuna attuale |
|---|---|---|
| `config/production.example.toml` | Catalogare directory, porte, log level, retention, modalità offline e feature flags senza hard-code. | Le variabili sono sparse tra shell, Python, Node e unità systemd; non esiste un contratto condiviso. |
| `.env.example` | Documentare nomi e formato dei segreti senza includerli. | `ZDOS_EVIDENCE_KEY`, `ZDOS_IDENTITY_PASSPHRASE`, `ZLANG_ROOT`, `LEDGER` e directory operative sono descritti nei documenti ma non in un esempio machine-readable. |
| `services/zdos-organismd.env.example` | Separare configurazione non segreta dal servizio systemd. | L’unità usa valori assoluti e non offre un modello per installazioni diverse. |
| `services/zdos-organismd.socket` o policy equivalente | Definire un’interfaccia locale autenticata/read-only se il supervisore deve essere interrogato. | Il servizio è avviabile ma non ha un endpoint operativo formalizzato. |
| `services/zdos-organismd.tmpfiles.conf` | Creare directory, ownership e permessi di stato in modo dichiarativo. | Il servizio assume che `/var/lib/zdos/organism` esista correttamente. |
| `services/zdos-organismd.sysusers.conf` | Creare l’utente e il gruppo `zdos` durante l’installazione. | `User=zdos` e `Group=zdos` sono presenti nell’unità, ma il provisioning dell’identità di sistema non è versionato. |
| `etc/systemd/journald.conf.d/zdos.conf` | Definire retention, compressione, limiti e forward dei log. | Non esiste configurazione di logging persistente o quota di log. |
| `etc/logrotate.d/zdos` | Ruotare ledger, log e diagnostica se non gestiti soltanto da journald. | Rischio di crescita illimitata dei file operativi. |
| `config/logging.yaml` | Uniformare formato, livelli, redazione dati e correlation ID. | Ogni componente decide autonomamente come scrivere output. |
| `config/backup-policy.yaml` | Dichiarare cosa salvare, cifratura, retention, RPO/RTO e verifica restore. | È presente un ledger, ma non una strategia di backup/restore di stato, identità e configurazioni. |
| `config/observability.yaml` | Stabilire metriche, health check, probe, alert e modalità offline. | Non esiste un contratto di operabilità oltre ai marker di test. |

## Priorità P1 — web e deployment pubblico

Il server Node è correttamente orientato a un uso locale read-only. Per renderlo un servizio pubblico non va semplicemente cambiato il bind a `0.0.0.0`: servono configurazioni aggiuntive e test dedicati.

| File/configurazione proposta | Scopo |
|---|---|
| `deploy/Caddyfile` oppure `deploy/nginx/zdos.conf` | TLS, redirect HTTPS, proxy verso `127.0.0.1`, timeout, body limit e access log. |
| `interface/web/.env.example` | Host, porta, modalità read-only, origin consentiti e ambiente. Deve contenere solo placeholder. |
| `interface/web/config/security.json` | CSP, CORS allowlist, trusted proxy, rate limits e dimensione massima payload. |
| `deploy/systemd/zdos-web.service` | Avvio del server web come utente dedicato con sandbox e restart policy. |
| `deploy/systemd/zdos-web.socket` | Socket activation o bind locale esplicito, se compatibile con Express. |
| `config/auth-policy.yaml` | Identità, sessioni, scadenza, MFA, ruoli e revoche. Attualmente il web non implementa autenticazione reale. |

Senza questi file, la configurazione pubblica raccomandata deve rimanere **GitHub Pages statica**; il server Express non deve essere esposto direttamente su Internet.

## Priorità P0/P1 — installazione, boot e aggiornamenti

| File/configurazione proposta | Necessità |
|---|---|
| `distro/boot/grub.cfg` versionato per BIOS | Il workflow costruisce GRUB, ma il contratto di boot non è separato in una configurazione installabile e revisionabile. |
| `distro/boot/grub-uefi.cfg` | Necessario per un percorso UEFI esplicito. |
| `distro/uefi/loader/loader.conf` e `distro/uefi/loader/entries/zdos.conf` | Necessari se si sceglie systemd-boot/UKI o una configurazione UEFI dichiarativa. |
| `distro/installer/install-policy.yaml` | Destinazione disco, partizionamento, cifratura, conferma distruttiva e rollback dell’installazione. Oggi non esiste installer. |
| `distro/installer/hardware-policy.yaml` | CPU, RAM, storage, console, NIC e device supportati. Oggi la compatibilità hardware non è certificata. |
| `distro/update/update-policy.yaml` | Canale, metadati, versioni minime, finestra di manutenzione e policy offline. |
| `distro/update/keys/repository.pub` | Verifica delle firme dei pacchetti o delle immagini aggiornate. Gli hash da soli non bastano per un repository remoto. |
| `distro/update/rollback-policy.yaml` | A/B slots, versione precedente, condizioni di abort, boot counter e recovery. |
| `distro/verity/roothash.pub` e configurazione dm-verity/UKI | Integrità del rootfs al boot e protezione contro manomissione locale. |
| `distro/recovery/recovery-policy.yaml` | Accesso recovery, support media, reset, export diagnostico e autorizzazioni. |

Questa categoria è **bloccante**: senza installer, update firmati e rollback ZDOS può essere verificato in QEMU, ma non può essere gestito come piattaforma operativa aggiornata nel tempo.

## Priorità P2 — qualità e governance del repository

| File/configurazione proposta | Valore |
|---|---|
| `pyproject.toml` alla radice | Packaging e metadati coerenti per i moduli Python, entrypoint e test. Oggi esistono `pyproject.toml` solo in sottoalberi specifici. |
| `requirements.lock` o lock per gruppo (`requirements-test.lock`, `requirements-runtime.lock`) | Riproducibilità delle dipendenze Python se il runtime esce dalla sola standard library. |
| `.python-version` | Uniformare la versione Python usata localmente e in CI. |
| `.editorconfig` | Eliminare differenze di newline, encoding, indentazione e fine file. |
| `.gitattributes` | Normalizzare script, file di testo e asset; utile per evitare artefatti di line ending. |
| `.pre-commit-config.yaml` | Shellcheck, shfmt, ruff/black, prettier e controlli sui segreti prima del push. |
| `.github/ISSUE_TEMPLATE/security_vulnerability.md` | Separare vulnerabilità da issue pubbliche ordinarie. |
| `.github/workflows/reproducibility.yml` | Build due volte in ambienti puliti e confronto hash/manifest. |
| `.github/workflows/sbom.yml` | Generare SBOM SPDX/CycloneDX per ISO, BusyBox, kernel, moduli e npm. |
| `SECURITY.md` con policy CVE e tempi di risposta | Il file esiste, ma deve essere collegato a una procedura di release, escalation e revoca. |

## Contratti da non confondere con file mancanti

Alcune lacune non si risolvono creando una configurazione:

1. **Secure Boot** richiede una catena di chiavi, firma UKI/bootloader, enrollment e procedura di revoca, non soltanto `grub.cfg`.
2. **Aggiornamenti sicuri** richiedono un formato di artefatto, metadati firmati, repository, policy di rollback e test di interruzione corrente.
3. **Autenticazione amministrativa** richiede un modello di identità, gestione chiavi, revoche, recovery e audit; `passwd` e `shadow` da soli non bastano.
4. **Supporto hardware** richiede una matrice reale di device, kernel config, moduli e test; un file `hardware-policy.yaml` può descriverla ma non crearla.
5. **Alta affidabilità** richiede backup verificati, health checks, alert, runbook e prove di ripristino; una configurazione di logging non sostituisce l’operatività.

## Ordine consigliato di implementazione

| Fase | Risultato minimo |
|---|---|
| **1 — Contratto host** | `os-release`, `fstab`, hostname, rete, sysctl, modprobe/mdev, sysusers/tmpfiles e test del rootfs. |
| **2 — Provenienza** | Chiave pubblica, policy release, manifest firmato, SBOM e verifica negativa di artefatti alterati. |
| **3 — Operabilità** | Configurazione comune, journald/logrotate, backup policy, health/metrics e runbook. |
| **4 — Installabilità** | BIOS/UEFI, installer non distruttivo con conferma, recovery e hardware policy. |
| **5 — Lifecycle** | Update repository firmato, A/B o snapshot, rollback e test di power loss. |
| **6 — Servizio pubblico** | Reverse proxy TLS, auth policy, rate limiting, audit e deploy systemd separato dal web locale. |
| **7 — Governance** | CODEOWNERS, Dependabot, security workflow, SBOM workflow e riproducibility workflow. |

## Verdict

Per la milestone attuale non è necessario aggiungere immediatamente ogni file della lista: molti appartengono a un installer o a una piattaforma host che ancora non esistono. I file più urgenti da implementare sono `os-release`, `fstab`, `hostname`, configurazioni di rete e hardening del rootfs, seguito da una policy di firma release e dai file `sysusers/tmpfiles` per il servizio residente.

La dichiarazione corretta oggi è quindi: **ZDOS Linux è una preview x86_64 riproducibile e verificata in QEMU, con servizio locale read-only e deployment documentale statico; non è ancora una distribuzione installabile e gestibile in produzione**.
