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
zdos-launcher zlang programma.zlang
zdos-launcher zretro progetto.zretro
zdos-launcher build
zdos-launcher qemu immagine.iso
```

`status` mostra l’ambiente rilevato. `doctor` esegue controlli non distruttivi e individua i progetti ZRetro. `zlang` compila un file `.zlang` in una directory temporanea. `zretro` invoca l’IDE disponibile. `verify` esegue le suite locali trovate. `build` invoca la build della distro. `qemu` avvia un’immagine soltanto quando richiesto esplicitamente.

## Castel Goblin

Il progetto demo originale è disponibile in `zretro/projects/castel-goblin/`, con tre livelli progressivi. Può essere eseguito con:

```bash
zdos-launcher zretro zretro/projects/castel-goblin/level-01-courtyard/main.zretro
zdos-launcher zretro zretro/projects/castel-goblin/level-02-dungeons/main.zretro
zdos-launcher zretro zretro/projects/castel-goblin/level-03-keep/main.zretro
```

## Sicurezza e stato delle capability

Il launcher non formatta dischi, non installa pacchetti, non riavvia servizi, non modifica repository e non sovrascrive sorgenti. La build può produrre artefatti secondo le regole del repository. Input interattivo, collisioni, audio nativo e multiplayer non devono essere considerati disponibili finché non sono implementati nel runtime ZDOS e coperti da test riproducibili.
