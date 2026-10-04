# ZDOS Alert Command Center

Il sistema raccoglie dati reali da fonti pubbliche dichiarate e conserva l'ultima fotografia verificata per la comunicazione quando il collegamento cade.

La spiegazione AI è locale e deterministica per default. L'inoltro facoltativo al bridge LLM già presente richiede esplicitamente `ZDOS_ALERT_AI_ONLINE=1` e una richiesta JSON con `online: true`; se il bridge non è configurato, il risultato torna automaticamente alla spiegazione locale.

## Fonti

- **MeteoAlarm Atom/JSON**: allerte ufficiali del servizio nazionale aderente, con livello, fenomeno, area, validità e istruzioni. Feed Italia: `https://feeds.meteoalarm.org/api/v1/warnings/feeds-italy`.
- **Dipartimento della Protezione Civile**: bollettino ufficiale di criticità meteo-idrogeologica: `https://mappe.protezionecivile.gov.it/it/mappe-rischi/bollettino-di-criticita/`.
- **Open-Meteo**: previsione modellistica locale con precipitazione, neve, profondità neve, probabilità e livello di congelamento. È un segnale previsionale, non un'allerta ufficiale: `https://open-meteo.com/en/docs`.

Il rischio idrogeologico è il proxy ufficiale per lo scenario frane. ZDOS non dichiara una frana puntuale sulla base del solo meteo e non sostituisce i bollettini locali.

## API

```text
GET  /api/alerts/status
GET  /api/alerts/refresh?lat=45.4642&lon=9.1900
GET  /api/alerts/outbox              # bridge token richiesto
POST /api/alerts/explain             # AI bounded, nessuna decisione operativa
```

Per abilitare l'assistenza LLM senza cambiare il contratto di sicurezza:

```bash
ZDOS_ALERT_AI_ONLINE=1
```

La chiave e l'endpoint restano quelli del bridge `ai/zdos_llm_bridge.py`; non vengono mai inseriti nei pacchetti offline.

Senza coordinate il refresh interroga le fonti nazionali. Con coordinate aggiunge la previsione Open-Meteo per il luogo indicato.

## Comunicazione offline

Ogni alert nuovo viene trasformato in un pacchetto `zdos.alert.offline-packet.v1` e scritto nell'outbox locale con SHA-256. Il trasporto previsto è **store-and-forward ZComm**: un nodo autenticato può leggere i pacchetti con `/api/alerts/outbox` quando torna online. Un dato cached viene sempre marcato `OFFLINE_STALE`; non viene mostrato come attuale.

L'integrità SHA-256 rileva corruzioni accidentali. Per autenticità forte l'amministratore può aggiungere una firma del nodo in un connettore futuro; ZDOS non inventa firme quando la chiave non è configurata.

## AI bounded

L'endpoint di spiegazione usa classificazione deterministica locale. Riassume numero di alert, livelli e prossima azione prudente. Non può:

- creare alert;
- cambiare il livello ufficiale;
- dichiarare un'emergenza;
- inviare comunicazioni di soccorso;
- trasmettere via radio;
- tracciare persone;
- sostituire Protezione Civile o autorità locali.

Il contratto Zlang è [`alerts/zdos_alerts_guard.zlang`](../alerts/zdos_alerts_guard.zlang).
