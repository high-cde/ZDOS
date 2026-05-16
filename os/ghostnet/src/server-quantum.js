/**
 * ZDOS Quantum Server
 * Integrated AGI + Crypto Payments + Z-Onion Infrastructure
 * 
 * This is the main server that orchestrates all systems
 */

import express from 'express';
import cors from 'cors';
import QuantumAGIEngine from './agi/quantum-engine.js';
import CryptoPaymentEngine from './payments/crypto-engine.js';
import ZOnionSuite from './infrastructure/z-onion-suite.js';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Initialize all engines
const agi_engine = new QuantumAGIEngine();
const payment_engine = new CryptoPaymentEngine();
const z_onion = new ZOnionSuite();

/**
 * ============================================
 * AGI ENDPOINTS
 * ============================================
 */

// Multi-Step Reasoning
app.post('/agi/reasoning', async (req, res) => {
  try {
    const { query, context } = req.body;
    const result = await agi_engine.multiStepReasoning(query, context);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Real-Time Analysis
app.post('/agi/analyze', async (req, res) => {
  try {
    const { data_source, analysis_type } = req.body;
    const result = await agi_engine.realTimeAnalysis(data_source, analysis_type);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Contextual Intelligence
app.post('/agi/intelligence', async (req, res) => {
  try {
    const { workflow_context } = req.body;
    const result = await agi_engine.contextualIntelligence(workflow_context);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Persistent Memory
app.post('/agi/memory/:operation', async (req, res) => {
  try {
    const { operation } = req.params;
    const { data } = req.body;
    const result = await agi_engine.persistentMemory(operation, data);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// AGI System Status
app.get('/agi/status', (req, res) => {
  res.json({
    success: true,
    data: agi_engine.getSystemStatus(),
    timestamp: new Date().toISOString()
  });
});

/**
 * ============================================
 * CRYPTO PAYMENT ENDPOINTS
 * ============================================
 */

// Create Payment (DSN or Monero)
app.post('/payments/create', async (req, res) => {
  try {
    const payment_data = req.body;
    const result = await payment_engine.createPayment(payment_data);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Atomic Swap (DSN ↔ Monero)
app.post('/payments/atomic-swap', async (req, res) => {
  try {
    const swap_data = req.body;
    const result = await payment_engine.atomicSwap(swap_data);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Create Escrow
app.post('/payments/escrow', async (req, res) => {
  try {
    const escrow_data = req.body;
    const result = await payment_engine.createEscrow(escrow_data);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Release Escrow
app.post('/payments/escrow/:escrow_id/release', async (req, res) => {
  try {
    const { escrow_id } = req.params;
    const { reason } = req.body;
    const result = await payment_engine.releaseEscrow(escrow_id, reason);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Payment Statistics
app.get('/payments/stats', (req, res) => {
  res.json({
    success: true,
    data: payment_engine.getPaymentStats(),
    timestamp: new Date().toISOString()
  });
});

// Payment System Status
app.get('/payments/status', (req, res) => {
  res.json({
    success: true,
    data: payment_engine.getSystemStatus(),
    timestamp: new Date().toISOString()
  });
});

/**
 * ============================================
 * Z-ONION INFRASTRUCTURE ENDPOINTS
 * ============================================
 */

// Create Onion Service
app.post('/z-onion/service', async (req, res) => {
  try {
    const service_config = req.body;
    const result = await z_onion.createOnionService(service_config);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Build Tor Circuit
app.post('/z-onion/circuit', async (req, res) => {
  try {
    const circuit_config = req.body;
    const result = await z_onion.buildCircuit(circuit_config);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Route Data
app.post('/z-onion/route', async (req, res) => {
  try {
    const { circuit_id, data, destination } = req.body;
    const result = await z_onion.routeData(circuit_id, data, destination);
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Analyze Tor Network
app.get('/z-onion/analyze', async (req, res) => {
  try {
    const result = await z_onion.analyzeNetwork();
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Detect Anomalies
app.get('/z-onion/anomalies', async (req, res) => {
  try {
    const result = await z_onion.detectAnomalies();
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Z-Onion System Status
app.get('/z-onion/status', (req, res) => {
  res.json({
    success: true,
    data: z_onion.getSystemStatus(),
    timestamp: new Date().toISOString()
  });
});

/**
 * ============================================
 * INTEGRATED SYSTEM ENDPOINTS
 * ============================================
 */

// System Dashboard
app.get('/system/dashboard', (req, res) => {
  res.json({
    success: true,
    data: {
      agi_engine: agi_engine.getSystemStatus(),
      payment_engine: payment_engine.getSystemStatus(),
      z_onion_suite: z_onion.getSystemStatus(),
      timestamp: new Date().toISOString()
    }
  });
});

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    version: '1.0.0-quantum',
    systems: {
      agi: 'ACTIVE',
      payments: 'ACTIVE',
      z_onion: 'ACTIVE'
    },
    timestamp: new Date().toISOString()
  });
});

// System Information
app.get('/info', (req, res) => {
  res.json({
    name: 'ZDOS Quantum System',
    version: '1.0.0-quantum',
    description: 'Integrated AGI + Crypto Payments + Z-Onion Infrastructure',
    systems: {
      agi: 'Quantum-Neuro Reasoning Engine',
      payments: 'DSN + Monero Payment System',
      infrastructure: 'Z-Onion Tor Suite'
    },
    timestamp: new Date().toISOString()
  });
});

/**
 * ============================================
 * ERROR HANDLING
 * ============================================
 */

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: err.message
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

/**
 * ============================================
 * SERVER STARTUP
 * ============================================
 */

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  🟢 ZDOS QUANTUM SYSTEM - ONLINE                           ║
║  Version: 1.0.0-quantum                                    ║
║  Port: ${PORT}                                                ║
║  Status: ✅ ACTIVE                                          ║
║                                                            ║
║  Systems:                                                  ║
║  ✅ AGI Quantum-Neuro Engine                               ║
║  ✅ Crypto Payment System (DSN + Monero)                   ║
║  ✅ Z-Onion Infrastructure (Tor)                           ║
║                                                            ║
║  Endpoints:                                                ║
║  /agi/* - AGI Reasoning & Analysis                         ║
║  /payments/* - Crypto Payments                             ║
║  /z-onion/* - Tor Infrastructure                           ║
║  /system/dashboard - Integrated Dashboard                  ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
  `);
});

export default app;
