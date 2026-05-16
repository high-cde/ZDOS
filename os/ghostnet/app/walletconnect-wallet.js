/**
 * WalletConnect + Phantom Wallet Integration - GRATUITO
 * Supporta: Multi-chain, Multi-wallet
 * Zero fee - Usa RPC pubblici
 */

class UniversalWallet {
  constructor() {
    this.wallet = null;
    this.walletType = null; // 'metamask', 'walletconnect', 'phantom'
    this.account = null;
    this.chainId = null;
    this.balance = {};
    this.transactions = [];
    this.supportedWallets = ['MetaMask', 'WalletConnect', 'Phantom', 'Coinbase'];
  }

  async detectWallets() {
    const available = [];

    if (typeof window.ethereum !== 'undefined') {
      available.push({
        name: 'MetaMask',
        icon: '🦊',
        provider: window.ethereum,
        type: 'metamask'
      });
    }

    if (typeof window.solana !== 'undefined' && window.solana.isPhantom) {
      available.push({
        name: 'Phantom',
        icon: '👻',
        provider: window.solana,
        type: 'phantom'
      });
    }

    // WalletConnect - sempre disponibile
    available.push({
      name: 'WalletConnect',
      icon: '🔗',
      provider: null,
      type: 'walletconnect',
      url: 'https://walletconnect.org'
    });

    return available;
  }

  async connectMetaMask() {
    if (typeof window.ethereum === 'undefined') {
      return { success: false, error: 'MetaMask non installato' };
    }

    try {
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      this.account = accounts[0];
      this.walletType = 'metamask';
      this.wallet = window.ethereum;

      const chainId = await window.ethereum.request({ method: 'eth_chainId' });
      this.chainId = chainId;

      return {
        success: true,
        wallet: 'MetaMask',
        account: this.account,
        chainId: chainId
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async connectPhantom() {
    if (typeof window.solana === 'undefined' || !window.solana.isPhantom) {
      return { success: false, error: 'Phantom non installato' };
    }

    try {
      const response = await window.solana.connect();
      this.account = response.publicKey.toString();
      this.walletType = 'phantom';
      this.wallet = window.solana;
      this.chainId = 'solana-mainnet';

      return {
        success: true,
        wallet: 'Phantom',
        account: this.account,
        chainId: this.chainId
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async connectWalletConnect() {
    // Implementazione semplificata - in produzione usare @walletconnect/web3modal
    const deepLink = 'https://walletconnect.org/apps';
    window.open(deepLink, '_blank');

    return {
      success: true,
      message: 'Apri WalletConnect e scansiona il QR code',
      url: deepLink
    };
  }

  async connect(walletType) {
    switch (walletType.toLowerCase()) {
      case 'metamask':
        return await this.connectMetaMask();
      case 'phantom':
        return await this.connectPhantom();
      case 'walletconnect':
        return await this.connectWalletConnect();
      default:
        return { success: false, error: 'Wallet non supportato' };
    }
  }

  async disconnect() {
    this.wallet = null;
    this.account = null;
    this.walletType = null;
    return { success: true, message: 'Disconnesso' };
  }

  async getBalance(token = 'native') {
    if (!this.account) return { success: false, error: 'Non connesso' };

    try {
      if (this.walletType === 'metamask') {
        const balance = await this.wallet.request({
          method: 'eth_getBalance',
          params: [this.account, 'latest']
        });
        const ethBalance = parseInt(balance, 16) / 1e18;
        this.balance[token] = ethBalance;
        return { success: true, balance: ethBalance, token: 'ETH' };
      } else if (this.walletType === 'phantom') {
        // Phantom - Solana balance
        const balance = Math.random() * 100; // Simulazione
        this.balance[token] = balance;
        return { success: true, balance: balance, token: 'SOL' };
      }
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async sendTransaction(to, amount, token = 'native') {
    if (!this.account) return { success: false, error: 'Non connesso' };

    try {
      if (this.walletType === 'metamask') {
        const tx = {
          from: this.account,
          to: to,
          value: (amount * 1e18).toString(16),
          gas: '21000'
        };

        const txHash = await this.wallet.request({
          method: 'eth_sendTransaction',
          params: [tx]
        });

        this.transactions.push({
          id: txHash,
          from: this.account,
          to: to,
          amount: amount,
          token: token,
          timestamp: Date.now(),
          status: 'PENDING'
        });

        return {
          success: true,
          txHash: txHash,
          explorerUrl: `https://etherscan.io/tx/${txHash}`
        };
      }
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  renderWalletSelector() {
    return `
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; padding: 20px;">
        <button onclick="universalWallet.connect('metamask')" style="background: #ff6b35; color: white; border: none; padding: 15px; border-radius: 4px; cursor: pointer; font-weight: bold;">
          🦊 MetaMask
        </button>
        <button onclick="universalWallet.connect('phantom')" style="background: #14f195; color: #0a0e27; border: none; padding: 15px; border-radius: 4px; cursor: pointer; font-weight: bold;">
          👻 Phantom
        </button>
        <button onclick="universalWallet.connect('walletconnect')" style="background: #3b99fc; color: white; border: none; padding: 15px; border-radius: 4px; cursor: pointer; font-weight: bold; grid-column: 1 / -1;">
          🔗 WalletConnect
        </button>
      </div>
    `;
  }

  getStatus() {
    return {
      connected: this.account !== null,
      wallet: this.walletType,
      account: this.account,
      chainId: this.chainId,
      balance: this.balance
    };
  }
}

// Export
if (typeof module !== 'undefined' && module.exports) {
  module.exports = UniversalWallet;
}
