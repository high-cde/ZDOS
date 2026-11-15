# Proof of Personhood — Approfondimento

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Contesto:** Governance DSN e Sybil resistance

## Cos'è

Il **Proof of Personhood** (PoP) è un meccanismo che cerca di garantire che ogni identità corrisponda a una persona unica e reale, contrastando gli attacchi Sybil (una persona che controlla molte identità).

## Principali approcci esistenti

| Approccio              | Esempio              | Come funziona                          | Pro                          | Contro                     |
|------------------------|----------------------|----------------------------------------|------------------------------|----------------------------|
| Biometrico             | World ID (Orb)       | Scansione iride + ZK proof             | Alta unicità                 | Privacy, centralizzazione  |
| Sociale / Web of Trust | BrightID, PoH        | Vouching reciproco o video + corte     | Più decentralizzato          | Difficile da scalare       |
| Puzzle sincroni        | Idena                | Tutti risolvono CAPTCHA allo stesso tempo | No biometria               | Cerimonie periodiche       |
| Aggregazione credenziali | Human Passport     | Score da stamp multipli                | Flessibile                   | Farmabile                  |

## Benchmark costi gas (stime laboratorio)

| Sistema              | Azione principale          | Gas stimato (EVM) | Costo indicativo (gas basso) | Note |
|----------------------|----------------------------|-------------------|------------------------------|------|
| World ID             | Verifica on-chain (ZK)     | 200k – 800k        | $0.01 – $0.50              | Dipende da circuito e chain (World Chain più economica) |
| Proof of Humanity    | Submit + vouch + finalize  | 150k – 400k        | $0.05 – $2+                | Deposit refundable; più economico su Gnosis |
| BrightID             | Pubblicazione verifica     | 80k – 200k         | $0.01 – $0.20              | Firma off-chain + submit on-chain |
| Groth16 generico     | Verifica prova             | 200k – 300k        | $0.05 – $0.30              | Baseline per molti PoP ZK |
| Soft PoP interno ZDOS| Binding + time-lock record| ~50k – 100k        | Trascurabile                | Solo record DSN, no chain esterna |

**Note**: I costi variano fortemente con il prezzo del gas e la chain. Su L2 (Base, Polygon, World Chain) sono spesso sotto i $0.05. Su Ethereum mainnet possono essere più alti. I valori sono stime di laboratorio, non misurazioni precise.

## Relazione con la governance DSN

Attualmente la governance ZDOS usa **peso $DSN** (token-weighted).  
Questo è resistente a Sybil solo finché il token ha valore, ma permette concentrazione di potere (plutocrazia).

### Possibili integrazioni (laboratorio)

1. **Ibrido token + personhood**
   - Una quota del peso (es. 20-30%) riservata a identità verificate PoP.
   - Il resto rimane token-weighted.

2. **Nullifier style**
   - Ogni persona verificata ottiene un nullifier univoco (ispirato a Zcash).
   - Può votare una sola volta indipendentemente dal numero di wallet.

3. **Soft PoP interno**
   - In laboratorio: binding a chiave pubblica + time-lock $DSN + comportamento storico del nodo.
   - Non è un vero PoP, ma alza il costo di creazione di identità multiple.
   - Costo gas: trascurabile (solo record DSN).

## Limiti onesti

- Nessun PoP è perfetto (puppeteering, coercizione, centralizzazione).
- I sistemi biometrici sollevano problemi di privacy e accesso.
- I sistemi sociali sono lenti da bootstrappare.
- Nel contesto ZDOS (privacy-oriented e sperimentale) un PoP forte è difficile da implementare senza compromettere la sovranità.
- I costi gas elevati su L1 riducono l'accessibilità.

## Raccomandazione per ZDOS

Per il laboratorio attuale:
- Mantenere il peso $DSN come meccanismo principale.
- Aggiungere time-lock e rate limiting.
- Preferire un Soft PoP interno (basso costo, nessuna dipendenza esterna).
- Non introdurre biometria o dipendenze esterne in questa fase.

Il Proof of Personhood resta un obiettivo di lungo termine, non un requisito immediato.
