# Evidenza Laboratorio — Z-Onion e Record Tipizzati

**Data:** 2026-11-15  
**Stato:** M1 (laboratorio)

## Cosa è stato attivato

- Nodo DSN supporta record tipizzati (`ZDOS_DSN_TYPED_V1`).
- Tipi implementati: `security-event`, `onion-message`, `esim-profile` (pronto), `heartbeat`.
- Security Agent genera record `security-event` pronti per la propagazione DSN.
- Documentato il layer **Z-Onion** come comunicazione privata sovrana, disciplinata da ZLang/ZDOS.

## Test di laboratorio

```sh
# Avvia nodo
python3 network/dsn/node.py --node-id node1 --listen 127.0.0.1:7777 --demo-typed
```

Output atteso: propagazione di `security-event` e `onion-message`.

## Dichiarazione onesta

Z-Onion non è ancora un onion routing di produzione.  
È la base architetturale per un "nuovo web" privato controllato dall'utente, integrato nativamente in DSN e verificabile in ZLang.  
Nessuna crittografia layered completa è attiva in questa versione.
