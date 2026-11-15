# Anonimato delle Transazioni DSN

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Livello:** Laboratorio M1

## Obiettivo

Aumentare l'anonimato delle transazioni e delle commissioni $DSN sulla rete DSN, ispirandosi a principi di unlinkability e mixing (stile derivati privacy / Monero), senza uscire dalla disciplina sperimentale ZDOS.

## Stato attuale

- I record DSN sono tipizzati e propagati in chiaro (JSON).
- Le commissioni $DSN sono verificate da Æsir tramite balance gate.
- Z-Onion nasconde il percorso a livello di circuito, ma i record restano leggibili dai nodi intermediari.
- Nessun mixing o ring signature è ancora implementato.

## Meccanismi proposti (laboratorio)

### 1. Aggregazione delle commissioni
- Più commissioni $DSN vengono raggruppate in un unico record `fee-aggregate`.
- Il record contiene solo il totale e una lista di hash di riferimento, non i singoli mittenti.
- Riduce la correlazione diretta azione ↔ pagamento.

### 2. Mixing a livello di record
- I nodi volontari possono ritardare e mescolare l'ordine di propagazione di record di tipo `security-event`, `governance-vote` e `onion-message`.
- Simulazione di un pool di mixing locale.

### 3. Hint minimi in Z-Onion
- Il campo `src_hint` diventa opzionale e può essere omesso o sostituito da un valore casuale.
- Ogni hop rimuove informazioni non necessarie prima di inoltrare.

### 4. Snapshot di balance per il voto
- Il peso del voto usa uno snapshot firmato dal nodo, non il balance in tempo reale.
- Riduce il linking tra voto e movimenti successivi di $DSN.

### 5. Record di copertura (cover traffic)
- I nodi possono emettere record `heartbeat` o `cover` a intervalli casuali per confondere l'analisi di traffico.

## Limiti onesti

- Non è un'implementazione di ring signature, stealth address o zero-knowledge.
- I nodi intermediari vedono ancora il contenuto dei record (a meno di cifratura aggiuntiva).
- L'anonimato dipende dalla partecipazione dei nodi e dal volume di traffico.
- È una base sperimentale, non una garanzia di privacy forte.

## Integrazione

- DSN node: supporto a record `fee-aggregate` e ritardo di propagazione.
- Æsir: verifica delle commissioni aggregate.
- Security Agent: audit senza esporre identità non necessarie.
- Z-Onion: riduzione degli hint.

## Prossimi passi concreti

- [ ] Aggiungere tipo `fee-aggregate` nel nodo DSN
- [ ] Implementare ritardo casuale di propagazione (mixing semplice)
- [ ] Rendere `src_hint` opzionale di default in Z-Onion
- [ ] Documentare i trade-off in ZLang
