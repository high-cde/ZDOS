# Evidenze prove software — 2026-11-15

Eseguite in ambiente di simulazione locale (non su hardware fisico).

## Prova 1: Replica multi-nodo DSN
- Payload eSIM propagato da node-01 a node-02.
- Hash verificato: `b50ba718daeba9312f438009021b1c9d6505ef30f2ea6b3cf68b45ce285245d1`
- Risultato: **SUCCESSO** (record presente su entrambi i nodi).

## Prova 2: Gate $DSN
- Balance 5.0 → APPROVED
- Balance 0.2 → DENIED
- Risultato: **SUCCESSO**

## Prova 3: Provisioning eSIM via ZComm + DSN
- Richiesta con balance sufficiente → provisioned
- Token di attivazione generato e record replicato.
- Hash: `8c263e207ffe88cd469a20b05c9931b6d5ffb593c78844ca4892c7b14a1b88d6`
- Risultato: **SUCCESSO** (simulazione di laboratorio)

## Limiti
Queste sono prove di logica e flusso, non di produzione.  
Non sostituiscono validazione hardware, UEFI, security review formale o integrazione SM-DP+ reale.

Usabili come evidenza M1 per i componenti coinvolti.
