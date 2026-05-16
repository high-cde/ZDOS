# ⚡ Quick Start Guide

Get ZDOS Quantum System running in 5 minutes!

---

## 1. Clone Repository

```bash
git clone https://github.com/high-cde/x-zdos-quantum-ghostnet-os.git
cd x-zdos-quantum-ghostnet-os
```

---

## 2. Install Dependencies

```bash
npm install
```

---

## 3. Start the Backend

```bash
npm start
# Server running on http://localhost:3001
```

---

## 4. Test Connection

```bash
curl http://localhost:3001/health
```

Expected response:
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

---

## 5. Try Your First API Call

### Test AGI Engine
```bash
curl -X POST http://localhost:3001/agi/status
```

### Create a Payment
```bash
curl -X POST http://localhost:3001/payments/create \
  -H "Content-Type: application/json" \
  -d '{
    "from": "0x123...",
    "to": "0x456...",
    "amount": 100,
    "currency": "DSN"
  }'
```

### Build Tor Circuit
```bash
curl -X POST http://localhost:3001/z-onion/circuit \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 🎉 You're Ready!

Your ZDOS Quantum System is now running! 

Next steps:
- Read the [[API Endpoints]] documentation
- Explore the [[AGI Engine]] capabilities
- Try the [[Crypto Payments]] system
- Check out the [[Z-Onion Infrastructure]]

---

## 📚 Full Documentation

- **[[Installation]]** - Detailed setup
- **[[Configuration]]** - Customize your setup
- **[[API Endpoints]]** - Complete API reference
- **[[Deployment]]** - Production deployment
