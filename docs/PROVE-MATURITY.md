# Procedure di prova per avanzamento maturità ZDOS

**Data:** 2026-11-15  
**Policy:** Si aggiorna `docs/MATURITY.md` solo dopo prove osservabili e ripetibili.

## 1. Validazione su hardware fisico

- [ ] Boot ISO ZDOS Linux su almeno 1 macchina fisica (documentare modello, BIOS/UEFI, risultato seriale).
- [ ] Verifica persistenza UUID.
- [ ] Registrare output in `docs/evidence/hardware-boot.md`.

## 2. UEFI / Secure Boot

- [ ] Prototipo di configurazione GRUB UEFI.
- [ ] Documento dei requisiti e limiti attuali.
- [ ] Prova su hardware UEFI (anche senza Secure Boot attivo).

## 3. Package firmati e upgrade atomici

- [ ] Estensione di `zdos-pkg` con verifica firma (prototipo).
- [ ] Script di upgrade/rollback di laboratorio.
- [ ] Test positivo e negativo.

## 4. Consenso e sicurezza di rete

- [ ] Specifica di consenso leggero (es. quorum semplice su record DSN).
- [ ] Estensione di `network/dsn/node.py` con verifica peer.
- [ ] Test con peer non raggiungibile e peer malevolo simulato.

## 5. Utility reale e testata di $DSN

- [ ] Gate di laboratorio che controlla balance $DSN prima di un'azione (es. provisioning eSIM).
- [ ] Integrazione con Æsir o stub zBAG.
- [ ] Test con balance sufficiente / insufficiente.

## 6. Security review

- [ ] Checklist di review interna (superfici, input, crypto).
- [ ] Documento `docs/SECURITY-REVIEW-YYYYMMDD.md`.
- [ ] Eventuale review esterna (fuori scope codice).

## 7. Aggiornamento esplicito di MATURITY.md

Solo dopo che i punti sopra hanno evidenze:
- Aggiornare la tabella in `docs/MATURITY.md`.
- Citare i documenti di prova.
- Richiede documento di migrazione per ogni incremento.

---

Quando tutte le prove rilevanti sono eseguite e documentate, si può procedere all'aggiornamento totale di ZComm e degli altri moduli.
