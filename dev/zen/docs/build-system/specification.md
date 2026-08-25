# ZEN TOTAL BUILD SYSTEM SPECIFICATION

Il sistema di build di ZEN è modulare e auto-espandibile.

## Struttura
Ogni modulo vive in:
modules/<modulo>/
 ├── build.sh
 ├── src/
 ├── docs/
 ├── tests/
 └── examples/

## Pipeline
1. Build del linguaggio base
2. Build dei moduli
3. Test
4. Documentazione
5. Deploy

## Autodiscovery
Ogni modulo con build.sh viene automaticamente rilevato.
