# 🔌 API Endpoints Reference

Complete documentation of all ZDOS Quantum System API endpoints.

---

## Base URL

```
http://localhost:3001
```

---

## System Endpoints

### Health Check
```
GET /health
```

Returns system status and active systems.

**Response:**
```json
{
  "status": "online",
  "version": "1.0.0-quantum",
  "systems": {
    "agi": "ACTIVE",
    "payments": "ACTIVE",
    "z_onion": "ACTIVE"
  }
}
```

### System Information
```
GET /info
```

Returns detailed system information.

### System Dashboard
```
GET /system/dashboard
```

Returns integrated dashboard with all system metrics.

---

## AGI Engine Endpoints

### Multi-Step Reasoning
```
POST /agi/reasoning
```

Perform multi-step reasoning analysis.

**Request:**
```json
{
  "query": "Analyze this transaction",
  "context": {}
}
```

### Real-Time Analysis
```
POST /agi/analyze
```

Analyze data in real-time.

**Request:**
```json
{
  "data_source": "blockchain",
  "analysis_type": "security"
}
```

### Contextual Intelligence
```
POST /agi/intelligence
```

Get contextual intelligence for workflows.

**Request:**
```json
{
  "workflow_context": "payment_processing"
}
```

### Persistent Memory
```
POST /agi/memory/:operation
```

Manage AGI persistent memory.

**Operations:**
- `save` - Save conversation
- `retrieve` - Get conversation
- `list` - List all conversations
- `delete` - Delete conversation

### AGI Status
```
GET /agi/status
```

Get AGI engine status and capabilities.

---

## Crypto Payment Endpoints

### Create Payment
```
POST /payments/create
```

Create a new payment (DSN or Monero).

**Request:**
```json
{
  "from": "0x123...",
  "to": "0x456...",
  "amount": 100,
  "currency": "DSN"
}
```

### Atomic Swap
```
POST /payments/atomic-swap
```

Perform atomic swap between DSN and Monero.

**Request:**
```json
{
  "from_currency": "DSN",
  "to_currency": "XMR",
  "amount": 50,
  "from_address": "0x123...",
  "to_address": "xmr_address..."
}
```

### Create Escrow
```
POST /payments/escrow
```

Create escrow account for secure payments.

**Request:**
```json
{
  "buyer": "0x123...",
  "seller": "0x456...",
  "amount": 100,
  "currency": "DSN"
}
```

### Release Escrow
```
POST /payments/escrow/:escrow_id/release
```

Release escrowed funds.

**Request:**
```json
{
  "reason": "Transaction completed"
}
```

### Payment Statistics
```
GET /payments/stats
```

Get payment system statistics.

### Payment System Status
```
GET /payments/status
```

Get payment system status.

---

## Z-Onion Infrastructure Endpoints

### Create Onion Service
```
POST /z-onion/service
```

Create a new onion service.

**Request:**
```json
{
  "port": 8080,
  "version": 3
}
```

### Build Tor Circuit
```
POST /z-onion/circuit
```

Build a new Tor circuit.

**Request:**
```json
{
  "hops": 3,
  "exit_node": "preferred"
}
```

### Route Data
```
POST /z-onion/route
```

Route data through Tor circuit.

**Request:**
```json
{
  "circuit_id": "circuit_123",
  "data": "encrypted_payload",
  "destination": "onion_address"
}
```

### Analyze Tor Network
```
GET /z-onion/analyze
```

Analyze Tor network status and metrics.

### Detect Anomalies
```
GET /z-onion/anomalies
```

Detect anomalies in Tor network.

### Z-Onion Status
```
GET /z-onion/status
```

Get Z-Onion infrastructure status.

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "error": "Error message",
  "timestamp": "2026-05-16T11:20:17.710Z"
}
```

---

## Rate Limiting

Currently no rate limiting. Production deployment should implement:
- 100 requests/minute per IP
- 1000 requests/hour per API key
- 10000 requests/day per API key

---

## Authentication

Current version uses no authentication. Future versions will support:
- JWT tokens
- API keys
- OAuth 2.0
- 2FA

---

## CORS

CORS is enabled for all origins. Configure in production:
```javascript
cors({
  origin: ['https://your-domain.com'],
  credentials: true
})
```

---

## Versioning

API version: `1.0.0-quantum`

Future versions will use URL versioning:
- `/v1/agi/reasoning`
- `/v2/payments/create`

---

## See Also

- [[AGI Engine]] - AGI-specific documentation
- [[Crypto Payments]] - Payment system details
- [[Z-Onion Infrastructure]] - Tor infrastructure details
