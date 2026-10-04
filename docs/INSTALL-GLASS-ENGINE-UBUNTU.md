# Installazione ZDOS Glass Engine su Ubuntu

## Installazione locale consigliata

Dalla root di `ZDOS`:

```bash
bash scripts/install-glass-engine-ubuntu.sh
```

Lo script:

1. copia solo `interface/web` in `~/.local/share/zdos-glass-engine`;
2. installa le dipendenze bloccate con `npm ci --omit=dev`;
3. esegue `npm run check`;
4. crea un servizio **systemd utente**;
5. avvia la console solo su `127.0.0.1:8080`;
6. non usa `sudo`, non modifica NetworkManager e non apre porte sulla LAN.

Aprire:

```text
http://127.0.0.1:8080
```

Comandi utili:

```bash
systemctl --user status zdos-glass-engine.service
journalctl --user -u zdos-glass-engine.service -f
systemctl --user disable --now zdos-glass-engine.service
```

Per scegliere un'altra porta:

```bash
ZDOS_GLASS_PORT=8181 bash scripts/install-glass-engine-ubuntu.sh
```

## Analisi PC e Wi-Fi

La console rileva localmente, in sola lettura:

- distribuzione, kernel e architettura;
- CPU, load average, RAM e filesystem;
- interfacce `ip`;
- reti Wi-Fi tramite `nmcli` se NetworkManager è presente;
- presenza di tool come `iw`, `qemu`, `xorriso`, `grub-mkrescue`, `ffmpeg`, `docker`;
- stato locale ZComm.

Non salva password Wi-Fi, non effettua scansioni invasive, non cambia connessioni e non avvia automaticamente tool.

## USB/CD e vero sistema operativo

L'installer sopra è una **app Ubuntu installabile**, non un ISO desktop completo. Il repository possiede un builder bare-metal (`distro/build.sh`) per un'immagine ZDOS seriale/minimale, ma non è ancora una distribuzione grafica completa con NetworkManager, firmware Wi-Fi, desktop, WebRTC e installer grafico.

Per un vero supporto USB/CD servono una fase separata e gate aggiuntivi:

1. kernel e moduli compatibili con la macchina target;
2. firmware Wi-Fi redistribuibile e NetworkManager/wpa_supplicant;
3. desktop/sessione grafica o kiosk browser;
4. installer e partizionamento con conferma esplicita;
5. test QEMU e test su hardware reale;
6. checksum e rollback del supporto.

Non usare `distro/build.sh` per sostituire Ubuntu sul disco: oggi produce un'immagine tecnica/seriale, non un desktop ZDOS pronto per l'uso quotidiano.

## ZComm chat e video

Il client Microcosm attuale ha:

- coda locale persistente;
- pagine e stanze locali;
- messaggi bounded;
- sync HTTPS opzionale;
- default-deny e `remoteExecution: false`.

Per chattare tra due persone serve ancora un backend con login, stanze, autorizzazioni, storage e receipts. Per videochiamate serve inoltre WebRTC con signaling, STUN/TURN, gestione dispositivi, permessi microfono/camera e rate limit. L'app non deve esporre il PC su Internet direttamente né usare un endpoint POST generico.

La console espone quindi lo stato corretto `LOCAL_QUEUE_READY`, `chat: NOT_CONFIGURED`, `video: NOT_CONFIGURED` invece di dichiarare una chiamata attiva che non esiste.
