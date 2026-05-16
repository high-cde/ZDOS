// X-ZDOS UI Manager - Channels & Identity System

class UIManager {
  constructor() {
    this.currentSection = 'identity';
    this.setupEventListeners();
    this.render();

    // Subscribe to state changes
    core.subscribe(() => this.render());
  }

  setupEventListeners() {
    // Navigation
    document.querySelectorAll('nav button').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const section = e.target.dataset.section;
        if (section) {
          this.switchSection(section);
        }
      });
    });
  }

  switchSection(section) {
    this.currentSection = section;

    // Update nav active state
    document.querySelectorAll('nav button').forEach(btn => {
      btn.classList.remove('active');
      if (btn.dataset.section === section) {
        btn.classList.add('active');
      }
    });

    // Update section visibility
    document.querySelectorAll('.section').forEach(sec => {
      sec.classList.remove('active');
    });
    const activeSection = document.getElementById(`section-${section}`);
    if (activeSection) {
      activeSection.classList.add('active');
    }

    this.render();
  }

  render() {
    const state = core.state;

    // Render all sections
    this.renderIdentity(state);
    this.renderChannels(state);
    this.renderChat(state);
    this.renderDashboard(state);
    this.renderMining(state);
    this.renderCybersec(state);
    this.renderMarketplace(state);
    this.renderQuantumEco(state);
    this.renderSettings(state);
  }

  // ==================== IDENTITY SECTION ====================

  renderIdentity(state) {
    const html = `
      <div class="card">
        <h3>🔐 GhostNet Identity</h3>
        <p>Your cryptographic identity — stored locally, never on a server</p>
      </div>

      <div class="card">
        <h3>GHOST ADDRESS</h3>
        <p class="card-value" style="word-break: break-all; font-size: 0.9rem;">${state.identity.ghostAddress}</p>
        <button onclick="copyToClipboard('${state.identity.ghostAddress}')">📋 Copy</button>
      </div>

      <div class="card">
        <h3>DISPLAY ALIAS</h3>
        <p class="card-value">${state.identity.displayAlias}</p>
      </div>

      <div class="card">
        <h3>PUBLIC KEY</h3>
        <p class="card-value" style="font-size: 0.8rem; word-break: break-all;">${state.identity.publicKey}</p>
        <button onclick="copyToClipboard('${state.identity.publicKey}')">📋 Copy</button>
      </div>

      <div class="card">
        <h3>IDENTITY CREATED</h3>
        <p class="card-value">${state.identity.createdAt}</p>
      </div>

      <div class="card" style="border: 2px solid var(--error);">
        <h3>⚠️ DANGER ZONE</h3>
        <p>Warning: This action is irreversible. Your current address and all associated data will be lost.</p>
        <button onclick="core.regenerateIdentity()" class="danger">🔄 REGENERATE IDENTITY</button>
      </div>
    `;

    const el = document.getElementById('identity-content');
    if (el) el.innerHTML = html;
  }

  // ==================== CHANNELS SECTION ====================

  renderChannels(state) {
    const channelsList = state.channels.map(ch => `
      <button class="channel-item ${state.currentChannel === ch.id ? 'active' : ''}" 
              onclick="core.joinChannel('${ch.id}'); ui.switchSection('chat');">
        <div class="channel-name">#${ch.name}</div>
        <div class="channel-desc">${ch.description}</div>
        <div class="channel-meta">${ch.members} member${ch.members !== 1 ? 's' : ''}</div>
      </button>
    `).join('');

    const html = `
      <div class="card">
        <h3>📡 CHANNELS</h3>
        <p>Join a channel to start chatting anonymously</p>
      </div>

      <div class="channels-list">
        ${channelsList}
      </div>

      <div class="card">
        <h3>➕ CREATE NEW CHANNEL</h3>
        <input type="text" id="new-channel-name" placeholder="Channel name" maxlength="30">
        <textarea id="new-channel-desc" placeholder="Channel description (optional)" maxlength="100" style="resize: vertical; height: 60px;"></textarea>
        <button onclick="createNewChannel()">🆕 CREATE CHANNEL</button>
      </div>
    `;

    const el = document.getElementById('channels-content');
    if (el) el.innerHTML = html;
  }

  // ==================== CHAT SECTION ====================

  renderChat(state) {
    if (!state.currentChannel) {
      const html = '<p style="color: var(--muted); text-align: center; padding: 2rem;">Select a channel to start chatting</p>';
      const el = document.getElementById('chat-content');
      if (el) el.innerHTML = html;
      return;
    }

    const messages = state.messages[state.currentChannel] || [];
    const messagesHtml = messages.map(msg => `
      <div class="chat-message">
        <div class="chat-message-alias">${msg.from}</div>
        <div class="chat-message-text">${core.decryptMessage(msg.text)}</div>
        <small style="color: var(--muted);">${new Date(msg.timestamp).toLocaleTimeString()}</small>
      </div>
    `).join('');

    const currentChannelName = state.channels.find(c => c.id === state.currentChannel)?.name || 'unknown';

    const html = `
      <div class="card">
        <h3>#${currentChannelName}</h3>
        <p>Chat anonymously with other users</p>
        <button onclick="core.leaveChannel(); ui.switchSection('channels');" class="secondary">← Back to Channels</button>
      </div>

      <div class="chat-container">
        <div class="chat-messages">${messagesHtml || '<p style="color: var(--muted);">No messages yet...</p>'}</div>
        <div class="chat-input-area">
          <textarea id="chat-input" placeholder="Type message..." maxlength="500"></textarea>
          <button onclick="sendChannelMessage()">Send</button>
        </div>
      </div>
    `;

    const el = document.getElementById('chat-content');
    if (el) el.innerHTML = html;
  }

  // ==================== DASHBOARD SECTION ====================

  renderDashboard(state) {
    const html = `
      <div class="grid">
        <div class="card">
          <h3>🔐 Identity</h3>
          <p>Alias: <span class="card-value">${state.identity.displayAlias}</span></p>
          <p>Channels: <span class="card-value">${state.channels.length}</span></p>
        </div>

        <div class="card">
          <h3>💬 Channels</h3>
          <p>Active: <span class="card-value">${state.currentChannel ? '#' + state.channels.find(c => c.id === state.currentChannel)?.name : 'None'}</span></p>
          <p>Messages: <span class="card-value">${(state.messages[state.currentChannel] || []).length}</span></p>
        </div>

        <div class="card">
          <h3>⛏️ Mining</h3>
          <p>Status: <span class="card-value">${state.mining.isActive ? 'ACTIVE' : 'IDLE'}</span></p>
          <p>Blocks: <span class="card-value">${state.mining.blocksFound}</span></p>
        </div>

        <div class="card">
          <h3>💰 Wallet</h3>
          <p>Balance: <span class="card-value">${state.wallet.balance} GNT</span></p>
          <p>Transactions: <span class="card-value">${state.wallet.transactions.length}</span></p>
        </div>

        <div class="card">
          <h3>🛡️ Security</h3>
          <p>Threat: <span class="card-value">${state.cybersec.threatLevel.toUpperCase()}</span></p>
          <p>Events: <span class="card-value">${state.cybersec.events.length}</span></p>
        </div>

        <div class="card">
          <h3>⛓️ Blockchain</h3>
          <p>Height: <span class="card-value">${state.blockchain.length}</span></p>
          <p>Supply: <span class="card-value">${state.mining.totalReward} GNT</span></p>
        </div>
      </div>
    `;

    const el = document.getElementById('dashboard-content');
    if (el) el.innerHTML = html;
  }

  // ==================== OTHER SECTIONS ====================

  renderMining(state) {
    const html = `
      <div class="card">
        <h3>⛏️ Mining Control</h3>
        <p>Status: <span class="card-value">${state.mining.isActive ? 'ACTIVE' : 'INACTIVE'}</span></p>
        <p>Hash Rate: <span class="card-value">${state.mining.hashRate.toLocaleString()} H/s</span></p>
        <p>Blocks: <span class="card-value">${state.mining.blocksFound}</span></p>
        <p>Reward: <span class="card-value">${state.mining.totalReward} GNT</span></p>
        <div style="margin-top: 1rem;">
          <button onclick="core.startMining()" ${state.mining.isActive ? 'disabled' : ''}>⚡ Start Mining</button>
          <button onclick="core.stopMining()" class="danger" ${!state.mining.isActive ? 'disabled' : ''}>⏹ Stop Mining</button>
        </div>
      </div>
    `;

    const el = document.getElementById('mining-content');
    if (el) el.innerHTML = html;
  }

  renderCybersec(state) {
    const events = state.cybersec.events.slice(-10).reverse().map(event => `
      <div class="list-item">
        <span>${event.type}</span>
        <span class="badge ${event.severity === 'critical' ? 'error' : event.severity === 'warning' ? 'warning' : 'info'}">
          ${event.severity.toUpperCase()}
        </span>
      </div>
    `).join('');

    const html = `
      <div class="card">
        <h3>🛡️ Cybersecurity</h3>
        <p>Threat Level: <span class="card-value">${state.cybersec.threatLevel.toUpperCase()}</span></p>
        <p>Events: <span class="card-value">${state.cybersec.events.length}</span></p>
        <div style="margin-top: 1rem;">
          <button onclick="core.activatePanicMode()" class="danger" ${state.cybersec.panicMode ? 'disabled' : ''}>🚨 Panic Mode</button>
        </div>
      </div>

      <div class="card">
        <h3>Recent Events</h3>
        <ul class="list">${events || '<li style="color: var(--muted);">No events</li>'}</ul>
      </div>
    `;

    const el = document.getElementById('cybersec-content');
    if (el) el.innerHTML = html;
  }

  renderMarketplace(state) {
    const modules = state.marketplace.modules.map(mod => `
      <div class="list-item">
        <div>
          <strong>${mod.name}</strong>
          <p style="color: var(--muted); font-size: 0.8rem;">${mod.description}</p>
        </div>
        <div style="text-align: right;">
          <p>${mod.price} GNT</p>
          <button onclick="installMarketplaceModule('${mod.id}')" 
            ${state.marketplace.installed.includes(mod.id) ? 'disabled' : ''}
            style="width: 100px; font-size: 0.8rem;">
            ${state.marketplace.installed.includes(mod.id) ? '✓ Installed' : 'Install'}
          </button>
        </div>
      </div>
    `).join('');

    const html = `
      <div class="card">
        <h3>🛒 Marketplace</h3>
        <p>Modules: <span class="card-value">${state.marketplace.modules.length}</span></p>
        <p>Installed: <span class="card-value">${state.marketplace.installed.length}</span></p>
      </div>

      <div class="card">
        <h3>Available Modules</h3>
        <ul class="list">${modules || '<li style="color: var(--muted);">No modules</li>'}</ul>
      </div>
    `;

    const el = document.getElementById('marketplace-content');
    if (el) el.innerHTML = html;
  }

  renderQuantumEco(state) {
    const services = state.quantumeco.services.map(svc => `
      <div class="list-item">
        <div>
          <strong>${svc.name}</strong>
          <p style="color: var(--muted); font-size: 0.8rem;">Uptime: ${svc.uptime}%</p>
        </div>
        <button onclick="toggleQuantumEcoService('${svc.id}')"
          class="${state.quantumeco.active.includes(svc.id) ? 'danger' : 'secondary'}"
          style="width: 100px; font-size: 0.8rem;">
          ${state.quantumeco.active.includes(svc.id) ? 'Deactivate' : 'Activate'}
        </button>
      </div>
    `).join('');

    const html = `
      <div class="card">
        <h3>🌱 QuantumEco Services</h3>
        <p>Available: <span class="card-value">${state.quantumeco.services.length}</span></p>
        <p>Active: <span class="card-value">${state.quantumeco.active.length}</span></p>
      </div>

      <div class="card">
        <h3>Services</h3>
        <ul class="list">${services || '<li style="color: var(--muted);">No services</li>'}</ul>
      </div>
    `;

    const el = document.getElementById('quantumeco-content');
    if (el) el.innerHTML = html;
  }

  renderSettings(state) {
    const html = `
      <div class="card">
        <h3>💾 Data Management</h3>
        <button onclick="exportNodeData()">📥 Export Data</button>
        <button onclick="importNodeData()">📤 Import Data</button>
        <button onclick="core.resetNode()" class="danger">🔄 Reset Node</button>
      </div>

      <div class="card">
        <h3>ℹ️ About</h3>
        <p>X-ZDOS Quantum GhostNet OS v2.0</p>
        <p>100% Client-Side • Offline-First • Anonymous</p>
        <p>With Channels & Identity System</p>
      </div>
    `;

    const el = document.getElementById('settings-content');
    if (el) el.innerHTML = html;
  }
}

// ==================== HELPER FUNCTIONS ====================

function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    alert('✓ Copied to clipboard!');
  });
}

function createNewChannel() {
  const nameInput = document.getElementById('new-channel-name');
  const descInput = document.getElementById('new-channel-desc');
  
  if (nameInput && nameInput.value.trim()) {
    const result = core.createChannel(nameInput.value, descInput?.value || '');
    if (result) {
      alert(`✓ Channel #${result.name} created!`);
      nameInput.value = '';
      if (descInput) descInput.value = '';
      ui.switchSection('channels');
    } else {
      alert('✗ Channel already exists!');
    }
  } else {
    alert('✗ Please enter a channel name');
  }
}

function sendChannelMessage() {
  const input = document.getElementById('chat-input');
  if (input && input.value.trim() && core.state.currentChannel) {
    core.addChannelMessage(core.state.currentChannel, input.value);
    input.value = '';
  }
}

function installMarketplaceModule(moduleId) {
  if (core.installModule(moduleId)) {
    alert('✓ Module installed successfully!');
  } else {
    alert('✗ Insufficient balance!');
  }
}

function toggleQuantumEcoService(serviceId) {
  if (core.state.quantumeco.active.includes(serviceId)) {
    core.deactivateService(serviceId);
  } else {
    core.activateService(serviceId);
  }
}

function exportNodeData() {
  const data = core.exportData();
  const blob = new Blob([data], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'x-zdos-backup.json';
  a.click();
}

function importNodeData() {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.json';
  input.onchange = (e) => {
    const file = e.target.files[0];
    const reader = new FileReader();
    reader.onload = (event) => {
      if (core.importData(event.target.result)) {
        alert('✓ Data imported successfully!');
      } else {
        alert('✗ Failed to import data!');
      }
    };
    reader.readAsText(file);
  };
  input.click();
}

// Initialize UI
let ui;
document.addEventListener('DOMContentLoaded', () => {
  ui = new UIManager();
});
