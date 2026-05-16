/**
 * X-ZDOS Advanced UI Module
 * Gestisce Discord integration e GNT Price display
 */

class AdvancedUI {
  constructor() {
    this.init();
  }

  init() {
    this.setupDiscordSection();
    this.setupPriceDisplay();
    this.setupMultiDeviceSync();
  }

  // Setup sezione Discord
  setupDiscordSection() {
    const walletSection = document.getElementById('wallet');
    if (!walletSection) return;

    const discordDiv = document.createElement('div');
    discordDiv.className = 'card';
    discordDiv.style.marginTop = '20px';
    discordDiv.innerHTML = `
      <h3>🔗 Discord Integration</h3>
      <input type="text" id="discordWebhook" placeholder="Incolla Discord Webhook URL" style="margin: 10px 0;">
      <button onclick="advancedUI.connectDiscord()">Connetti Discord</button>
      <div id="discordStatus" style="margin-top: 10px; color: #FF00FF;"></div>
    `;
    walletSection.appendChild(discordDiv);
  }

  // Connetti Discord
  async connectDiscord() {
    const webhookUrl = document.getElementById('discordWebhook').value.trim();
    if (!webhookUrl) {
      alert('Inserisci un Discord Webhook URL valido');
      return;
    }

    const result = await discordIntegration.connectWithWebhook(webhookUrl);
    const statusDiv = document.getElementById('discordStatus');
    
    if (result.success) {
      statusDiv.textContent = '✓ Discord connesso!';
      statusDiv.style.color = '#00FF00';
      
      // Test messaggio
      await discordIntegration.sendToDiscord('general', 'X-ZDOS connesso a Discord!', 'System');
    } else {
      statusDiv.textContent = `✗ Errore: ${result.error}`;
      statusDiv.style.color = '#FF0000';
    }
  }

  // Setup display prezzo GNT
  setupPriceDisplay() {
    const walletSection = document.getElementById('wallet');
    if (!walletSection) return;

    const priceDiv = document.createElement('div');
    priceDiv.className = 'card';
    priceDiv.style.marginTop = '20px';
    priceDiv.innerHTML = `
      <h3>💹 GNT Price</h3>
      <div id="priceDisplay" style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; margin: 10px 0;">
        <div><strong>USD:</strong> <span id="priceUSD">$0.00</span></div>
        <div><strong>BTC:</strong> <span id="priceBTC">0.00000000</span></div>
        <div><strong>ETH:</strong> <span id="priceETH">0.000000</span></div>
        <div><strong>24h Change:</strong> <span id="priceChange">0.00%</span></div>
        <div><strong>Market Cap:</strong> <span id="marketCap">$0</span></div>
        <div><strong>Volume 24h:</strong> <span id="volume24h">$0</span></div>
      </div>
      <button onclick="advancedUI.updatePriceDisplay()">Aggiorna Prezzo</button>
    `;
    walletSection.appendChild(priceDiv);

    // Registra listener per aggiornamenti prezzo
    gntValue.onPriceChange((priceInfo) => {
      this.updatePriceDisplay(priceInfo);
    });

    // Aggiorna subito
    this.updatePriceDisplay();
  }

  // Aggiorna display prezzo
  updatePriceDisplay(priceInfo = null) {
    const info = priceInfo || gntValue.getPriceInfo();
    
    document.getElementById('priceUSD').textContent = `$${info.priceUSD}`;
    document.getElementById('priceBTC').textContent = info.priceBTC;
    document.getElementById('priceETH').textContent = info.priceETH;
    
    const changeEl = document.getElementById('priceChange');
    const changeValue = parseFloat(info.change24h);
    changeEl.textContent = `${changeValue > 0 ? '+' : ''}${info.change24h}%`;
    changeEl.style.color = changeValue > 0 ? '#00FF00' : '#FF0000';
    
    document.getElementById('marketCap').textContent = info.marketCap;
    document.getElementById('volume24h').textContent = info.volume24h;
  }

  // Setup sincronizzazione multi-dispositivo
  setupMultiDeviceSync() {
    // Ascolta cambiamenti da altri dispositivi
    multiDeviceSync.onSync((data) => {
      if (data.type === 'message') {
        this.handleSyncedMessage(data);
      } else if (data.type === 'channel-update') {
        this.handleSyncedChannel(data);
      }
    });

    console.log('✓ Multi-device sync attivato');
  }

  // Gestisci messaggio sincronizzato
  handleSyncedMessage(msg) {
    const chatMessages = document.getElementById('chatMessages');
    if (!chatMessages) return;

    const msgEl = document.createElement('div');
    msgEl.className = 'message';
    const time = new Date(msg.timestamp).toLocaleTimeString();
    msgEl.textContent = `[${time}] ${msg.message}`;
    msgEl.style.opacity = '0.7'; // Differenzia dai messaggi locali
    chatMessages.appendChild(msgEl);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  // Gestisci canale sincronizzato
  handleSyncedChannel(data) {
    const channelsList = document.getElementById('channelsList');
    if (!channelsList) return;

    // Aggiorna lista canali
    const existingChannel = Array.from(channelsList.children).find(
      el => el.textContent.includes(data.name)
    );

    if (!existingChannel) {
      const item = document.createElement('div');
      item.className = 'card';
      item.textContent = `📡 ${data.name} (${data.members || 0} members)`;
      channelsList.appendChild(item);
    }
  }

  // Invia messaggio con sincronizzazione
  sendSyncedMessage(channel, message) {
    // Invia localmente
    this.sendLocalMessage(message);

    // Sincronizza su altri dispositivi
    multiDeviceSync.broadcastMessage(channel, message);

    // Invia a Discord se connesso
    if (discordIntegration.isConnected) {
      discordIntegration.sendToDiscord(channel, message, 'X-ZDOS User');
    }
  }

  // Invia messaggio localmente
  sendLocalMessage(message) {
    const chatMessages = document.getElementById('chatMessages');
    if (!chatMessages) return;

    const msgEl = document.createElement('div');
    msgEl.className = 'message';
    const time = new Date().toLocaleTimeString();
    msgEl.textContent = `[${time}] ${message}`;
    chatMessages.appendChild(msgEl);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  // Calcola valore portafoglio
  calculatePortfolioValue(gntAmount) {
    return gntValue.calculatePortfolioValue(gntAmount);
  }

  // Converti GNT a altre valute
  convertGNT(amount, currency) {
    return gntValue.convertGNT(amount, currency);
  }
}

// Esporta singleton
const advancedUI = new AdvancedUI();
