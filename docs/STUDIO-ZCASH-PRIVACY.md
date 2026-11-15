# Studio Privacy Zcash e Confronto con DSN

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS

## Come funziona la privacy in Zcash

Zcash usa **zk-SNARKs** per le transazioni shielded.

### Meccanismo
- Note rappresentate da commitment.
- Allo spend: pubblicazione di un **nullifier** + prova zk-SNARK.
- La prova dimostra (senza rivelare):
  - Esistenza della note nell'albero.
  - Possesso della chiave di spesa.
  - Bilanciamento degli importi.
  - Correttezza del nullifier.
- Mittente, destinatario e importo restano nascosti.

### Pool principali
- Sprout (legacy), Sapling, Orchard (Halo 2, no trusted setup), Ironwood (pool principale dal 2026).

### Limiti
- Privacy opzionale.
- Anonimity set dipende dal pool.
- Metadata esterni possono leakare.

## Confronto con DSN ZDOS (laboratorio)

| Aspetto              | Zcash                  | DSN attuale          | Evoluzione possibile      |
|----------------------|------------------------|----------------------|---------------------------|
| Prova di validità    | zk-SNARK               | Nessuna              | Aggregazione / prova minima |
| Unlinkability        | Nullifier + tree       | Debole               | Mixing + fee-aggregate    |
| Importi nascosti     | Sì (shielded)         | No                   | Aggregazione commissioni  |
| Trusted setup        | Eliminato in Orchard   | N/A                  | Evitare                   |

## Conclusioni per ZDOS

Non replichiamo zk-SNARK completi in questa fase.  
Ispiriamo i principi di uniqueness (nullifier-style), aggregazione delle commissioni e riduzione degli hint in Z-Onion per migliorare l'anonimato delle transazioni DSN e delle commissioni $DSN.

Riferimento: `docs/DSN-ANONYMITY.md`
