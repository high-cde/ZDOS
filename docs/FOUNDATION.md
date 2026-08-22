# ZDOS Foundation

## Scopo

ZDOS è un ecosistema operativo sperimentale costruito attorno a una regola semplice: **nessuna capacità viene considerata reale senza codice, contratto, prova riproducibile e limite dichiarato**. La distribuzione Linux, il laboratorio bare-metal, Zlang, la Evidence Chain e il portale SEC sono parti diverse dello stesso sistema, non prodotti indipendenti con promesse sovrapposte.

## Modello a quattro livelli

| Livello | Responsabilità | Prova minima |
|---|---|---|
| **Foundation** | Contratti, versioni, governance e policy | Documento versionato e controllo CI |
| **Runtime** | ZDOS Linux, kernel bare-metal e Zlang | Build riproducibile e boot osservabile |
| **Evidence** | Eventi, hash, attestazioni e revoche | Ledger verificabile e test negativo |
| **Operations** | Portale, operatori, release e incidenti | Log, policy e audit senza claim impliciti |

## Contratto di capacità

Ogni nuova capacità ZDOS deve definire un identificatore stabile, input, output, errore atteso, autorizzazione necessaria, prova positiva e almeno una prova negativa. Una schermata o una stringa di log non è sufficiente per certificare una proprietà di sicurezza.

```text
CAPABILITY = contract + implementation + evidence + boundary
```

## Governance tecnica

Le modifiche che impattano boot, bytecode, identità, policy o dati devono essere approvate tramite pull request, mantenere compatibilità esplicita o documentare la migrazione, aggiungere test di regressione e produrre un’attestazione nella Evidence Chain. Le chiavi di firma, i segreti e i dati personali non entrano nel repository né nel ledger.

## Separazione delle responsabilità

ZDOS esegue il runtime e conserva gli eventi. Zlang definisce contratti deterministici, senza accesso arbitrario al filesystem o alla rete. ZDOS-SEC amministra policy, identità, revoche e audit; non deve diventare un canale di esecuzione remota non autenticato.

## Definizione di “production-ready”

ZDOS non può essere dichiarato production-ready finché ogni componente critico non ha documentazione di threat model, gestione delle chiavi, aggiornamento e rollback, test di interoperabilità, logging auditabile, procedure di incidente e una prova su un ambiente target dichiarato.
