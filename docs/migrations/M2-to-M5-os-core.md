# Documento di migrazione: ZDOS OS Core (M2 → M5)

**Capacità:** ZDOS Linux live + Bare-metal  
**Stato di partenza:** M2  
**Obiettivo:** M5 Production candidate  
**Data:** 2026-11-15

## Gap principali dichiarati in README e MATURITY

- Non validato su hardware fisico.
- Assenza di UEFI / Secure Boot.
- Package manager senza repository firmati.
- Nessun aggiornamento atomico / rollback.
- Nessun ambiente grafico.
- Nessuna matrice hardware certificata.

## Piano di avanzamento

### M2 → M3 (Verified)
- [ ] Test end-to-end su almeno 1 macchina fisica (documentare modello, BIOS, risultato).
- [ ] Contratto di boot stabile (marker seriali verificabili).
- [ ] Test negativi (disco assente, UUID errato, ecc.).

### M3 → M4 (Operable)
- [ ] Logging strutturato e recovery documentati.
- [ ] Runbook di installazione e recovery.
- [ ] Gestione configurazione versionata.

### M4 → M5 (Production candidate)
- [ ] Supporto UEFI iniziale.
- [ ] Package repositories firmati (almeno prototipo).
- [ ] Percorso di upgrade/rollback atomico.
- [ ] Security review documentata.
- [ ] Backup e prove su target dichiarati.

## Note
Molti punti richiedono hardware fisico e review umana. Il codice e la documentazione possono preparare i percorsi, ma la prova osservabile resta esterna.
