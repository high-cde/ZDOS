# Z-Onion — Comunicazione Privata Sovrana

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Obiettivo:** Creare un layer di comunicazione privata reale, ispirato a onion routing ma nativo dell'ecosistema ZDOS, oltre il Web3 tradizionale.

## Principi

- **Sovranità**: nessun intermediario non controllato.
- **Disciplina ZLang**: i circuiti e i messaggi sono esprimibili e verificabili in ZLang/ZLB2.
- **Integrazione DSN**: i messaggi onion viaggiano come record tipizzati `onion-message`.
- **Sicurezza**: ogni hop è un nodo DSN autenticato; policy applicata da Æsir.
- **Audit**: ogni evento di circuito è registrabile dal Security Agent.

## Struttura di un messaggio onion

```json
{
  "type": "onion-message",
  "v": 1,
  "circuit_id": "hex-or-uuid",
  "hops": 3,
  "next_hop": "node-id-or-addr",
  "payload": "encrypted-or-layered",
  "ttl": 5,
  "src_hint": "optional"
}
```

Il payload può essere layered (ogni nodo rimuove un layer). In laboratorio è simulato.

## Flusso

1. Il mittente costruisce il circuito (lista di nodi DSN).
2. Il messaggio viene propagato come record DSN tipizzato.
3. Ogni nodo intermediario verifica la policy (Æsir), logga l'evento (Security Agent) e inoltra.
4. Il destinatario finale riceve e può rispondere sullo stesso circuito o su uno nuovo.

## Integrazione

- **DSN**: trasporto nativo via `propagate_record("onion-message", ...)`.
- **Security Agent**: cattura tentativi di manomissione o circuiti anomali.
- **Æsir**: decide se un hop è permesso in base a balance $DSN e vincoli di rete.
- **ZComm**: può usare Z-Onion come trasporto per chat E2E avanzata.
- **ZLang**: definizione formale dei tipi di messaggio e delle regole di routing.

## Stato

Laboratorio (M1). Il nodo DSN supporta già il tipo `onion-message`.  
Non è un'implementazione di produzione di onion routing (manca crittografia layered completa, directory, e protezione da analisi di traffico).  
È la base sovrana per un "nuovo web" privato controllato dall'utente, non da terze parti.

## Prossimi passi

- Crittografia layered minima (AES o simile per hop).
- Directory di nodi volontari.
- Test di circuito end-to-end.
- Espressione delle regole in ZLang.
