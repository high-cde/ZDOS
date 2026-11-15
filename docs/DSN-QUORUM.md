# Logica del Quorum — DSN Governance

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Livello:** Laboratorio M1

## Definizione

Il **quorum** è la soglia minima di partecipazione (in peso $DSN) necessaria affinché una proposta di governance sia considerata valida.

## Modello proposto

### 1. Peso del voto
- Peso = snapshot del balance $DSN (Solana + Polygon) al momento del voto.
- Il Super System unifica le due chain.

### 2. Quorum base
- **Quorum minimo**: 15% del totale $DSN snapshot circolante (o del totale detenuto dai nodi attivi).
- Se non si raggiunge il quorum entro la finestra di voto, la proposta decade.

### 3. Soglia di approvazione
- Una volta raggiunto il quorum, serve **maggioranza semplice** dei voti espressi (peso yes > peso no).
- Per proposte critiche (modifica di policy di sicurezza o di Z-Onion): **maggioranza qualificata** (66%).

### 4. Finestra di voto
- Durata laboratorio: 24–72 ore (configurabile).
- Dopo la scadenza, Æsir calcola il risultato e propaga un record `policy-update` se approvata.

### 5. Protezioni
- Un nodo può votare una sola volta per proposta.
- Il peso è bloccato allo snapshot (no double-voting con movimenti successivi).
- Commissioni $DSN richieste per proporre e (opzionalmente) per votare.

## Esempio

| Parametro              | Valore laboratorio |
|------------------------|--------------------|
| Quorum                 | 15%                |
| Soglia normale         | >50%               |
| Soglia critica         | ≥66%               |
| Finestra               | 48h                |

## Integrazione

- **Æsir**: applica le regole di quorum e soglia.
- **DSN**: trasporta i record `governance-vote` e il risultato finale.
- **Security Agent**: esegue la policy solo se il quorum è stato raggiunto e la proposta approvata.
- **Pannello**: mostra percentuale di quorum raggiunta in tempo reale.

## Stato

Proposta di laboratorio. I valori (15%, 50%, 66%) sono configurabili e non ancora codificati nel nodo.
