# ZDOS Launcher

`tools/zdos-launcher.sh` è il launcher operativo ufficiale per l’ambiente ZDOS. Rileva automaticamente i checkout ZDOS, Zlang e ZRetro e offre un’interfaccia uniforme per diagnosi, compilazione, test, build e avvio esplicito di QEMU.

## Installazione

Dopo avere clonato il repository, installare il launcher con:

```bash
install -Dm755 tools/zdos-launcher.sh /usr/local/bin/zdos-launcher
```

È possibile indicare percorsi non standard con:

```bash
export ZDOS_ROOT=/percorso/ZDOS
export ZLANG_ROOT=/percorso/Zlang
```

## Comandi principali

```text
zdos-launcher status
zdos-launcher doctor
zdos-launcher verify
zdos-launcher selftest
zdos-launcher selftest --distro --qemu
zdos-launcher selftest --distro --qemu --strict
zdos-launcher zlang programma.zlang
zdos-launcher zretro progetto.zretro
zdos-launcher build
zdos-launcher qemu immagine.iso
```

`status` mostra l’ambiente rilevato. `doctor` esegue controlli non distruttivi e individua i progetti ZRetro. `zlang` compila un file `.zlang` in una directory temporanea. `zretro` invoca l’IDE disponibile. `verify` esegue le suite locali trovate. `selftest` esegue shell syntax check, test ZRetro, test Zlang e verifica del kernel quando gli strumenti sono presenti; `--distro` abilita la build ISO e `--qemu` il boot test. I controlli non disponibili sono marcati `SKIP`, mentre una regressione produce `FAIL`. Per un gate di release usare `--strict`: in quel caso ogni toolchain mancante diventa `FAIL` e il check non può risultare verde per errore. `build` invoca la build della distro. `qemu` avvia un’immagine soltanto quando richiesto esplicitamente.

## Castel Goblin

Il progetto demo originale è disponibile in `zretro/projects/castel-goblin/`, con tre livelli progressivi. Può essere eseguito con:

```bash
zdos-launcher zretro zretro/projects/castel-goblin/level-01-courtyard/main.zretro
zdos-launcher zretro zretro/projects/castel-goblin/level-02-dungeons/main.zretro
zdos-launcher zretro zretro/projects/castel-goblin/level-03-keep/main.zretro
```

## Sicurezza e stato delle capability

Il launcher non formatta dischi, non installa pacchetti, non riavvia servizi, non modifica repository e non sovrascrive sorgenti. La build può produrre artefatti secondo le regole del repository. Input interattivo, collisioni, audio nativo e multiplayer non devono essere considerati disponibili finché non sono implementati nel runtime ZDOS e coperti da test riproducibili.
