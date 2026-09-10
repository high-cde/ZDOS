# ZDOS Official ZRetro Software

Questo catalogo contiene software ufficiale **ZRetro by ZDOS** in formato sorgente e manifesto verificabile.

| Pacchetto | Target | Stato |
|---|---|---|
| `zretro-terminal-c64` | Commodore 64 / 6502 | source-ready, build verificabile con `zretro build` |
| `zretro-terminal-amiga` | Amiga / Motorola 68000 | source-ready, build verificabile con `zretro build` |

I pacchetti condividono il runtime `zretro-terminal-v1`, il profilo `zlang-by-zdos` e il bus locale `zretro.local`. Il bus non apre socket e non abilita rete implicita: i terminali comunicano solo quando l’operatore crea esplicitamente un link nella directory del bus.

## Build

```sh
python3 zretro/ide/zretro.py build zretro/packages/official/zretro-terminal-c64/main.zretro
python3 zretro/ide/zretro.py build zretro/packages/official/zretro-terminal-amiga/main.zretro
```

Il build produce IR e manifesti target-specifici. La generazione di un `.prg` o di un `.adf` nativo richiede le rispettive toolchain e non viene dichiarata automaticamente dal builder portabile.

## Interconnessione locale

```sh
python3 zretro/ide/zretro.py console --root /tmp/zdos-bus
# l c64-01 amiga-01
# s amiga-01 hello from c64
# i c64-01
```
