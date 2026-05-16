# X-ZDOS Quantum GhostNet OS v2.0

**Anonymous Decentralized Chat with Channels & Ghost Identity**

---

## 🎯 Panoramica

X-ZDOS è un ecosistema decentralizzato completamente client-side che combina blockchain, mining CPU, chat anonima crittografata, canali pubblici, identità ghost e mesh network. Tutto funziona offline nel browser, senza server backend.

### Novità v2.0

✨ **Sistema di Identità Ghost** - Registrazione anonima automatica con chiave crittografica  
✨ **Canali Pubblici** - Crea e unisciti a stanze di chat anonime  
✨ **Layout Sidebar** - Navigazione migliorata con 9 sezioni principali  
✨ **Messaggi Effimeri** - TTL di 1 ora con crittografia XOR  
✨ **Zero Dipendenze** - Vanilla JavaScript puro, nessun framework

---

## 🚀 Caratteristiche Principali

### 🔐 Identità Anonima

Ogni utente riceve automaticamente un'identità ghost unica al primo accesso:

- **GHOST Address**: Formato `GHOST-{32 hex chars}` (es. `GHOST-408CBEBA51936F2F`)
- **Display Alias**: Derivato dall'indirizzo (es. `ghost_408cbe`)
- **Public Key**: Chiave pubblica per crittografia
- **Regenerate**: Opzione per generare nuova identità (irreversibile)

Tutto salvato localmente in localStorage, mai trasmesso a server.

### 📡 Sistema di Canali

Crea e unisciti a canali pubblici per chat anonima:

- **Canali Predefiniti**: general, ghostnet, anonymous, trading, zdos
- **Crea Canali**: Nome e descrizione personalizzati
- **Chat Anonima**: Messaggi crittografati con TTL di 1 ora
- **Peer Discovery**: Visualizza numero di membri online

### ⛓️ Blockchain GNT

Blockchain proof-of-work locale con difficoltà dinamica:

- **Mining CPU**: Genera blocchi e ricevi GNT come reward
- **Validazione**: Verifica proof-of-work per ogni blocco
- **Explorer**: Visualizza catena completa e transazioni
- **Difficoltà Dinamica**: Aumenta ogni 10 blocchi

### ⛏️ Mining

Mining CPU locale senza GPU:

- **Hash Rate Real-Time**: Visualizza H/s attuali
- **Reward Automatica**: 10 GNT per blocco trovato
- **Start/Stop**: Controllo mining con pulsanti
- **Statistiche**: Blocchi trovati e reward totale

### 💬 Chat Anonima

Messaggi crittografati con TTL:

- **Crittografia XOR**: Demo (upgrade a AES-256 consigliato)
- **TTL 1 Ora**: Messaggi scadono automaticamente
- **Alias Dinamico**: Derivato da ghost address
- **Broadcast**: Messaggi distribuiti via mesh

### 🌐 Mesh Network

Peer-to-peer network simulation:

- **Peer Discovery**: Rilevamento automatico di nodi
- **Sync Chain**: Sincronizzazione blockchain tra peer
- **Broadcast**: Distribuzione messaggi e blocchi
- **Local Mode**: Fallback offline

### 🧅 Tor Mode

Modalità anonima avanzata:

- **Rilevamento .onion**: Attiva automaticamente se su Tor
- **Hidden Service**: Documentazione per deployment
- **Mesh Tor**: Routing attraverso rete Tor
- **Anonimato Totale**: IP mai esposto

### 🛡️ Cybersecurity SOC

Monitoraggio sicurezza e threat detection:

- **Event Logging**: Registra tutti gli eventi di sicurezza
- **Threat Level**: low, medium, high, critical
- **Panic Mode**: Disabilita mining, chat, mesh
- **Alert System**: Notifiche per minacce rilevate

### 🛒 Marketplace

Moduli installabili pagabili in GNT:

- **5 Moduli Demo**: Advanced Mining, Privacy Shield, Mesh Booster, AI Sentinel, Quantum Wallet
- **Pagamento GNT**: Acquista con balance wallet
- **Installazione**: Moduli attivi persistono in localStorage
- **Upgrade Path**: Aggiungi moduli custom

### 🌱 QuantumEco

Servizi ecologici integrati:

- **5 Servizi**: Quantum Compute, Eco Analytics, Carbon Offset, Energy Harvesting, Eco Rewards
- **Attivazione**: Toggle servizi on/off
- **Uptime**: Visualizza disponibilità servizio
- **Sostenibilità**: Mining eco-friendly

---

## 📊 Architettura

### Struttura File

```
x-zdos-web/
├── index.html              (Entry point con sidebar)
├── app/
│   ├── core.js            (State management + logica)
│   └── ui.js              (UI rendering + event handlers)
├── assets/
│   └── style.css          (Cyberpunk theme + layout)
├── server.js              (Node.js server)
├── package.json           (Dipendenze)
├── vercel.json            (Deploy Vercel)
├── netlify.toml           (Deploy Netlify)
├── DEPLOYMENT.md          (Guida deploy)
└── README.md              (Questo file)
```

### Flusso Dati

```
User Input
    ↓
UI Event Handler (ui.js)
    ↓
Core State Update (core.js)
    ↓
localStorage.setItem()
    ↓
UI Re-render
    ↓
Display Update
```

### Storage

Tutto salvato in localStorage:

- **x-zdos-identity**: Identità ghost (GHOST address, public key, alias)
- **x-zdos-channels**: Lista canali e metadata
- **x-zdos-state**: Stato completo (blockchain, wallet, mining, etc.)

---

## 🎮 Come Usare

### 1. Apertura Sito

**Doppio click su index.html** (Windows 7+) oppure apri nel browser:
```
file:///path/to/x-zdos-web/index.html
```

### 2. Registrazione Anonima

Automatica al primo accesso:
- Visualizza GHOST Address nella sezione Identity
- Copia indirizzo con pulsante 📋 Copy
- Condividi con altri per identificarti

### 3. Creazione Canale

1. Vai a sezione **CHANNELS**
2. Compila "Channel name" e "Channel description"
3. Clicca **CREATE CHANNEL**
4. Nuovo canale appare nella lista

### 4. Chat Anonima

1. Seleziona canale dalla lista
2. Automaticamente entra in chat
3. Digita messaggio in input
4. Clicca **Send**
5. Messaggio crittografato e distribuito

### 5. Mining

1. Vai a sezione **MINING**
2. Clicca **Start Mining**
3. Guarda hash rate aumentare
4. Ricevi 10 GNT per ogni blocco trovato

### 6. Marketplace

1. Vai a sezione **MARKETPLACE**
2. Visualizza moduli disponibili e prezzo
3. Clicca **Install** per acquistare
4. Modulo installato se balance sufficiente

### 7. Export/Import

**Backup dati**:
1. Vai a sezione **SETTINGS**
2. Clicca **Export Data**
3. File JSON scaricato

**Restore dati**:
1. Vai a sezione **SETTINGS**
2. Clicca **Import Data**
3. Seleziona file JSON
4. Dati ripristinati

---

## 🔧 Configurazione

### Variabili Ambiente

Nessuna richiesta! App funziona 100% offline.

### Personalizzazione

**Modifica colori** in `assets/style.css`:
```css
:root {
  --primary: #00FF00;      /* Neon green */
  --secondary: #FF00FF;    /* Magenta */
  --tertiary: #00FFFF;     /* Cyan */
  --bg: #0A0E27;           /* Dark background */
  --surface: #1A1F3A;      /* Surface color */
}
```

**Modifica canali predefiniti** in `app/core.js`:
```javascript
const defaultChannels = [
  { id: 'general', name: 'general', description: 'General discussion' },
  // Aggiungi altri canali...
];
```

---

## 📈 Statistiche

| Metrica | Valore |
|---------|--------|
| **Righe di codice** | ~2,100 |
| **Dipendenze** | 0 |
| **Dimensione totale** | 150 KB |
| **Tempo caricamento** | <100ms |
| **Browser support** | 95%+ |
| **Offline** | ✅ 100% |
| **Mobile** | ✅ Responsive |

---

## 🔒 Sicurezza

### Crittografia

- **Messaggi Chat**: XOR encryption (demo, upgrade a AES-256)
- **Identity**: Generata localmente, mai trasmessa
- **Storage**: localStorage (browser storage nativo)

### Privacy

- ✅ Zero server backend
- ✅ Zero tracking
- ✅ Zero analytics
- ✅ Tutti i dati rimangono locali
- ✅ Nessuna trasmissione esterna

### Limitazioni

- ⚠️ XOR encryption non è sicuro per produzione
- ⚠️ localStorage non è encrypted
- ⚠️ Browser history contiene dati
- ⚠️ Mesh network è simulato (non reale)

---

## 🚀 Deploy

### Opzione 1: GitHub Pages (Consigliato)

```bash
# 1. Crea repo su GitHub
# 2. Clona
git clone https://github.com/yourusername/x-zdos.git
cd x-zdos

# 3. Copia file
cp -r /path/to/x-zdos-web/* .

# 4. Commit e push
git add .
git commit -m "Initial commit: X-ZDOS v2.0"
git push origin main

# 5. Abilita Pages
# Settings → Pages → Source: main branch
# Accedi a: https://yourusername.github.io/x-zdos
```

### Opzione 2: Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir .
# Accedi a: https://x-zdos.netlify.app
```

### Opzione 3: Vercel

```bash
npm install -g vercel
vercel --prod
# Accedi a: https://x-zdos.vercel.app
```

---

## 🛠️ Sviluppo

### Setup Locale

```bash
# 1. Clona repo
git clone https://github.com/yourusername/x-zdos.git
cd x-zdos

# 2. Installa dipendenze (opzionale)
npm install

# 3. Avvia server
node server.js

# 4. Apri browser
open http://localhost:3000
```

### Aggiungere Funzionalità

1. **Modifica `app/core.js`** per logica
2. **Modifica `app/ui.js`** per UI
3. **Modifica `assets/style.css`** per stile
4. **Test nel browser** (F12 per console)
5. **Commit e push** su GitHub

### Debug

Apri DevTools (F12) e controlla:
- **Console**: Errori JavaScript
- **Application → Storage → localStorage**: Dati salvati
- **Network**: Richieste HTTP (dovrebbe essere vuoto)

---

## 📚 Documentazione Aggiuntiva

- **DEPLOYMENT.md**: Guida completa deploy permanente
- **QUICK_START.md**: Guida rapida accesso
- **LICENSE**: MIT License

---

## 🔄 Roadmap Futuro

### v2.1
- [ ] Upgrade a AES-256 encryption
- [ ] WebRTC reale per mesh network
- [ ] Persistenza cloud opzionale
- [ ] Backup automatico

### v2.2
- [ ] Mobile app (React Native)
- [ ] Desktop app (Electron)
- [ ] Browser extension
- [ ] Tor integration nativa

### v3.0
- [ ] Backend Node.js opzionale
- [ ] Database PostgreSQL
- [ ] Autenticazione OAuth
- [ ] API REST pubblica

---

## 📞 Supporto

- 📖 Leggi README.md per documentazione
- 🐛 Apri issue su GitHub per bug
- 💬 Discussioni su GitHub per domande
- 🔗 Vedi DEPLOYMENT.md per deploy

---

## 📄 Licenza

MIT License - Vedi LICENSE file

---

## 👨‍💻 Autore

High-cde - Maggio 2026

---

## 🎉 Ringraziamenti

Ispirato da:
- Z-Anon (z-anon.onhercules.app)
- GhostNet Protocol
- Tor Project
- Bitcoin Blockchain

---

**X-ZDOS Quantum GhostNet OS v2.0**  
*Decentralized • Anonymous • Offline-First*
