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
p                         pubblicazione esplicita del manifest su Hub
q                         uscita
```

Il prototipo CLI è avviabile con:

```sh
python3 zretro/ide/zretro.py console --root zretro/projects
python3 zretro/ide/zretro.py run zretro/projects/meteor-patrol/main.zretro
python3 zretro/ide/zretro.py build zretro/projects/meteor-patrol/main.zretro
```

La console mostra il prompt nativo `x@zdos /zretro` e instrada i comandi brevi verso init, preview, build e catalogo target.

## Target e backend

| Target | CPU | Artefatto previsto | Backend di riferimento |
|---|---:|---|---|
| Commodore 64 | 6502 | `.prg` | cc65/ca65 e VICE |
| Atari 8-bit | 6502 | `.xex` | cc65/ca65 e Altirra |
| Amiga | 68000 | `.adf` | vasm + disk builder e FS-UAE |

La prima versione genera un IR ZRetro e manifest target verificabili. Il preview terminale è operativo; l’emissione di binari nativi e la chiamata agli emulatori sono backend successivi, da attivare soltanto quando gli strumenti sono presenti nel nodo.

La scelta dei backend è coerente con gli strumenti pubblici: cc65 supporta target 6502 tra cui Commodore e Atari [1]; Altirra documenta immagini Atari come ATR, ATX, XFD, ROM e BIN [2]; FS-UAE è un emulatore Amiga multipiattaforma focalizzato sui giochi [3].

## ZDOS Hub

Il collegamento a `zdos-hub.it` deve essere un adapter esplicito. ZRetro prepara un manifest firmato con nome progetto, hash del sorgente, target, asset e stato build; il publish richiede identità ZDOS, capability `hub.project.publish` e approvazione. La IDE locale non deve ricevere token permanenti e il browser non deve eseguire la build sul nodo.

## Sicurezza

Il progetto è confinato alla propria root. La DSL non esegue shell arbitraria, non apre rete durante build o preview e non modifica il sistema. Il packaging conserva provenance, hash e backend usato. Ogni target non disponibile viene marcato `PREPARED` o `NOT_VERIFIED`, mai dichiarato compilato senza prova.

## Roadmap

La roadmap tecnica è: editor TUI nativo, parser ZRetro completo, asset pipeline palette/sprite/sound, backend cc65 per C64/Atari, backend 68000 per Amiga, launcher emulatore locale, manifest firmati e pannello ZRetro nella War Room/Hub.

## Riferimenti

[1] [cc65 Users Guide](https://cc65.github.io/doc/cc65.html)

[2] [Altirra — 8-bit Atari emulator](https://www.virtualdub.org/altirra.html)

[3] [FS-UAE](https://fs-uae.net/)
