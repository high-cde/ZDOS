# ZDOS interface web

Questa è la console web locale **read-only** di ZDOS. La dashboard riunisce una vista delle capacità e della loro maturità documentata, link a onboarding e prove, e la diagnostica del solo processo web. Non controlla il kernel, il disco, la rete dell'host o nodi remoti e non implementa account, gestione della memoria, comandi remoti o deploy.

## Avvio

```sh
npm install
PORT=8080 node server/server.js
```

Aprire `http://127.0.0.1:8080/`. Gli endpoint disponibili sono:

- `GET /status`: stato del processo Node locale, runtime, uptime e inventario delle capacità con link alle prove. Le etichette di maturità sono dichiarazioni documentali, non controlli in tempo reale del sistema o attestazioni indipendenti.
- `GET /api/ping`: controllo di raggiungibilità dell'API.

Le risposte dichiarano `mutations: false`. Il server si lega a `127.0.0.1` per impostazione predefinita; impostare `HOST` esplicitamente solo quando si comprende l'esposizione di rete. Non esporre questa console come pannello remoto: autenticazione, ruoli, audit e autorizzazione delle mutazioni non sono implementati.

La UI è servita da Node ed è la superficie canonica di questa console. `web/index.html` è una pagina pubblica separata per la telemetria PHP locale e non è collegata a questo server. Le prove del kernel, del compilatore e del boot sono disponibili nei workflow e nella documentazione del repository ZDOS; questa interfaccia non le sostituisce né esegue build o test nel browser.

## Verifica

```sh
npm run check
```
