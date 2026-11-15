# Studio Halo 2

**Data:** 2026-11-15  
**Disciplina:** ZLang by ZDOS

## Cos'è Halo 2

Halo 2 è il sistema di proving zero-knowledge usato dal pool shielded **Orchard** di Zcash (attivato con NU5 nel 2022) e dal successivo Ironwood.

È l'implementazione pratica del protocollo Halo, sviluppato da Electric Coin Company.

## Proprietà principali

- **Nessun trusted setup**: elimina la cerimonia di generazione dei parametri ("toxic waste") richiesta da Groth16 (usato in Sprout e Sapling).
- **Recursive proof composition**: una prova può verificare altre prove. In Orchard questa capacità è supportata ma non ancora usata pienamente nel protocollo attuale.
- **PLONKish arithmetization**: più flessibile di R1CS. Supporta custom gates e lookup arguments.
- **Curve Pasta**: Pallas e Vesta (ciclo di curve elliptic efficienti per la ricorsione).
- **Accumulation scheme**: permette di accumulare prove in modo efficiente.

## Confronto con Groth16

| Aspetto              | Groth16 (Sapling)     | Halo 2 (Orchard)      |
|----------------------|-----------------------|-----------------------|
| Trusted setup        | Sì (per circuito)    | No                    |
| Arithmetization      | R1CS                  | PLONKish              |
| Dimensione prova     | Molto piccola         | Più grande            |
| Ricorsione           | Limitata              | Nativa                |
| Aggiornabilità       | Nuova cerimonia       | Più agile             |

## Ruolo in Zcash

- Orchard è il primo pool shielded senza trusted setup.
- Una singola prova Halo 2 copre un intero *bundle* di Actions (ogni Action contiene una note spesa e una creata, anche dummy).
- Migliora la privacy e riduce il rischio di forgiatura legato al setup.

## Rilevanza per ZDOS / DSN

Halo 2 rappresenta lo stato dell'arte della privacy zero-knowledge senza trusted setup.  
Nel contesto sperimentale ZDOS non implementiamo Halo 2, ma ne studiamo i principi:

- Eliminazione di setup fidati
- Aggregazione di prove/azioni
- Flessibilità dell'arithmetization

Questi principi guidano le scelte future su aggregazione commissioni e Z-Onion.

## Limiti

- Implementazione complessa (Rust, circuiti grandi).
- Orchard ha avuto un bug di soundness corretto in NU6.2 (2026).
- Non è un drop-in per sistemi leggeri come il DSN di laboratorio.
