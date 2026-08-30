# Castel Goblin

## Una nuova avventura ZRetro in stile Atari

**Castel Goblin** è un progetto originale per ZRetro/ZDOS, ispirato all’estetica dei computer domestici a 8 bit: schermate compatte, palette limitata, messaggi brevi, ritmo leggibile e azioni deterministiche. Non usa ROM, grafica, musica, nomi di personaggi o livelli copiati da opere proprietarie.

## Livelli e difficoltà

| Livello | Scenario | Pressione di gioco | Elementi |
|---|---|---|---|
| 01 — Il Cortile delle Lanterne | Ingresso del castello | Introductory | Un goblin, movimento base, collisioni e fuoco |
| 02 — Le Cripte del Muschio | Sotterranei | Advanced | Goblin e pipistrello, ritmo più alto e suono d’allarme |
| 03 — La Torre del Re Ombra | Fortezza interna | Nightmare | Goblin, pipistrello e guardiano, scontro finale |

La DSL ZRetro attualmente non possiede parole chiave native per `level`, `difficulty`, punteggio, vite o calendario di spawn. Per mantenere la compatibilità con il parser reale, i livelli sono tre progetti `.zretro` separati, con difficoltà e contenuti dichiarati nei commenti e nei manifest di progetto.

## Avvio locale

Dalla radice del repository ZDOS:

```sh
python3 zretro/ide/zretro.py run zretro/projects/castel-goblin/level-01-courtyard/main.zretro
python3 zretro/ide/zretro.py run zretro/projects/castel-goblin/level-02-dungeons/main.zretro
python3 zretro/ide/zretro.py run zretro/projects/castel-goblin/level-03-keep/main.zretro
```

Per preparare i manifest target:

```sh
for level in zretro/projects/castel-goblin/*; do
  python3 zretro/ide/zretro.py build "$level/main.zretro"
done
```

Il preview terminale è operativo e genera IR/manifest per C64, Atari 8-bit e Amiga. L’attuale runtime stampa una scena deterministica; l’input interattivo e l’emissione di binari nativi sono milestone successive.

## Multiplayer: contratto progettato, runtime da implementare

La prima modalità multiplayer prevista è **Castle Relay**, una modalità cooperativa locale a turni brevi: due giocatori condividono la schermata, il primo controlla il Wanderer e il secondo il Lantern Keeper. Entrambi devono coordinare movimento e fuoco per superare il livello; ogni stanza produce un tick deterministico e il risultato viene verificato prima del passaggio alla stanza successiva.

Il contratto futuro dovrà definire:

```text
players: 2
mode: cooperative-local
input: player-1, player-2
state: tick, room, score, lives, seed
network: disabled-by-default
sync: deterministic-state-hash
```

Questo non viene presentato come multiplayer già giocabile: oggi il parser ZRetro ammette `player` e `on` come elementi descrittivi, ma il runtime dichiara che l’input interattivo è una milestone futura e il manifest imposta `network: disabled`. Per una modalità online serviranno un protocollo, un’autorità di sessione, limiti anti-abuso, test di desincronizzazione e una capability esplicita; non si userà il feed pubblico come canale di gioco o di esecuzione.

## Roadmap tecnica

La versione successiva può aggiungere, in quest’ordine, un modello di input locale, due entità giocatore, tick deterministici, collisioni e vite, caricamento sequenziale dei tre livelli, hash dello stato e solo dopo un adapter multiplayer autorizzato. I backend C64/Atari e Amiga dovranno produrre artefatti reali soltanto quando gli strumenti dichiarati sono presenti e i test passano.

## Riferimenti

* [DSL e sicurezza ZRetro](../../docs/ZRETRO.md)
* [IDE ZRetro](../../zretro/ide/zretro.py)
* [Demo Meteor Patrol](../meteor-patrol/main.zretro)
* [Zlang](https://github.com/high-cde/Zlang)
* [ZDOS](https://github.com/high-cde/ZDOS)
* [Pagina Retro Computing](https://x-zdos.it/retro-computing.html)

**Castel Goblin · ZRetro · ZDOS — Build what you can prove.**
