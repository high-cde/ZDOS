# X-ZDOS Quantum GhostNet OS - Deployment Guide

## 🌐 Deploy Permanente

### Opzione 1: GitHub Pages (Gratuito, Permanente)

```bash
# 1. Crea repository su GitHub
# https://github.com/new
# Nome: x-zdos-quantum-ghostnet-os

# 2. Clona il repository
git clone https://github.com/yourusername/x-zdos-quantum-ghostnet-os.git
cd x-zdos-quantum-ghostnet-os

# 3. Copia i file del progetto
cp -r /home/ubuntu/x-zdos-web/* .

# 4. Commit e push
git add .
git commit -m "Initial commit: X-ZDOS v1.0"
git push origin main

# 5. Abilita GitHub Pages
# Settings → Pages → Source: main branch
# Accedi a: https://yourusername.github.io/x-zdos-quantum-ghostnet-os
```

**Vantaggi**:
- ✅ Gratuito
- ✅ Permanente
- ✅ HTTPS automatico
- ✅ CDN globale
- ✅ Nessuna manutenzione

**Svantaggi**:
- ❌ Dominio GitHub
- ❌ Limitato a siti statici

---

### Opzione 2: Netlify (Gratuito, Permanente)

```bash
# 1. Installa Netlify CLI
npm install -g netlify-cli

# 2. Deploy
cd /home/ubuntu/x-zdos-web
netlify deploy --prod --dir .

# 3. Segui le istruzioni
# Accedi a: https://x-zdos.netlify.app
```

**Vantaggi**:
- ✅ Gratuito
- ✅ Dominio personalizzato
- ✅ HTTPS automatico
- ✅ Rewrite rules incluse
- ✅ Analytics

**Svantaggi**:
- ❌ Richiede account
- ❌ Limite di banda

---

### Opzione 3: Vercel (Gratuito, Permanente)

```bash
# 1. Installa Vercel CLI
npm install -g vercel

# 2. Deploy
cd /home/ubuntu/x-zdos-web
vercel --prod

# 3. Segui le istruzioni
# Accedi a: https://x-zdos.vercel.app
```

**Vantaggi**:
- ✅ Gratuito
- ✅ Velocissimo
- ✅ Dominio personalizzato
- ✅ HTTPS automatico
- ✅ Edge functions

---

### Opzione 4: Self-Hosted (VPS)

```bash
# 1. Affittare VPS (DigitalOcean, Linode, Hetzner, etc.)
# Costo: ~$5-10/mese

# 2. SSH nel server
ssh root@your-vps-ip

# 3. Installare Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 4. Clonare il repository
git clone https://github.com/yourusername/x-zdos-quantum-ghostnet-os.git
cd x-zdos-quantum-ghostnet-os

# 5. Installare PM2 (process manager)
sudo npm install -g pm2

# 6. Avviare l'app
pm2 start server.js --name "x-zdos"
pm2 startup
pm2 save

# 7. Configurare Nginx come reverse proxy
sudo apt-get install -y nginx

# 8. Configurare dominio e SSL (Let's Encrypt)
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com

# 9. Accedi a: https://yourdomain.com
```

**Vantaggi**:
- ✅ Pieno controllo
- ✅ Dominio personalizzato
- ✅ Nessun limite di banda
- ✅ Scalabile

**Svantaggi**:
- ❌ Costo mensile
- ❌ Richiede manutenzione

---

### Opzione 5: Docker (Containerizzato)

```bash
# 1. Creare Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# 2. Creare .dockerignore
cat > .dockerignore << 'EOF'
node_modules
.git
.gitignore
README.md
LICENSE
EOF

# 3. Build Docker image
docker build -t x-zdos:latest .

# 4. Eseguire container
docker run -p 3000:3000 x-zdos:latest

# 5. Accedi a: http://localhost:3000
```

---

## 📊 Confronto Opzioni

| Opzione | Costo | Setup | Manutenzione | Scalabilità | Dominio |
|---------|-------|-------|--------------|-------------|---------|
| GitHub Pages | Gratis | 5 min | Nulla | Limitata | GitHub |
| Netlify | Gratis | 2 min | Nulla | Media | Personalizzato |
| Vercel | Gratis | 2 min | Nulla | Media | Personalizzato |
| VPS | $5-10/mese | 30 min | Media | Alta | Personalizzato |
| Docker | Variabile | 10 min | Media | Molto Alta | Personalizzato |

---

## 🚀 Raccomandazione

**Per uso personale/demo**: **GitHub Pages** (gratuito, semplice)

**Per produzione leggera**: **Netlify** o **Vercel** (gratuito, affidabile)

**Per produzione seria**: **VPS** (controllo totale, scalabilità)

---

## 🔒 Configurazione Sicurezza

### Headers di Sicurezza (già inclusi in server.js)

```javascript
'X-Content-Type-Options': 'nosniff'
'X-Frame-Options': 'SAMEORIGIN'
'X-XSS-Protection': '1; mode=block'
'Referrer-Policy': 'strict-origin-when-cross-origin'
```

### HTTPS

Tutti i servizi di hosting moderni (GitHub Pages, Netlify, Vercel, Let's Encrypt) forniscono HTTPS gratuito.

### CORS

L'app è 100% client-side, quindi CORS non è un problema.

---

## 📈 Monitoraggio

### Uptime Monitoring

Usa servizi gratuiti come:
- UptimeRobot
- Pingdom
- StatusCake

### Analytics

- Google Analytics (gratuito)
- Plausible (privacy-friendly)
- Fathom (privacy-friendly)

---

## 🔄 CI/CD Pipeline

### GitHub Actions (Gratuito)

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git push -f origin main:gh-pages
```

---

## 📝 Checklist Deployment

- [ ] Repository creato su GitHub
- [ ] File pushati
- [ ] Dominio configurato (se personalizzato)
- [ ] HTTPS abilitato
- [ ] Tested in production
- [ ] Backup locale
- [ ] Monitoraggio uptime attivato
- [ ] Analytics configurato

---

## 🆘 Troubleshooting

### Sito non carica

1. Verificare che i file siano stati uploadati
2. Controllare la console del browser (F12)
3. Verificare che index.html sia nel root

### Stile non carica

1. Verificare percorso di `assets/style.css`
2. Controllare che il server serva file statici
3. Pulire cache del browser (Ctrl+Shift+Del)

### Script non funzionano

1. Verificare percorsi di `app/core.js` e `app/ui.js`
2. Controllare console per errori JavaScript
3. Verificare che localStorage sia disponibile

---

## 📞 Supporto

Per problemi di deployment:
1. Consulta la documentazione del servizio
2. Apri issue su GitHub
3. Contatta il supporto del provider

---

**X-ZDOS Quantum GhostNet OS v1.0**  
Deployment Guide - Maggio 2026
