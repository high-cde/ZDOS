#!/bin/bash

echo "=== ZEN ULTRA AUTOBUILD v2 — FULL ECOSYSTEM REBUILD ==="

###############################################
# 0) AUTO-SYNC & AUTO-REPAIR
###############################################

echo "[SYNC] Sincronizzazione repository..."

git pull --rebase --autostash || {
    echo "[SYNC] Rebase fallito, tentativo di riparazione..."
    git rebase --abort 2>/dev/null
    git pull --autostash --no-rebase
}

###############################################
# 1) TERMINALE ZEN REALE
###############################################

echo "[TERMINAL] Aggiornamento terminale ZEN..."

mkdir -p docs

cat > docs/terminal.js << 'EOF'
// ZEN CLI + Terminal Engine — Browser Edition

function zen_exec(code) {
    const tokens = code.trim().split(/\s+/);
    const stack = [];

    for (let t of tokens) {
        if (!isNaN(t)) {
            stack.push(parseInt(t));
        } else if (t === "+") {
            stack.push(stack.pop() + stack.pop());
        } else if (t === "-") {
            let b = stack.pop(), a = stack.pop();
            stack.push(a - b);
        } else if (t === "*") {
            stack.push(stack.pop() * stack.pop());
        } else if (t === "/") {
            let b = stack.pop(), a = stack.pop();
            stack.push(a / b);
        } else if (t === "print") {
            return stack.pop();
        } else if (t === "help") {
            return "Comandi: + - * / print help info modules";
        } else if (t === "info") {
            return "ZEN Framework v2 — CLI Browser Edition";
        } else if (t === "modules") {
            return "[zvm, zasm, znet, zsec, zboot, zai, zdb, zfs, zui, zos]";
        } else {
            return "Errore: comando sconosciuto '" + t + "'";
        }
    }
    return "(ok)";
}

function zen_terminal_init() {
    const term = document.getElementById("zen-terminal");
    const input = document.getElementById("zen-input");

    input.addEventListener("keydown", e => {
        if (e.key === "Enter") {
            const cmd = input.value;
            input.value = "";

            const result = zen_exec(cmd);
            term.textContent += "\n$ " + cmd + "\n" + result;
            term.scrollTop = term.scrollHeight;
        }
    });
}
EOF

###############################################
# 2) INDEX HTML
###############################################

echo "[SITE] Aggiornamento index.html..."

cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<title>ZEN Framework</title>
<link rel="stylesheet" href="style.css">
<style>
.hero { padding:80px 20px; text-align:center; background:#111; color:white; }
.section-title { font-size:2rem; text-align:center; margin-bottom:20px; }
.terminal { background:#000; color:#0f0; padding:20px; border-radius:10px;
            font-family:monospace; border:1px solid #0f0; max-width:900px; margin:auto; white-space:pre-wrap; }
</style>
</head>

<body>

<header>
    <h1>ZEN Framework</h1>
    <nav>
        <a href="index.html">Home</a>
        <a href="modules.html">Moduli</a>
        <a href="os.html">zOS</a>
        <a href="ai.html">zAI</a>
        <a href="docs.html">Docs</a>
    </nav>
</header>

<div class="hero">
    <h1>ZEN Framework v2</h1>
    <p>Il linguaggio. Il sistema operativo. L’ecosistema vivente.</p>
</div>

<div class="section">
    <h2 class="section-title">Terminale ZEN (reale)</h2>

    <div id="zen-terminal" class="terminal">
$ Benvenuto nel terminale ZEN
$ Digita un comando e premi INVIO
    </div>

    <input id="zen-input"
           style="width:100%; padding:10px; margin-top:10px; font-family:monospace;"
           placeholder="Esempio: 10 20 + print">
</div>

<script src="terminal.js"></script>
<script>zen_terminal_init()</script>

</body>
</html>
EOF

###############################################
# 3) BUILD COMPLETO DEL CORE
###############################################

echo "[BUILD] Ricostruzione completa del core..."

rm -rf build
mkdir -p build/core
cp -r src/* build/core/

###############################################
# 4) DOCUMENTAZIONE AUTOMATICA
###############################################

echo "[DOCS] Generazione documentazione..."

cat > docs/docs.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<title>ZEN Docs</title>
</head>
<body>
<h1>Documentazione ZEN Framework v2</h1>
<p>Questa documentazione è generata automaticamente dall'autobuild.</p>
<p>Moduli disponibili: zvm, zasm, znet, zsec, zboot, zai, zdb, zfs, zui, zos</p>
</body>
</html>
EOF

###############################################
# 5) COMMIT + PUSH
###############################################

echo "[GIT] Commit & push..."

git add .
git commit -m "ZEN ULTRA AUTOBUILD v2: full rebuild + autosync + docs + terminal" || true
git push || {
    echo "[GIT] Push fallito, tentativo di riparazione..."
    git pull --rebase --autostash
    git push
}

echo "=== COMPLETATO ==="
