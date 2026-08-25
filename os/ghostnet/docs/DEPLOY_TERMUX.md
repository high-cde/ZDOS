# X-ZDOS Backend - Deployment su Termux (Android)

Guida completa per eseguire il backend X-ZDOS su Termux (emulatore Linux per Android).

---

## 📱 Prerequisiti

- **Android Device** con Termux installato
- **Termux App** (scarica da F-Droid o Google Play)
- **Storage**: ~200MB disponibili
- **RAM**: Minimo 1GB

---

## 🔧 Installazione Passo per Passo

### 1. Installa Termux

Scarica Termux da:
- **F-Droid** (consigliato): https://f-droid.org/packages/com.termux/
- **Google Play**: https://play.google.com/store/apps/details?id=com.termux

### 2. Apri Termux e Aggiorna i Pacchetti

```bash
# Aggiorna package manager
apt update
apt upgrade -y
```

### 3. Installa Node.js

```bash
# Installa Node.js
pkg install nodejs -y

# Verifica installazione
node --version
npm --version
```

### 4. Installa Git

```bash
pkg install git -y
```

### 5. Clona il Repository

```bash
# Crea directory di lavoro
mkdir -p ~/projects
cd ~/projects

# Clona il repository
git clone https://github.com/high-cde/x-zdos-quantum-ghostnet-os.git
cd x-zdos-quantum-ghostnet-os/

# Entra nella directory backend
cd x-zdos-backend
```

### 6. Installa Dipendenze

```bash
# Installa dipendenze npm
npm install

# Verifica installazione
npm list
```

### 7. Avvia il Server

```bash
# Avvia il server
npm start

# Output atteso:
# ╔════════════════════════════════════════════════════════════╗
# ║  🟢 X-ZDOS GhostNet Backend - ONLINE                       ║
# ║  Version: 1.0.0 (Quantum Minimal v1)                      ║
# ║  Port: 3001                                                ║
# ║  Status: ✅ ACTIVE                                          ║
# ╚════════════════════════════════════════════════════════════╝
```

---

## 🌐 Accesso al Backend

### Locale (Stesso Dispositivo)
```bash
# Su Termux
curl http://localhost:3001/health
```

### Da Altro Dispositivo sulla Stessa Rete

1. **Trova l'IP del tuo dispositivo Android**:
```bash
# Su Termux
ifconfig | grep "inet addr"
# Cerca qualcosa come: 192.168.1.100
```

2. **Accedi da altro dispositivo**:
```bash
# Da computer sulla stessa rete WiFi
curl http://192.168.1.100:3001/health
```

### Esponi il Backend su Internet (Opzionale)

Usa **ngrok** per esporre il backend pubblicamente:

```bash
# Installa ngrok
pkg install wget -y
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip
unzip ngrok-v3-stable-linux-arm.zip
./ngrok http 3001

# Output:
# Forwarding    https://xxxx-xxxx-xxxx.ngrok.io -> http://localhost:3001
```

---

## 📊 Test del Backend

### Test Health Check

```bash
curl http://localhost:3001/health
```

**Risposta attesa:**
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

### Genera Identità

```bash
curl -X POST http://localhost:3001/identity/generate
```

### Crea Wallet

```bash
curl -X POST http://localhost:3001/wallet/create \
  -H "Content-Type: application/json" \
  -d '{
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE..."
  }'
```

### Estrai Blocco

```bash
curl -X POST http://localhost:3001/block/mine \
  -H "Content-Type: application/json" \
  -d '{
    "minerAddress": "GNT-MINER1234567890ABCDEFGHIJKLMNOP"
  }'
```

---

## 🔄 Esecuzione in Background

### Opzione 1: Usa `screen` (Consigliato)

```bash
# Installa screen
pkg install screen -y

# Crea una nuova sessione screen
screen -S x-zdos-backend

# Nel nuovo terminale, avvia il server
cd ~/projects/x-zdos-quantum-ghostnet-os/x-zdos-backend
npm start

# Scollega dalla sessione (Ctrl+A, poi D)
# Per ricollegarsi:
screen -r x-zdos-backend

# Per terminare la sessione:
screen -X -S x-zdos-backend quit
```

### Opzione 2: Usa `nohup`

```bash
# Avvia in background
nohup npm start > server.log 2>&1 &

# Visualizza log
tail -f server.log

# Termina il processo
pkill -f "npm start"
```

### Opzione 3: Crea uno Script di Avvio

```bash
# Crea script
cat > ~/start-backend.sh << 'EOF'
#!/bin/bash
cd ~/projects/x-zdos-quantum-ghostnet-os/x-zdos-backend
npm start
EOF

# Rendi eseguibile
chmod +x ~/start-backend.sh

# Esegui
~/start-backend.sh
```

---

## 📱 Integrazione con Frontend GhostNet

### Configura il Frontend per Usare il Backend

Nel file `index.html` della WebApp GhostNet, modifica:

```javascript
// Cambia da:
const API_URL = 'http://localhost:3001';

// A (per accesso da rete):
const API_URL = 'http://192.168.1.100:3001';

// O (per accesso pubblico con ngrok):
const API_URL = 'https://xxxx-xxxx-xxxx.ngrok.io';
```

### Esempio di Integrazione

```javascript
// Nel frontend GhostNet
const BACKEND_URL = 'http://192.168.1.100:3001';

// Genera identità
async function generateGhostIdentity() {
  const response = await fetch(`${BACKEND_URL}/identity/generate`, {
    method: 'POST'
  });
  const data = await response.json();
  console.log('New Identity:', data.identity);
  return data.identity;
}

// Crea wallet
async function createWallet(publicKey) {
  const response = await fetch(`${BACKEND_URL}/wallet/create`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ publicKey })
  });
  const data = await response.json();
  console.log('New Wallet:', data.wallet);
  return data.wallet;
}

// Estrai blocco
async function mineBlock(minerAddress) {
  const response = await fetch(`${BACKEND_URL}/block/mine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ minerAddress })
  });
  const data = await response.json();
  console.log('Block Mined:', data.block);
  return data.block;
}
```

---

## 🔍 Troubleshooting

### Errore: "Port 3001 already in use"

```bash
# Cambia porta
PORT=3002 npm start

# Oppure termina il processo che usa la porta
lsof -i :3001
kill -9 <PID>
```

### Errore: "Cannot find module 'express'"

```bash
# Reinstalla dipendenze
rm -rf node_modules package-lock.json
npm install
```

### Errore: "EACCES: permission denied"

```bash
# Concedi permessi
chmod -R 755 ~/projects/x-zdos-quantum-ghostnet-os/

# Oppure cambia proprietario
chown -R $(whoami) ~/projects/x-zdos-quantum-ghostnet-os/
```

### Il server si arresta quando chiudo Termux

Usa **screen** o **nohup** per esecuzione persistente (vedi sezione "Esecuzione in Background").

---

## 📊 Monitoraggio

### Visualizza Statistiche

```bash
# Blockchain info
curl http://localhost:3001/chain/info

# Mining stats
curl http://localhost:3001/mining/stats

# Wallet stats
curl http://localhost:3001/wallet/stats
```

### Visualizza Log

```bash
# Se usi nohup
tail -f server.log

# Se usi screen
screen -r x-zdos-backend
```

---

## 🔐 Sicurezza

### Firewall (Opzionale)

Se vuoi limitare l'accesso al backend:

```bash
# Installa ufw
pkg install ufw -y

# Abilita firewall
ufw enable

# Permetti solo localhost
ufw allow from 127.0.0.1 to any port 3001

# Oppure permetti la tua rete locale
ufw allow from 192.168.1.0/24 to any port 3001
```

### Backup dei Dati

```bash
# Backup della blockchain e wallet
tar -czf backup-$(date +%Y%m%d).tar.gz ~/projects/x-zdos-quantum-ghostnet-os/x-zdos-backend/data/

# Ripristino
tar -xzf backup-20260515.tar.gz -C ~/projects/x-zdos-quantum-ghostnet-os/x-zdos-backend/
```

---

## 📈 Performance

### Ottimizzazioni per Termux

```bash
# Aumenta memoria disponibile (se possibile)
# Modifica in Termux settings

# Limita processi in background
ps aux | grep node

# Monitora uso risorse
top
```

---

## 🚀 Aggiornamenti

### Aggiorna il Backend

```bash
cd ~/projects/x-zdos-quantum-ghostnet-os/x-zdos-backend

# Fetch ultimi cambiamenti
git pull origin master

# Reinstalla dipendenze
npm install

# Riavvia il server
npm start
```

---

## 📞 Support

Se riscontri problemi:

1. **Verifica i log**: `tail -f server.log`
2. **Testa la connessione**: `curl http://localhost:3001/health`
3. **Controlla le dipendenze**: `npm list`
4. **Leggi la documentazione**: [docs/API.md](./API.md)

---

## 📱 Comandi Utili Termux

```bash
# Visualizza storage
df -h

# Visualizza memoria
free -h

# Visualizza processi Node.js
ps aux | grep node

# Termina processo
kill -9 <PID>

# Visualizza porta in uso
netstat -tulpn | grep 3001
```

---

## 🎯 Prossimi Step

1. ✅ Backend in esecuzione su Termux
2. ✅ Frontend GhostNet collegato
3. ⏭️ Aggiungi autenticazione
4. ⏭️ Implementa database remoto
5. ⏭️ Deploy su cloud (Heroku/Railway)

---

**Version**: 1.0.0  
**Last Updated**: May 15, 2026  
**Status**: ✅ TESTED ON TERMUX
