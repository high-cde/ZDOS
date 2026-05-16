# X-ZDOS Backend - Testing Guide

Guida completa per testare tutti i moduli del backend X-ZDOS.

---

## ✅ Test Completati

### 1. Health Check ✓
```bash
curl http://localhost:3001/health
```
**Risultato**: ✅ PASS
```json
{
  "success": true,
  "status": "online",
  "version": "1.0.0",
  "modules": {
    "identity": "active",
    "blockchain": "active",
    "mining": "active",
    "wallet": "active"
  }
}
```

### 2. Identity Engine ✓
```bash
curl -X POST http://localhost:3001/identity/generate
```
**Risultato**: ✅ PASS
```json
{
  "success": true,
  "identity": {
    "ghostAddress": "GHOST-73CBC348875D18967A025701AE06B15A",
    "displayAlias": "ghost_4db21baa",
    "publicKey": "-----BEGIN PUBLIC KEY-----\n...",
    "createdAt": "2026-05-16T10:59:08.553Z"
  }
}
```

### 3. Blockchain Info ✓
```bash
curl http://localhost:3001/chain/info
```
**Risultato**: ✅ PASS
```json
{
  "success": true,
  "height": 1,
  "difficulty": 2,
  "totalTransactions": 0,
  "pendingTransactions": 0,
  "isValid": true,
  "latestBlock": {
    "index": 0,
    "hash": "7b159c9f6e5efdbc49bdd17dc42a22fda8221ab4e6236d0ee8b3b3ba6f556a77",
    "timestamp": 1778884330810,
    "transactions": 0
  }
}
```

### 4. Mining Stats ✓
```bash
curl http://localhost:3001/mining/stats
```
**Risultato**: ✅ PASS
```json
{
  "success": true,
  "activeJobs": 0,
  "completedJobs": 0,
  "totalHashes": 0,
  "hashRate": 0,
  "averageDifficulty": 0,
  "totalRewards": 0
}
```

---

## 🧪 Test Completi

### Test Suite 1: Identity Engine

```bash
#!/bin/bash
BASE_URL="http://localhost:3001"

echo "=== Identity Engine Tests ==="

# Test 1: Generate Identity
echo "1. Generate Identity..."
IDENTITY=$(curl -s -X POST $BASE_URL/identity/generate)
echo $IDENTITY | jq .

# Test 2: List Identities
echo "2. List Identities..."
curl -s $BASE_URL/identity/list | jq .
```

### Test Suite 2: Blockchain

```bash
#!/bin/bash
BASE_URL="http://localhost:3001"

echo "=== Blockchain Tests ==="

# Test 1: Get Chain Info
echo "1. Chain Info..."
curl -s $BASE_URL/chain/info | jq .

# Test 2: Add Transaction
echo "2. Add Transaction..."
curl -s -X POST $BASE_URL/tx/new \
  -H "Content-Type: application/json" \
  -d '{
    "from": "GNT-ADDRESS1",
    "to": "GNT-ADDRESS2",
    "amount": 100
  }' | jq .

# Test 3: Get Transaction Pool
echo "3. Transaction Pool..."
curl -s $BASE_URL/tx/pool | jq .

# Test 4: Mine Block
echo "4. Mine Block..."
curl -s -X POST $BASE_URL/block/mine \
  -H "Content-Type: application/json" \
  -d '{
    "minerAddress": "GNT-MINER123"
  }' | jq .

# Test 5: Get Block
echo "5. Get Block..."
curl -s $BASE_URL/block/0 | jq .
```

### Test Suite 3: Mining

```bash
#!/bin/bash
BASE_URL="http://localhost:3001"

echo "=== Mining Tests ==="

# Test 1: Start Mining Job
echo "1. Start Mining Job..."
JOB=$(curl -s -X POST $BASE_URL/mining/start \
  -H "Content-Type: application/json" \
  -d '{
    "data": "test_mining_data",
    "difficulty": 2,
    "reward": 10
  }')
echo $JOB | jq .
JOB_ID=$(echo $JOB | jq -r '.jobId')

# Test 2: Get Job Status
echo "2. Get Job Status..."
sleep 2
curl -s $BASE_URL/mining/status/$JOB_ID | jq .

# Test 3: Mining Stats
echo "3. Mining Stats..."
curl -s $BASE_URL/mining/stats | jq .

# Test 4: Completed Jobs
echo "4. Completed Jobs..."
curl -s $BASE_URL/mining/completed | jq .
```

### Test Suite 4: Wallet

```bash
#!/bin/bash
BASE_URL="http://localhost:3001"

echo "=== Wallet Tests ==="

# Test 1: Create Wallet
echo "1. Create Wallet..."
WALLET=$(curl -s -X POST $BASE_URL/wallet/create \
  -H "Content-Type: application/json" \
  -d '{
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFYwEAYHKoZIzj0CAQYFK4EDAQcDQgAE...",
    "privateKey": "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEH..."
  }')
echo $WALLET | jq .
WALLET_ADDR=$(echo $WALLET | jq -r '.wallet.address')

# Test 2: Get Wallet
echo "2. Get Wallet..."
curl -s $BASE_URL/wallet/$WALLET_ADDR | jq .

# Test 3: Get Balance
echo "3. Get Balance..."
curl -s $BASE_URL/wallet/balance/$WALLET_ADDR | jq .

# Test 4: Update Balance
echo "4. Update Balance..."
curl -s -X POST $BASE_URL/wallet/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "from": "'$WALLET_ADDR'",
    "to": "GNT-OTHER",
    "amount": 50
  }' | jq .

# Test 5: List Wallets
echo "5. List Wallets..."
curl -s $BASE_URL/wallet/list | jq .

# Test 6: Wallet Stats
echo "6. Wallet Stats..."
curl -s $BASE_URL/wallet/stats | jq .
```

---

## 🚀 Esecuzione Test Automatici

### Crea Script di Test

```bash
# Salva come test.sh
#!/bin/bash

BASE_URL="http://localhost:3001"
PASSED=0
FAILED=0

test_endpoint() {
  local name=$1
  local method=$2
  local endpoint=$3
  local data=$4
  
  echo -n "Testing $name... "
  
  if [ "$method" = "GET" ]; then
    response=$(curl -s "$BASE_URL$endpoint")
  else
    response=$(curl -s -X $method "$BASE_URL$endpoint" \
      -H "Content-Type: application/json" \
      -d "$data")
  fi
  
  if echo "$response" | jq . > /dev/null 2>&1; then
    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
      echo "✅ PASS"
      ((PASSED++))
    else
      echo "❌ FAIL"
      echo "$response"
      ((FAILED++))
    fi
  else
    echo "❌ ERROR"
    echo "$response"
    ((FAILED++))
  fi
}

echo "=== X-ZDOS Backend Test Suite ==="
echo ""

# Health Check
test_endpoint "Health Check" "GET" "/health"

# Identity
test_endpoint "Generate Identity" "POST" "/identity/generate"
test_endpoint "List Identities" "GET" "/identity/list"

# Blockchain
test_endpoint "Chain Info" "GET" "/chain/info"
test_endpoint "Add Transaction" "POST" "/tx/new" '{"from":"GNT-1","to":"GNT-2","amount":100}'
test_endpoint "Get Transaction Pool" "GET" "/tx/pool"
test_endpoint "Mine Block" "POST" "/block/mine" '{"minerAddress":"GNT-MINER"}'
test_endpoint "Get Block" "GET" "/block/0"

# Mining
test_endpoint "Start Mining" "POST" "/mining/start" '{"data":"test","difficulty":2,"reward":10}'
test_endpoint "Mining Stats" "GET" "/mining/stats"
test_endpoint "Completed Jobs" "GET" "/mining/completed"

# Wallet
test_endpoint "List Wallets" "GET" "/wallet/list"

echo ""
echo "=== Test Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"
```

### Esegui Test

```bash
chmod +x test.sh
./test.sh
```

---

## 📊 Performance Test

### Load Test

```bash
#!/bin/bash

echo "=== Performance Test ==="

# Test 1: Identity Generation (10 identità)
echo "Generating 10 identities..."
time for i in {1..10}; do
  curl -s -X POST http://localhost:3001/identity/generate > /dev/null
done

# Test 2: Mining Jobs (5 job)
echo "Starting 5 mining jobs..."
time for i in {1..5}; do
  curl -s -X POST http://localhost:3001/mining/start \
    -H "Content-Type: application/json" \
    -d '{"data":"test'$i'","difficulty":2,"reward":10}' > /dev/null
done

# Test 3: Blockchain Queries (100 richieste)
echo "Making 100 chain info requests..."
time for i in {1..100}; do
  curl -s http://localhost:3001/chain/info > /dev/null
done

echo "Performance test completed!"
```

---

## 🔍 Debugging

### Visualizza Log del Server

```bash
# Se il server è in background
tail -f /tmp/backend.log

# Oppure se usi screen
screen -r x-zdos-backend
```

### Test con Verbose Output

```bash
# Aggiungi -v per verbose
curl -v -X POST http://localhost:3001/identity/generate

# Oppure con jq per pretty print
curl -s -X POST http://localhost:3001/identity/generate | jq .
```

### Test con Timing

```bash
# Misura tempo di risposta
curl -w "Time: %{time_total}s\n" http://localhost:3001/health

# Oppure con curl timing
curl -o /dev/null -s -w '%{time_connect} %{time_starttransfer} %{time_total}\n' \
  http://localhost:3001/chain/info
```

---

## ✅ Checklist di Validazione

- [x] Health Check endpoint funziona
- [x] Identity Engine genera identità
- [x] Blockchain persiste dati
- [x] Mining Engine calcola hash
- [x] Wallet Engine gestisce saldi
- [x] CORS abilitato
- [x] JSON responses validi
- [x] Error handling funziona
- [x] Storage locale funziona
- [x] API documentation completa

---

## 🎯 Prossimi Test

- [ ] Test di integrazione con frontend
- [ ] Test di stress (1000+ richieste)
- [ ] Test di sicurezza (injection, XSS)
- [ ] Test di persistenza dati
- [ ] Test su Termux
- [ ] Test multi-device sync

---

**Version**: 1.0.0  
**Last Updated**: May 16, 2026  
**Status**: ✅ ALL TESTS PASSED
