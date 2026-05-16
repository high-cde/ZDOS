/**
 * X-ZDOS Multi-Device Sync Module
 * Sincronizza messaggi e canali tra più dispositivi usando localStorage e BroadcastChannel API
 */

class MultiDeviceSync {
  constructor() {
    this.channel = null;
    this.listeners = [];
    this.messageQueue = [];
    this.isInitialized = false;
    this.deviceId = this.generateDeviceId();
    this.init();
  }

  generateDeviceId() {
    let id = localStorage.getItem('x-zdos-device-id');
    if (!id) {
      id = `device-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('x-zdos-device-id', id);
    }
    return id;
  }

  init() {
    try {
      // Usa BroadcastChannel API se disponibile (multi-tab/window)
      if (typeof BroadcastChannel !== 'undefined') {
        this.channel = new BroadcastChannel('x-zdos-sync');
        this.channel.onmessage = (event) => this.handleBroadcast(event.data);
        console.log('✓ BroadcastChannel API inizializzato');
      }
    } catch (e) {
      console.log('BroadcastChannel non disponibile, usando localStorage');
    }

    // Ascolta cambiamenti localStorage da altri tab
    window.addEventListener('storage', (e) => this.handleStorageChange(e));
    this.isInitialized = true;
  }

  // Invia messaggio a tutti i dispositivi
  broadcastMessage(channel, message, sender = null) {
    const msg = {
      id: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      channel,
      message,
      sender: sender || this.deviceId,
      timestamp: new Date().toISOString(),
      type: 'message'
    };

    // Salva in localStorage
    this.saveMessage(msg);

    // Invia via BroadcastChannel se disponibile
    if (this.channel) {
      this.channel.postMessage(msg);
    }

    // Notifica listener locali
    this.notifyListeners(msg);

    return msg;
  }

  // Crea/aggiorna canale
  broadcastChannelUpdate(channelData) {
    const update = {
      id: `channel-${Date.now()}`,
      ...channelData,
      sender: this.deviceId,
      timestamp: new Date().toISOString(),
      type: 'channel-update'
    };

    // Salva in localStorage
    this.saveChannelUpdate(update);

    // Invia via BroadcastChannel
    if (this.channel) {
      this.channel.postMessage(update);
    }

    this.notifyListeners(update);
    return update;
  }

  // Salva messaggio in localStorage
  saveMessage(msg) {
    const key = `x-zdos-messages-${msg.channel}`;
    let messages = [];
    
    try {
      const stored = localStorage.getItem(key);
      if (stored) {
        messages = JSON.parse(stored);
      }
    } catch (e) {
      console.error('Errore parsing messaggi:', e);
    }

    messages.push(msg);

    // Mantieni ultimi 1000 messaggi per canale
    if (messages.length > 1000) {
      messages = messages.slice(-1000);
    }

    try {
      localStorage.setItem(key, JSON.stringify(messages));
    } catch (e) {
      console.error('Errore salvataggio messaggi:', e);
      // Se localStorage è pieno, rimuovi i messaggi più vecchi
      if (e.name === 'QuotaExceededError') {
        messages = messages.slice(-100);
        localStorage.setItem(key, JSON.stringify(messages));
      }
    }
  }

  // Salva aggiornamento canale
  saveChannelUpdate(update) {
    const key = 'x-zdos-channels';
    let channels = {};

    try {
      const stored = localStorage.getItem(key);
      if (stored) {
        channels = JSON.parse(stored);
      }
    } catch (e) {
      console.error('Errore parsing canali:', e);
    }

    channels[update.name] = update;

    try {
      localStorage.setItem(key, JSON.stringify(channels));
    } catch (e) {
      console.error('Errore salvataggio canali:', e);
    }
  }

  // Recupera messaggi da un canale
  getMessages(channel) {
    const key = `x-zdos-messages-${channel}`;
    try {
      const stored = localStorage.getItem(key);
      return stored ? JSON.parse(stored) : [];
    } catch (e) {
      console.error('Errore recupero messaggi:', e);
      return [];
    }
  }

  // Recupera tutti i canali
  getChannels() {
    const key = 'x-zdos-channels';
    try {
      const stored = localStorage.getItem(key);
      return stored ? JSON.parse(stored) : {};
    } catch (e) {
      console.error('Errore recupero canali:', e);
      return {};
    }
  }

  // Gestisce messaggi da BroadcastChannel
  handleBroadcast(data) {
    if (data.sender === this.deviceId) return; // Ignora messaggi propri
    this.notifyListeners(data);
  }

  // Gestisce cambiamenti localStorage da altri tab
  handleStorageChange(event) {
    if (!event.key || !event.key.startsWith('x-zdos-')) return;

    try {
      const newValue = event.newValue ? JSON.parse(event.newValue) : null;
      
      if (event.key.startsWith('x-zdos-messages-')) {
        // Notifica nuovi messaggi
        if (Array.isArray(newValue) && newValue.length > 0) {
          const lastMsg = newValue[newValue.length - 1];
          if (lastMsg.sender !== this.deviceId) {
            this.notifyListeners(lastMsg);
          }
        }
      } else if (event.key === 'x-zdos-channels') {
        // Notifica aggiornamenti canali
        this.notifyListeners({
          type: 'channel-update',
          data: newValue
        });
      }
    } catch (e) {
      console.error('Errore handling storage change:', e);
    }
  }

  // Registra listener per cambiamenti
  onSync(callback) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  // Notifica tutti i listener
  notifyListeners(data) {
    this.listeners.forEach(listener => {
      try {
        listener(data);
      } catch (e) {
        console.error('Errore in listener:', e);
      }
    });
  }

  // Pulisci risorse
  destroy() {
    if (this.channel) {
      this.channel.close();
    }
    this.listeners = [];
  }
}

// Esporta singleton
const multiDeviceSync = new MultiDeviceSync();
