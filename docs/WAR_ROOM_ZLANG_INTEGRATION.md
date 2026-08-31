# War Room · Integrazione ZLang by ZDOS

## Scopo

La War Room è il control plane autenticato dell’ecosistema ZDOS. Registra programmi, asset, scope, approvazioni, evidenze e audit; non è un interprete shell e non deve diventare un servizio di esecuzione privilegiata.

L’execution plane è **ZLang by ZDOS**. Ogni programma operativo è versionato, hashato e associato a capability, limiti e schema di output. Il gateway applica una policy default-deny prima di avviare il runner.

## Circuito verificabile

```text
War Room
  -> job pending_approval
  -> approvazione owner
  -> manifest ZLang + source_sha256
  -> validazione scope/capability/limiti
  -> runner non privilegiato
  -> output evidence.v1
  -> Evidence Chain + audit
```

Un job è eseguibile soltanto se il programma è registrato, il target è nello scope attivo, l’approvazione è valida e la capability richiesta appartiene all’allowlist del profilo. Ogni errore produce un rifiuto fail-closed.

## Profili iniziali

| Profilo | Capability | Limiti iniziali | Effetto |
|---|---|---|---|
| `passive_inventory` | `storage.read-v1` | nessuna rete | legge asset già registrati |
| `security_headers` | `net.read` | una richiesta, timeout breve | osserva header HTTP |
| `tls_metadata` | `net.read` | una connessione, timeout breve | osserva metadati TLS |
| `dns_metadata` | `net.read` | risoluzione limitata | osserva DNS del target |
| `http_baseline` | `net.read` | GET/HEAD soltanto | baseline non mutante |

Exploit, brute force, password spraying, fuzzing aggressivo, DoS, evasione, lateral movement, shell arbitraria e target fuori scope non appartengono al circuito iniziale.

## Manifest minimo

```json
{
  "id": "security_headers_v1",
  "runtime": "zlang-2.5",
  "capabilities": ["net.read"],
  "scope": {"asset_id": "uuid", "hostname": "example.org"},
  "limits": {"requests": 1, "timeout_seconds": 10, "max_bytes": 4096},
  "approval": {"required": true},
  "output_schema": "evidence.v1",
  "source_sha256": "..."
}
```

I manifest non contengono password, token, cookie, chiavi private o DSN. I segreti restano nelle variabili server-side e non sono disponibili al programma salvo capability documentate.

## Evidenza e audit

L’output normalizzato deve contenere almeno identificativo del job, profilo, asset, timestamp, versione runtime, limiti applicati, stato, metadati osservati e SHA-256 dell’artefatto. Dati personali, credenziali e contenuto non necessario non devono essere copiati nella Evidence Chain.

La Evidence Chain dimostra integrità e provenienza degli eventi; non dimostra automaticamente sicurezza del target, anonimato, cifratura o autorizzazione. L’autorizzazione resta una responsabilità del proprietario dello scope e dell’owner che approva il job.

## Basso consumo

Il circuito deve funzionare senza LLM nel percorso principale, senza browser headless e con concorrenza 1. Il runner usa timeout, quote di byte e una coda limitata. Il contenuto ripetitivo può essere rappresentato con hash e differenze. Redis non è necessario per il primo incremento.

## Verifica e rilascio

Prima della promozione sono richiesti:

```sh
git diff --check
python3 tests/test_storage_read_v1.py
cargo fmt --all -- --check
cargo check --all-targets
```

La War Room deve essere verificata separatamente con test di rifiuto per target fuori scope, capability non allowlisted, path assoluti, `..`, timeout e output oltre quota. Il deployment deve avvenire in staging, con backup della unit systemd e rollback documentato.

## Stato

Questa specifica documenta l’architettura e il contratto del primo incremento. Un profilo è da considerare **implementato** soltanto quando il codice, i test, il manifest e una prova riproducibile sono presenti nello stesso rilascio.
