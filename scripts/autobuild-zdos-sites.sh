#!/usr/bin/env bash
set -Eeuo pipefail

XZDOS_ROOT="${XZDOS_ROOT:-/var/www/x-zdos.it/public}"
SEC_ROOT="${SEC_ROOT:-/var/www/zdos-sec.it/public}"
RELOAD_WEB="${RELOAD_WEB:-0}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$XZDOS_ROOT" "$SEC_ROOT"

backup_index() {
  local root="$1"
  if [[ -f "$root/index.html" ]]; then
    cp -a "$root/index.html" "$root/index.html.bak.$STAMP"
  fi
}

write_site() {
  local root="$1"
  local domain="$2"
  local site_name="$3"
  local eyebrow="$4"
  local headline="$5"
  local subline="$6"
  local primary_label="$7"
  local primary_href="$8"
  local secondary_label="$9"
  local secondary_href="${10}"
  local mode_label="${11}"
  local card1_title="${12}"
  local card1_text="${13}"
  local card2_title="${14}"
  local card2_text="${15}"
  local card3_title="${16}"
  local card3_text="${17}"
  local card4_title="${18}"
  local card4_text="${19}"
  local collaboration_section=""
  if [[ "$domain" == "x-zdos.it" ]]; then
    collaboration_section=$(cat <<'COLLAB'
    <section class="section wrap" aria-labelledby="collaboration-title">
      <div class="panel collaboration">
        <div class="collaboration-grid">
          <div>
            <div class="section-kicker">COLLABORATION / LANOVA AVON</div>
            <h2 id="collaboration-title">Un nuovo canale per restare connessi.</h2>
            <p>LaNova AVON entra nel percorso pubblico di X-ZDOS. Segui il canale ufficiale su WhatsApp per scoprire aggiornamenti e contenuti della collaborazione.</p>
          </div>
          <div class="collaboration-action">
            <div>
              <div class="collaboration-badge">WHATSAPP CHANNEL</div>
              <a class="button" href="https://whatsapp.com/channel/0029Vb7akVkKAwEp2NjB0U0x" target="_blank" rel="noopener noreferrer">SEGUI LANOVA AVON ↗</a>
            </div>
          </div>
        </div>
      </div>
    </section>
COLLAB
)
  fi

  backup_index "$root"
  cat > "$root/index.html" <<HTML
<!doctype html>
<html lang="it">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#080b12">
  <meta name="description" content="$subline">
  <title>$site_name // Secure Neon</title>
  <style>
    :root{--bg:#080b12;--surface:#0d121d;--surface2:#0a0f18;--line:#1e293b;--line2:#263c62;--text:#eef4ff;--muted:#8b9ab0;--dim:#475569;--cyan:#5ee7ff;--blue:#3f8cff;--violet:#b996ff;--green:#7df2a7;--amber:#d97706;--danger:#ef6b87;--max:1240px}
    *{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--text);font-family:Inter,Segoe UI,system-ui,sans-serif;line-height:1.5}a{color:inherit}.wrap{width:min(calc(100% - 40px),var(--max));margin:auto}.topbar{min-height:52px;background:#0b101a;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;gap:20px;padding:0 24px;font:12px ui-monospace,SFMono-Regular,Consolas,monospace;color:var(--muted);position:sticky;top:0;z-index:10}.brand{font:800 18px Inter,Segoe UI,sans-serif;letter-spacing:2px;display:flex;align-items:center;gap:10px;white-space:nowrap}.mark{width:26px;height:26px;display:grid;place-items:center;border:1px solid var(--cyan);color:var(--cyan);font:700 14px ui-monospace,monospace}.toplink{color:var(--cyan);text-decoration:none}.hero{padding:86px 0 70px;background:radial-gradient(ellipse at 78% 18%,rgba(63,140,255,.16),transparent 34%),linear-gradient(135deg,#080b12 0%,#080b12 55%,#0b1020 100%)}.hero-grid{display:grid;grid-template-columns:minmax(0,1.2fr) minmax(300px,.8fr);gap:46px;align-items:end}.eyebrow{color:var(--cyan);font:12px ui-monospace,monospace;letter-spacing:3px;text-transform:uppercase}.hero h1{font-size:clamp(44px,7vw,82px);line-height:1.02;letter-spacing:-3px;margin:18px 0 24px;max-width:850px}.hero h1 span{color:var(--cyan)}.hero p{max-width:720px;color:var(--muted);font-size:20px;margin:0}.actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:32px}.button{display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:0 18px;background:var(--cyan);border:1px solid var(--cyan);color:#061016;text-decoration:none;font:700 12px ui-monospace,monospace;letter-spacing:.3px;text-transform:uppercase}.button.alt{background:transparent;color:var(--cyan)}.button:hover{background:transparent;color:var(--text)}.button.alt:hover{background:var(--cyan);color:#061016}.hero-panel{background:rgba(13,18,29,.9);border:1px solid var(--line2);padding:22px;min-height:225px}.panel-top{display:flex;justify-content:space-between;gap:12px;border-bottom:1px solid var(--line);padding-bottom:13px;color:var(--dim);font:11px ui-monospace,monospace}.state{color:var(--green)}.terminal{font:13px/1.7 ui-monospace,SFMono-Regular,Consolas,monospace;color:var(--muted);padding-top:18px}.terminal .info{color:var(--cyan)}.terminal .zlang{color:var(--violet)}.terminal .ok{color:var(--green)}.section{padding:66px 0}.section-head{display:flex;justify-content:space-between;align-items:end;gap:20px;border-bottom:1px solid var(--line);padding-bottom:16px;margin-bottom:22px}.section-kicker{color:var(--cyan);font:12px ui-monospace,monospace;letter-spacing:2px}.section h2{font-size:34px;margin:9px 0 0}.section-meta{color:var(--dim);font:12px ui-monospace,monospace}.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}.card{min-height:205px;background:var(--surface);border:1px solid var(--line);padding:20px}.card:nth-child(1){border-color:rgba(63,140,255,.72)}.card:nth-child(2){border-color:rgba(185,150,255,.72)}.card:nth-child(3){border-color:rgba(125,242,167,.62)}.card:nth-child(4){border-color:rgba(217,119,6,.72)}.card-label{font:11px ui-monospace,monospace;color:var(--dim);letter-spacing:1px}.card h3{font-size:21px;margin:18px 0 12px}.card p{font-size:15px;color:var(--muted);margin:0}.split{display:grid;grid-template-columns:1fr 1fr;gap:18px}.panel{background:var(--surface);border:1px solid var(--line);padding:26px}.panel h3{margin:0 0 12px;font-size:21px}.panel p{color:var(--muted);margin:0}.list{list-style:none;padding:0;margin:0}.list li{padding:12px 0;border-bottom:1px solid #161e2d;color:var(--muted);font:13px ui-monospace,monospace}.list li:last-child{border-bottom:0}.list b{color:var(--cyan);font-weight:500}.collaboration{position:relative;overflow:hidden;background:linear-gradient(135deg,rgba(185,150,255,.1),rgba(13,18,29,.94) 60%);border-color:rgba(185,150,255,.62)}.collaboration::after{content:"";position:absolute;width:220px;height:220px;border:1px solid rgba(94,231,255,.22);border-radius:50%;right:-74px;top:-104px;box-shadow:0 0 0 22px rgba(94,231,255,.04),0 0 0 44px rgba(94,231,255,.025);pointer-events:none}.collaboration-grid{display:grid;grid-template-columns:minmax(0,1.3fr) minmax(220px,.7fr);gap:26px;align-items:center}.collaboration .section-kicker{color:var(--violet)}.collaboration h2{font-size:clamp(28px,4vw,44px);line-height:1.05;margin:10px 0 14px;max-width:680px}.collaboration p{max-width:660px;color:var(--muted);font-size:16px;margin:0}.collaboration-action{display:flex;justify-content:flex-end;position:relative;z-index:1}.collaboration-badge{color:var(--cyan);font:11px ui-monospace,monospace;letter-spacing:1.5px;margin-bottom:14px}.footer{border-top:1px solid var(--line);padding:25px 0 38px;color:var(--dim);font:12px ui-monospace,monospace;display:flex;justify-content:space-between;gap:16px}.grid-noise{background-image:linear-gradient(rgba(94,231,255,.035) 1px,transparent 1px),linear-gradient(90deg,rgba(94,231,255,.035) 1px,transparent 1px);background-size:32px 32px}@media(max-width:900px){.hero-grid,.split,.collaboration-grid{grid-template-columns:1fr}.cards{grid-template-columns:repeat(2,minmax(0,1fr))}.hero{padding-top:60px}.collaboration-action{justify-content:flex-start}}@media(max-width:600px){.wrap{width:min(calc(100% - 28px),var(--max))}.topbar{padding:0 14px}.topbar .toplink{display:none}.hero h1{letter-spacing:-1.5px}.hero p{font-size:18px}.cards{grid-template-columns:1fr}.section{padding:46px 0}.section-head{display:block}.section-meta{padding-top:10px}.footer{display:block}.footer span{display:block;margin-top:8px}}
  </style>
</head>
<body>
  <header class="topbar">
    <a class="brand" href="/" aria-label="$site_name home"><span class="mark">Z</span>$site_name</a>
    <div>SECURE NEON // $mode_label</div>
    <a class="toplink" href="$secondary_href">$secondary_label →</a>
  </header>
  <main>
    <section class="hero grid-noise">
      <div class="wrap hero-grid">
        <div>
          <div class="eyebrow">$eyebrow</div>
          <h1>$headline</h1>
          <p>$subline</p>
          <div class="actions"><a class="button" href="$primary_href">$primary_label</a><a class="button alt" href="$secondary_href">$secondary_label</a></div>
        </div>
        <div class="hero-panel">
          <div class="panel-top"><span>ZDOS SYSTEM CONSOLE</span><span class="state">● ONLINE</span></div>
          <div class="terminal"><div class="info">[0.234567] $domain</div><div class="zlang">[0.312890] ZLB2 RUNTIME READY</div><div class="ok">[0.456789] EVIDENCE PATH CONFIGURED</div><div class="ok">[0.678901] OPERATIONAL HUD AVAILABLE</div><div style="padding-top:15px;color:var(--text)">zdos@system:~$ <span style="color:var(--cyan)">_</span></div></div>
        </div>
      </div>
    </section>

    <section class="section wrap">
      <div class="section-head"><div><div class="section-kicker">SYSTEM MODULES / $domain</div><h2>Un ecosistema che mostra il percorso.</h2></div><div class="section-meta">BUILD → BOOT → EVIDENCE</div></div>
      <div class="cards">
        <article class="card"><div class="card-label">[ CORE ]</div><h3>$card1_title</h3><p>$card1_text</p></article>
        <article class="card"><div class="card-label">[ ZLANG ]</div><h3>$card2_title</h3><p>$card2_text</p></article>
        <article class="card"><div class="card-label">[ VERIFIED ]</div><h3>$card3_title</h3><p>$card3_text</p></article>
        <article class="card"><div class="card-label">[ ROADMAP ]</div><h3>$card4_title</h3><p>$card4_text</p></article>
      </div>
    </section>

${collaboration_section}

    <section class="section wrap" style="padding-top:0">
      <div class="split">
        <div class="panel"><h3>Stati leggibili, non claim assoluti.</h3><ul class="list"><li><b>CORE</b> — sistema e componenti operativi</li><li><b>ZLB2</b> — runtime e contratto bytecode</li><li><b>VERIFIED</b> — prova ricevuta dal percorso</li><li><b>ROADMAP</b> — capacità ancora in sviluppo</li></ul></div>
        <div class="panel"><h3>Provenienza prima della promessa.</h3><p>La piattaforma separa l’interfaccia, i dati osservabili e ciò che resta da verificare. La grafica è cyber-tecnica; il linguaggio resta concreto e auditabile.</p></div>
      </div>
    </section>
  </main>
  <footer class="footer wrap"><span>© 2026 $site_name · ZDOS ecosystem</span><span>Observe the system. Prove the path.</span></footer>
</body>
</html>
HTML
}

write_site "$XZDOS_ROOT" "x-zdos.it" "X-ZDOS" "PUBLIC EDGE / X-ZDOS" "Il sistema che puoi osservare." "Un punto di ingresso pubblico all’ecosistema ZDOS: tecnologia, runtime Zlang, distribuzione e percorso di evidenza raccontati senza promesse non dimostrate." "ESPLORA L’ECOSISTEMA" "https://github.com/high-cde/ZDOS" "LEGGI EVIDENCE CHAIN" "https://github.com/high-cde/ZDOS-SEC-PORTAL" "PUBLIC LANDING" "ZDOS Linux" "Una distribuzione x86_64 in evoluzione, con build ISO, initramfs e bootstrap operativo." "Zlang / ZLB2" "Il linguaggio e il runtime che definiscono il contratto bytecode v2.5." "Provenance" "Build, boot e ledger vengono collegati come eventi osservabili." "Roadmap" "Installer, package provenance e aggiornamenti atomici restano obiettivi espliciti."
write_site "$SEC_ROOT" "zdos-sec.it" "ZDOS-SEC" "SEC OPERATIONS / ZDOS-SEC" "Observe the system. Prove the path." "Una console operativa per osservare feed, pipeline ZLB2, boot QEMU ed Evidence Chain con una trust boundary dichiarata." "APRI CONTROL CENTER" "https://github.com/high-cde/ZDOS-SEC-PORTAL" "VEDI IL CODICE" "https://github.com/high-cde/ZDOS" "OPERATIONAL HUD" "Control Center" "Dashboard, status panel, terminale e navigazione laterale in una singola interfaccia Secure Neon." "ZLB2 Pipeline" "Compilazione locale, streaming Socket.IO e collegamento al checkout ZDOS configurato." "Evidence Chain" "Ledger locale, record append-only e aggiornamento live tramite API e Socket.IO." "Trust boundary" "Il portale osserva i risultati; non sostituisce audit indipendenti o attestazioni esterne."

if command -v nginx >/dev/null 2>&1; then
  nginx -t
  if [[ "$RELOAD_WEB" == "1" ]] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
    systemctl reload nginx
    echo "[ZDOS] nginx reloaded"
  fi
elif command -v apache2ctl >/dev/null 2>&1; then
  apache2ctl configtest
  if [[ "$RELOAD_WEB" == "1" ]] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet apache2; then
    systemctl reload apache2
    echo "[ZDOS] apache2 reloaded"
  fi
else
  echo "[ZDOS] Nessun nginx/apache rilevato: file generati, reload non eseguito."
fi

printf '\n[ZDOS] Build completata.\n[ZDOS] x-zdos.it -> %s/index.html\n[ZDOS] zdos-sec.it -> %s/index.html\n[ZDOS] Backup timestamp -> %s\n' "$XZDOS_ROOT" "$SEC_ROOT" "$STAMP"
