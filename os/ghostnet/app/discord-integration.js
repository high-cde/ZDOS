/**
 * X-ZDOS Discord Integration
 * Sincronizza messaggi con Discord webhook e OAuth
 */

class DiscordIntegration {
  constructor() {
    this.webhookUrl = null;
    this.oauthToken = null;
    this.serverId = null;
    this.channelMap = new Map(); // Mappa canali X-ZDOS -> Discord
    this.isConnected = false;
    this.loadConfig();
  }

  loadConfig() {
    try {
      const config = localStorage.getItem('x-zdos-discord-config');
      if (config) {
        const parsed = JSON.parse(config);
        this.webhookUrl = parsed.webhookUrl;
        this.oauthToken = parsed.oauthToken;
        this.serverId = parsed.serverId;
        this.channelMap = new Map(parsed.channelMap || []);
        this.isConnected = !!this.webhookUrl;
      }
    } catch (e) {
      console.error('Errore caricamento config Discord:', e);
    }
  }

  saveConfig() {
    try {
      const config = {
        webhookUrl: this.webhookUrl,
        oauthToken: this.oauthToken,
        serverId: this.serverId,
        channelMap: Array.from(this.channelMap.entries())
      };
      localStorage.setItem('x-zdos-discord-config', JSON.stringify(config));
    } catch (e) {
      console.error('Errore salvataggio config Discord:', e);
    }
  }

  // Connetti con webhook
  async connectWithWebhook(webhookUrl) {
    try {
      // Valida webhook
      const response = await fetch(webhookUrl, { method: 'GET' });
      if (!response.ok) throw new Error('Webhook non valido');

      this.webhookUrl = webhookUrl;
      this.isConnected = true;
      this.saveConfig();
      return { success: true, message: 'Webhook connesso' };
    } catch (e) {
      console.error('Errore connessione webhook:', e);
      return { success: false, error: e.message };
    }
  }

  // Invia messaggio a Discord
  async sendToDiscord(channelName, message, author) {
    if (!this.isConnected || !this.webhookUrl) {
      return { success: false, error: 'Discord non connesso' };
    }

    try {
      const embed = {
        title: `#${channelName}`,
        description: message,
        author: { name: author || 'Anonymous' },
        color: 0x00FF00, // Neon green
        timestamp: new Date().toISOString()
      };

      const response = await fetch(this.webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ embeds: [embed] })
      });

      if (!response.ok) {
        throw new Error(`Discord API error: ${response.status}`);
      }

      return { success: true };
    } catch (e) {
      console.error('Errore invio a Discord:', e);
      return { success: false, error: e.message };
    }
  }

  // Mappa canale X-ZDOS a Discord
  mapChannel(xzdosChannel, discordChannelId) {
    this.channelMap.set(xzdosChannel, discordChannelId);
    this.saveConfig();
  }

  // Ottieni canale Discord mappato
  getDiscordChannel(xzdosChannel) {
    return this.channelMap.get(xzdosChannel);
  }

  // Disconnetti
  disconnect() {
    this.webhookUrl = null;
    this.oauthToken = null;
    this.isConnected = false;
    this.saveConfig();
  }

  // Stato connessione
  getStatus() {
    return {
      isConnected: this.isConnected,
      webhookUrl: this.webhookUrl ? '***' : null,
      serverId: this.serverId,
      channelCount: this.channelMap.size
    };
  }
}

// Esporta singleton
const discordIntegration = new DiscordIntegration();
