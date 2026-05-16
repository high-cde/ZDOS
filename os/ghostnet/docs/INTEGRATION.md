# X-ZDOS Backend - Integration Guide

Guida per integrare il backend X-ZDOS con il frontend GhostNet.

---

## 🔌 Setup Iniziale

### 1. Avvia il Backend

```bash
cd /home/ubuntu/x-zdos-backend
PORT=3001 npm start
```

**Output atteso:**
```
╔════════════════════════════════════════════════════════════╗
║  🟢 X-ZDOS GhostNet Backend - ONLINE                       ║
║  Version: 1.0.0 (Quantum Minimal v1)                      ║
║  Port: 3001                                                ║
║  Status: ✅ ACTIVE                                          ║
╚════════════════════════════════════════════════════════════╝
```

### 2. Verifica Connessione

```bash
curl http://localhost:3001/health
```

---

## 🌐 Configurazione Frontend

### Aggiungi API URL nel Frontend

Nel file `index.html` della WebApp GhostNet, aggiungi:

```javascript
// Configurazione API Backend
const BACKEND_API = {
  BASE_URL: 'http://localhost:3001',
  TIMEOUT: 5000,
  RETRY: 3
};

// Funzione helper per richieste API
async function apiCall(endpoint, options = {}) {
  const url = `${BACKEND_API.BASE_URL}${endpoint}`;
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  const response = await fetch(url, { ...defaultOptions, ...options });
  if (!response.ok) throw new Error(`API Error: ${response.status}`);
  return response.json();
}
```

---

## 🔐 Identity Integration

### Genera Identità GHOST

```javascript
async function generateGhostIdentity() {
  try {
    const data = await apiCall('/identity/generate', { method: 'POST' });
    
    if (data.success) {
      const identity = data.identity;
      
      // Salva localmente
      localStorage.setItem('ghostIdentity', JSON.stringify(identity));
      
      console.log('✅ Identità generata:', identity.ghostAddress);
      console.log('Alias:', identity.displayAlias);
      
      return identity;
    }
  } catch (error) {
    console.error('❌ Errore generazione identità:', error);
  }
}
```

### Firma Messaggio

```javascript
async function signMessage(message, privateKey) {
  try {
    const data = await apiCall('/identity/sign', {
      method: 'POST',
      body: JSON.stringify({ message, privateKey })
    });
    
    if (data.success) {
      console.log('✅ Messaggio firmato');
      return data.signature;
    }
  } catch (error) {
    console.error('❌ Errore firma:', error);
  }
}
```

### Verifica Firma

```javascript
async function verifySignature(message, signature, publicKey) {
  try {
    const data = await apiCall('/identity/verify', {
      method: 'POST',
      body: JSON.stringify({ message, signature, publicKey })
    });
    
    if (data.success) {
      console.log('✅ Firma valida:', data.isValid);
      return data.isValid;
    }
  } catch (error) {
    console.error('❌ Errore verifica:', error);
  }
}
```

---

## 💰 Wallet Integration

### Crea Wallet

```javascript
async function createWallet(publicKey, privateKey = null) {
  try {
    const data = await apiCall('/wallet/create', {
      method: 'POST',
      body: JSON.stringify({ publicKey, privateKey })
    });
    
    if (data.success) {
      const wallet = data.wallet;
      
      // Salva localmente
      localStorage.setItem('wallet', JSON.stringify(wallet));
      
      console.log('✅ Wallet creato:', wallet.address);
      console.log('Saldo:', wallet.balance);
      
      return wallet;
    }
  } catch (error) {
    console.error('❌ Errore creazione wallet:', error);
  }
}
```

### Ottieni Saldo

```javascript
async function getBalance(address) {
  try {
    const data = await apiCall(`/wallet/balance/${address}`);
    
    if (data.success) {
      console.log('💰 Saldo:', data.balance, 'GNT');
      return data.balance;
    }
  } catch (error) {
    console.error('❌ Errore lettura saldo:', error);
  }
}
```

### Trasferisci GNT

```javascript
async function transferGNT(from, to, amount) {
  try {
    const data = await apiCall('/wallet/transfer', {
      method: 'POST',
      body: JSON.stringify({ from, to, amount })
    });
    
    if (data.success) {
      console.log('✅ Trasferimento completato');
      console.log('Da:', data.from);
      console.log('A:', data.to);
      console.log('Importo:', data.amount);
      
      return data;
    }
  } catch (error) {
    console.error('❌ Errore trasferimento:', error);
  }
}
```

---

## ⛏️ Mining Integration

### Avvia Mining Job

```javascript
async function startMining(data, difficulty = 2, reward = 10) {
  try {
    const response = await apiCall('/mining/start', {
      method: 'POST',
      body: JSON.stringify({ data, difficulty, reward })
    });
    
    if (response.success) {
      const jobId = response.jobId;
      console.log('⛏️ Mining job avviato:', jobId);
      
      // Monitora il job
      monitorMiningJob(jobId);
      
      return jobId;
    }
  } catch (error) {
    console.error('❌ Errore avvio mining:', error);
  }
}
```

### Monitora Mining Job

```javascript
async function monitorMiningJob(jobId) {
  const interval = setInterval(async () => {
    try {
      const data = await apiCall(`/mining/status/${jobId}`);
      
      if (data.success) {
        console.log(`⛏️ Mining Job ${jobId}:`);
        console.log(`  - Completato: ${data.completed}`);
        console.log(`  - Nonce: ${data.nonce}`);
        console.log(`  - Hash: ${data.hash.substring(0, 16)}...`);
        console.log(`  - Tempo: ${data.elapsedTime}ms`);
        
        if (data.completed) {
          clearInterval(interval);
          console.log('✅ Mining completato!');
          console.log(`  - Reward: ${data.reward} GNT`);
        }
      }
    } catch (error) {
      console.error('❌ Errore monitoraggio:', error);
    }
  }, 1000);
}
```

### Ottieni Statistiche Mining

```javascript
async function getMiningStats() {
  try {
    const data = await apiCall('/mining/stats');
    
    if (data.success) {
      console.log('📊 Mining Statistics:');
      console.log(`  - Active Jobs: ${data.activeJobs}`);
      console.log(`  - Completed: ${data.completedJobs}`);
      console.log(`  - Total Hashes: ${data.totalHashes}`);
      console.log(`  - Hash Rate: ${data.hashRate} H/s`);
      console.log(`  - Total Rewards: ${data.totalRewards} GNT`);
      
      return data;
    }
  } catch (error) {
    console.error('❌ Errore statistiche:', error);
  }
}
```

---

## ⛓️ Blockchain Integration

### Ottieni Informazioni Blockchain

```javascript
async function getChainInfo() {
  try {
    const data = await apiCall('/chain/info');
    
    if (data.success) {
      console.log('⛓️ Blockchain Info:');
      console.log(`  - Height: ${data.height}`);
      console.log(`  - Difficulty: ${data.difficulty}`);
      console.log(`  - Total Transactions: ${data.totalTransactions}`);
      console.log(`  - Pending: ${data.pendingTransactions}`);
      console.log(`  - Valid: ${data.isValid}`);
      
      return data;
    }
  } catch (error) {
    console.error('❌ Errore blockchain:', error);
  }
}
```

### Aggiungi Transazione

```javascript
async function addTransaction(from, to, amount) {
  try {
    const data = await apiCall('/tx/new', {
      method: 'POST',
      body: JSON.stringify({ from, to, amount })
    });
    
    if (data.success) {
      console.log('✅ Transazione aggiunta al pool');
      return data;
    }
  } catch (error) {
    console.error('❌ Errore transazione:', error);
  }
}
```

### Estrai Blocco

```javascript
async function mineBlock(minerAddress) {
  try {
    const data = await apiCall('/block/mine', {
      method: 'POST',
      body: JSON.stringify({ minerAddress })
    });
    
    if (data.success) {
      console.log('✅ Blocco estratto!');
      console.log(`  - Index: ${data.block.index}`);
      console.log(`  - Hash: ${data.block.hash.substring(0, 16)}...`);
      console.log(`  - Transactions: ${data.block.transactions}`);
      console.log(`  - Nonce: ${data.block.nonce}`);
      
      return data.block;
    }
  } catch (error) {
    console.error('❌ Errore mining blocco:', error);
  }
}
```

### Ottieni Cronologia Transazioni

```javascript
async function getTransactionHistory(address, limit = 50) {
  try {
    const data = await apiCall(`/history/${address}?limit=${limit}`);
    
    if (data.success) {
      console.log(`📋 Transazioni per ${address}:`);
      data.transactions.forEach((tx, i) => {
        console.log(`  ${i + 1}. ${tx.from} → ${tx.to}: ${tx.amount} GNT`);
      });
      
      return data.transactions;
    }
  } catch (error) {
    console.error('❌ Errore cronologia:', error);
  }
}
```

---

## 🔄 Real-time Updates

### Polling per Aggiornamenti

```javascript
class BackendPoller {
  constructor(interval = 5000) {
    this.interval = interval;
    this.timers = [];
  }
  
  startPolling(endpoint, callback) {
    const timer = setInterval(async () => {
      try {
        const data = await apiCall(endpoint);
        if (data.success) {
          callback(data);
        }
      } catch (error) {
        console.error('Polling error:', error);
      }
    }, this.interval);
    
    this.timers.push(timer);
    return timer;
  }
  
  stopPolling(timer) {
    clearInterval(timer);
    this.timers = this.timers.filter(t => t !== timer);
  }
  
  stopAll() {
    this.timers.forEach(t => clearInterval(t));
    this.timers = [];
  }
}

// Uso
const poller = new BackendPoller(5000);

// Monitora blockchain
poller.startPolling('/chain/info', (data) => {
  console.log('Blockchain aggiornato:', data);
  updateBlockchainUI(data);
});

// Monitora mining
poller.startPolling('/mining/stats', (data) => {
  console.log('Mining stats aggiornate:', data);
  updateMiningUI(data);
});
```

---

## 🎨 UI Updates

### Aggiorna UI con Dati Backend

```javascript
function updateBlockchainUI(data) {
  document.getElementById('chain-height').textContent = data.height;
  document.getElementById('chain-difficulty').textContent = data.difficulty;
  document.getElementById('total-transactions').textContent = data.totalTransactions;
  document.getElementById('pending-transactions').textContent = data.pendingTransactions;
  document.getElementById('chain-valid').textContent = data.isValid ? '✅' : '❌';
}

function updateMiningUI(data) {
  document.getElementById('active-jobs').textContent = data.activeJobs;
  document.getElementById('completed-jobs').textContent = data.completedJobs;
  document.getElementById('hash-rate').textContent = data.hashRate + ' H/s';
  document.getElementById('total-rewards').textContent = data.totalRewards + ' GNT';
}

function updateWalletUI(wallet) {
  document.getElementById('wallet-address').textContent = wallet.address;
  document.getElementById('wallet-balance').textContent = wallet.balance + ' GNT';
}
```

---

## 🧪 Test di Integrazione

### Completo Workflow

```javascript
async function completeWorkflow() {
  console.log('🚀 Avvio workflow completo...\n');
  
  // 1. Genera identità
  console.log('1️⃣ Generazione identità...');
  const identity = await generateGhostIdentity();
  
  // 2. Crea wallet
  console.log('\n2️⃣ Creazione wallet...');
  const wallet = await createWallet(identity.publicKey);
  
  // 3. Ottieni saldo
  console.log('\n3️⃣ Lettura saldo...');
  const balance = await getBalance(wallet.address);
  
  // 4. Aggiungi transazione
  console.log('\n4️⃣ Aggiunta transazione...');
  await addTransaction(wallet.address, 'GNT-OTHER', 50);
  
  // 5. Estrai blocco
  console.log('\n5️⃣ Estrazione blocco...');
  const block = await mineBlock(wallet.address);
  
  // 6. Ottieni info blockchain
  console.log('\n6️⃣ Info blockchain...');
  const chainInfo = await getChainInfo();
  
  // 7. Avvia mining
  console.log('\n7️⃣ Avvio mining...');
  const jobId = await startMining('test_data', 2, 10);
  
  // 8. Ottieni statistiche
  console.log('\n8️⃣ Statistiche mining...');
  const stats = await getMiningStats();
  
  console.log('\n✅ Workflow completato!');
}

// Esegui
completeWorkflow();
```

---

## 🔗 Deployment Remoto

### Usa ngrok per Accesso Pubblico

```bash
# Installa ngrok
npm install -g ngrok

# Esponi il backend
ngrok http 3001

# Output:
# Forwarding    https://xxxx-xxxx-xxxx.ngrok.io -> http://localhost:3001
```

### Aggiorna Frontend per Accesso Remoto

```javascript
// Cambia API URL
const BACKEND_API = {
  BASE_URL: 'https://xxxx-xxxx-xxxx.ngrok.io',
  TIMEOUT: 5000,
  RETRY: 3
};
```

---

## 📊 Monitoraggio

### Dashboard di Monitoraggio

```html
<div id="backend-dashboard">
  <h2>Backend Status</h2>
  
  <div class="section">
    <h3>Blockchain</h3>
    <p>Height: <span id="chain-height">-</span></p>
    <p>Difficulty: <span id="chain-difficulty">-</span></p>
    <p>Transactions: <span id="total-transactions">-</span></p>
  </div>
  
  <div class="section">
    <h3>Mining</h3>
    <p>Active Jobs: <span id="active-jobs">-</span></p>
    <p>Completed: <span id="completed-jobs">-</span></p>
    <p>Hash Rate: <span id="hash-rate">-</span></p>
  </div>
  
  <div class="section">
    <h3>Wallet</h3>
    <p>Address: <span id="wallet-address">-</span></p>
    <p>Balance: <span id="wallet-balance">-</span></p>
  </div>
</div>

<script>
  // Aggiorna dashboard ogni 5 secondi
  setInterval(async () => {
    const chain = await apiCall('/chain/info');
    const mining = await apiCall('/mining/stats');
    
    if (chain.success) updateBlockchainUI(chain);
    if (mining.success) updateMiningUI(mining);
  }, 5000);
</script>
```

---

## 🐛 Troubleshooting

### CORS Error

```javascript
// Se ricevi errore CORS, verifica che il backend abbia CORS abilitato
// Nel backend (src/index.js):
app.use(cors());
```

### Connection Refused

```bash
# Verifica che il backend sia in esecuzione
curl http://localhost:3001/health

# Se non funziona, riavvia il backend
PORT=3001 npm start
```

### Timeout

```javascript
// Aumenta timeout se necessario
const BACKEND_API = {
  BASE_URL: 'http://localhost:3001',
  TIMEOUT: 10000  // 10 secondi
};
```

---

**Version**: 1.0.0  
**Last Updated**: May 16, 2026  
**Status**: ✅ READY FOR INTEGRATION
