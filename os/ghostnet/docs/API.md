# X-ZDOS GhostNet Backend - API Documentation

**Version**: 1.0.0 (Quantum Minimal v1)  
**Status**: ✅ ACTIVE  
**Base URL**: `http://localhost:3001`

---

## 📋 Table of Contents

1. [Health Check](#health-check)
2. [Identity Engine](#identity-engine)
3. [Blockchain](#blockchain)
4. [Mining](#mining)
5. [Wallet](#wallet)
6. [Error Handling](#error-handling)

---

## Health Check

### GET /health
Verifica lo stato del server

**Response:**
```json
{
  "success": true,
  "status": "online",
  "timestamp": "2026-05-15T22:30:00.000Z",
  "version": "1.0.0",
  "modules": {
    "identity": "active",
    "blockchain": "active",
    "mining": "active",
    "wallet": "active"
  }
}
```

---

## Identity Engine

### POST /identity/generate
Genera una nuova identità GHOST con chiavi ECDSA secp256k1

**Request:**
```bash
curl -X POST http://localhost:3001/identity/generate
```

**Response:**
```json
{
  "success": true,
  "identity": {
    "ghostAddress": "GHOST-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "displayAlias": "ghost_a1b2c3d4",
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
    "createdAt": "2026-05-15T22:30:00.000Z"
  }
}
```

### POST /identity/sign
Firma un messaggio con una chiave privata

**Request:**
```bash
curl -X POST http://localhost:3001/identity/sign \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello GhostNet",
    "privateKey": "-----BEGIN PRIVATE KEY-----\n..."
  }'
```

**Response:**
```json
{
  "success": true,
  "signature": "304402203f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f022047..."
}
```

### POST /identity/verify
Verifica la firma di un messaggio

**Request:**
```bash
curl -X POST http://localhost:3001/identity/verify \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello GhostNet",
    "signature": "304402203f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f022047...",
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE..."
  }'
```

**Response:**
```json
{
  "success": true,
  "isValid": true
}
```

### GET /identity/list
Elenca tutte le identità salvate

**Request:**
```bash
curl http://localhost:3001/identity/list
```

**Response:**
```json
{
  "success": true,
  "identities": [
    {
      "file": "GHOST-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6.json",
      "ghostAddress": "GHOST-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
      "displayAlias": "ghost_a1b2c3d4",
      "createdAt": "2026-05-15T22:30:00.000Z"
    }
  ]
}
```

---

## Blockchain

### GET /chain/info
Ottiene informazioni sulla blockchain

**Request:**
```bash
curl http://localhost:3001/chain/info
```

**Response:**
```json
{
  "success": true,
  "height": 42,
  "difficulty": 3,
  "totalTransactions": 156,
  "pendingTransactions": 5,
  "isValid": true,
  "latestBlock": {
    "index": 41,
    "hash": "0000a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6",
    "timestamp": 1715808600000,
    "transactions": 3
  }
}
```

### POST /tx/new
Aggiunge una nuova transazione al pool

**Request:**
```bash
curl -X POST http://localhost:3001/tx/new \
  -H "Content-Type: application/json" \
  -d '{
    "from": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "to": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
    "amount": 100
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Transaction added to pool"
}
```

### GET /tx/pool
Ottiene il pool di transazioni in sospeso

**Request:**
```bash
curl http://localhost:3001/tx/pool
```

**Response:**
```json
{
  "success": true,
  "transactions": [
    {
      "from": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
      "to": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
      "amount": 100,
      "timestamp": 1715808600000,
      "id": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
    }
  ],
  "count": 1
}
```

### POST /block/mine
Estrae un nuovo blocco (Proof-of-Work)

**Request:**
```bash
curl -X POST http://localhost:3001/block/mine \
  -H "Content-Type: application/json" \
  -d '{
    "minerAddress": "GNT-MINER1234567890ABCDEFGHIJKLMNOP"
  }'
```

**Response:**
```json
{
  "success": true,
  "block": {
    "index": 42,
    "hash": "0000b1c2d3e4f5g6h7i8j9k0l1m2n3o4p5q6r7s8t9u0v1w2x3y4z5",
    "timestamp": 1715808700000,
    "transactions": 5,
    "nonce": 12345,
    "difficulty": 3
  }
}
```

### GET /block/:index
Ottiene un blocco per indice

**Request:**
```bash
curl http://localhost:3001/block/42
```

**Response:**
```json
{
  "success": true,
  "block": {
    "index": 42,
    "timestamp": 1715808700000,
    "transactions": [...],
    "previousHash": "0000a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6",
    "nonce": 12345,
    "difficulty": 3,
    "hash": "0000b1c2d3e4f5g6h7i8j9k0l1m2n3o4p5q6r7s8t9u0v1w2x3y4z5"
  }
}
```

### GET /balance/:address
Ottiene il saldo di un indirizzo

**Request:**
```bash
curl http://localhost:3001/balance/GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6
```

**Response:**
```json
{
  "success": true,
  "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
  "balance": 1250
}
```

### GET /history/:address
Ottiene la cronologia delle transazioni

**Request:**
```bash
curl "http://localhost:3001/history/GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6?limit=10"
```

**Response:**
```json
{
  "success": true,
  "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
  "transactions": [
    {
      "from": "SYSTEM",
      "to": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
      "amount": 10,
      "type": "mining_reward",
      "timestamp": 1715808700000,
      "blockIndex": 42,
      "blockHash": "0000b1c2d3e4f5g6h7i8j9k0l1m2n3o4p5q6r7s8t9u0v1w2x3y4z5"
    }
  ]
}
```

---

## Mining

### POST /mining/start
Avvia un job di mining

**Request:**
```bash
curl -X POST http://localhost:3001/mining/start \
  -H "Content-Type: application/json" \
  -d '{
    "data": "mining_data_here",
    "difficulty": 3,
    "reward": 10
  }'
```

**Response:**
```json
{
  "success": true,
  "jobId": "a1b2c3d4e5f6g7h8"
}
```

### GET /mining/status/:jobId
Ottiene lo stato di un job di mining

**Request:**
```bash
curl http://localhost:3001/mining/status/a1b2c3d4e5f6g7h8
```

**Response:**
```json
{
  "success": true,
  "jobId": "a1b2c3d4e5f6g7h8",
  "completed": true,
  "difficulty": 3,
  "nonce": 45678,
  "hash": "0000c1d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4",
  "elapsedTime": 2345,
  "reward": 10
}
```

### GET /mining/stats
Ottiene statistiche di mining

**Request:**
```bash
curl http://localhost:3001/mining/stats
```

**Response:**
```json
{
  "success": true,
  "activeJobs": 0,
  "completedJobs": 42,
  "totalHashes": 1234567890,
  "hashRate": 125000,
  "averageDifficulty": 2.8,
  "totalRewards": 420
}
```

### GET /mining/completed
Ottiene i job di mining completati

**Request:**
```bash
curl "http://localhost:3001/mining/completed?limit=5"
```

**Response:**
```json
{
  "success": true,
  "jobs": [
    {
      "jobId": "a1b2c3d4e5f6g7h8",
      "difficulty": 3,
      "nonce": 45678,
      "hash": "0000c1d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4",
      "elapsedTime": 2345,
      "reward": 10,
      "completedAt": "2026-05-15T22:35:00.000Z"
    }
  ]
}
```

---

## Wallet

### POST /wallet/create
Crea un nuovo wallet

**Request:**
```bash
curl -X POST http://localhost:3001/wallet/create \
  -H "Content-Type: application/json" \
  -d '{
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
    "privateKey": "-----BEGIN PRIVATE KEY-----\n..."
  }'
```

**Response:**
```json
{
  "success": true,
  "wallet": {
    "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "balance": 0,
    "createdAt": "2026-05-15T22:30:00.000Z"
  }
}
```

### GET /wallet/:address
Ottiene un wallet

**Request:**
```bash
curl http://localhost:3001/wallet/GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6
```

**Response:**
```json
{
  "success": true,
  "wallet": {
    "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
    "balance": 1250,
    "createdAt": "2026-05-15T22:30:00.000Z"
  }
}
```

### GET /wallet/balance/:address
Ottiene il saldo di un wallet

**Request:**
```bash
curl http://localhost:3001/wallet/balance/GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6
```

**Response:**
```json
{
  "success": true,
  "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
  "balance": 1250
}
```

### POST /wallet/transfer
Trasferisce GNT tra wallet

**Request:**
```bash
curl -X POST http://localhost:3001/wallet/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "from": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
    "to": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
    "amount": 100
  }'
```

**Response:**
```json
{
  "success": true,
  "from": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
  "to": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
  "amount": 100,
  "fromBalance": 1150,
  "toBalance": 100,
  "timestamp": "2026-05-15T22:35:00.000Z"
}
```

### GET /wallet/list
Elenca tutti i wallet

**Request:**
```bash
curl http://localhost:3001/wallet/list
```

**Response:**
```json
{
  "success": true,
  "wallets": [
    {
      "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
      "balance": 1150,
      "createdAt": "2026-05-15T22:30:00.000Z"
    },
    {
      "address": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
      "balance": 100,
      "createdAt": "2026-05-15T22:35:00.000Z"
    }
  ]
}
```

### GET /wallet/stats
Ottiene statistiche wallet

**Request:**
```bash
curl http://localhost:3001/wallet/stats
```

**Response:**
```json
{
  "success": true,
  "totalWallets": 2,
  "totalBalance": 1250,
  "averageBalance": 625,
  "topWallets": [
    {
      "address": "GNT-A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6",
      "balance": 1150
    },
    {
      "address": "GNT-X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6",
      "balance": 100
    }
  ]
}
```

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": "Description of the error"
}
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error |

### Example Error Response

```bash
curl -X POST http://localhost:3001/tx/new \
  -H "Content-Type: application/json" \
  -d '{"from": "GNT-123"}'
```

```json
{
  "success": false,
  "error": "Missing transaction fields"
}
```

---

## Integration Example

```javascript
// Connect to X-ZDOS Backend
const BASE_URL = 'http://localhost:3001';

// Generate Identity
async function generateIdentity() {
  const response = await fetch(`${BASE_URL}/identity/generate`, {
    method: 'POST'
  });
  return await response.json();
}

// Create Wallet
async function createWallet(publicKey) {
  const response = await fetch(`${BASE_URL}/wallet/create`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ publicKey })
  });
  return await response.json();
}

// Mine Block
async function mineBlock(minerAddress) {
  const response = await fetch(`${BASE_URL}/block/mine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ minerAddress })
  });
  return await response.json();
}

// Get Balance
async function getBalance(address) {
  const response = await fetch(`${BASE_URL}/balance/${address}`);
  return await response.json();
}
```

---

**Last Updated**: May 15, 2026  
**API Version**: 1.0.0  
**Status**: ✅ STABLE
