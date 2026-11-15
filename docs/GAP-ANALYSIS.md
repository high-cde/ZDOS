# Gap Analysis — Cosa Manca Ancora al Sistema ZDOS

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS  
**Livello attuale:** Laboratorio M1

## Stato attuale

Il sistema ha una base documentale e architetturale coerente su:
- Token $DSN (Solana + Polygon)
- Governance e quorum
- Sybil resistance (Soft PoP)
- Commissioni e fee
- Z-Onion, DSN, Æsir, Security Agent
- Super System e pannello

## Gap principali

### 1. Implementazione codice (alta priorità)
- **Nodo DSN**: supporto completo ai record tipizzati (`fee-paid`, `governance-vote`, `policy-update`) e calcolo quorum reale.
- **Soft PoP**: time-lock e binding implementati nel nodo, non solo documentati.
- **Æsir**: verifica automatica di balance e peso del voto (anche se in laboratorio).
- **Security Agent**: applicazione effettiva delle policy approvate.

### 2. Integrazione wallet e balance reali
- Lettura balance $DSN da Solana e Polygon nel pannello o in Æsir.
- Attualmente tutto è manuale o simulato.

### 3. Test e validazione
- Test di propagazione record tra nodi.
- Test di calcolo quorum e soglie.
- Test di Soft PoP (time-lock).
- Validazione su hardware reale (già menzionata in passato ma non completata).

### 4. Sicurezza e audit
- Security review formale del protocollo di comunicazione e dei record.
- Analisi di edge case (double-voting, snapshot manipulation, Sybil avanzati).
- Firma dei record critici.

### 5. Documentazione e allineamento
- Aggiornamento di `MATURITY.md` solo dopo prove reali.
- Sincronizzazione tra tutti i documenti di governance, Sybil, PoP e Super System.
- Protocollo di comunicazione aggiornato con i nuovi record.

### 6. Interfaccia utente
- Super Pannello: visualizzazione reale di quorum, commissioni pagate, balance e stato Soft PoP.
- Collegamento wallet Phantom per lettura balance.

### 7. Operatività reale
- Esecuzione (anche parziale) di commissioni on-chain o simulazione robusta.
- Deployment e test multi-nodo del DSN.
- Attivazione di Z-Onion con hop reali in laboratorio.

## Priorità suggerite

| Priorità | Area                    | Azione |
|---------|-------------------------|--------|
| Alta    | Nodo DSN + record       | Implementare propagazione e calcolo quorum |
| Alta    | Soft PoP                | Codificare time-lock e binding |
| Media   | Wallet integration      | Lettura balance reale nel pannello |
| Media   | Test                    | Suite di test su record e quorum |
| Bassa   | PoP esterno             | Non prioritario |
| Bassa   | Audit formale           | Dopo implementazione minima |

## Conclusione onesta

Il sistema è **coerente e ben documentato**, ma resta in gran parte a livello di specifica e laboratorio.  
Manca l'implementazione concreta nel codice (nodo DSN, Æsir, Security Agent) e la validazione reale.

Prossimo passo logico: implementare i record tipizzati e il calcolo del quorum nel nodo DSN.
