# Z-X SOLANA — App Android (Mobile)

Versione mobile del Super System ZDOS / Z-X Solana.

## Caratteristiche
- WebView a schermo intero
- Carica https://high-cde.github.io/
- Supporto JavaScript e DOM Storage
- Navigazione indietro con tasto back
- Tema scuro coerente

## Come compilare
1. Apri la cartella `android/` con Android Studio
2. Sync Gradle
3. Build → Build Bundle(s) / APK(s) → Build APK(s)

## Note
- Se GitHub Pages non è attivo, modifica `MainActivity.java` e carica l'HTML locale da `assets/index.html`.
- Permessi Internet già dichiarati.
- Livello: laboratorio M1 (versione base WebView).

## Prossimi passi possibili
- Integrazione wallet Phantom / Solana Mobile
- Notifiche per quorum e governance
- Modalità offline con HTML embedded
