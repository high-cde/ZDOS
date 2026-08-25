/**
 * X-ZDOS Quantum GhostNet OS - Core Module (Optimized)
 * Blockchain, Mining, Identity, Chat, Mesh Network
 */

class GhostnetIdentity {
  constructor() {
    this.load();
  }

  load() {
    const stored = localStorage.getItem('ghostnet_identity');
    if (stored) {
      const data = JSON.parse(stored);
      Object.assign(this, data);
    } else {
      this.generateIdentity();
    }
  }

  generateIdentity() {
    this.ghostAddress = 'GHOST-' + Math.random().toString(16).substr(2, 32).toUpperCase();
    this.publicKey = this.generatePublicKey();
    this.displayAlias = 'ghost_' + Math.random().toString(16).substr(2, 8);
    this.createdAt = new Date().toISOString();
    this.save();
  }

  generatePublicKey() {
    return 'PK-' + Math.random().toString(16).substr(2, 64).toUpperCase();
  }

  regenerateIdentity() {
    this.generateIdentity();
    return { success: true, message: 'Identità rigenerata' };
  }

  save() {
    localStorage.setItem('ghostnet_identity', JSON.stringify({
      ghostAddress: this.ghostAddress,
      publicKey: this.publicKey,
      displayAlias: this.displayAlias,
      createdAt: this.createdAt
    }));
  }

  renderIdentityPanel() {
    return `
      <div style="padding: 20px; max-width: 600px;">
        <h2>🔐 GhostNet Identity</h2>
        <div style="border: 2px dashed #00ff00; padding: 15px; margin: 15px 0; border-radius: 4px;">
          <p><strong>GHOST Address:</strong></p>
          <code style="background: #0f1429; padding: 10px; display: block; margin: 10px 0; word-break: break-all;">${this.ghostAddress}</code>
          <p><strong>Display Alias:</strong> <span style="color: #00ff00;">${this.displayAlias}</span></p>
          <p><strong>Public Key:</strong></p>
          <code style="background: #0f1429; padding: 10px; display: block; margin: 10px 0; word-break: break-all; font-size: 0.8em;">${this.publicKey}</code>
          <p><strong>Status:</strong> <span style="color: #00ff00;">✓ LINKED</span></p>
          <button onclick="ghostnetIdentity.regenerateIdentity(); location.reload();" style="background: #ff0099; color: #0a0e27; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin-top: 10px;">Rigenerare Identità</button>
        </div>
      </div>
    `;
  }
}

class SimpleBlockchain {
  constructor() {
    this.chain = [];
    this.difficulty = 1;
    this.createGenesisBlock();
    this.load();
  }

  createGenesisBlock() {
    const genesisBlock = {
      index: 0,
      timestamp: Date.now(),
      transactions: [],
      nonce: 0,
      hash: 'GENESIS'
    };
    this.chain.push(genesisBlock);
  }

  load() {
    const stored = localStorage.getItem('blockchain');
    if (stored) {
      this.chain = JSON.parse(stored);
    }
  }

  save() {
    localStorage.setItem('blockchain', JSON.stringify(this.chain));
  }

  addBlock(transactions = []) {
    const newBlock = {
      index: this.chain.length,
      timestamp: Date.now(),
      transactions: transactions,
      nonce: 0,
      hash: ''
    };

    // Simple PoW
    while (!newBlock.hash.startsWith('0'.repeat(this.difficulty))) {
      newBlock.nonce++;
      newBlock.hash = this.calculateHash(newBlock);
    }

    this.chain.push(newBlock);
    this.save();
    return newBlock;
  }

  calculateHash(block) {
    const str = JSON.stringify(block);
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }

  getChainHeight() {
    return this.chain.length;
  }

  getLastBlock() {
    return this.chain[this.chain.length - 1];
  }
}

class SimpleMiner {
  constructor(blockchain) {
    this.blockchain = blockchain;
    this.isMining = false;
    this.hashRate = 0;
    this.totalBlocks = 0;
    this.totalReward = 0;
  }

  startMining() {
    this.isMining = true;
    this.mine();
  }

  stopMining() {
    this.isMining = false;
  }

  mine() {
    if (!this.isMining) return;

    const startTime = Date.now();
    const block = this.blockchain.addBlock([{ type: 'mining_reward', amount: 10 }]);
    const elapsed = (Date.now() - startTime) / 1000;

    this.totalBlocks++;
    this.totalReward += 10;
    this.hashRate = Math.round(1000000 / (elapsed * 1000));

    setTimeout(() => this.mine(), 100);
  }

  getStats() {
    return {
      isMining: this.isMining,
      hashRate: this.hashRate,
      totalBlocks: this.totalBlocks,
      totalReward: this.totalReward
    };
  }
}

class SimpleChat {
  constructor() {
    this.messages = [];
    this.channels = [
      { id: 'general', name: 'General', members: 0 },
      { id: 'ghostnet', name: 'GhostNet', members: 0 },
      { id: 'anonymous', name: 'Anonymous', members: 0 },
      { id: 'trading', name: 'Trading', members: 0 },
      { id: 'zdos', name: 'X-ZDOS', members: 0 }
    ];
    this.currentChannel = 'general';
    this.load();
  }

  load() {
    const stored = localStorage.getItem('chat_messages');
    if (stored) {
      this.messages = JSON.parse(stored);
    }
  }

  save() {
    localStorage.setItem('chat_messages', JSON.stringify(this.messages));
  }

  sendMessage(text, ghostAddress) {
    const message = {
      id: Math.random().toString(36).substr(2, 9),
      channel: this.currentChannel,
      text: this.encryptMessage(text),
      sender: this.generateAlias(ghostAddress),
      timestamp: Date.now(),
      ttl: 3600000 // 1 hour
    };
    this.messages.push(message);
    this.save();
    return message;
  }

  encryptMessage(text) {
    // Simple XOR encryption
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
      return '[Encrypted]';
    }
  }

  generateAlias(ghostAddress) {
    return 'anon_' + ghostAddress.substr(-6).toLowerCase();
  }

  getChannelMessages() {
    return this.messages.filter(m => m.channel === this.currentChannel && Date.now() - m.timestamp < m.ttl);
  }

  getChannels() {
    return this.channels;
  }

  switchChannel(channelId) {
    this.currentChannel = channelId;
  }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { GhostnetIdentity, SimpleBlockchain, SimpleMiner, SimpleChat };
}
