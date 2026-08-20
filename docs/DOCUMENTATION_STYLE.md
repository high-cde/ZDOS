# 🎨 ZDOS Documentation Style

## Obiettivo

La documentazione ZDOS deve essere tecnica, leggibile e visivamente riconoscibile. Il linguaggio comune dell’ecosistema combina header grafici, badge funzionali, emoji informative, tabelle di stato, diagrammi Mermaid e una dichiarazione esplicita dei limiti.

## Ordine consigliato del README

1. Header grafico o identità visuale.
2. Titolo con una frase che definisce il componente.
3. Badge per CI, target, runtime, stato e licenza.
4. Blockquote con la definizione operativa.
5. Sezione rapida con la prova più breve.
6. Tabella delle funzionalità disponibili e non disponibili.
7. Diagramma dell’architettura quando esistono almeno tre componenti.
8. Setup riproducibile.
9. API, comandi o contratti tecnici.
10. Sicurezza, limiti, troubleshooting e roadmap.
11. Collegamenti agli altri repository dell’ecosistema.
12. Footer visuale coerente.

## Regole visuali

| Elemento | Convenzione |
|---|---|
| Emoji | Una emoji funzionale per sezione; evitare decorazione senza significato |
| Badge | Solo badge verificabili; CI e stato devono puntare a una pagina reale |
| Colori | Viola/indigo per Zlang, blu/verde per ZDOS, ciano/rosso per SEC |
| Grafici | Preferire Mermaid versionato nel repository quando descrive architettura o flussi |
| Tabelle | Usarle per stato, API, componenti e confronti |
| Codice | Ogni comando deve essere copiabile e indicare la directory di esecuzione |
| Stato | Distinguere sempre verificato, sperimentale, parziale e roadmap |

## Regola di verità

Una frase come “supportato”, “operativo” o “production-ready” richiede una prova corrispondente. Quando la prova manca, usare “prototipo”, “laboratorio”, “parziale” o “roadmap”. La documentazione deve spiegare anche ciò che non è implementato.

## Grafici e asset

Gli asset devono essere versionati quando sono parte dell’identità o della spiegazione tecnica. I diagrammi Mermaid devono avere un sorgente leggibile (`.mmd`) e, quando possibile, una preview PNG. I link a immagini esterne devono usare URL stabili e non contenere credenziali.

## Checklist prima del commit

```sh
git diff --check
# verificare che badge e link principali rispondano
# eseguire build/test dichiarati dal README
# controllare che gli esempi siano coerenti con il codice
# confermare che artefatti generati e secret non siano inclusi
git status --short
```
