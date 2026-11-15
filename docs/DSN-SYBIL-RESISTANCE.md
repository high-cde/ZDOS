# Meccanismi di Sybil Resistance — DSN Governance

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Livello:** Laboratorio M1

## Problema

Un attacco Sybil consiste nel creare molte identità (nodi) per influenzare voti o risorse senza un costo reale proporzionale.

## Meccanismi attuali e proposti

### 1. Costo economico ($DSN)
- Il peso del voto è proporzionale al balance $DSN (Solana + Polygon).
- Creare molti nodi senza $DSN non dà potere di voto.
- **Forza**: alta se il token ha valore.
- **Debolezza**: chi accumula $DSN può comunque concentrare potere.

### 2. Snapshot bloccato
- Il peso è fissato al momento dello snapshot.
- Impedisce di spostare token tra nodi durante la finestra di voto.
- **Forza**: riduce il double-voting e il flash-loan style.
- **Debolezza**: non impedisce l'accumulo preventivo.

### 3. Commissione per proporre e votare
- Richiedere una commissione $DSN per creare una proposta o per votare alza il costo di un attacco massivo.
- **Forza**: aumenta il costo lineare con il numero di identità.
- **Debolezza**: se la commissione è bassa, resta conveniente.

### 4. Quorum alto
- Un quorum del 15% (o superiore) obbliga l'attaccante a controllare una frazione significativa del peso totale.
- **Forza**: rende costoso raggiungere la soglia.
- **Debolezza**: se la partecipazione è bassa, il quorum può essere difficile da raggiungere anche per utenti onesti.

### 5. Un voto per nodo + binding identità
- Un nodo può votare una sola volta.
- In futuro: binding a chiave pubblica o a prova di possesso $DSN.
- **Forza**: limita il moltiplicatore di identità.
- **Debolezza**: senza prova forte di identità unica, un attaccante può ancora creare molti nodi.

### 6. Meccanismi aggiuntivi (proposti)
- **Proof-of-DSN**: il nodo deve dimostrare di detenere $DSN da un tempo minimo (time-lock).
- **Reputazione nodo**: i nodi con storico di comportamento corretto hanno peso leggermente maggiore (ancora sperimentale).
- **Rate limiting**: limite al numero di proposte per finestra temporale.

## Valutazione complessiva

| Meccanismo              | Efficacia attuale | Note                          |
|-------------------------|-------------------|-------------------------------|
| Peso $DSN               | Alta              | Principale difesa             |
| Snapshot                | Media-Alta        | Anti flash-move               |
| Commissioni             | Media             | Dipende dal valore            |
| Quorum                  | Media             | Dipende dalla partecipazione  |
| Un voto per nodo        | Bassa-Media       | Facilmente aggirabile         |

## Conclusione onesta

La resistenza Sybil principale è **economica** (possesso di $DSN).  
Non esiste ancora un meccanismo di identità unica forte (tipo proof-of-personhood).  
Il sistema è adeguato per un laboratorio, ma per un uso reale richiederebbe:
- Time-lock o vesting del peso
- Maggiore costo per la creazione di proposte
- Monitoraggio di comportamenti anomali da parte del Security Agent

## Stato

Analisi di laboratorio. Nessun meccanismo Sybil avanzato è ancora codificato nel nodo DSN.
