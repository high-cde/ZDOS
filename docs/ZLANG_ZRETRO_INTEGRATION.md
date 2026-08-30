# Integrazione ZDOS, Zlang e ZRetro

## Scopo

Questo documento descrive il confine tra ZDOS, Zlang e ZRetro. L’obiettivo è rendere riproducibile il percorso dal sorgente al programma retro, senza presentare come operativo ciò che è ancora una roadmap.

| Livello | Responsabilità | Evidenza |
|---|---|---|
| Zlang | Sorgente `.zlang`, compilatore e bytecode ZLB2 v2.5 | [Repository Zlang](https://github.com/high-cde/Zlang), `tools/zlangc.py` |
| ZDOS | Target x86_64, runtime bare-metal, boot e verifiche QEMU | [Repository ZDOS](https://github.com/high-cde/ZDOS), `os/x86_64` |
| ZRetro | IDE TUI e DSL dichiarativa per progetti retro | [`zretro/`](../zretro), [`docs/ZRETRO.md`](ZRETRO.md) |
| Hub | Superficie pubblica per documentazione e segnali | [Retro Computing](https://x-zdos.it/retro-computing.html) |

## Flusso verificato

Un programma Zlang viene compilato in bytecode ZLB2 v2.5. Nel percorso bare-metal il bytecode viene incorporato nel kernel sperimentale ZDOS, avviato tramite Multiboot2 e verificato in QEMU. Il percorso ZRetro è adiacente: produce un IR e manifest di progetto, ma l’emissione di binari nativi e il lancio degli emulatori restano backend successivi.

```text
programma .zlang → zlangc.py → ZLB2 v2.5 → runtime ZDOS → QEMU → output seriale
progetto .zretro → IDE ZRetro → IR/manifest → target retro futuro
```

La verifica Zlang–ZDOS può essere eseguita così:

```sh
git clone https://github.com/high-cde/Zlang.git
git clone https://github.com/high-cde/ZDOS.git
cd ZDOS/os/x86_64
make clean
make verify
sh tools/verify_qemu.sh
```

L’output atteso del prototipo è:

```text
ZDOS x86_64 bootstrap
Zlang runtime ZLB2 v2.5 ready
ZDOS: native Zlang program executed
ZDOS: Zlang halted cleanly
```

## Esempio Zlang minimo

Il profilo documentato supporta, tra l’altro, `emit`:

```zlang
# examples/hello.zlang
emit Ciao dal programma Zlang nativo
emit Il kernel ZDOS ha eseguito questo bytecode
```

La compilazione produce bytecode e header C:

```sh
python3 tools/zlangc.py examples/hello.zlang \
  --bytecode /tmp/hello.zlb \
  --header /tmp/hello.h
```

Il compilatore rifiuta istruzioni non appartenenti al profilo, invece di attribuire loro un significato implicito.

## Esempio ZRetro

Il primo progetto demo è [`Meteor Patrol`](../zretro/projects/meteor-patrol/main.zretro). La DSL descrive progetto, target, schermo, palette, scena, oggetti e cicli di gioco. Il percorso locale è:

```sh
python3 zretro/ide/zretro.py run zretro/projects/meteor-patrol/main.zretro
python3 zretro/ide/zretro.py build zretro/projects/meteor-patrol/main.zretro
```

I target dichiarati includono Commodore 64, Atari 8-bit e Amiga come direzioni della pipeline. La prima versione produce un IR ZRetro e manifest verificabili; non promette ancora binari nativi o avvio automatico di emulatori.

## Regole di pubblicazione

ZRetro non deve trattare il feed pubblico come registro di build, storage di artefatti o concessione di capability. Un’eventuale pubblicazione deve passare da un adapter esplicito, da un manifest firmato, da un’identità ZDOS e dalla capability `hub.project.publish` con approvazione.

Non pubblicare ROM, BIOS, credenziali, chiavi private, token, dati personali o istruzioni operative dannose. Il tasto **ZRetro** del sito conduce alla pagina documentaria [Retro Computing](https://x-zdos.it/retro-computing.html), non esegue build remote e non concede accessi al nodo.

## Riferimenti

* [Zlang README](https://github.com/high-cde/Zlang/blob/main/README.md)
* [Profilo ZLB2 v2.5](https://github.com/high-cde/Zlang/blob/main/docs/zdos-x86_64-profile.md)
* [ZDOS ZRetro](ZRETRO.md)
* [ZRetro command library](../zretro/ide/command-library.json)
* [ZRetro demo](../zretro/projects/meteor-patrol/main.zretro)
* [ZDOS workflow x86_64](../.github/workflows/validate-x86_64.yml)
* [Pagina pubblica Retro Computing](https://x-zdos.it/retro-computing.html)

**ZDOS · Zlang · ZRetro — Build what you can prove.**

## Licenza

Il contenuto segue la licenza del repository ZDOS. I marchi e i materiali storici Atari, Commodore e Amiga restano soggetti ai rispettivi diritti.
