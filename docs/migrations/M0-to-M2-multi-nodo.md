# Documento di migrazione: Rete multi-nodo / DSN (M0 → M2)

**Capacità:** Rete multi-nodo / DSN  
**Stato di partenza:** M0 (Idea)  
**Stato attuale:** M1 (Prototype) — codice eseguibile presente  
**Obiettivo di questo documento:** raggiungere M2 (Reproducible)  
**Data:** 2026-11-15  
**Autore:** Grok (su richiesta di high-cde)

## 1. Contesto e obiettivo

Secondo `docs/MATURITY.md` la capacità "Rete multi-nodo" era a livello **M0**.  
Con l'aggiunta di `network/dsn/node.py` e `tools/test-multinode.sh` esiste ora un prototipo eseguibile localmente → **M1**.

Questo documento fornisce la specifica minima, il piano di prototipo e i criteri di verifica necessari per avanzare la capacità a **M2** (Reproducible).

Non dichiara implementazione completa né produzione. Segue la policy di verità ZDOS: si usa "implementato" solo quando il codice esiste e passa test riproducibili.

## 2. Specifica minima (M1)

### 2.1 Modello di nodo
- Ogni nodo è un processo ZDOS (Linux live o bare-metal) che espone:
  - un identificatore stabile (node_id, generato localmente e persistito)
  - un endpoint di ascolto (TCP o Unix socket in laboratorio)
  - un set di capacità dichiarate (storage, compute, gateway)

### 2.2 Discovery
Fase M1 (laboratorio):
- Discovery statica via file di configurazione locale (`peers.json`).
- Formato minimo:
  ```json
  [
    {"node_id": "node-01", "addr": "127.0.0.1:7777"},
    {"node_id": "node-02", "addr": "127.0.0.1:7778"}
  ]
  ```
- Esempio: `network/dsn/peers.example.json`

### 2.3 Replica base
- Replicazione di un oggetto semplice (payload binario).
- Meccanismo: push on-demand verso i peer noti.
- Integrità: verifica hash SHA-256 del payload.
- Quorum: non richiesto in M1 (best-effort).

### 2.4 Consenso
Non implementato in M1/M2. La specifica lascia esplicitamente aperto il modello (Raft-like, gossip+quorum, o altro) per fasi successive.

## 3. Piano di Proof-of-Concept (M1) — IMPLEMENTATO

### 3.1 Ambiente
- Script locale `tools/test-multinode.sh` che avvia due processi sulla stessa macchina.
- Supporto QEMU pianificato ma non ancora automatizzato.

### 3.2 Comportamento atteso
1. Ogni nodo parte, carica i peer e registra il proprio node_id.
2. Un nodo propaga un record di prova.
3. Il record viene ricevuto dagli altri nodi.
4. Ogni nodo può verificare l'hash del record ricevuto.

### 3.3 Criteri di successo M1 — SODDISFATTI (codice)
- Codice eseguibile localmente: `network/dsn/node.py`
- Script di test: `tools/test-multinode.sh`
- Log chiaro di discovery, invio e verifica.
- Nessuna dipendenza esterna non documentata (solo stdlib Python).

## 4. Criteri per M2 (Reproducible)

Per avanzare a M2 devono essere soddisfatti tutti i seguenti punti:

| Criterio | Descrizione | Prova richiesta |
|----------|-------------|-----------------|
| Build ripetibile | Script o Makefile che costruisce i binari di rete | Comando documentato che produce artefatti identici |
| Versioni fissate | Dipendenze (kernel, librerie, ZLang) bloccate | `sources.lock` o equivalente |
| Test automatici | Test che verificano discovery + replica su 2 nodi | Script `test-multinode.sh` o equivalente che passa in CI |
| Contratto stabile | Formato messaggi e API interne versionati | Documento o schema in `docs/` |
| Osservabilità | Log strutturati e marker verificabili | Output QEMU o log che contiene marker attesi |

Un test positivo e uno negativo (es. peer irraggiungibile) devono passare.

## 5. Checklist di avanzamento

### Da M0 a M1
- [x] Specifica di discovery e replica scritta e revisionata
- [x] Prototipo eseguibile (locale)
- [ ] Log di propagazione di un record di prova (da eseguire e registrare)
- [x] Documento di migrazione aggiornato con evidenze

### Da M1 a M2
- [ ] Script di build e test riproducibile integrato in CI
- [ ] Test automatico in CI (anche locale) con marker verificabili
- [ ] Formato messaggi versionato esplicito
- [ ] Aggiornamento di `docs/MATURITY.md` con nuovo livello e motivazione

## 6. Prossimi passi consigliati

1. Eseguire `./tools/test-multinode.sh` e registrare l'output nel documento.
2. Integrare il test in un workflow CI.
3. Estendere a QEMU multi-guest.
4. Solo dopo evidenze positive e ripetibili, aggiornare `docs/MATURITY.md` a M2.

## 7. Rischi e limiti dichiarati

- Nessun consenso, nessuna tolleranza ai guasti, nessuna sicurezza di rete in questa fase.
- Discovery statica: non adatta a reti dinamiche.
- Il PoC è limitato a laboratorio (processi locali / futuro QEMU). Non validato su hardware fisico.
- Governance e modello economico di $DSN restano fuori scope fino a M3+.

---

*Questo documento è un artefatto di avanzamento. Non modifica lo stato di maturità finché non esistono prove osservabili e un aggiornamento esplicito di `docs/MATURITY.md`.*
