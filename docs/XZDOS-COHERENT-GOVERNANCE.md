# XZDOS — Ragionamento Coerente: Gas, Fee, Chain, PoP e Governance

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Livello:** Laboratorio M1

## Obiettivo

Definire un sistema di governance e accesso coerente che unifica:
- Token $DSN su Solana e Polygon
- Commissioni e fee
- Costi gas
- Proof of Personhood (soft e futuro)
- Sybil resistance
- Quorum e peso del voto

## 1. Chain e Token

| Chain    | Token | Indirizzo | Ruolo principale |
|----------|-------|-----------|------------------|
| Solana   | $DSN  | `35w74RT77BPSYNpmzpvxmR9wu2ihpgzubKy4bkGHR3F4` | Accesso primario, commissioni rapide, peso voto |
| Polygon  | $DSN  | `0xfc90516a1f736FaC557e09D8853dB80dA192c296` | Accesso secondario, backup, peso voto aggiuntivo |

**Regola unificata**: Æsir accetta $DSN da **entrambe** le chain (OR). Il peso del voto è la **somma** dei balance snapshot.

## 2. Fee e Commissioni

| Azione privilegiata       | Commissione minima | Chain preferita | Record prodotto |
|---------------------------|--------------------|-----------------|-----------------|
| Hop Z-Onion               | 0.1 $DSN           | Qualsiasi       | `fee-paid` |
| Provisioning eSIM         | 0.5 $DSN           | Solana          | `fee-paid` |
| Proposta governance       | 1.0 $DSN           | Qualsiasi       | `fee-paid` + `governance-vote` |
| Voto                      | 0.05 $DSN (opz.)   | Qualsiasi       | `governance-vote` |

Le commissioni sono registrate come record tipizzati. In laboratorio non vengono eseguite transazioni on-chain automatiche.

## 3. Gas e Costi

| Componente                | Costo gas stimato | Note |
|---------------------------|-------------------|------|
| Soft PoP interno (DSN)    | Trascurabile      | Solo record DSN |
| Verifica World ID         | 200k–800k         | Troppo alto per laboratorio |
| PoH registration          | 150k–400k         | Non adottato |
| BrightID publish          | 80k–200k          | Non adottato |
| Operazioni DSN interne    | ~50k–100k         | Accettabile |

**Decisione**: evitare verifiche PoP esterne on-chain in questa fase a causa dei costi gas e delle dipendenze.

## 4. Proof of Personhood (PoP)

### Soft PoP interno (adottato)
- Binding chiave pubblica + time-lock minimo $DSN (es. 7 giorni).
- Un voto per nodo per proposta.
- Peso basato su snapshot.
- Nessuna biometria, nessuna dipendenza esterna.

### PoP esterno (futuro)
- Non implementato.
- Possibile integrazione futura solo se i costi gas scendono e la privacy è preservata.

## 5. Sybil Resistance

| Meccanismo              | Stato     | Efficacia |
|-------------------------|-----------|-----------|
| Peso $DSN               | Attivo    | Alta |
| Snapshot bloccato       | Attivo    | Media-Alta |
| Commissione proposta    | Attivo    | Media |
| Un voto per nodo        | Attivo    | Bassa-Media |
| Time-lock Soft PoP      | Proposto  | Media |
| PoP biometrico/esterno  | Rifiutato | - |

## 6. Quorum e Soglie

| Parametro           | Valore |
|---------------------|--------|
| Quorum minimo       | 15% del peso totale snapshot |
| Soglia normale      | >50% |
| Soglia critica      | ≥66% |
| Finestra di voto    | 48 ore |

Æsir calcola il risultato. Se quorum + soglia sono raggiunti, viene propagato un record `policy-update`.

## 7. Flusso coerente completo

1. Utente detiene $DSN su Solana e/o Polygon.
2. Æsir verifica il balance (OR).
3. Per azioni privilegiate: pagamento commissione → record `fee-paid`.
4. Per governance: proposta con deposito → voti con snapshot → calcolo quorum da Æsir → eventuale `policy-update`.
5. Security Agent e Z-Onion applicano la policy solo se validata.
6. Soft PoP limita i voti multipli tramite binding + time-lock.

## 8. Stato e limiti onesti

- Tutto è a livello laboratorio M1.
- Nessuna transazione on-chain automatica.
- Nessun PoP esterno.
- Coerenza prioritaria su sovranità, bassi costi e assenza di dipendenze esterne.

## Conclusione

Il sistema è coerente: i due token $DSN alimentano accesso, commissioni e peso di voto; il Soft PoP e le commissioni forniscono Sybil resistance senza costi gas elevati; il quorum e Æsir chiudono il ciclo di governance. Tutto resta sotto la disciplina ZLang by ZDOS.
