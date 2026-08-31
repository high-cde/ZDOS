#!/usr/bin/env bash
set -Eeuo pipefail

APP=/opt/zdos-cybercore-warroom
INDEX="$APP/public/index.html"
SERVICE=zdos-cybercore-warroom.service
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT=/root/warroom-backups/$STAMP
ROLLBACK_INDEX="$BACKUP_ROOT/index.html.before"

fail() { echo "[CYBERSUITE][FAIL] $*" >&2; exit 1; }
trap 'rc=$?; if [ "$rc" -ne 0 ] && [ -f "$ROLLBACK_INDEX" ]; then cp -f "$ROLLBACK_INDEX" "$INDEX"; systemctl restart "$SERVICE" >/dev/null 2>&1 || true; fi; exit "$rc"' EXIT

[ "$(id -u)" -eq 0 ] || fail "eseguire come root"
[ -f "$INDEX" ] || fail "file assente: $INDEX"
mkdir -p "$BACKUP_ROOT"
cp -a "$INDEX" "$ROLLBACK_INDEX"

python3 - "$INDEX" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()
if 'id="cybersuite-panel"' in s:
    print('[CYBERSUITE] menu già presente; nessuna modifica')
    raise SystemExit(0)

old_nav = "const nav=['overview','toolbox','programs','scopes','assets','reports','evidence','jobs','audit'];"
new_nav = "const nav=['overview','toolbox','programs','scopes','assets','reports','evidence','jobs','audit','cybersuite'];"
if old_nav not in s:
    raise SystemExit('lista menu non riconosciuta')
s = s.replace(old_nav, new_nav, 1)

old_label = "(x==='overview'?'CONTROL PLANE':labels[x]).toUpperCase()"
new_label = "(x==='cybersuite'?'CYBERSUITE':(x==='overview'?'CONTROL PLANE':labels[x])).toUpperCase()"
if old_label in s:
    s = s.replace(old_label, new_label, 1)

needle = "}else{const items=await getItems(state.section);"
block = r''' }else if(state.section==='cybersuite'){c.innerHTML=`<div class="card" id="cybersuite-panel"><div class="section-head"><h2>CYBERSUITE · ZDOS MODE</h2><span class="tag">ZLANG GATED</span></div><p class="desc">Interazione con agenti metodologici in modalità controllata. L’esecuzione resta read-only, limitata allo scope e soggetta ad approvazione owner.</p><div class="grid"><div class="metric safe"><small>EXECUTION PLANE</small><strong>ZLANG</strong></div><div class="metric"><small>POLICY</small><strong>DEFAULT-DENY</strong></div><div class="metric"><small>LLM</small><strong>OFF BY DEFAULT</strong></div><div class="metric safe"><small>MODE</small><strong>READ-ONLY</strong></div></div><div class="form-grid" style="margin-top:16px"><label class="field">MODE<select id="cs-mode"><option value="observe">Observe · evidenze passive</option><option value="baseline">Baseline · richieste non mutanti</option><option value="review">Review · analisi di evidenze esistenti</option></select></label><label class="field">AGENT<select id="cs-agent"><option value="web-application">Web Application · OWASP review</option><option value="cloud-security">Cloud Security · CIS review</option><option value="compliance">Compliance · controlli dichiarativi</option><option value="evidence">Evidence Analyst · correlazione locale</option></select></label><label class="field">SCOPE ID<input id="cs-scope" placeholder="UUID scope autorizzato"></label><label class="field">REQUEST<textarea id="cs-request" rows="3" placeholder="Descrivi l’osservazione autorizzata"></textarea></label></div><div class="notice" style="margin-top:14px">GATE: il pulsante registra una richiesta in attesa di approvazione. Non esegue shell, exploit, brute force, fuzzing o target fuori scope.</div><button class="btn primary" id="cs-request-btn" type="button">ADD CYBERSUITE REQUEST</button><span id="cs-result" class="tag" style="margin-left:10px"></span></div>`;document.querySelector('#cs-request-btn')?.addEventListener('click',()=>{const scope=document.querySelector('#cs-scope').value.trim();const request=document.querySelector('#cs-request').value.trim();const result=document.querySelector('#cs-result');if(!scope||!request){result.textContent='SCOPE + REQUEST REQUIRED';return}result.textContent='PENDING_APPROVAL · READ-ONLY'});''' + needle
if needle not in s:
    raise SystemExit('punto di inserimento renderer non riconosciuto')
s = s.replace(needle, block, 1)
p.write_text(s)
PY

grep -q "'cybersuite'" "$INDEX" || fail "voce CyberSuite non presente"
grep -q 'id="cybersuite-panel"' "$INDEX" || fail "pannello CyberSuite non presente"
grep -q 'ZLANG GATED' "$INDEX" || fail "gate ZLang non presente"

if [ -d "$APP/.git" ]; then
  git -C "$APP" add public/index.html
  git -C "$APP" diff --cached --check
  if ! git -C "$APP" diff --cached --quiet; then
    git -C "$APP" commit -m 'feat(warroom): add gated CyberSuite agent menu'
  fi
fi

systemctl restart "$SERVICE"
sleep 2
systemctl is-active --quiet "$SERVICE" || fail "servizio non attivo dopo il riavvio"
curl -fsS --max-time 10 -o /tmp/warroom-cybersuite.html -w '%{http_code}\n' http://127.0.0.1:3021/ | grep -qx '200' || fail "smoke test HTTP locale fallito"
grep -q 'CYBERSUITE' /tmp/warroom-cybersuite.html || fail "CyberSuite non presente nella risposta HTTP"
rm -f /tmp/warroom-cybersuite.html
trap - EXIT

echo "[CYBERSUITE][OK] menu CyberSuite ZLang attivato"
echo "[CYBERSUITE] backup: $BACKUP_ROOT"
echo "[CYBERSUITE] commit: $(git -C "$APP" log -1 --oneline 2>/dev/null || echo n/a)"
echo "[CYBERSUITE] modalità disponibili: observe, baseline, review"
echo "[CYBERSUITE] agenti: web-application, cloud-security, compliance, evidence"
