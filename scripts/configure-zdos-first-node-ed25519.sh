#!/usr/bin/env bash
set -Eeuo pipefail

APP=/opt/zdos-node
AGENT="$APP/node-agent.mjs"
SERVICE=zdos-first-node.service
KEYDIR=/etc/zdos/keys
PRIV="$KEYDIR/zdos-first-node-ed25519.pem"
PUB="$KEYDIR/zdos-first-node-ed25519.pub.pem"
STATE=/var/lib/zdos-node
STATUS="$STATE/status.json"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=/root/zdos-first-node-backups/$STAMP
DROPIN=/etc/systemd/system/$SERVICE.d/ed25519.conf

fail(){ echo "[ED25519][FAIL] $*" >&2; exit 1; }
trap 'rc=$?; if [ "$rc" -ne 0 ] && [ -f "$BACKUP/node-agent.mjs.before" ]; then cp -f "$BACKUP/node-agent.mjs.before" "$AGENT"; [ -f "$BACKUP/ed25519.conf.before" ] && cp -f "$BACKUP/ed25519.conf.before" "$DROPIN" || rm -f "$DROPIN"; systemctl daemon-reload >/dev/null 2>&1 || true; systemctl restart "$SERVICE" >/dev/null 2>&1 || true; fi; exit "$rc"' EXIT

[ "$(id -u)" -eq 0 ] || fail 'eseguire come root'
[ -f "$AGENT" ] || fail "file assente: $AGENT"
command -v openssl >/dev/null || fail 'openssl non trovato'
command -v node >/dev/null || fail 'node non trovato'
mkdir -p "$BACKUP" "$KEYDIR" "$(dirname "$DROPIN")"
cp -a "$AGENT" "$BACKUP/node-agent.mjs.before"
[ -f "$DROPIN" ] && cp -a "$DROPIN" "$BACKUP/ed25519.conf.before" || true

# Genera una chiave solo se non esiste: nessuna rotazione implicita.
if [ ! -s "$PRIV" ] || [ ! -s "$PUB" ]; then
  umask 077
  tmppriv=$(mktemp "$KEYDIR/.private.XXXXXX")
  tmppub=$(mktemp "$KEYDIR/.public.XXXXXX")
  openssl genpkey -algorithm Ed25519 -out "$tmppriv" >/dev/null 2>&1
  openssl pkey -in "$tmppriv" -pubout -out "$tmppub" >/dev/null 2>&1
  install -o root -g www-data -m 0640 "$tmppriv" "$PRIV"
  install -o root -g root -m 0644 "$tmppub" "$PUB"
  rm -f "$tmppriv" "$tmppub"
fi
chown root:www-data "$KEYDIR" "$PRIV"
chmod 0750 "$KEYDIR"
chmod 0640 "$PRIV"
chown root:root "$PUB"
chmod 0644 "$PUB"

# Inserisce il signer nel publisher esistente, senza sostituire il resto dell’agente.
python3 - "$AGENT" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text()
if 'ZDOS_NODE_SIGNING_KEY' in s:
    print('[ED25519] signer già presente; nessuna modifica al publisher')
    raise SystemExit(0)
anchor="const activationPath = process.env.ZDOS_NODE_ACTIVATION || '/var/lib/zdos-node/runtime/activation.json';"
insert="""const signingKeyPath = process.env.ZDOS_NODE_SIGNING_KEY || '/etc/zdos/keys/zdos-first-node-ed25519.pem';
const publicKeyPath = process.env.ZDOS_NODE_PUBLIC_KEY || '/etc/zdos/keys/zdos-first-node-ed25519.pub.pem';"""
if anchor not in s:
    raise SystemExit('anchor signingKey non trovato')
s=s.replace(anchor, anchor+'\n'+insert, 1)
anchor2="function publish() {"
helpers="""function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map(k => [k, stable(value[k])]));
  return value;
}
function signedAttestation(payload) {
  try {
    const privateKey = crypto.createPrivateKey(fs.readFileSync(signingKeyPath));
    const publicKeyPem = fs.readFileSync(publicKeyPath, 'utf8');
    const unsigned = { ...payload, attestation: { ...payload.attestation, signature: null } };
    const message = Buffer.from(JSON.stringify(stable(unsigned)));
    const signature = crypto.sign(null, message, privateKey).toString('base64');
    const publicKeySha256 = crypto.createHash('sha256').update(publicKeyPem).digest('hex');
    return { ...payload, attestation: { ...payload.attestation, mode: 'ed25519', algorithm: 'Ed25519', public_key_sha256: publicKeySha256, signature } };
  } catch (error) {
    return { ...payload, status: 'DEGRADED', attestation: { ...payload.attestation, mode: 'ed25519', algorithm: 'Ed25519', status: 'SIGNING_ERROR', signature: null } };
  }
}

"""
if anchor2 not in s:
    raise SystemExit('anchor publish non trovato')
s=s.replace(anchor2, helpers+anchor2, 1)
old="""    attestation: { schema: 'zdos.node.attestation.v1', mode: 'local-hash', subject: nodeId, status: 'VALID' },"""
new="""    attestation: { schema: 'zdos.node.attestation.v1', mode: 'ed25519', subject: nodeId, status: 'VALID', signature: null },"""
if old not in s:
    raise SystemExit('attestation anchor non trovato')
s=s.replace(old,new,1)
old2="""  const tmp = `${statusPath}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, `${JSON.stringify(payload, null, 2)}\\n`, { mode: 0o640 });"""
new2="""  const signedPayload = signedAttestation(payload);
  const tmp = `${statusPath}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, `${JSON.stringify(signedPayload, null, 2)}\\n`, { mode: 0o640 });"""
if old2 not in s:
    raise SystemExit('write anchor non trovato')
s=s.replace(old2,new2,1)
p.write_text(s)
PY

cat > "$DROPIN" <<'EOF'
[Service]
Environment=ZDOS_NODE_SIGNING_KEY=/etc/zdos/keys/zdos-first-node-ed25519.pem
Environment=ZDOS_NODE_PUBLIC_KEY=/etc/zdos/keys/zdos-first-node-ed25519.pub.pem
EOF

node --check "$AGENT"
systemctl daemon-reload
systemctl restart "$SERVICE"
sleep 3
systemctl is-active --quiet "$SERVICE" || fail 'servizio non attivo dopo il riavvio'

cat > /tmp/verify-zdos-ed25519.mjs <<'NODE'
import fs from 'node:fs';
import crypto from 'node:crypto';
const status=JSON.parse(fs.readFileSync('/var/lib/zdos-node/status.json','utf8'));
const publicKey=fs.readFileSync('/etc/zdos/keys/zdos-first-node-ed25519.pub.pem','utf8');
const signature=status?.attestation?.signature;
if (!signature) throw new Error('signature assente');
const unsigned={...status,attestation:{...status.attestation,signature:null}};
function stable(v){if(Array.isArray(v))return v.map(stable);if(v&&typeof v==='object')return Object.fromEntries(Object.keys(v).sort().map(k=>[k,stable(v[k])]));return v;}
const ok=crypto.verify(null,Buffer.from(JSON.stringify(stable(unsigned))),crypto.createPublicKey(publicKey),Buffer.from(signature,'base64'));
if(!ok) throw new Error('firma non valida');
if(status.attestation.algorithm!=='Ed25519') throw new Error('algoritmo inatteso');
console.log(`[ED25519][OK] node=${status.node_id} status=${status.status} signature=valid`);
NODE
node /tmp/verify-zdos-ed25519.mjs
rm -f /tmp/verify-zdos-ed25519.mjs

# Verifica permessi senza leggere la chiave privata.
mode=$(stat -c '%a' "$PRIV")
owner=$(stat -c '%U:%G' "$PRIV")
[ "$mode" = 640 ] || fail "permessi chiave inattesi: $mode"
[ "$owner" = 'root:www-data' ] || fail "ownership chiave inattesa: $owner"

trap - EXIT
echo "[ED25519][OK] firma Ed25519 attiva sul publisher di zdos-first-node"
echo "[ED25519] backup: $BACKUP"
echo "[ED25519] public-key: $PUB"
echo "[ED25519] private-key: protetta, non stampata"
echo "[ED25519] rollback: cp '$BACKUP/node-agent.mjs.before' '$AGENT'; systemctl restart '$SERVICE'"
