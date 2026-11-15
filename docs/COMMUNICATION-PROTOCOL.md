# Protocollo di Comunicazione Ecosistema ZDOS

**Data:** 2026-11-15  
**Obiettivo:** Far comunicare tutti i componenti in modo coerente.

## Componenti

- **ZDOS-Security-Agent** — intercettazione e cattura
- **ZComm** — comunicazione E2E e provisioning eSIM
- **DSN Node** (`network/dsn/node.py`) — replica stato
- **Z-X-Solana-Store** — frontend viaggi/eSIM/store
- **K.I.R.A.** — analisi e policy (Scudo)
- **xCLOUD** — gestionale e pannello Starlink
- **Æsir / zBAG** — gate $DSN

## Messaggi standard (JSON)

```json
{
  "type": "SUSPICIOUS_REQUEST | ESIM_PROVISION | ATTACK_CAPTURE | POLICY_UPDATE | HEARTBEAT",
  "src": "component-name",
  "dst": "target-component",
  "payload": {},
  "ts": "ISO8601",
  "hash": "sha256"
}
```

## Flussi principali

1. **Store → Scudo K.I.R.A. / Security Agent**  
   Ogni link esterno viene inviato per verifica prima del redirect.

2. **Security Agent → K.I.R.A.**  
   Eventi sospetti → analisi → decisione (allow/monitor/block).

3. **Security Agent → DSN**  
   Alert replicati come record `security-event`.

4. **ZComm → DSN**  
   Record `esim-profile` propagati per coerenza multi-nodo.

5. **Store / xCLOUD → ZComm**  
   Apertura chat cifrata o richiesta provisioning eSIM.

6. **Tutti → Gate $DSN**  
   Controllo balance prima di azioni privilegiate.

## Implementazione attuale

- Stub e prototipi presenti nei rispettivi repo.
- Protocollo definito qui come contratto.
- Avanzamento a M2 richiede test end-to-end osservabili.

## Prossimi passi

- [ ] Endpoint HTTP locale comune per i messaggi (es. `:7778/events`)
- [ ] Test di propagazione Store → Agent → DSN
- [ ] Aggiornamento demo Store con chiamate reali agli stub
