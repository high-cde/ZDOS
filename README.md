# ZDOS: The Unified Ecosystem

Benvenuti nel **ZDOS Unified Repository**. Questo monorepo consolida l'intera suite di tecnologie Z-GENESIS e ZDOS in un framework unico e coeso.

## 🚀 Panoramica

ZDOS è un ecosistema in evoluzione che riunisce componenti di runtime, automazione, ricerca e sistemi operativi sperimentali. Il percorso oggi **effettivamente avviabile e verificato** è il prototipo bare-metal `os/x86_64`, eseguito in QEMU con un programma Zlang nativo; gli altri sottosistemi vanno considerati componenti o direzioni progettuali finché non dispongono di una prova equivalente.

## ✅ Percorso verificato: Zlang → ZDOS x86_64

[![Target](https://img.shields.io/badge/target-x86__64-1f6feb?style=for-the-badge)](os/x86_64/)
[![Boot](https://img.shields.io/badge/boot-QEMU%20verificato-2ea043?style=for-the-badge)](os/x86_64/)
[![Bytecode](https://img.shields.io/badge/bytecode-ZLB0%20v1-d29922?style=for-the-badge)](os/x86_64/ARCHITECTURE.md)

Il flusso verificato è **programma Zlang → compilatore ZLB0 v1 → kernel bare-metal → ISO GRUB Multiboot2 → QEMU → console seriale**. La guida completa, con prerequisiti, esempi e limiti, è disponibile in [`os/x86_64/`](os/x86_64/).

```sh
cd os/x86_64
make clean && make verify
sh tools/verify_qemu.sh
```

## 📂 Struttura del Progetto

- **`core/`**: Il livello di intelligenza.
  - `cortex/`: Routing neurale e elaborazione del segnale.
  - `aaak/`: Kernel di accesso autonomo agli agenti.
  - `memory/`: Sistemi di memoria AI ad alto punteggio.
- **`os/`**: Le fondamenta sperimentali.
  - `x86_64/`: Prototipo bare-metal avviabile in QEMU con runtime Zlang incorporato.
  - `kernel/`: Base kernel Z80/Collapse OS e relativi strumenti.
  - `ghostnet/`: Componenti di ricerca del sottosistema Ghostnet.
- **`network/`**: L'infrastruttura.
  - `nodes/`: Gestione dei nodi distribuiti.
  - `dsn/`: Logica della rete di servizi distribuiti.
- **`interface/`**: Il livello di interazione.
  - `cli/`: Interfaccia a riga di comando unificata (`zgenctl`).
  - `web/`: Dashboard e visualizzazione live.
  - `cloud/`: Portale cloud aziendale.
- **`dev/`**: Il toolkit.
  - `zen/`: Hub di programmazione e SDK.

## 🛠 Guida Rapida e Setup

Per iniziare con ZDOS, seguire i passaggi seguenti:

1.  **Clonare il repository:**
    ```bash
    git clone https://github.com/high-cde/ZDOS.git
    cd ZDOS
    ```

2.  **Installare le dipendenze:**
    Assicurarsi di avere Python 3.8+ e Node.js 16+ installati. Quindi, eseguire lo script di setup principale:
    ```bash
    ./scripts/setup_all.sh
    ```
    Questo script installerà tutte le dipendenze necessarie e configurerà l'ambiente.

3.  **Avviare i servizi:**
    Per avviare tutti i componenti di ZDOS, utilizzare:
    ```bash
    ./scripts/start_all.sh
    ```

## 💡 Esempi di Utilizzo

-   **Interazione con la CLI:**
    ```bash
    zgenctl status
    zgenctl agent create --name my_agent
    ```
-   **Accesso alla Dashboard Web:**
    Dopo aver avviato i servizi, la dashboard web sarà disponibile all'indirizzo `http://localhost:3000`.

## 🤝 Contribuzione

Siamo entusiasti di accogliere contributi alla piattaforma ZDOS! Se desideri contribuire, segui queste linee guida:

1.  **Fork del repository.**
2.  **Crea un nuovo branch** per la tua funzionalità o correzione di bug (`git checkout -b feature/nome-funzionalita` o `bugfix/nome-bug`).
3.  **Effettua le tue modifiche** e assicurati che il codice sia conforme agli standard di stile esistenti.
4.  **Scrivi test** per le tue modifiche, se applicabile.
5.  **Esegui i test** per assicurarti che tutto funzioni correttamente.
6.  **Fai il commit delle tue modifiche** (`git commit -m 'Descrizione dettagliata della tua modifica'`).
7.  **Fai il push del branch** (`git push origin feature/nome-funzionalita`).
8.  **Apri una Pull Request** descrivendo le tue modifiche e il problema che risolvono.

## 🛡 Licenza

Questo progetto è rilasciato sotto la licenza MIT. Vedere il file `LICENSE` per maggiori dettagli.

---
*Costruito con precisione. Alimentato da ZDOS.*
# Test
