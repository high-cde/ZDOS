# ZComm Android ↔ ZDOS Glass Engine

Questo bridge collega l'APK **ZDOS Microcosm** al Glass Engine sul PC Ubuntu tramite la stessa rete locale.

## Confini di sicurezza

- pairing esplicito con token casuale locale;
- sync solo dei messaggi ZComm, massimo 240 caratteri ciascuno;
- coda persistente JSONL sul PC;
- nessuna shell, esecuzione remota, lettura file o wallet;
- `DEFAULT-DENY` resta attivo;
- video/WebRTC non è simulato: richiede un signaling server e STUN/TURN separati.

## Attivazione sul PC

Esegui come utente Ubuntu normale, non come root:

```bash
ZDOS_LAN=1 ZDOS_GLASS_HOST=0.0.0.0 bash -c '\
  curl -fsSL https://raw.githubusercontent.com/high-cde/ZDOS/feat/glass-engine-console/scripts/autobuild-zdos.sh | bash'
```

Il comando crea o conserva il token in:

```text
~/.config/zdos/bridge.token
```

Ricava l'IP del PC sulla Wi-Fi:

```bash
hostname -I | awk '{print $1}'
```

E visualizza il token da inserire nell'APK:

```bash
cat ~/.config/zdos/bridge.token
```

Verifica il servizio:

```bash
systemctl --user status zdos-glass-engine.service
curl http://127.0.0.1:8080/api/local/zcomm
```

## Pairing nell'APK

1. Apri **ZComm / Videotel**.
2. Nel pannello **ZDOS-PC BRIDGE** inserisci, per esempio:

   ```text
   http://192.168.1.20:8080
   ```

3. Inserisci il contenuto di `~/.config/zdos/bridge.token`.
4. Premi **PAIR ZDOS-PC**.
5. Scrivi un messaggio e premi **SYNC ZDOS-PC**.

Il messaggio viene inviato al PC, salvato nella coda bridge e mostrato nel workbench ZComm della console Glass Engine.

## Verifica manuale autenticata

```bash
TOKEN="$(cat ~/.config/zdos/bridge.token)"

curl -fsS \
  -H "x-zdos-bridge-token: $TOKEN" \
  http://127.0.0.1:8080/api/bridge/status
```

Invio di un messaggio di test nella coda che l'APK riceverà al prossimo sync:

```bash
curl -fsS -X POST \
  -H "content-type: application/json" \
  -H "x-zdos-bridge-token: $TOKEN" \
  -d '{"messages":[{"id":"pc-test-1","roomId":"piazza","nick":"ZDOS-PC","body":"Messaggio dal Glass Engine","createdAt":"'"$(date -Is)'"}]} ' \
  http://127.0.0.1:8080/api/bridge/sync
```

## Aggiornamento APK

Il pairing richiede la versione Microcosm che contiene:

- `pairZCommBridge`;
- token persistente in AsyncStorage;
- `syncZCommState` verso `/api/bridge/sync`;
- pannello **ZDOS-PC BRIDGE**;
- supporto Android per il trasporto LAN HTTP durante il laboratorio.

Quindi l'APK già installato deve essere ricompilato e reinstallato dal repository `zdos-microcosm-beta` prima del pairing.

## Troubleshooting

- **PC non raggiungibile:** telefono e PC devono essere sulla stessa Wi-Fi; controlla `hostname -I`.
- **401 bridge token required:** ricopia il token senza spazi o newline.
- **Connessione rifiutata:** controlla `systemctl --user status zdos-glass-engine.service` e la porta 8080.
- **APK ancora offline:** ricompila l'APK aggiornato; la versione precedente conosce solo la coda locale.
- **Rete pubblica:** non usare `ZDOS_GLASS_HOST=0.0.0.0` su una rete non fidata senza firewall; il bridge è progettato per laboratorio LAN.
