# ZDOS Maturity Model

La maturità ZDOS è assegnata per capacità, non per repository intero. Un componente può avanzare soltanto quando supera la soglia della fase precedente.

| Livello | Nome | Requisiti |
|---|---|---|
| M0 | Idea | Obiettivo e rischio descritti |
| M1 | Prototype | Codice eseguibile localmente |
| M2 | Reproducible | Build ripetibile, versioni fissate e test automatici |
| M3 | Verified | Test positivi e negativi, contratto stabile, prova osservabile |
| M4 | Operable | Logging, recovery, revoca, gestione configurazione e runbook |
| M5 | Production candidate | Security review, interoperabilità, backup, upgrade/rollback e prove su target dichiarati |

## Stato corrente

| Capacità | Livello | Motivazione |
|---|---:|---|
| ZDOS Linux live | M2 | ISO e boot QEMU riproducibili; non è ancora general-purpose |
| Bare-metal ZDOS | M2 | Build, runtime ZLB2 e boot QEMU verificati |
| Zlang ZLB2 | M2 | Formato versionato e runtime bounds-checked; capability ancora limitate |
| Evidence Chain locale | M2 | Hash chain, attestazioni e verifica append-only |
| Portale ZDOS-SEC | M1 | Interfaccia e API di laboratorio; non è un piano C2 production-ready |
| Rete multi-nodo | M0 | Da definire consenso, discovery, replica e governance |

Un incremento di livello richiede un documento di migrazione e non può essere ottenuto modificando soltanto badge, colori o messaggi dell’interfaccia.
