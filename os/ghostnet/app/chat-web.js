/**
 * X-ZDOS Chat Web - Chat Anonima Funzionante
 * Supporta: Messaggi in tempo reale, Canali, Crittografia
 */

class ChatWeb {
  constructor() {
    this.messages = [];
    this.channels = [
      { id: 'general', name: '🌐 General', members: 0 },
      { id: 'ghostnet', name: '👻 GhostNet', members: 0 },
      { id: 'anonymous', name: '🔐 Anonymous', members: 0 },
      { id: 'trading', name: '💰 Trading', members: 0 },
      { id: 'zdos', name: '⚡ X-ZDOS', members: 0 }
    ];
    this.currentChannel = 'general';
    this.username = 'anon_' + Math.random().toString(36).substr(2, 8);
    this.load();
    this.setupBroadcast();
  }

  setupBroadcast() {
    // Ascolta cambiamenti in altri tab
    window.addEventListener('storage', (e) => {
      if (e.key === 'chat_messages') {
        this.load();
        this.onMessagesUpdated();
      }
    });
  }

  load() {
    const stored = localStorage.getItem('chat_messages');
    if (stored) {
      try {
        this.messages = JSON.parse(stored);
      } catch (e) {
        this.messages = [];
      }
    }
  }

  save() {
    localStorage.setItem('chat_messages', JSON.stringify(this.messages));
    // Trigger evento per altri tab
    window.dispatchEvent(new StorageEvent('storage', {
      key: 'chat_messages',
      newValue: JSON.stringify(this.messages)
    }));
  }

  sendMessage(text) {
    if (!text || text.trim().length === 0) {
      return { success: false, error: 'Messaggio vuoto' };
    }

    const message = {
      id: Math.random().toString(36).substr(2, 9),
      channel: this.currentChannel,
      text: text.trim(),
      sender: this.username,
      timestamp: Date.now(),
      encrypted: this.encryptMessage(text),
      ttl: 3600000 // 1 ora
    };

    this.messages.push(message);
    this.save();

    return {
      success: true,
      message: message,
      count: this.getChannelMessages().length
    };
  }

  encryptMessage(text) {
    // XOR encryption semplice
    let encrypted = '';
    for (let i = 0; i < text.length; i++) {
      encrypted += String.fromCharCode(text.charCodeAt(i) ^ 42);
    }
    return btoa(encrypted);
  }

  decryptMessage(encrypted) {
    try {
      const decrypted = atob(encrypted);
      let text = '';
      for (let i = 0; i < decrypted.length; i++) {
        text += String.fromCharCode(decrypted.charCodeAt(i) ^ 42);
      }
      return text;
    } catch (e) {
      return '[Crittografato]';
    }
  }

  getChannelMessages() {
    return this.messages.filter(m => {
      const isCurrentChannel = m.channel === this.currentChannel;
      const isNotExpired = Date.now() - m.timestamp < m.ttl;
      return isCurrentChannel && isNotExpired;
    }).sort((a, b) => a.timestamp - b.timestamp);
  }

  switchChannel(channelId) {
    this.currentChannel = channelId;
    return { success: true, channel: channelId };
  }

  deleteMessage(messageId) {
    this.messages = this.messages.filter(m => m.id !== messageId);
    this.save();
    return { success: true };
  }

  clearChannel() {
    this.messages = this.messages.filter(m => m.channel !== this.currentChannel);
    this.save();
    return { success: true };
  }

  getChannels() {
    return this.channels;
  }

  getCurrentChannel() {
    return this.channels.find(c => c.id === this.currentChannel);
  }

  renderChatUI() {
    const messages = this.getChannelMessages();
    const currentChannel = this.getCurrentChannel();

    let html = `
      <div style="display: flex; flex-direction: column; height: 100%; padding: 20px;">
        <h2>${currentChannel.name}</h2>
        
        <!-- Channel Selector -->
        <div style="display: flex; gap: 5px; margin-bottom: 15px; overflow-x: auto; padding-bottom: 10px;">
    `;

    this.channels.forEach(channel => {
      const isActive = channel.id === this.currentChannel;
      const bgColor = isActive ? '#00ff00' : '#ff0099';
      const textColor = isActive ? '#0a0e27' : '#00ff00';
      
      html += `
        <button onclick="chatWeb.switchChannel('${channel.id}'); location.reload();" 
          style="background: ${bgColor}; color: ${textColor}; border: none; padding: 8px 12px; border-radius: 4px; cursor: pointer; white-space: nowrap; font-weight: bold;">
          ${channel.name}
        </button>
      `;
    });

    html += `
        </div>

        <!-- Messages Container -->
        <div style="flex: 1; overflow-y: auto; border: 2px dashed #00ff00; padding: 15px; margin-bottom: 15px; border-radius: 4px; background: #0a0e27;">
    `;

    if (messages.length === 0) {
      html += `<p style="color: #888; text-align: center;">Nessun messaggio in questo canale. Sii il primo a scrivere!</p>`;
    } else {
      messages.forEach(msg => {
        const time = new Date(msg.timestamp).toLocaleTimeString();
        html += `
          <div style="border-left: 3px solid #00ff00; padding: 10px; margin-bottom: 10px; background: #0f1429; border-radius: 4px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <strong style="color: #00ff00;">${msg.sender}</strong>
              <small style="color: #888;">${time}</small>
            </div>
            <p style="margin: 8px 0; color: #ccc;">${msg.text}</p>
          </div>
        `;
      });
    }

    html += `
        </div>

        <!-- Input Area -->
        <div style="display: flex; gap: 10px;">
          <input type="text" id="chatInput" placeholder="Scrivi un messaggio..." 
            style="flex: 1; padding: 10px; background: #0f1429; color: #00ff00; border: 2px solid #00ff00; border-radius: 4px; font-family: monospace;"
            onkeypress="if(event.key==='Enter') chatWeb.sendMessageFromUI();">
          <button onclick="chatWeb.sendMessageFromUI()" 
            style="background: #00ff00; color: #0a0e27; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold;">
            Invia
          </button>
        </div>

        <!-- Stats -->
        <div style="margin-top: 10px; padding: 10px; background: #0f1429; border-radius: 4px; text-align: center; font-size: 0.9em; color: #888;">
          ${messages.length} messaggi in ${currentChannel.name}
        </div>
      </div>
    `;

    return html;
  }

  sendMessageFromUI() {
    const input = document.getElementById('chatInput');
    if (!input) return;

    const text = input.value;
    const result = this.sendMessage(text);

    if (result.success) {
      input.value = '';
      this.onMessagesUpdated();
    } else {
      alert(result.error);
    }
  }

  onMessagesUpdated() {
    // Callback per aggiornare UI
    const contentArea = document.getElementById('content-area');
    if (contentArea) {
      contentArea.innerHTML = this.renderChatUI();
    }
  }
}

// Export
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ChatWeb;
}
