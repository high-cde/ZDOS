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

## Limiti onesti

- Nessun PoP è perfetto (puppeteering, coercizione, centralizzazione).
- I sistemi biometrici sollevano problemi di privacy e accesso.
- I sistemi sociali sono lenti da bootstrappare.
- Nel contesto ZDOS (privacy-oriented e sperimentale) un PoP forte è difficile da implementare senza compromettere la sovranità.

## Raccomandazione per ZDOS

Per il laboratorio attuale:
- Mantenere il peso $DSN come meccanismo principale.
- Aggiungere time-lock e rate limiting.
- Studiare un nullifier leggero per limitare i voti multipli.
- Non introdurre biometria o dipendenze esterne in questa fase.

Il Proof of Personhood resta un obiettivo di lungo termine, non un requisito immediato.
