# XZDOS Super System

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Token:** $DSN Solana + $DSN Polygon

## Obiettivo

Dare potenziale reale all'ecosistema ZDOS attraverso un sistema unificato che usa i due token $DSN (Solana e Polygon) per utilità, accesso, commissioni, governance e servizi sovrani.

## Token ufficiali

| Chain    | Token | Indirizzo |
|----------|-------|-----------|
| Solana   | $DSN  | `35w74RT77BPSYNpmzpvxmR9wu2ihpgzubKy4bkGHR3F4` |
| Polygon  | $DSN  | `0xfc90516a1f736FaC557e09D8853dB80dA192c296` |

## Architettura del Super System

### 1. Gate Unificato (Æsir Cross-Chain)
- Verifica balance $DSN su **entrambe** le chain.
- Una sola policy: se l'utente ha $DSN su Solana **o** su Polygon, ottiene accesso.
- Soglie diverse per servizi diversi.

### 2. Commissioni Dual-Chain
- Hop Z-Onion, provisioning eSIM, propagazione record critici e voti DAO richiedono commissione $DSN.
- L'utente sceglie con quale chain pagare (Solana o Polygon).
- In laboratorio: registrazione del pagamento come record `fee-paid` con chain indicata.

### 3. Governance Pesata
- Il peso del voto è la somma (o il massimo) dei balance snapshot su entrambe le chain.
- Record `governance-vote` include `weight_solana` e `weight_polygon`.

### 4. Servizi Potenziati
| Servizio              | Utilità $DSN                          | Chain preferita |
|-----------------------|--------------------------------------|-----------------|
| Z-Onion hop           | Commissione per hop                  | Qualsiasi       |
| eSIM provisioning     | Accesso + commissione                | Solana          |
| Security Agent premium| Soglia anomaly più bassa              | Polygon         |
| Store partner links   | Priorità e riduzione fee               | Qualsiasi       |
| DAO proposal          | Deposito $DSN per proporre           | Entrambe        |

### 5. Pannello di Controllo
Il Super Pannello mostra:
- Balance stimato (manuale o via wallet)
- Servizi sbloccati
- Commissioni pagate (lab)
- Voti attivi

## Record tipizzati aggiunti

```json
{
  "type": "fee-paid",
  "chain": "solana | polygon",
  "amount": "0.1",
  "service": "z-onion-hop | esim | vote",
  "wallet": "address"
}
```

## Stato

Laboratorio M1. Il sistema è documentato, integrato nel protocollo di comunicazione e pronto per essere collegato a Æsir e al pannello. Nessuna transazione on-chain reale è eseguita automaticamente in questa versione.

## Potenziale

- Unifica i due token sotto un'unica identità ZDOS.
- Dà utilità concreta a $DSN su Solana e Polygon.
- Apre la strada a servizi sovrani a pagamento senza dipendere da terze parti.
- Base per una DAO di sicurezza cross-chain.
