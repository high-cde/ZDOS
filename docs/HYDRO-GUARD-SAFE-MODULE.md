# ZDOS Hydro Guard · Safe Module

Questo modulo aggrega la proposta di sorveglianza idrogeologica in una forma installabile e verificabile.

## Attivo

- lettura di telemetria JSON;
- validazione di valori non negativi;
- quattro bande di allerta;
- output canonico `hydro.evaluation.v1`;
- logica deterministica ripetibile;
- policy Zlang di osservazione;
- predisposizione per attestazione Evidence Chain dopo approvazione operatore.

## Bloccato intenzionalmente

Il modulo non apre porte, non scansiona frequenze e non trasmette su CB, radio, sub-GHz o Wi-Fi. Non controlla sirene, ESP32, Flipper Zero, parabole o altri dispositivi. Queste operazioni richiederebbero autorizzazione esplicita, driver certificati, frequenze legali, autenticazione del comando, fail-safe fisici e procedure di emergenza.

La valutazione restituisce sempre:

```json
{
  "policy": "DEFAULT-DENY",
  "actions": {
    "radio_tx": false,
    "siren_actuation": false,
    "flipper_tx": false,
    "esp32_command": false
  }
}
```

## Soglie iniziali

- `0–30 cm`: `ASSENTE`;
- `>30–80 cm`: `ORDINARIA`;
- `>80–150 cm`: `MODERATA`;
- `>150 cm` oppure flusso `>2500 mm/s`: `ELEVATA_FLASH_FLOOD`.

Le soglie sono parametri iniziali di laboratorio, non un bollettino ufficiale e non sostituiscono autorità di protezione civile, sensori certificati o procedure locali.

## Esecuzione

```bash
python3 tools/evaluate-hydro-telemetry.py hydro/telemetry.example.json
```

Il risultato può essere registrato come evidenza soltanto dopo la revisione dell'operatore e l'aggiunta di un vero issuer/identità del sensore.
