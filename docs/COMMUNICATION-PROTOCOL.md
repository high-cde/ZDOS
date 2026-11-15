# Protocollo di Comunicazione Ecosistema ZDOS

**Data:** 2026-11-15  
**Obiettivo:** Far comunicare tutti i componenti in modo coerente, con record tipizzati e layer privato Z-Onion.

## Componenti

- **ZDOS-Security-Agent** — intercettazione, cattura e audit
- **ZComm** — comunicazione E2E e provisioning eSIM
- **DSN Node** (`network/dsn/node.py`) — replica stato con record tipizzati
- **Z-Onion** — comunicazione privata sovrana (oltre Web3)
- **Z-X-Solana-Store** — frontend
- **K.I.R.A.** — analisi e policy (Scudo)
- **Æsir / zBAG** — gate $DSN

## Record tipizzati DSN

```json
{
  "v": 1,
  "type": "security-event | esim-profile | onion-message | heartbeat | policy-update",
  "id": "hex",
  "ts": "ISO8601",
  "src": "component-or-node",
  "payload": {}
}
```

Marker di trasporto: `ZDOS_DSN_TYPED_V1`

## Flussi principali

1. Store → Scudo / Security Agent  
2. Security Agent → K.I.R.A. e → DSN (`security-event`)  
3. ZComm → DSN (`esim-profile`)  
4. Qualsiasi → Z-Onion → DSN (`onion-message`)  
5. Tutti → Gate $DSN (Æsir)

## Sicurezza e Audit

- Ogni evento sospetto è catturato dal Security Agent su file JSONL.
- I record DSN possono essere firmati in futuro (HMAC o firma nodo).
- Z-Onion logga ogni hop per audit locale.

## Stato

Prototipi di laboratorio allineati. Record tipizzati attivi nel nodo DSN. Z-Onion documentato e supportato come tipo di record.
