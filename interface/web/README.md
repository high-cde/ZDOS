# ZDOS interface web

Questa è una piccola interfaccia HTTP locale **read-only** per mostrare lo stato del servizio. Non implementa un feed remoto, nodi distribuiti, Z-CORTEX, DSN-PALACE o azioni di deploy.

## Avvio

```sh
npm install
PORT=8080 node server/server.js
```

Aprire `http://127.0.0.1:8080/`. L’endpoint `GET /status` restituisce esclusivamente lo stato del processo locale e il flag `mutations: false`.

Le prove del kernel, del compilatore e del boot sono disponibili nei workflow e nella documentazione dei repository ZDOS e Zlang; questa interfaccia non le sostituisce.
