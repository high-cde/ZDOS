# 💰 Coinomi Wallet Integration Guide

## Overview

X-ZDOS Quantum GhostNet OS ora include un **wallet Coinomi completo** che permette di:
- 💳 Depositare GNT da GhostNet
- 🔄 Scambiare GNT con crypto reali (BTC, ETH, USDT, XRP, LTC)
- 📤 Ritirare crypto verso indirizzi esterni
- 📊 Tracciare transazioni e saldi
- 💾 Backup e restore del wallet

## Features

### 1. **Registrazione Automatica**
- Genera wallet address unico al primo accesso
- Public key crittografica
- Indirizzi di deposit per ogni coin supportato
- Salvataggio automatico in localStorage

### 2. **Deposit GNT**
- Deposita GNT da GhostNet Identity
- Conferma istantanea
- Saldo aggiornato in tempo reale
- Cronologia transazioni

### 3. **Exchange Crypto**
- Tassi di cambio reali (simulati)
- Fee automatica 0.5%
- Supporta: BTC, ETH, USDT, XRP, LTC, GNT
- Calcolo istantaneo dell'importo ricevuto

### 4. **Withdraw**
- Ritira verso qualsiasi indirizzo
- Fee di rete automatica
- Status transazione (PENDING/CONFIRMED)
- Cronologia completa

### 5. **Dashboard**
- Saldi in tempo reale
- Valore totale in USD
- Percentuale portafoglio
- Cronologia transazioni

## Supported Coins

| Coin | Symbol | Exchange Rate |
|------|--------|---------------|
| GhostNet Token | GNT | 1.0 |
| Bitcoin | BTC | 0.000024 |
| Ethereum | ETH | 0.00035 |
| Tether | USDT | 0.85 |
| Ripple | XRP | 2.1 |
| Litecoin | LTC | 0.0042 |

## API Reference

### CoinomiWallet Class

```javascript
// Inizializza wallet
const wallet = new CoinomiWallet();

// Genera nuovo wallet
wallet.generateWallet();
// Returns: { address, publicKey, depositAddresses }

// Deposita GNT
wallet.depositGNT(amount, ghostAddress);
// Returns: { success, transaction, newBalance }

// Scambia crypto
wallet.exchangeGNT(fromAmount, fromCoin, toCoin);
// Returns: { success, transaction, toAmount, fee }

// Ritira crypto
wallet.withdrawCrypto(coin, amount, withdrawAddress);
// Returns: { success, transaction, newBalance }

// Ottieni saldo totale in USD
wallet.getTotalBalance();
// Returns: number (USD value)

// Ottieni cronologia transazioni
wallet.getTransactionHistory(limit);
// Returns: array of transactions

// Esporta wallet (backup)
wallet.exportWallet();
// Returns: { walletAddress, publicKey, balances, transactions }

// Importa wallet (restore)
wallet.importWallet(data);
// Returns: { success, message }

// Resetta wallet
wallet.resetWallet();
```

## Usage Examples

### Deposita 100 GNT

```javascript
const wallet = new CoinomiWallet();
const result = wallet.depositGNT(100, 'GHOST-1234567890ABCDEF');

if (result.success) {
  console.log('Depositato:', result.transaction);
  console.log('Nuovo saldo:', result.newBalance, 'GNT');
}
```

### Scambia 50 GNT a BTC

```javascript
const result = wallet.exchangeGNT(50, 'GNT', 'BTC');

if (result.success) {
  console.log('Ricevuto:', result.toAmount, 'BTC');
  console.log('Fee:', result.fee, 'BTC');
}
```

### Ritira 0.01 BTC

```javascript
const result = wallet.withdrawCrypto('BTC', 0.01, '1A1z7agoat...');

if (result.success) {
  console.log('Prelievo in elaborazione');
  console.log('Hash:', result.transaction.hash);
}
```

### Esporta Wallet (Backup)

```javascript
const backup = wallet.exportWallet();
localStorage.setItem('wallet_backup', JSON.stringify(backup));
```

### Importa Wallet (Restore)

```javascript
const backup = JSON.parse(localStorage.getItem('wallet_backup'));
wallet.importWallet(backup);
```

## Data Storage

Tutti i dati del wallet sono salvati in **localStorage** con chiave: `coinomi_wallet`

Struttura:
```json
{
  "walletAddress": "0x...",
  "publicKey": "...",
  "walletBalances": {
    "BTC": 0.001,
    "ETH": 0.05,
    "USDT": 100,
    "XRP": 500,
    "LTC": 1,
    "GNT": 1000
  },
  "transactions": [...],
  "depositAddresses": {...},
  "withdrawAddresses": {...}
}
```

## Security Notes

⚠️ **Importante**: Questo è un wallet **simulato** per demo. Per uso in produzione:

1. **Non usare localStorage** - Usare secure storage (Keychain, Keystore)
2. **Implementare crittografia** - Proteggere le private keys
3. **Validare indirizzi** - Verificare formato indirizzi
4. **Usare API reali** - Integrare Coinomi API ufficiale
5. **Implementare 2FA** - Autenticazione a due fattori
6. **Audit di sicurezza** - Far controllare il codice

## Testing

Accedi a: `https://your-domain/test-wallet.html`

Funzionalità testate:
- ✅ Generazione wallet
- ✅ Deposit GNT
- ✅ Exchange crypto
- ✅ Calcolo saldi
- ✅ Persistenza localStorage

## Roadmap

- [ ] Integrazione Coinomi API reale
- [ ] QR code per deposit/withdraw
- [ ] Multi-signature wallet
- [ ] Hardware wallet support
- [ ] Staking rewards
- [ ] DeFi integration

## Support

Per problemi o domande:
1. Leggi questa guida
2. Controlla la console browser (F12)
3. Verifica localStorage: `localStorage.getItem('coinomi_wallet')`
4. Crea issue su GitHub

## License

MIT License - Vedi LICENSE file
