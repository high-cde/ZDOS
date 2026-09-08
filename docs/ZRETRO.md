# ZRetro

**ZRetro** è la prima IDE retro nativa di ZDOS: un ambiente testuale in stile Commodore che usa un DSL dichiarativo ZRetro, compilabile e gestibile dal runtime Zlang by ZDOS.

## Visione

ZRetro non è un file manager e non è una IDE moderna con finestre. È uno spazio di creazione a caratteri, con prompt `x@zdos /zretro`, progetti versionati, scene, sprite, suoni, input e pipeline target.

## Primo progetto

`zretro/projects/meteor-patrol/main.zretro` è il primo programma demo creato nel formato nativo. La DSL descrive progetto, target, schermo, palette, scena, oggetti e cicli di gioco:

```text
project Meteor Patrol
target c64 atari8 amiga
screen 40 22
palette c64
scene starfield
player ship
enemy drone
on tick
on fire
on collide
end
```

## Comandi

```text
x@zdos /zretro
h                         aiuto
n <nome>                  nuovo progetto
e <file>                  modifica sorgente
b <file>                  valida e prepara pacchetti target
r <file>                  preview terminale retro
t                         target supportati
a                         panoramica asset
l <id> <peer>              collega due terminali sul bus locale
s <to> <messaggio>         invia messaggio ZRetro local-only
i <id>                    legge la inbox del terminale
p                         pubblicazione esplicita del manifest su Hub
q                         uscita
```

Il prototipo CLI è avviabile con:

```sh
python3 zretro/ide/zretro.py console --root zretro/projects
python3 zretro/ide/zretro.py run zretro/projects/meteor-patrol/main.zretro
python3 zretro/ide/zretro.py build zretro/projects/meteor-patrol/main.zretro
```

La console mostra il prompt nativo `x@zdos /zretro` e instrada i comandi brevi verso init, preview, build, catalogo target e bus locale.

## Software ufficiale ZDOS per Amiga e Commodore 64

Il catalogo [`zretro/packages/official/`](../zretro/packages/official/) contiene i primi pacchetti **ZRetro by ZDOS**: `zretro-terminal-c64` per Commodore 64 e `zretro-terminal-amiga` per Amiga. Sono sorgenti DSL e manifesti verificabili, non ROM o immagini proprietarie: il builder produce IR e provenance; l’emissione di `.prg` e `.adf` richiede toolchain native installate e viene dichiarata solo dopo una build verificata.

I terminali possono essere creatori e comunicativi tramite `zretro.local`. Il bus è append-only JSONL nella directory di progetto o in `ZDOS_ZRETRO_BUS_DIR`; non apre socket, non usa credenziali e non abilita rete implicita. L’interconnessione è esplicita:

```sh
python3 zretro/ide/zretro.py console --root /tmp/zdos-bus
# l c64-01 amiga-01
# s amiga-01 hello from C64
# i amiga-01
```

## Target e backend

| Target | CPU | Artefatto previsto | Backend di riferimento |
|---|---:|---|---|
| Commodore 64 | 6502 | `.prg` | cc65/ca65 e VICE |
| Atari 8-bit | 6502 | `.xex` | cc65/ca65 e Altirra |
| Amiga | 68000 | `.adf` | vasm + disk builder e FS-UAE |

La versione attuale genera un IR ZRetro, manifest target verificabili e messaggi locali tra terminali. Il preview e il bus sono operativi; l’emissione di binari nativi e la chiamata agli emulatori sono backend successivi, da attivare soltanto quando gli strumenti sono presenti nel nodo.

La scelta dei backend è coerente con gli strumenti pubblici: cc65 supporta target 6502 tra cui Commodore e Atari [1]; Altirra documenta immagini Atari come ATR, ATX, XFD, ROM e BIN [2]; FS-UAE è un emulatore Amiga multipiattaforma focalizzato sui giochi [3].

## ZDOS Hub

Il collegamento a `zdos-hub.it` deve essere un adapter esplicito. ZRetro prepara un manifest firmato con nome progetto, hash del sorgente, target, asset e stato build; il publish richiede identità ZDOS, capability `hub.project.publish` e approvazione. La IDE locale non deve ricevere token permanenti e il browser non deve eseguire la build sul nodo.

## Sicurezza

Il progetto è confinato alla propria root. La DSL non esegue shell arbitraria, non apre rete durante build o preview e non modifica il sistema. Il packaging conserva provenance, hash e backend usato. Ogni target non disponibile viene marcato `PREPARED` o `NOT_VERIFIED`, mai dichiarato compilato senza prova.

## Roadmap

La roadmap tecnica residua è: editor TUI nativo, parser ZRetro completo, asset pipeline palette/sprite/sound, backend cc65 per C64, backend 68000 per Amiga, launcher emulatore locale, manifest firmati e pannello ZRetro nella War Room/Hub. Il contratto di comunicazione locale e il catalogo sorgente ufficiale sono già attivi e testati.

## Riferimenti

[1] [cc65 Users Guide](https://cc65.github.io/doc/cc65.html)

[2] [Altirra — 8-bit Atari emulator](https://www.virtualdub.org/altirra.html)

[3] [FS-UAE](https://fs-uae.net/)
