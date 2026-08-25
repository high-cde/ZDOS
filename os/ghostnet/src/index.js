/**
 * X-ZDOS GhostNet Backend - Main Server
 * Express API per Identity, Blockchain, Mining, Wallet
 */

import express from 'express';
import cors from 'cors';
import IdentityEngine from './identity/index.js';
import Blockchain from './blockchain/index.js';
import MiningEngine from './mining/index.js';
import WalletEngine from './wallet/index.js';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(express.json());
app.use(cors());

// Inizializza i motori
const identity = new IdentityEngine('./data/identities');
const blockchain = new Blockchain('./data/blockchain.json');
const mining = new MiningEngine();
const wallet = new WalletEngine('./data/wallets');

// ==================== IDENTITY ENDPOINTS ====================

/**
 * POST /identity/generate
 * Genera una nuova identità GHOST
 */
app.post('/identity/generate', (req, res) => {
  try {
    const newIdentity = identity.generateIdentity();
    res.json({
      success: true,
      identity: {
        ghostAddress: newIdentity.ghostAddress,
        displayAlias: newIdentity.displayAlias,
        publicKey: newIdentity.publicKey.substring(0, 50) + '...',
        createdAt: newIdentity.createdAt
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /identity/sign
 * Firma un messaggio
 */
app.post('/identity/sign', (req, res) => {
  try {
    const { message, privateKey } = req.body;
    if (!message || !privateKey) {
      return res.status(400).json({ success: false, error: 'Missing message or privateKey' });
    }
    const signature = identity.signMessage(privateKey, message);
    res.json({ success: true, signature });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /identity/verify
 * Verifica una firma
 */
app.post('/identity/verify', (req, res) => {
  try {
    const { message, signature, publicKey } = req.body;
    if (!message || !signature || !publicKey) {
      return res.status(400).json({ success: false, error: 'Missing parameters' });
    }
    const isValid = identity.verifySignature(publicKey, message, signature);
    res.json({ success: true, isValid });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /identity/list
 * Elenca tutte le identità salvate
 */
app.get('/identity/list', (req, res) => {
  try {
    const identities = identity.listIdentities();
    res.json({ success: true, identities });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== BLOCKCHAIN ENDPOINTS ====================

/**
 * GET /chain/info
 * Informazioni sulla blockchain
 */
app.get('/chain/info', (req, res) => {
  try {
    const info = blockchain.getChainInfo();
    res.json({ success: true, ...info });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /tx/new
 * Aggiunge una nuova transazione
 */
app.post('/tx/new', (req, res) => {
  try {
    const { from, to, amount } = req.body;
    if (!from || !to || !amount) {
      return res.status(400).json({ success: false, error: 'Missing transaction fields' });
    }
    blockchain.addTransaction({ from, to, amount });
    res.json({ success: true, message: 'Transaction added to pool' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /tx/pool
 * Ottiene il pool di transazioni in sospeso
 */
app.get('/tx/pool', (req, res) => {
  try {
    const pool = blockchain.getTransactionPool();
    res.json({ success: true, transactions: pool, count: pool.length });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /block/mine
 * Estrae un nuovo blocco
 */
app.post('/block/mine', (req, res) => {
  try {
    const { minerAddress } = req.body;
    if (!minerAddress) {
      return res.status(400).json({ success: false, error: 'Missing minerAddress' });
    }
    const block = blockchain.minePendingTransactions(minerAddress);
    blockchain.adjustDifficulty();
    res.json({
      success: true,
      block: {
        index: block.index,
        hash: block.hash,
        timestamp: block.timestamp,
        transactions: block.transactions.length,
        nonce: block.nonce,
        difficulty: block.difficulty
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /block/:index
 * Ottiene un blocco per indice
 */
app.get('/block/:index', (req, res) => {
  try {
    const block = blockchain.getBlockByIndex(parseInt(req.params.index));
    if (!block) {
      return res.status(404).json({ success: false, error: 'Block not found' });
    }
    res.json({ success: true, block });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /balance/:address
 * Ottiene il saldo di un indirizzo
 */
app.get('/balance/:address', (req, res) => {
  try {
    const balance = blockchain.getBalance(req.params.address);
    res.json({ success: true, address: req.params.address, balance });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /history/:address
 * Ottiene la cronologia delle transazioni
 */
app.get('/history/:address', (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const history = blockchain.getTransactionHistory(req.params.address, limit);
    res.json({ success: true, address: req.params.address, transactions: history });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== MINING ENDPOINTS ====================

/**
 * POST /mining/start
 * Avvia un job di mining
 */
app.post('/mining/start', (req, res) => {
  try {
    const { data, difficulty, reward } = req.body;
    if (!data) {
      return res.status(400).json({ success: false, error: 'Missing data' });
    }
    const jobId = mining.startMiningJob(data, difficulty, reward);
    res.json({ success: true, jobId });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /mining/status/:jobId
 * Ottiene lo stato di un job di mining
 */
app.get('/mining/status/:jobId', (req, res) => {
  try {
    const status = mining.getJobStatus(req.params.jobId);
    if (!status) {
      return res.status(404).json({ success: false, error: 'Job not found' });
    }
    res.json({ success: true, ...status });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /mining/stats
 * Ottiene statistiche di mining
 */
app.get('/mining/stats', (req, res) => {
  try {
    const stats = mining.getStats();
    res.json({ success: true, ...stats });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /mining/completed
 * Ottiene i job di mining completati
 */
app.get('/mining/completed', (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const jobs = mining.getCompletedJobs(limit);
    res.json({ success: true, jobs });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== WALLET ENDPOINTS ====================

/**
 * POST /wallet/create
 * Crea un nuovo wallet
 */
app.post('/wallet/create', (req, res) => {
  try {
    const { publicKey, privateKey } = req.body;
    if (!publicKey) {
      return res.status(400).json({ success: false, error: 'Missing publicKey' });
    }
    const newWallet = wallet.createWallet(publicKey, privateKey);
    res.json({
      success: true,
      wallet: {
        address: newWallet.address,
        balance: newWallet.balance,
        createdAt: newWallet.createdAt
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /wallet/:address
 * Ottiene un wallet
 */
app.get('/wallet/:address', (req, res) => {
  try {
    const w = wallet.getWallet(req.params.address);
    if (!w) {
      return res.status(404).json({ success: false, error: 'Wallet not found' });
    }
    res.json({ success: true, wallet: w.toJSON() });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /wallet/balance/:address
 * Ottiene il saldo di un wallet
 */
app.get('/wallet/balance/:address', (req, res) => {
  try {
    const balance = wallet.getBalance(req.params.address);
    res.json({ success: true, address: req.params.address, balance });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /wallet/transfer
 * Trasferisce GNT tra wallet
 */
app.post('/wallet/transfer', (req, res) => {
  try {
    const { from, to, amount } = req.body;
    if (!from || !to || !amount) {
      return res.status(400).json({ success: false, error: 'Missing parameters' });
    }
    const result = wallet.transfer(from, to, amount);
    res.json({ success: true, ...result });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /wallet/list
 * Elenca tutti i wallet
 */
app.get('/wallet/list', (req, res) => {
  try {
    const wallets = wallet.listWallets();
    res.json({ success: true, wallets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /wallet/stats
 * Ottiene statistiche wallet
 */
app.get('/wallet/stats', (req, res) => {
  try {
    const stats = wallet.getStats();
    res.json({ success: true, ...stats });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== HEALTH CHECK ====================

/**
 * GET /health
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'online',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    modules: {
      identity: 'active',
      blockchain: 'active',
      mining: 'active',
      wallet: 'active'
    }
  });
});

/**
 * GET /
 * Root endpoint
 */
app.get('/', (req, res) => {
  res.json({
    name: 'X-ZDOS GhostNet Backend',
    version: '1.0.0',
    description: 'GhostNet Core Engine – ZDOS Quantum Minimal v1',
    endpoints: {
      identity: '/identity/generate, /identity/sign, /identity/verify, /identity/list',
      blockchain: '/chain/info, /tx/new, /tx/pool, /block/mine, /block/:index, /balance/:address, /history/:address',
      mining: '/mining/start, /mining/status/:jobId, /mining/stats, /mining/completed',
      wallet: '/wallet/create, /wallet/:address, /wallet/balance/:address, /wallet/transfer, /wallet/list, /wallet/stats',
      health: '/health'
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  🟢 X-ZDOS GhostNet Backend - ONLINE                       ║
║  Version: 1.0.0 (Quantum Minimal v1)                      ║
║  Port: ${PORT}                                              ║
║  Status: ✅ ACTIVE                                          ║
╚════════════════════════════════════════════════════════════╝

📡 API Endpoints:
  • Identity Engine: /identity/*
  • Blockchain: /chain/*, /tx/*, /block/*
  • Mining Engine: /mining/*
  • Wallet Engine: /wallet/*
  • Health: /health

🚀 Ready to accept connections!
  `);
});

export default app;
