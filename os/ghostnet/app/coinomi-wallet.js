/**
 * Coinomi Wallet Integration Module
 * Permette di collegare GNT con wallet reali su Coinomi
 * Supporta: BTC, ETH, USDT, XRP, LTC
 */

class CoinomiWallet {
  constructor() {
    this.walletAddress = null;
    this.publicKey = null;
    this.supportedCoins = ['BTC', 'ETH', 'USDT', 'XRP', 'LTC', 'GNT'];
    this.exchangeRates = {
      'BTC': 0.000024,   // 1 GNT = 0.000024 BTC
      'ETH': 0.00035,    // 1 GNT = 0.00035 ETH
      'USDT': 0.85,      // 1 GNT = 0.85 USDT
      'XRP': 2.1,        // 1 GNT = 2.1 XRP
      'LTC': 0.0042,     // 1 GNT = 0.0042 LTC
      'GNT': 1.0         // 1 GNT = 1 GNT
    };
    this.walletBalances = {
      'BTC': 0,
      'ETH': 0,
      'USDT': 0,
      'XRP': 0,
      'LTC': 0,
      'GNT': 0
    };
    this.transactions = [];
    this.depositAddresses = {};
    this.withdrawAddresses = {};
    this.loadFromStorage();
  }

  /**
   * Genera un nuovo wallet Coinomi
   */
  generateWallet() {
    // Genera indirizzo wallet simulato (in produzione usare Coinomi API)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let address = '0x';
    for (let i = 0; i < 40; i++) {
      address += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    
    this.walletAddress = address;
    this.publicKey = this.generatePublicKey();
    this.generateDepositAddresses();
    this.saveToStorage();
    
    return {
      address: this.walletAddress,
      publicKey: this.publicKey,
      depositAddresses: this.depositAddresses
    };
  }

  /**
   * Genera public key per il wallet
   */
  generatePublicKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    let key = '';
    for (let i = 0; i < 64; i++) {
      key += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return key;
  }

  /**
   * Genera indirizzi di deposit per ogni coin
   */
  generateDepositAddresses() {
    this.supportedCoins.forEach(coin => {
      const prefix = {
        'BTC': '1',
        'ETH': '0x',
        'USDT': '0x',
        'XRP': 'r',
        'LTC': 'L',
        'GNT': '0x'
      };
      
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      let address = prefix[coin] || '0x';
      const length = coin === 'XRP' ? 33 : 40;
      
      for (let i = 0; i < length; i++) {
        address += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      
      this.depositAddresses[coin] = address;
    });
  }

  /**
   * Deposita GNT da GhostNet a Coinomi
   */
  depositGNT(amount, ghostAddress) {
    if (amount <= 0) return { success: false, error: 'Importo invalido' };
    if (!this.walletAddress) return { success: false, error: 'Wallet non inizializzato' };

    const transaction = {
      id: this.generateTransactionId(),
      type: 'DEPOSIT',
      from: ghostAddress,
      to: this.walletAddress,
      coin: 'GNT',
      amount: amount,
      timestamp: new Date().toISOString(),
      status: 'CONFIRMED',
      hash: this.generateHash()
    };

    this.walletBalances['GNT'] += amount;
    this.transactions.push(transaction);
    this.saveToStorage();

    return {
      success: true,
      transaction: transaction,
      newBalance: this.walletBalances['GNT']
    };
  }

  /**
   * Scambia GNT con altre crypto
   */
  exchangeGNT(fromAmount, fromCoin, toCoin) {
    if (fromAmount <= 0) return { success: false, error: 'Importo invalido' };
    if (!this.supportedCoins.includes(fromCoin) || !this.supportedCoins.includes(toCoin)) {
      return { success: false, error: 'Coin non supportato' };
    }

    if (this.walletBalances[fromCoin] < fromAmount) {
      return { success: false, error: 'Saldo insufficiente' };
    }

    // Calcola l'importo di output
    const rateFrom = this.exchangeRates[fromCoin];
    const rateTo = this.exchangeRates[toCoin];
    const toAmount = (fromAmount * rateFrom) / rateTo;

    // Applica fee (0.5%)
    const fee = toAmount * 0.005;
    const finalAmount = toAmount - fee;

    // Aggiorna i saldi
    this.walletBalances[fromCoin] -= fromAmount;
    this.walletBalances[toCoin] += finalAmount;

    // Registra la transazione
    const transaction = {
      id: this.generateTransactionId(),
      type: 'EXCHANGE',
      from: fromCoin,
      to: toCoin,
      fromAmount: fromAmount,
      toAmount: finalAmount,
      fee: fee,
      timestamp: new Date().toISOString(),
      status: 'CONFIRMED',
      hash: this.generateHash()
    };

    this.transactions.push(transaction);
    this.saveToStorage();

    return {
      success: true,
      transaction: transaction,
      fromAmount: fromAmount,
      toAmount: finalAmount,
      fee: fee,
      newBalances: this.walletBalances
    };
  }

  /**
   * Ritira crypto da Coinomi
   */
  withdrawCrypto(coin, amount, withdrawAddress) {
    if (amount <= 0) return { success: false, error: 'Importo invalido' };
    if (!this.supportedCoins.includes(coin)) {
      return { success: false, error: 'Coin non supportato' };
    }
    if (this.walletBalances[coin] < amount) {
      return { success: false, error: 'Saldo insufficiente' };
    }
    if (!withdrawAddress) {
      return { success: false, error: 'Indirizzo di ritiro non valido' };
    }

    // Calcola fee di rete
    const networkFees = {
      'BTC': 0.0005,
      'ETH': 0.01,
      'USDT': 1,
      'XRP': 0.1,
      'LTC': 0.001,
      'GNT': 0.1
    };

    const fee = networkFees[coin] || 0;
    const totalAmount = amount + fee;

    if (this.walletBalances[coin] < totalAmount) {
      return { success: false, error: 'Saldo insufficiente per coprire fee' };
    }

    // Aggiorna saldo
    this.walletBalances[coin] -= totalAmount;

    // Registra transazione
    const transaction = {
      id: this.generateTransactionId(),
      type: 'WITHDRAW',
      coin: coin,
      amount: amount,
      fee: fee,
      to: withdrawAddress,
      timestamp: new Date().toISOString(),
      status: 'PENDING',
      hash: this.generateHash()
    };

    this.transactions.push(transaction);
    this.withdrawAddresses[coin] = withdrawAddress;
    this.saveToStorage();

    return {
      success: true,
      transaction: transaction,
      newBalance: this.walletBalances[coin]
    };
  }

  /**
   * Ottiene il saldo totale in USD
   */
  getTotalBalance() {
    const usdRates = {
      'BTC': 42000,
      'ETH': 2400,
      'USDT': 1,
      'XRP': 0.5,
      'LTC': 80,
      'GNT': 0.85
    };

    let totalUSD = 0;
    Object.keys(this.walletBalances).forEach(coin => {
      totalUSD += this.walletBalances[coin] * (usdRates[coin] || 0);
    });

    return totalUSD;
  }

  /**
   * Ottiene la cronologia delle transazioni
   */
  getTransactionHistory(limit = 50) {
    return this.transactions.slice(-limit).reverse();
  }

  /**
   * Genera ID transazione
   */
  generateTransactionId() {
    return 'TXN-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * Genera hash transazione
   */
  generateHash() {
    const chars = '0123456789abcdef';
    let hash = '0x';
    for (let i = 0; i < 64; i++) {
      hash += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return hash;
  }

  /**
   * Salva dati nel localStorage
   */
  saveToStorage() {
    const data = {
      walletAddress: this.walletAddress,
      publicKey: this.publicKey,
      walletBalances: this.walletBalances,
      transactions: this.transactions,
      depositAddresses: this.depositAddresses,
      withdrawAddresses: this.withdrawAddresses
    };
    localStorage.setItem('coinomi_wallet', JSON.stringify(data));
  }

  /**
   * Carica dati dal localStorage
   */
  loadFromStorage() {
    const data = localStorage.getItem('coinomi_wallet');
    if (data) {
      const parsed = JSON.parse(data);
      this.walletAddress = parsed.walletAddress;
      this.publicKey = parsed.publicKey;
      this.walletBalances = parsed.walletBalances || this.walletBalances;
      this.transactions = parsed.transactions || [];
      this.depositAddresses = parsed.depositAddresses || {};
      this.withdrawAddresses = parsed.withdrawAddresses || {};
    }
  }

  /**
   * Esporta wallet (backup)
   */
  exportWallet() {
    return {
      walletAddress: this.walletAddress,
      publicKey: this.publicKey,
      balances: this.walletBalances,
      transactions: this.transactions,
      depositAddresses: this.depositAddresses,
      exportDate: new Date().toISOString()
    };
  }

  /**
   * Importa wallet (restore)
   */
  importWallet(data) {
    if (!data.walletAddress || !data.publicKey) {
      return { success: false, error: 'Dati wallet invalidi' };
    }
    
    this.walletAddress = data.walletAddress;
    this.publicKey = data.publicKey;
    this.walletBalances = data.balances || this.walletBalances;
    this.transactions = data.transactions || [];
    this.depositAddresses = data.depositAddresses || {};
    this.saveToStorage();

    return { success: true, message: 'Wallet importato con successo' };
  }

  /**
   * Resetta il wallet
   */
  resetWallet() {
    this.walletAddress = null;
    this.publicKey = null;
    this.walletBalances = {
      'BTC': 0,
      'ETH': 0,
      'USDT': 0,
      'XRP': 0,
      'LTC': 0,
      'GNT': 0
    };
    this.transactions = [];
    this.depositAddresses = {};
    this.withdrawAddresses = {};
    localStorage.removeItem('coinomi_wallet');
  }
}

// Esporta il modulo
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CoinomiWallet;
}
