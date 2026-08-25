/**
 * Coinomi Wallet UI Manager
 * Interfaccia per gestire depositi, prelievi e scambi di crypto
 */

class WalletUI {
  constructor(wallet, ghostnetIdentity) {
    this.wallet = wallet;
    this.ghostnetIdentity = ghostnetIdentity;
    this.currentTab = 'overview';
  }

  /**
   * Renderizza la sezione wallet
   */
  renderWalletSection() {
    const wallet = this.wallet;
    
    if (!wallet.walletAddress) {
      wallet.generateWallet();
    }

    const totalBalance = wallet.getTotalBalance();
    const gntBalance = wallet.walletBalances['GNT'];

    return `
      <div class="wallet-container">
        <div class="wallet-header">
          <h2>💰 COINOMI WALLET</h2>
          <div class="wallet-status">
            <span class="status-badge">🟢 CONNECTED</span>
          </div>
        </div>

        <!-- Wallet Address -->
        <div class="wallet-info-box">
          <div class="info-row">
            <span class="label">Wallet Address:</span>
            <span class="value mono">${wallet.walletAddress}</span>
            <button class="btn-copy" onclick="navigator.clipboard.writeText('${wallet.walletAddress}')">📋</button>
          </div>
          <div class="info-row">
            <span class="label">Public Key:</span>
            <span class="value mono">${wallet.publicKey.substring(0, 20)}...</span>
            <button class="btn-copy" onclick="navigator.clipboard.writeText('${wallet.publicKey}')">📋</button>
          </div>
        </div>

        <!-- Balances Overview -->
        <div class="balances-grid">
          <div class="balance-card">
            <div class="coin-icon">🟢</div>
            <div class="coin-name">GNT</div>
            <div class="coin-balance">${gntBalance.toFixed(2)}</div>
            <div class="coin-usd">≈ $${(gntBalance * 0.85).toFixed(2)}</div>
          </div>
          
          <div class="balance-card">
            <div class="coin-icon">₿</div>
            <div class="coin-name">BTC</div>
            <div class="coin-balance">${wallet.walletBalances['BTC'].toFixed(8)}</div>
            <div class="coin-usd">≈ $${(wallet.walletBalances['BTC'] * 42000).toFixed(2)}</div>
          </div>
          
          <div class="balance-card">
            <div class="coin-icon">Ξ</div>
            <div class="coin-name">ETH</div>
            <div class="coin-balance">${wallet.walletBalances['ETH'].toFixed(6)}</div>
            <div class="coin-usd">≈ $${(wallet.walletBalances['ETH'] * 2400).toFixed(2)}</div>
          </div>
          
          <div class="balance-card">
            <div class="coin-icon">₮</div>
            <div class="coin-name">USDT</div>
            <div class="coin-balance">${wallet.walletBalances['USDT'].toFixed(2)}</div>
            <div class="coin-usd">≈ $${wallet.walletBalances['USDT'].toFixed(2)}</div>
          </div>
          
          <div class="balance-card">
            <div class="coin-icon">✕</div>
            <div class="coin-name">XRP</div>
            <div class="coin-balance">${wallet.walletBalances['XRP'].toFixed(2)}</div>
            <div class="coin-usd">≈ $${(wallet.walletBalances['XRP'] * 0.5).toFixed(2)}</div>
          </div>
          
          <div class="balance-card">
            <div class="coin-icon">Ł</div>
            <div class="coin-name">LTC</div>
            <div class="coin-balance">${wallet.walletBalances['LTC'].toFixed(6)}</div>
            <div class="coin-usd">≈ $${(wallet.walletBalances['LTC'] * 80).toFixed(2)}</div>
          </div>
        </div>

        <!-- Total Balance -->
        <div class="total-balance-box">
          <div class="total-label">TOTAL BALANCE</div>
          <div class="total-amount">$${totalBalance.toFixed(2)}</div>
        </div>

        <!-- Tabs -->
        <div class="wallet-tabs">
          <button class="tab-btn ${this.currentTab === 'overview' ? 'active' : ''}" onclick="walletUI.setTab('overview')">📊 OVERVIEW</button>
          <button class="tab-btn ${this.currentTab === 'deposit' ? 'active' : ''}" onclick="walletUI.setTab('deposit')">📥 DEPOSIT</button>
          <button class="tab-btn ${this.currentTab === 'exchange' ? 'active' : ''}" onclick="walletUI.setTab('exchange')">🔄 EXCHANGE</button>
          <button class="tab-btn ${this.currentTab === 'withdraw' ? 'active' : ''}" onclick="walletUI.setTab('withdraw')">📤 WITHDRAW</button>
          <button class="tab-btn ${this.currentTab === 'history' ? 'active' : ''}" onclick="walletUI.setTab('history')">📋 HISTORY</button>
        </div>

        <!-- Tab Content -->
        <div class="tab-content">
          ${this.currentTab === 'overview' ? this.renderOverviewTab() : ''}
          ${this.currentTab === 'deposit' ? this.renderDepositTab() : ''}
          ${this.currentTab === 'exchange' ? this.renderExchangeTab() : ''}
          ${this.currentTab === 'withdraw' ? this.renderWithdrawTab() : ''}
          ${this.currentTab === 'history' ? this.renderHistoryTab() : ''}
        </div>
      </div>
    `;
  }

  /**
   * Renderizza tab overview
   */
  renderOverviewTab() {
    const wallet = this.wallet;
    const coins = ['BTC', 'ETH', 'USDT', 'XRP', 'LTC', 'GNT'];
    const rates = { 'BTC': 42000, 'ETH': 2400, 'USDT': 1, 'XRP': 0.5, 'LTC': 80, 'GNT': 0.85 };

    let html = '<div class="tab-pane">';
    html += '<h3>Saldi Attuali</h3>';
    html += '<table class="wallet-table"><tr><th>Coin</th><th>Saldo</th><th>Valore USD</th><th>% Portafoglio</th></tr>';

    const total = wallet.getTotalBalance();
    coins.forEach(coin => {
      const balance = wallet.walletBalances[coin];
      const usd = balance * (rates[coin] || 0);
      const percent = total > 0 ? ((usd / total) * 100).toFixed(1) : 0;
      html += `<tr><td>${coin}</td><td>${balance.toFixed(6)}</td><td>$${usd.toFixed(2)}</td><td>${percent}%</td></tr>`;
    });

    html += '</table>';
    html += '</div>';
    return html;
  }

  /**
   * Renderizza tab deposit
   */
  renderDepositTab() {
    const wallet = this.wallet;
    const ghostAddress = this.ghostnetIdentity.ghostAddress;

    let html = '<div class="tab-pane">';
    html += '<h3>Deposita GNT da GhostNet</h3>';
    html += `
      <div class="form-group">
        <label>Importo GNT:</label>
        <input type="number" id="depositAmount" placeholder="Es. 100" min="0" step="0.01">
      </div>
      <div class="form-group">
        <label>Da GhostNet Address:</label>
        <input type="text" value="${ghostAddress}" readonly>
      </div>
      <button class="btn-primary" onclick="walletUI.depositGNT()">💰 DEPOSITA GNT</button>
      <div id="depositResult" class="result-box"></div>
    `;
    html += '</div>';
    return html;
  }

  /**
   * Renderizza tab exchange
   */
  renderExchangeTab() {
    const wallet = this.wallet;
    const coins = ['BTC', 'ETH', 'USDT', 'XRP', 'LTC', 'GNT'];
    const rates = wallet.exchangeRates;

    let html = '<div class="tab-pane">';
    html += '<h3>Scambia Crypto</h3>';
    html += `
      <div class="exchange-container">
        <div class="exchange-from">
          <label>Da:</label>
          <select id="exchangeFromCoin">
            ${coins.map(c => `<option value="${c}">${c}</option>`).join('')}
          </select>
          <input type="number" id="exchangeFromAmount" placeholder="Importo" min="0" step="0.01" onchange="walletUI.updateExchangeRate()">
          <div class="balance-info">Saldo: <span id="balanceFrom">0</span></div>
        </div>
        
        <div class="exchange-arrow">⇄</div>
        
        <div class="exchange-to">
          <label>A:</label>
          <select id="exchangeToCoin">
            ${coins.map(c => `<option value="${c}">${c}</option>`).join('')}
          </select>
          <input type="number" id="exchangeToAmount" placeholder="Importo" readonly>
          <div class="exchange-info">Fee: 0.5% | Rate: <span id="exchangeRate">-</span></div>
        </div>
      </div>
      <button class="btn-primary" onclick="walletUI.exchangeCrypto()">🔄 SCAMBIA</button>
      <div id="exchangeResult" class="result-box"></div>
    `;
    html += '</div>';
    return html;
  }

  /**
   * Renderizza tab withdraw
   */
  renderWithdrawTab() {
    const wallet = this.wallet;
    const coins = ['BTC', 'ETH', 'USDT', 'XRP', 'LTC', 'GNT'];

    let html = '<div class="tab-pane">';
    html += '<h3>Ritira Crypto</h3>';
    html += `
      <div class="form-group">
        <label>Coin:</label>
        <select id="withdrawCoin">
          ${coins.map(c => `<option value="${c}">${c}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label>Importo:</label>
        <input type="number" id="withdrawAmount" placeholder="Importo" min="0" step="0.01">
        <div class="balance-info">Saldo: <span id="withdrawBalance">0</span></div>
      </div>
      <div class="form-group">
        <label>Indirizzo di Ritiro:</label>
        <input type="text" id="withdrawAddress" placeholder="Es. 1A1z7agoat...">
      </div>
      <button class="btn-primary" onclick="walletUI.withdrawCrypto()">📤 RITIRA</button>
      <div id="withdrawResult" class="result-box"></div>
    `;
    html += '</div>';
    return html;
  }

  /**
   * Renderizza tab history
   */
  renderHistoryTab() {
    const wallet = this.wallet;
    const transactions = wallet.getTransactionHistory(20);

    let html = '<div class="tab-pane">';
    html += '<h3>Cronologia Transazioni</h3>';
    
    if (transactions.length === 0) {
      html += '<p class="empty-state">Nessuna transazione</p>';
    } else {
      html += '<table class="transaction-table"><tr><th>Tipo</th><th>Coin</th><th>Importo</th><th>Data</th><th>Hash</th></tr>';
      transactions.forEach(tx => {
        const coin = tx.coin || `${tx.from} → ${tx.to}`;
        const amount = tx.amount || `${tx.fromAmount} → ${tx.toAmount}`;
        html += `<tr><td>${tx.type}</td><td>${coin}</td><td>${amount}</td><td>${new Date(tx.timestamp).toLocaleString()}</td><td class="mono">${tx.hash.substring(0, 16)}...</td></tr>`;
      });
      html += '</table>';
    }
    html += '</div>';
    return html;
  }

  /**
   * Cambia tab
   */
  setTab(tab) {
    this.currentTab = tab;
    this.updateWalletDisplay();
  }

  /**
   * Deposita GNT
   */
  depositGNT() {
    const amount = parseFloat(document.getElementById('depositAmount').value);
    if (!amount || amount <= 0) {
      document.getElementById('depositResult').innerHTML = '<div class="error">Importo invalido</div>';
      return;
    }

    const result = this.wallet.depositGNT(amount, this.ghostnetIdentity.ghostAddress);
    const resultDiv = document.getElementById('depositResult');
    
    if (result.success) {
      resultDiv.innerHTML = `
        <div class="success">
          ✓ Deposito confermato!<br>
          Importo: ${amount} GNT<br>
          Nuovo saldo: ${result.newBalance.toFixed(2)} GNT<br>
          Hash: ${result.transaction.hash.substring(0, 32)}...
        </div>
      `;
      document.getElementById('depositAmount').value = '';
    } else {
      resultDiv.innerHTML = `<div class="error">✗ ${result.error}</div>`;
    }
    
    this.updateWalletDisplay();
  }

  /**
   * Aggiorna il tasso di cambio
   */
  updateExchangeRate() {
    const fromCoin = document.getElementById('exchangeFromCoin').value;
    const toCoin = document.getElementById('exchangeToCoin').value;
    const fromAmount = parseFloat(document.getElementById('exchangeFromAmount').value) || 0;

    if (fromAmount <= 0) {
      document.getElementById('exchangeToAmount').value = '';
      return;
    }

    const rateFrom = this.wallet.exchangeRates[fromCoin];
    const rateTo = this.wallet.exchangeRates[toCoin];
    const toAmount = (fromAmount * rateFrom) / rateTo * 0.995; // 0.5% fee

    document.getElementById('exchangeToAmount').value = toAmount.toFixed(6);
    document.getElementById('exchangeRate').textContent = `1 ${fromCoin} = ${(rateFrom / rateTo).toFixed(6)} ${toCoin}`;
    document.getElementById('balanceFrom').textContent = this.wallet.walletBalances[fromCoin].toFixed(6);
  }

  /**
   * Scambia crypto
   */
  exchangeCrypto() {
    const fromCoin = document.getElementById('exchangeFromCoin').value;
    const toCoin = document.getElementById('exchangeToCoin').value;
    const fromAmount = parseFloat(document.getElementById('exchangeFromAmount').value);

    if (!fromAmount || fromAmount <= 0) {
      document.getElementById('exchangeResult').innerHTML = '<div class="error">Importo invalido</div>';
      return;
    }

    const result = this.wallet.exchangeGNT(fromAmount, fromCoin, toCoin);
    const resultDiv = document.getElementById('exchangeResult');

    if (result.success) {
      resultDiv.innerHTML = `
        <div class="success">
          ✓ Scambio completato!<br>
          ${fromAmount} ${fromCoin} → ${result.toAmount.toFixed(6)} ${toCoin}<br>
          Fee: ${result.fee.toFixed(6)} ${toCoin}
        </div>
      `;
      document.getElementById('exchangeFromAmount').value = '';
      document.getElementById('exchangeToAmount').value = '';
    } else {
      resultDiv.innerHTML = `<div class="error">✗ ${result.error}</div>`;
    }

    this.updateWalletDisplay();
  }

  /**
   * Ritira crypto
   */
  withdrawCrypto() {
    const coin = document.getElementById('withdrawCoin').value;
    const amount = parseFloat(document.getElementById('withdrawAmount').value);
    const address = document.getElementById('withdrawAddress').value;

    if (!amount || amount <= 0) {
      document.getElementById('withdrawResult').innerHTML = '<div class="error">Importo invalido</div>';
      return;
    }

    if (!address) {
      document.getElementById('withdrawResult').innerHTML = '<div class="error">Indirizzo non valido</div>';
      return;
    }

    const result = this.wallet.withdrawCrypto(coin, amount, address);
    const resultDiv = document.getElementById('withdrawResult');

    if (result.success) {
      resultDiv.innerHTML = `
        <div class="success">
          ✓ Prelievo in elaborazione!<br>
          Importo: ${amount} ${coin}<br>
          Fee: ${result.transaction.fee} ${coin}<br>
          Status: ${result.transaction.status}
        </div>
      `;
      document.getElementById('withdrawAmount').value = '';
      document.getElementById('withdrawAddress').value = '';
    } else {
      resultDiv.innerHTML = `<div class="error">✗ ${result.error}</div>`;
    }

    this.updateWalletDisplay();
  }

  /**
   * Aggiorna il display del wallet
   */
  updateWalletDisplay() {
    const walletContainer = document.querySelector('.wallet-container');
    if (walletContainer) {
      walletContainer.innerHTML = this.renderWalletSection();
    }
  }
}
