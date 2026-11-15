# DSN Governance & DAO di Sicurezza

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Token:** $DSN (Solana + Polygon)

## Obiettivo

Creare una DAO di sicurezza governata dai nodi DSN, con commissioni $DSN in stile derivati privacy (ispirati a concetti Monero: unlinkability, ring-like mixing a livello di laboratorio).

## Meccanismo di commissione

- Ogni azione privilegiata (hop Z-Onion, provisioning eSIM, propagazione record critico) richiede una **commissione $DSN**.
- La commissione è verificata da Æsir (balance gate).
- In laboratorio: soglia minima configurabile.
- Stile privacy: le commissioni possono essere aggregate o mixate a livello di record DSN (simulazione di unlinkability).

## Governance tramite nodi

1. I nodi DSN che detengono $DSN possono proporre o votare policy di sicurezza.
2. I voti viaggiano come record tipizzati `policy-update` o `governance-vote`.
3. Quorum e soglie definiti in Æsir.
4. Le decisioni aggiornano le regole del Security Agent e di Z-Onion.

## Pannello

Il Super Pannello ZComm Tutela espone:
- Stato motori
- Commissioni $DSN accumulate (lab)
- Proposte di governance attive
- Voto rapido (simulato)

## Record di governance

```json
{
  "type": "governance-vote",
  "proposal_id": "sec-policy-001",
  "vote": "yes|no|abstain",
  "weight": "dsn_balance_snapshot",
  "voter_node": "node-id"
}
```

## Stato

Laboratorio M1. Il meccanismo è documentato e integrabile con i record tipizzati esistenti. Nessuna implementazione on-chain completa di mixing o DAO formale è ancora attiva.

## Integrazione

- Æsir: verifica commissione e peso del voto
- DSN: trasporto dei voti e delle policy
- Security Agent: applica le policy approvate
- Pannello: interfaccia di controllo
