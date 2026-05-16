// X-ZDOS Quantum GhostNet OS - Core State Management
// 100% Client-Side, Offline-First, No Server Required

class XZDOSCore {
  constructor() {
    this.state = {
      identity: this.generateOrLoadIdentity(),
      channels: this.initializeChannels(),
      currentChannel: null,
      messages: {},
      blockchain: [],
      mining: { isActive: false, hashRate: 0, blocksFound: 0, totalReward: 0 },
      wallet: { balance: 0, transactions: [] },
      chat: { messages: [], alias: '' },
      mesh: { peers: [], mode: 'local' },
      tor: { isActive: false, onionAddress: '' },
      cybersec: { threatLevel: 'low', events: [], panicMode: false },
      marketplace: { modules: [], installed: [] },
      quantumeco: { services: [], active: [] },
      settings: { autoSync: true, encryptChat: true }
    };

    this.listeners = [];
    this.loadFromStorage();
    this.initializeBlockchain();
  }

  // ==================== IDENTITY SYSTEM ====================

  generateOrLoadIdentity() {
    const stored = localStorage.getItem('x-zdos-identity');
    if (stored) {
      return JSON.parse(stored);
    }

    const ghostAddress = 'GHOST-' + this.generateRandomId(32).toUpperCase();
    const publicKey = this.generatePublicKey();
    const displayAlias = this.generateAlias(ghostAddress);

    const identity = {
      ghostAddress,
      publicKey,
      displayAlias,
      createdAt: new Date().toLocaleString(),
      createdTimestamp: Date.now()
    };

    localStorage.setItem('x-zdos-identity', JSON.stringify(identity));
    return identity;
  }

  regenerateIdentity() {
    if (confirm('⚠️ WARNING: This will generate a new identity. All associated data will be lost. Continue?')) {
      localStorage.removeItem('x-zdos-identity');
      this.state.identity = this.generateOrLoadIdentity();
      this.saveToStorage();
      this.notifyListeners();
      return true;
    }
    return false;
  }

  generatePublicKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    let key = '';
    for (let i = 0; i < 32; i++) {
      key += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return key + '...';
  }

  // ==================== CHANNELS SYSTEM ====================

  initializeChannels() {
    const stored = localStorage.getItem('x-zdos-channels');
    if (stored) {
      return JSON.parse(stored);
    }

    const defaultChannels = [
      { id: 'general', name: 'general', description: 'General discussion', createdAt: Date.now(), members: 1 },
      { id: 'ghostnet', name: 'ghostnet', description: 'GhostNet ecosystem', createdAt: Date.now(), members: 1 },
      { id: 'anonymous', name: 'anonymous', description: 'Anonymous chat', createdAt: Date.now(), members: 1 },
      { id: 'trading', name: 'trading', description: 'GNT trading', createdAt: Date.now(), members: 1 },
      { id: 'zdos', name: 'zdos', description: 'X-ZDOS discussion', createdAt: Date.now(), members: 1 }
    ];

    localStorage.setItem('x-zdos-channels', JSON.stringify(defaultChannels));
    return defaultChannels;
  }

  createChannel(name, description = '') {
    if (!name || name.trim().length === 0) return false;

    const channelId = name.toLowerCase().replace(/[^a-z0-9]/g, '-');
    
    if (this.state.channels.find(c => c.id === channelId)) {
      return false;
    }

    const newChannel = {
      id: channelId,
      name: name.trim(),
      description: description.trim(),
      createdAt: Date.now(),
      createdBy: this.state.identity.ghostAddress,
      members: 1,
      isPrivate: false
    };

    this.state.channels.push(newChannel);
    this.state.messages[channelId] = [];
    
    this.saveToStorage();
    this.notifyListeners();
    return newChannel;
  }

  joinChannel(channelId) {
    const channel = this.state.channels.find(c => c.id === channelId);
    if (!channel) return false;

    this.state.currentChannel = channelId;
    if (!this.state.messages[channelId]) {
      this.state.messages[channelId] = [];
    }

    this.saveToStorage();
    this.notifyListeners();
    return true;
  }

  leaveChannel() {
    this.state.currentChannel = null;
    this.saveToStorage();
    this.notifyListeners();
  }

  getChannelMessages(channelId) {
    return this.state.messages[channelId] || [];
  }

  addChannelMessage(channelId, text) {
    if (!this.state.messages[channelId]) {
      this.state.messages[channelId] = [];
    }

    const message = {
      id: this.generateRandomId(8),
      from: this.state.identity.displayAlias,
      ghostFrom: this.state.identity.ghostAddress,
      text: this.encryptMessage(text),
      timestamp: Date.now(),
      expiresAt: Date.now() + 3600000
    };

    this.state.messages[channelId].push(message);
    this.state.messages[channelId] = this.state.messages[channelId].filter(m => m.expiresAt > Date.now());

    this.saveToStorage();
    this.notifyListeners();
    return message;
  }

  // Storage Management
  loadFromStorage() {
    const stored = localStorage.getItem('x-zdos-state');
    if (stored) {
      try {
        const data = JSON.parse(stored);
        this.state = { ...this.state, ...data };
      } catch (e) {
        console.error('Failed to load state from storage:', e);
      }
    }
  }

  saveToStorage() {
    try {
      localStorage.setItem('x-zdos-state', JSON.stringify(this.state));
    } catch (e) {
      console.error('Failed to save state to storage:', e);
    }
  }



  generateRandomId(length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  // Blockchain Management
  initializeBlockchain() {
    if (this.state.blockchain.length === 0) {
      const genesisBlock = {
        index: 0,
        timestamp: Date.now(),
        transactions: [],
        previousHash: '0',
        hash: this.calculateHash({ index: 0, timestamp: Date.now(), transactions: [], previousHash: '0', nonce: 0 }),
        nonce: 0,
        difficulty: 1
      };
      this.state.blockchain.push(genesisBlock);
      this.saveToStorage();
    }
  }

  calculateHash(block) {
    const data = JSON.stringify(block);
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16).padStart(16, '0');
  }

  addBlock(transactions = []) {
    const lastBlock = this.state.blockchain[this.state.blockchain.length - 1];
    const newBlock = {
      index: this.state.blockchain.length,
      timestamp: Date.now(),
      transactions,
      previousHash: lastBlock.hash,
      hash: '',
      nonce: 0,
      difficulty: this.calculateDifficulty()
    };

    newBlock.hash = this.calculateHash(newBlock);
    this.state.blockchain.push(newBlock);
    this.saveToStorage();
    this.notifyListeners();
    return newBlock;
  }

  calculateDifficulty() {
    const blockCount = this.state.blockchain.length;
    return Math.floor(blockCount / 10) + 1;
  }

  getLastBlock() {
    return this.state.blockchain[this.state.blockchain.length - 1];
  }

  // Mining
  startMining() {
    if (this.state.mining.isActive) return;
    this.state.mining.isActive = true;
    this.state.mining.startTime = Date.now();
    this.mineBlock();
  }

  stopMining() {
    this.state.mining.isActive = false;
    this.saveToStorage();
    this.notifyListeners();
  }

  mineBlock() {
    if (!this.state.mining.isActive) return;

    const iterations = 10000;
    let hashRate = 0;

    for (let i = 0; i < iterations; i++) {
      hashRate++;
    }

    this.state.mining.hashRate = hashRate * 60; // Simulate H/s

    // Simulate block finding every 5 seconds
    if (Math.random() < 0.05) {
      const reward = 10;
      this.state.mining.blocksFound++;
      this.state.mining.totalReward += reward;
      this.state.wallet.balance += reward;

      const transaction = {
        from: 'mining-reward',
        to: this.state.identity.gntAddress,
        amount: reward,
        ghostContext: { ghostFrom: this.state.identity.ghostAddress },
        timestamp: Date.now()
      };

      this.addBlock([transaction]);
      this.state.wallet.transactions.push(transaction);
    }

    this.saveToStorage();
    this.notifyListeners();

    if (this.state.mining.isActive) {
      setTimeout(() => this.mineBlock(), 100);
    }
  }

  // Chat Management
  addChatMessage(text) {
    const alias = this.generateAlias();
    const message = {
      id: this.generateRandomId(8),
      alias,
      text: this.encryptMessage(text),
      timestamp: Date.now(),
      expiresAt: Date.now() + 3600000, // 1 hour TTL
      ghostContext: { ghostFrom: this.state.identity.ghostAddress }
    };

    this.state.chat.messages.push(message);
    this.state.chat.alias = alias;

    // Remove expired messages
    this.state.chat.messages = this.state.chat.messages.filter(m => m.expiresAt > Date.now());

    this.saveToStorage();
    this.notifyListeners();
    return message;
  }

  generateAlias(ghostAddress) {
    const hash = ghostAddress.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0);
      return a & a;
    }, 0);
    return 'ghost_' + Math.abs(hash).toString(16).substring(0, 8).toLowerCase();
  }

  encryptMessage(text) {
    // Simple XOR encryption (demo only, not secure)
    const key = this.state.identity.ghostAddress;
    let encrypted = '';
    for (let i = 0; i < text.length; i++) {
      encrypted += String.fromCharCode(text.charCodeAt(i) ^ key.charCodeAt(i % key.length));
    }
    return btoa(encrypted); // Base64 encode
  }

  decryptMessage(encrypted) {
    try {
      const key = this.state.identity.ghostAddress;
      const text = atob(encrypted);
      let decrypted = '';
      for (let i = 0; i < text.length; i++) {
        decrypted += String.fromCharCode(text.charCodeAt(i) ^ key.charCodeAt(i % key.length));
      }
      return decrypted;
    } catch (e) {
      return encrypted;
    }
  }

  // Mesh Network
  addPeer(peerId) {
    const peer = {
      id: peerId,
      connected: true,
      synced: false,
      lastSeen: Date.now()
    };
    this.state.mesh.peers.push(peer);
    this.notifyListeners();
  }

  removePeer(peerId) {
    this.state.mesh.peers = this.state.mesh.peers.filter(p => p.id !== peerId);
    this.notifyListeners();
  }

  // Cybersecurity
  addSecurityEvent(type, severity, message) {
    const event = {
      id: this.generateRandomId(8),
      type,
      severity,
      message,
      timestamp: Date.now()
    };

    this.state.cybersec.events.push(event);
    this.state.cybersec.events = this.state.cybersec.events.slice(-100); // Keep last 100

    // Update threat level
    const criticalCount = this.state.cybersec.events.filter(e => e.severity === 'critical').length;
    if (criticalCount > 5) {
      this.state.cybersec.threatLevel = 'critical';
    } else if (criticalCount > 2) {
      this.state.cybersec.threatLevel = 'high';
    } else if (criticalCount > 0) {
      this.state.cybersec.threatLevel = 'medium';
    } else {
      this.state.cybersec.threatLevel = 'low';
    }

    this.saveToStorage();
    this.notifyListeners();
  }

  activatePanicMode() {
    this.state.cybersec.panicMode = true;
    this.state.mining.isActive = false;
    this.state.mesh.mode = 'local';
    this.addSecurityEvent('panic', 'critical', 'PANIC MODE ACTIVATED');
    this.saveToStorage();
    this.notifyListeners();
  }

  deactivatePanicMode() {
    this.state.cybersec.panicMode = false;
    this.addSecurityEvent('panic', 'info', 'Panic mode deactivated');
    this.saveToStorage();
    this.notifyListeners();
  }

  // Tor Mode
  enableTorMode() {
    this.state.tor.isActive = true;
    this.state.tor.onionAddress = this.generateRandomId(16) + '.onion';
    this.state.mesh.mode = 'tor';
    this.saveToStorage();
    this.notifyListeners();
  }

  disableTorMode() {
    this.state.tor.isActive = false;
    this.state.mesh.mode = 'local';
    this.saveToStorage();
    this.notifyListeners();
  }

  // Marketplace
  loadMarketplaceModules() {
    this.state.marketplace.modules = [
      { id: 'adv-mining', name: 'Advanced Mining', price: 50, description: 'GPU acceleration' },
      { id: 'privacy-shield', name: 'Privacy Shield', price: 100, description: 'Enhanced encryption' },
      { id: 'mesh-booster', name: 'Mesh Booster', price: 75, description: 'Network optimization' },
      { id: 'ai-sentinel', name: 'AI Sentinel', price: 150, description: 'Threat detection' },
      { id: 'quantum-wallet', name: 'Quantum Wallet', price: 200, description: 'Multi-signature' }
    ];
    this.notifyListeners();
  }

  installModule(moduleId) {
    const module = this.state.marketplace.modules.find(m => m.id === moduleId);
    if (module && this.state.wallet.balance >= module.price) {
      this.state.wallet.balance -= module.price;
      this.state.marketplace.installed.push(moduleId);
      this.saveToStorage();
      this.notifyListeners();
      return true;
    }
    return false;
  }

  // QuantumEco Services
  loadQuantumEcoServices() {
    this.state.quantumeco.services = [
      { id: 'quantum-compute', name: 'Quantum Compute', status: 'available', uptime: 99.5 },
      { id: 'eco-analytics', name: 'Eco Analytics', status: 'available', uptime: 98.2 },
      { id: 'carbon-offset', name: 'Carbon Offset', status: 'available', uptime: 100 },
      { id: 'energy-harvest', name: 'Energy Harvesting', status: 'available', uptime: 97.8 },
      { id: 'eco-rewards', name: 'Eco Rewards', status: 'available', uptime: 99.9 }
    ];
    this.notifyListeners();
  }

  activateService(serviceId) {
    const service = this.state.quantumeco.services.find(s => s.id === serviceId);
    if (service && !this.state.quantumeco.active.includes(serviceId)) {
      this.state.quantumeco.active.push(serviceId);
      this.saveToStorage();
      this.notifyListeners();
    }
  }

  deactivateService(serviceId) {
    this.state.quantumeco.active = this.state.quantumeco.active.filter(s => s !== serviceId);
    this.saveToStorage();
    this.notifyListeners();
  }

  // Settings
  exportData() {
    return JSON.stringify(this.state, null, 2);
  }

  importData(jsonData) {
    try {
      const data = JSON.parse(jsonData);
      this.state = { ...this.state, ...data };
      this.saveToStorage();
      this.notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  resetNode() {
    if (confirm('Are you sure? This will reset all data!')) {
      localStorage.clear();
      this.state = {
        identity: this.generateIdentity(),
        blockchain: [],
        mining: { isActive: false, hashRate: 0, blocksFound: 0, totalReward: 0 },
        wallet: { balance: 0, transactions: [] },
        chat: { messages: [], alias: '' },
        mesh: { peers: [], mode: 'local' },
        tor: { isActive: false, onionAddress: '' },
        cybersec: { threatLevel: 'low', events: [], panicMode: false },
        marketplace: { modules: [], installed: [] },
        quantumeco: { services: [], active: [] },
        settings: { autoSync: true, encryptChat: true }
      };
      this.initializeBlockchain();
      this.notifyListeners();
    }
  }

  // Observer Pattern
  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  notifyListeners() {
    this.listeners.forEach(listener => listener(this.state));
  }
}

// Global instance
const core = new XZDOSCore();
