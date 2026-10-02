# ZDOS Intelligence Release

## Obiettivo

Questa release aggiunge un **bridge LLM governato da Zlang**, non un agente con privilegi illimitati. Il modello può analizzare testo, spiegare e proporre piani; non può eseguire comandi, leggere credenziali, modificare file, scansionare reti, trasmettere via radio o firmare transazioni.

## Modalità

- `OFFLINE`: modalità predefinita quando non esiste una configurazione LLM.
- `ONLINE`: usa un endpoint OpenAI-compatible configurato dall'operatore.
- `DEGRADED`: l'endpoint non risponde; nessuna azione viene eseguita.

Configurazione opzionale:

```bash
export ZDOS_LLM_BASE_URL="${OPENAI_API_BASE:-https://api.openai.com/v1}"
export ZDOS_LLM_API_KEY="..."
export ZDOS_LLM_MODEL="gpt-5-mini"
```

Non inserire chiavi nel repository o nel README.

## Uso

```bash
python3 ai/zdos_llm_bridge.py "spiega l'ultimo evento Evidence Chain"
python3 ai/zdos_llm_bridge.py < richiesta.txt
```

La risposta è JSON con schema `zdos.llm.response.v1`, policy esplicita e stato operativo.

## Claim corretto

ZDOS non viene descritto come “superintelligenza”. È un runtime sperimentale con un adapter LLM bounded, auditabile e sostituibile. La qualità dipende dal modello configurato, dal contesto e dai controlli umani.
