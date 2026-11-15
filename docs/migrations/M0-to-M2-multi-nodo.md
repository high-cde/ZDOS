# Documento di migrazione: Rete multi-nodo / DSN (M0 → M2)

**Capacità:** Rete multi-nodo / DSN  
**Stato di partenza:** M0 (Idea)  
**Obiettivo di questo documento:** raggiungere M2 (Reproducible)  
**Data:** 2026-11-15  
**Autore:** Grok (su richiesta di high-cde)

## 1. Contesto e obiettivo

Secondo `docs/MATURITY.md` la capacità "Rete multi-nodo" è attualmente a livello **M0**:

> Da definire consenso, discovery, replica e governance.

Questo documento fornisce la specifica minima, il piano di prototipo e i criteri di verifica necessari per avanzare la capacità a **M1** (Prototype) e poi a **M2** (Reproducible).

Non dichiara implementazione completa né produzione. Segue la policy di verità ZDOS: si usa "implementato" solo quando il codice esiste e passa test riproducibili.

## 2. Specifica minima (M1)

### 2.1 Modello di nodo
- Ogni nodo è un processo ZDOS (Linux live o bare-metal) che espone:
  - un identificatore stabile (node_id, generato localmente e persistito)
  - un endpoint di ascolto (TCP o Unix socket in laboratorio)
  - un set di capacità dichiarate (storage, compute, gateway)

### 2.2 Discovery
Fase M1 (laboratorio):
- Discovery statica via file di configurazione locale (`/etc/zdos/peers.json`) o variabile d'ambiente.
- Formato minimo:
  ```json
  [
    {"node_id": "node-01", "addr": "192.168.1.10:7777"},
    {"node_id": "node-02", "addr": "192.168.1.11:7777"}
  ]
  ```
- Nessun servizio di discovery dinamico richiesto in questa fase.

### 2.3 Replica base
- Replicazione di un oggetto semplice (es. un record Evidence Chain o un file di stato).
- Meccanismo: push periodico o on-demand verso i peer noti.
- Integrità: verifica hash SHA-256 del payload.
- Quorum: non richiesto in M1 (single-leader o best-effort).

### 2.4 Consenso
Non implementato in M1/M2. La specifica lascia esplicitamente aperto il modello (Raft-like, gossip+quorum, o altro) per fasi successive.

## 3. Piano di Proof-of-Concept (M1)

### 3.1 Ambiente
- 2 o 3 istanze ZDOS Linux live in QEMU (o container) sulla stessa macchina host.
- Rete host-only o bridge tra i guest.
- Script di avvio documentato in `tools/` o `docs/`.

### 3.2 Comportamento atteso
1. Ogni nodo parte, carica i peer e registra il proprio node_id.
2. Un nodo scrive un record di prova nella Evidence Chain locale.
3. Il record viene propagato agli altri nodi entro un timeout dichiarato (es. 30s).
4. Ogni nodo può verificare l'hash del record ricevuto.

### 3.3 Criteri di successo M1
- Codice eseguibile localmente che dimostra i punti 1-4.
- Log chiaro di discovery, invio e verifica.
- Nessuna dipendenza esterna non documentata.

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
- [ ] Specifica di discovery e replica scritta e revisionata
- [ ] Prototipo eseguibile su 2 nodi QEMU
- [ ] Log di propagazione di un record di prova
- [ ] Documento di migrazione aggiornato con evidenze

### Da M1 a M2
- [ ] Script di build e test riproducibile
- [ ] Test automatico in CI (anche locale)
- [ ] Formato messaggi versionato
- [ ] Aggiornamento di `docs/MATURITY.md` con nuovo livello e motivazione

## 6. Prossimi passi consigliati

1. Implementare un modulo minimo `network/node.py` (o equivalente in ZLang/Rust) che:
   - legge `peers.json`
   - espone un endpoint
   - propaga un record di prova
2. Aggiungere `tools/test-multinode-qemu.sh` che avvia due guest e verifica la propagazione.
3. Eseguire il test e aggiornare questo documento con i risultati osservati.
4. Solo dopo evidenze positive, proporre l'aggiornamento di `MATURITY.md`.

## 7. Rischi e limiti dichiarati

- Nessun consenso, nessuna tolleranza ai guasti, nessuna sicurezza di rete in questa fase.
- Discovery statica: non adatta a reti dinamiche.
- Il PoC è limitato a laboratorio (QEMU/container). Non validato su hardware fisico.
- Governance e modello economico di $DSN restano fuori scope fino a M3+.

---

*Questo documento è un artefatto di avanzamento. Non modifica lo stato di maturità finché non esistono prove osservabili e un aggiornamento esplicito di `docs/MATURITY.md`.*
