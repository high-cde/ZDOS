# GhostNet / ZComm integration in ZDOS

## Cosa è stato replicato

La pagina pubblica `https://z-anon.onhercules.app/channels` espone una superficie chiamata **GHOSTNET** con navigazione `CHANNELS`, `DM`, `WALLET`, `IDENTITY`, stato peer, lista canali e installazione PWA.

Nel Glass Engine ZDOS è stata aggiunta una superficie compatibile a livello di interazione, mantenendo invariati i nomi canale osservati:

```text
general
ghostnet
anonymous
trading
zdos
vera
hotpulci
```

È una **replica funzionale dell'interfaccia**, non una copia del backend Hercules, del codice privato, di sessioni, wallet, identità o dati dell'app pubblica.

## Route e API

Workbench:

```text
http://127.0.0.1:8080/#zcomm-workbench
```

API locali:

```text
GET  /api/zcomm/ghostnet?channel=general
POST /api/zcomm/ghostnet/messages
```

La POST richiede contemporaneamente:

- client locale loopback;
- header `x-zdos-chat-intent: SEND_LOCAL_MESSAGE`;
- canale appartenente alla lista governata;
- corpo massimo 500 caratteri.

I messaggi vengono salvati nell'outbox locale `~/.local/share/zdos-glass-engine/ghostnet/messages.jsonl` con permessi utente. Se il bridge è configurato, il messaggio è marcato `QUEUED_FOR_ZCOMM`; altrimenti resta `LOCAL_OUTBOX`.

I client LAN non possono postare direttamente: devono usare il bridge ZComm autenticato con token. Questo evita di trasformare il pannello in un endpoint di broadcast anonimo.

## Identità e wallet

Il nome `ghost_local` è un'etichetta locale nuova, non un'imitazione dell'identità mostrata dalla chat pubblica. Nessuna chiave privata, seed, cookie o sessione viene importata.

La sezione WALLET è solo una vista compatibile: ZDOS non custodisce fondi, non firma e non trasferisce asset.

## Zlang guard

Il contratto `zcomm/zdos_ghostnet_guard.zlang` consente lettura canali, composizione, queue e sincronizzazione ZComm; nega impersonificazione, lettura chiavi private, export credenziali, wallet custody, broadcast remoto, cancellazioni e shell.

## PWA / installazione

La funzione `INSTALL GHOSTNET` osservata sul sito pubblico non viene falsificata. Il Glass Engine resta installabile come launcher desktop Ubuntu e il bridge Android continua a usare il percorso ZComm autenticato già documentato.
