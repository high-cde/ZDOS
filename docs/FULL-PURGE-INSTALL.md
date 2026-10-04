# ZDOS Full Purge Install

Script ufficiale:

```bash
curl -fsSL https://raw.githubusercontent.com/high-cde/ZDOS/feat/glass-engine-console/scripts/install-zdos-full-purge.sh | bash
```

Il comando:

1. crea un backup timestampato in `~/ZDOS-backups/full-purge-YYYYMMDD-HHMMSS`;
2. ferma e disabilita `zdos-glass-engine.service`;
3. rimuove le copie precedenti `ZDOS`, `zdos-organism`, `ZDOS-lab-v1` e `x-zdos-complete`;
4. rimuove launcher, dati installati e unità systemd del Glass Engine;
5. clona il branch `feat/glass-engine-console` in `~/ZDOS`;
6. reinstalla dipendenze, launcher e servizio;
7. verifica status HTTP, frontend e servizio systemd.

Lo script chiede di digitare `ELIMINA` prima della rimozione. Non usa `sudo` e non rimuove `~/zdos-microcosm-beta`.

Per usare un altro branch:

```bash
curl -fsSL https://raw.githubusercontent.com/high-cde/ZDOS/feat/glass-engine-console/scripts/install-zdos-full-purge.sh \
  | ZDOS_BRANCH=main bash
```
