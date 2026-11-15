# Z-X SOLANA — App Android (Mobile)

Versione mobile del Super System ZDOS / Z-X Solana con supporto wallet Solana.

## Caratteristiche
- WebView a schermo intero
- Integrazione wallet Phantom tramite deep link
- Interfaccia JavaScript `AndroidWallet`
- Visualizzazione wallet connesso
- Tema scuro coerente

## Come funziona il wallet
1. L'app espone `AndroidWallet.connectPhantom()`
2. Apre Phantom tramite deep link
3. Al ritorno riceve la public key
4. La inietta nella pagina web tramite `window.onWalletConnected(publicKey)`

## Come compilare
1. Apri la cartella `android/` con Android Studio
2. Sync Gradle
3. Build APK

## Note
- Richiede Phantom installato sul dispositivo
- Livello: laboratorio M1
- Per uso reale serve firma delle transazioni (da implementare in seguito)

## Prossimi passi possibili
- Firma transazioni $DSN
- Lettura balance reale
- Supporto altri wallet (Solflare, ecc.)
