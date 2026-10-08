const express = require("express");
const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");
const { spawnSync } = require("child_process");
const alertEngine = require("./alert-engine");

const app = express();
const port = Number.parseInt(process.env.PORT || "8080", 10);
const host = process.env.HOST || "127.0.0.1";
const root = path.resolve(__dirname, "../../..");
const remoteOrigin = "https://app.x-zdos.it";
const remoteApi = `${remoteOrigin}/api/trpc`;
const allowedRemote = new Set(["ecosystem.list", "evidence.list", "zcomm.catalog", "node.status", "zlang.validate"]);
const allowedBrowserHosts = new Set(["app.x-zdos.it", "github.com", "www.github.com", "githubusercontent.com", "raw.githubusercontent.com"]);
const audit = [];
const startedAt = new Date().toISOString();
const bridgeTokenFile = process.env.ZDOS_BRIDGE_TOKEN_FILE || path.join(os.homedir(), ".config/zdos/bridge.token");
const bridgeDataFile = process.env.ZDOS_BRIDGE_DATA_FILE || path.join(os.homedir(), ".local/share/zdos-glass-engine/bridge/messages.jsonl");
const ghostChatFile = process.env.ZDOS_GHOST_CHAT_FILE || path.join(os.homedir(), ".local/share/zdos-glass-engine/ghostnet/messages.jsonl");
const ghostChannels = ["general", "ghostnet", "anonymous", "trading", "zdos", "vera", "hotpulci"];
const ghostNavigation = ["CHANNELS", "DM", "WALLET", "IDENTITY"];
let bridgeMessages = [];
let ghostMessages = [];
const web3Networks = {
  ethereum: { chainId: "0x1", name: "Ethereum Mainnet", rpc: process.env.ZDOS_WEB3_ETHEREUM_RPC || "https://ethereum-rpc.publicnode.com" },
  polygon: { chainId: "0x89", name: "Polygon PoS", rpc: process.env.ZDOS_WEB3_POLYGON_RPC || "https://polygon-bor-rpc.publicnode.com" },
  base: { chainId: "0x2105", name: "Base", rpc: process.env.ZDOS_WEB3_BASE_RPC || "https://base-rpc.publicnode.com" },
  arbitrum: { chainId: "0xa4b1", name: "Arbitrum One", rpc: process.env.ZDOS_WEB3_ARBITRUM_RPC || "https://arbitrum-one-rpc.publicnode.com" },
  sepolia: { chainId: "0xaa36a7", name: "Ethereum Sepolia", rpc: process.env.ZDOS_WEB3_SEPOLIA_RPC || "https://ethereum-sepolia-rpc.publicnode.com" },
};
const web3Methods = new Set(["eth_chainId", "eth_blockNumber", "eth_getBalance", "net_version"]);

function isHexAddress(value) { return /^0x[a-fA-F0-9]{40}$/.test(String(value || "")); }
function web3Network(id) { return web3Networks[String(id || "").toLowerCase()] || null; }
async function web3Rpc(network, method, params = []) {
  if (!web3Methods.has(method)) throw new Error("metodo RPC non allowlisted: solo osservazione");
  if (!Array.isArray(params) || params.length > 2) throw new Error("parametri RPC oltre il limite");
  if (method === "eth_getBalance" && (!isHexAddress(params[0]) || !["latest", "pending"].includes(params[1]))) throw new Error("eth_getBalance richiede address e latest/pending");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 7000);
  try {
    const response = await fetch(network.rpc, { method: "POST", signal: controller.signal, headers: { accept: "application/json", "content-type": "application/json", "user-agent": "ZDOS-Web3-Observer/1" }, body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }) });
    if (!response.ok) throw new Error(`RPC HTTP ${response.status}`);
    const body = await response.json();
    if (body?.error) throw new Error(body.error.message || "RPC error");
    return body?.result ?? null;
  } finally { clearTimeout(timer); }
}
function validateWeb3Zlang(source) {
  const normalized = String(source || "").split("\n").map((line) => line.trim().toLowerCase()).filter(Boolean);
  const allowed = new Set(["web3.networks", "web3.chain.status", "web3.block.read", "web3.balance.read", "web3.address.validate", "web3.evidence.candidate", "wallet.sign.deny", "wallet.transfer.deny", "contract.write.deny", "halt"]);
  if (!normalized.length || normalized.some((line) => !allowed.has(line))) return { status: "DENIED", detail: "syntax or capability outside zdos.web3.observe.v1", capabilities: [] };
  if (!normalized.includes("web3.networks") || !normalized.includes("halt")) return { status: "DENIED", detail: "web3 observation profile requires web3.networks and HALT", capabilities: [] };
  return { status: "ACCEPTED", detail: "bounded Web3 observation contract", capabilities: normalized.filter((line) => line.startsWith("web3.")) };
}

function loadBridgeMessages() {
  try { bridgeMessages = fs.readFileSync(bridgeDataFile, "utf8").trim().split("\n").filter(Boolean).slice(-500).map((line) => JSON.parse(line)); } catch { bridgeMessages = []; }
  try { ghostMessages = fs.readFileSync(ghostChatFile, "utf8").trim().split("\n").filter(Boolean).slice(-500).map((line) => JSON.parse(line)); } catch { ghostMessages = []; }
}
function bridgeToken() {
  try { return fs.readFileSync(bridgeTokenFile, "utf8").trim(); } catch { return String(process.env.ZDOS_BRIDGE_TOKEN || "").trim(); }
}
function bridgeAuthorized(req) {
  const expected = bridgeToken();
  const supplied = String(req.headers["x-zdos-bridge-token"] || "");
  return Boolean(expected && supplied && supplied.length === expected.length && crypto.timingSafeEqual(Buffer.from(supplied), Buffer.from(expected)));
}
function appendBridgeMessages(messages) {
  if (!messages.length) return;
  fs.mkdirSync(path.dirname(bridgeDataFile), { recursive: true, mode: 0o700 });
  fs.appendFileSync(bridgeDataFile, messages.map((message) => `${JSON.stringify(message)}\n`).join(""), { mode: 0o600 });
}
function appendGhostMessages(messages) {
  if (!messages.length) return;
  fs.mkdirSync(path.dirname(ghostChatFile), { recursive: true, mode: 0o700 });
  fs.appendFileSync(ghostChatFile, messages.map((message) => `${JSON.stringify(message)}\n`).join(""), { mode: 0o600 });
}
function localChatIntent(req) {
  const address = String(req.ip || req.socket?.remoteAddress || "");
  return ["127.0.0.1", "::1", "::ffff:127.0.0.1"].includes(address) && req.headers["x-zdos-chat-intent"] === "SEND_LOCAL_MESSAGE";
}
loadBridgeMessages();

if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("PORT deve essere un intero compreso tra 1 e 65535");

function record(type, detail) {
  audit.push({ at: new Date().toISOString(), type, detail });
  if (audit.length > 100) audit.shift();
}

function tailJsonl(file, limit = 20) {
  try {
    return fs.readFileSync(file, "utf8").trim().split("\n").filter(Boolean).slice(-limit).map((line) => {
      try { return JSON.parse(line); } catch { return { raw: line.slice(0, 512) }; }
    });
  } catch { return []; }
}

function safeCommand(command, args = []) {
  const allowed = new Set(["ip", "nmcli", "iw", "df", "systemctl"]);
  if (!allowed.has(command)) return { ok: false, output: "command not allowlisted" };
  const result = spawnSync(command, args, { encoding: "utf8", timeout: 1500, maxBuffer: 256 * 1024 });
  return { ok: result.status === 0, output: String(result.stdout || "").trim(), error: String(result.stderr || "").trim() };
}

function toolInventory() {
  const tools = ["nmcli", "iw", "ip", "systemctl", "qemu-system-x86_64", "xorriso", "grub-mkrescue", "node", "npm", "python3", "ffmpeg", "git", "docker"];
  return Object.fromEntries(tools.map((tool) => {
    const result = spawnSync("sh", ["-c", "command -v -- \"$1\"", "zdos-tool", tool], { encoding: "utf8", timeout: 800, maxBuffer: 4096 });
    return [tool, result.status === 0];
  }));
}

function localSystemSnapshot() {
  const release = fs.existsSync("/etc/os-release") ? fs.readFileSync("/etc/os-release", "utf8") : "";
  const prettyName = release.match(/^PRETTY_NAME=(.*)$/m)?.[1]?.replace(/^"|"$/g, "") || os.platform();
  const disk = safeCommand("df", ["-h", root]);
  const network = safeCommand("ip", ["-brief", "addr"]);
  const wifi = safeCommand("nmcli", ["-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi"]);
  return {
    schema: "zdos.glass-engine.local-system.v1",
    read_only: true,
    hostname: os.hostname(), os: prettyName, kernel: os.release(), arch: os.arch(),
    uptime_seconds: Math.floor(os.uptime()), cpu: { count: os.cpus().length, load: os.loadavg() },
    memory: { total_bytes: os.totalmem(), free_bytes: os.freemem() }, disk: disk.output, network: network.output,
    wifi: { available: wifi.ok, scan: wifi.output, detail: wifi.error || null }, tools: toolInventory(),
    policy: "DEFAULT-DENY",
    note: "Analisi locale osservabile; nessuna connessione Wi-Fi, servizio o tool viene avviato automaticamente.",
  };
}

async function remoteQuery(procedure, input = {}) {
  if (!allowedRemote.has(procedure)) throw new Error("procedura remota non allowlisted");
  const url = new URL(`${remoteApi}/${procedure}`);
  url.searchParams.set("input", JSON.stringify({ json: input }));
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 7000);
  try {
    const response = await fetch(url, { signal: controller.signal, headers: { accept: "application/json", "user-agent": "ZDOS-Glass-Engine/1 read-only" } });
    if (!response.ok) throw new Error(`remote HTTP ${response.status}`);
    if (Number(response.headers.get("content-length") || 0) > 1024 * 1024) throw new Error("risposta remota oltre il limite");
    const body = await response.json();
    if (body?.error) throw new Error(body.error.json?.message || "errore tRPC remoto");
    return body?.result?.data?.json ?? body?.result?.data ?? body;
  } finally { clearTimeout(timer); }
}

function remoteError(res, err) {
  res.status(200).json({ status: "OFFLINE", policy: "DEFAULT-DENY", source: remoteOrigin, error: err instanceof Error ? err.message : String(err) });
}

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.set({
    "Cache-Control": "no-store",
    "Content-Security-Policy": "default-src 'self'; connect-src 'self'; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'",
    "Referrer-Policy": "no-referrer", "X-Content-Type-Options": "nosniff", "X-Frame-Options": "DENY",
  });
  next();
});
app.use(express.json({ limit: "16kb" }));
app.use("/api/videotel", require("./videotel").createRouter());
app.use(express.static(path.join(__dirname, "..", "web"), { index: "index.html" }));

app.get("/status", (_req, res) => res.json({ schema: "zdos.glass-engine.status.v1", status: "LOCAL_READ_ONLY", service: "zdos-interface-web", console: "GLASS_ENGINE", version: "2026.2", started_at: startedAt, mutations: false, remote_origin: remoteOrigin, policy: "DEFAULT-DENY" }));
app.get("/api/local/audit", (_req, res) => {
  const statusFile = path.join(root, "var/organism/status.json");
  let organism = { state: "NOT_CONNECTED" };
  try { if (fs.existsSync(statusFile)) organism = JSON.parse(fs.readFileSync(statusFile, "utf8")); } catch { organism = { state: "INVALID_STATUS_FILE" }; }
  res.json({ schema: "zdos.glass-engine.local.v1", policy: "DEFAULT-DENY", mutations: false, organism, evidence: tailJsonl(path.join(root, "evidence/ledger.jsonl")), events: tailJsonl(path.join(root, "var/organism/events.jsonl")), audit });
});
app.get("/api/local/evidence/wallet", (_req, res) => {
  const ledgerCandidates = [process.env.ZDOS_LEDGER, path.join(root, "evidence/ledger.jsonl"), "/var/lib/zdos-node/evidence.jsonl"].filter(Boolean);
  const ledgerPath = ledgerCandidates.map((item) => path.resolve(item)).find((item) => fs.existsSync(item)) || ledgerCandidates[1];
  const entries = tailJsonl(ledgerPath, 100000);
  const identityCandidates = [process.env.ZDOS_IDENTITY_DIR, path.join(os.homedir(), ".config/zdos/identity"), path.join(root, "identity/state")].filter(Boolean);
  let identity = { status: "NOT_INITIALIZED", network_identity: "none", capabilities: ["evidence.read-v1"] };
  for (const directory of identityCandidates) {
    const file = path.join(directory, "identity.json");
    if (!fs.existsSync(file)) continue;
    try { const profile = JSON.parse(fs.readFileSync(file, "utf8")); identity = { status: "IDENTITY_PRESENT", did: profile.identity, nick: profile.nick, role: profile.role, network_identity: profile.network_identity, capabilities: ["evidence.read-v1", ...(profile.role === "operator" || profile.role === "administrator" ? ["evidence.append-v1"] : [])] }; } catch { identity = { status: "INVALID_IDENTITY", network_identity: "none", capabilities: ["evidence.read-v1"] }; }
    break;
  }
  const last = entries.at(-1);
  const verification = entries.length ? spawnSync("python3", [path.join(root, "evidence/ledger.py"), "--ledger", ledgerPath, "verify"], { encoding: "utf8", timeout: 3000, maxBuffer: 16384 }) : { status: 0, stdout: "ledger is empty" };
  res.json({ schema: "zdos.evidence-wallet.v1", wallet_type: "NON_CUSTODIAL_READ_ONLY", chain: "ZDOS Evidence Chain", monetary_assets: false, ledger: { path: ledgerPath, status: entries.length ? "LOCAL_LEDGER_PRESENT" : "EMPTY", entries: entries.length, head: last?.hash || "0".repeat(64), last_event: last?.event?.type || null, verification: { status: entries.length && verification.status === 0 ? "VERIFIED" : entries.length ? "INVALID" : "EMPTY", detail: String(verification.stdout || verification.stderr || "").trim() } }, identity, capabilities: ["evidence.read-v1", "evidence.verify-v1"], denied: ["wallet.transfer-v1", "wallet.sign-transaction-v1", "contract.approve-v1"], policy: "DEFAULT_DENY", note: "Ledger hash-chained non-monetario; non è una rete di consenso e non custodisce fondi." });
});
app.get("/api/local/system", (_req, res) => { record("LOCAL_SYSTEM_READ", "safe inventory"); res.json(localSystemSnapshot()); });
app.get("/api/local/network", (_req, res) => res.json({ schema: "zdos.glass-engine.local-network.v1", read_only: true, interfaces: safeCommand("ip", ["-brief", "link"]).output, addresses: safeCommand("ip", ["-brief", "addr"]).output, wifi: safeCommand("nmcli", ["-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi"]).output, policy: "DEFAULT-DENY", note: "Rileva Wi-Fi e rete ma non salva password e non cambia connessioni." }));
app.get("/api/local/zcomm", (_req, res) => res.json({ schema: "zdos.zcomm.desktop-bridge.v2", status: bridgeToken() ? "PAIRING_READY" : "DISABLED_NO_TOKEN", chat: bridgeToken() ? "LAN_AUTHENTICATED_QUEUE" : "NOT_CONFIGURED", video: "NOT_CONFIGURED", capabilities: ["zcomm.page.read", "zcomm.message.queue", "zcomm.sync.push", "zcomm.sync.pull"], transport: "LAN_TOKEN_BRIDGE", policy: "DEFAULT-DENY", messages: bridgeMessages.length, recent: bridgeMessages.slice(-20), token_file: bridgeTokenFile, note: "Il bridge sincronizza solo messaggi ZComm autenticati; nessuna shell, file remoto, wallet o comando viene esposto." }));
app.get("/api/bridge/status", (req, res) => {
  if (!bridgeAuthorized(req)) return res.status(401).json({ status: "DENIED", detail: "bridge token required" });
  record("BRIDGE_STATUS", String(req.headers["x-zdos-node-id"] || "android-unknown"));
  res.json({ schema: "zdos.zcomm.bridge.v1", status: "PAIRED", node: "GLASS_ENGINE", transport: "LAN_AUTHENTICATED", policy: "DEFAULT-DENY", chat: "READY", video: "NOT_CONFIGURED", messages: bridgeMessages.slice(-100) });
});
app.post("/api/bridge/sync", (req, res) => {
  if (!bridgeAuthorized(req)) return res.status(401).json({ status: "DENIED", detail: "bridge token required" });
  const incoming = Array.isArray(req.body?.messages) ? req.body.messages.slice(0, 50) : [];
  const known = new Set(bridgeMessages.map((message) => message.id));
  const accepted = incoming.filter((message) => message && typeof message.id === "string" && typeof message.body === "string" && !known.has(message.id)).map((message) => ({ id: message.id.slice(0, 80), roomId: String(message.roomId || "piazza").slice(0, 40), nick: String(message.nick || "ANDROID").slice(0, 24), body: message.body.trim().slice(0, 240), createdAt: String(message.createdAt || new Date().toISOString()).slice(0, 40), source: "microcosm-android", receivedAt: new Date().toISOString() }));
  bridgeMessages = [...bridgeMessages, ...accepted].slice(-500);
  appendBridgeMessages(accepted);
  record("BRIDGE_SYNC", `accepted=${accepted.length}`);
  res.json({ schema: "zdos.zcomm.bridge-sync.v1", status: "SYNCED", accepted: accepted.length, messages: bridgeMessages.slice(-100), serverTime: new Date().toISOString() });
});
app.get("/api/zcomm/ghostnet", (req, res) => {
  const channel = ghostChannels.includes(String(req.query.channel || "")) ? String(req.query.channel) : "general";
  res.json({ schema: "zdos.zcomm.ghostnet.v1", product: "GHOSTNET", identity_label: "ghost_local", navigation: ghostNavigation, channels: ghostChannels, selected: channel, peers: bridgeToken() ? "LAN PAIRING READY" : "LOCAL ONLY", messages: ghostMessages.filter((message) => message.roomId === channel).slice(-100), capabilities: ["channel.read", "message.compose", "message.queue"], denied: ["wallet.custody", "credential.export", "identity.impersonate", "remote.broadcast"], transport: bridgeToken() ? "LOCAL_PLUS_AUTHENTICATED_ZCOMM" : "LOCAL_OUTBOX", policy: "DEFAULT-DENY", source_model: "public-ui-compatible-not-backend-clone" });
});
app.post("/api/zcomm/ghostnet/messages", (req, res) => {
  if (!localChatIntent(req)) return res.status(403).json({ status: "DENIED", detail: "local chat intent required; LAN clients must use authenticated ZComm bridge", policy: "DEFAULT-DENY" });
  const roomId = String(req.body?.roomId || ""); const body = String(req.body?.body || "").trim();
  if (!ghostChannels.includes(roomId) || !body) return res.status(400).json({ status: "DENIED", detail: "channel or message invalid" });
  const message = { id: `local-${crypto.randomUUID()}`, roomId, nick: "GHOST_LOCAL", body: body.slice(0, 500), createdAt: new Date().toISOString(), source: "zdos-glass-engine", delivery: bridgeToken() ? "QUEUED_FOR_ZCOMM" : "LOCAL_OUTBOX" };
  ghostMessages = [...ghostMessages, message].slice(-500); appendGhostMessages([message]); record("GHOSTNET_MESSAGE_QUEUED", roomId); res.status(201).json({ schema: "zdos.zcomm.ghostnet.message.v1", status: "QUEUED", message, policy: "DEFAULT-DENY" });
});
app.get("/api/alerts/status", (_req, res) => {
  const snapshot = alertEngine.offlineSnapshot();
  res.json({ ...snapshot, outbox: { count: alertEngine.readOutbox().length, file: alertEngine.OUTBOX_FILE }, sources: snapshot.sources.map((source) => ({ source: source.source, status: source.status, url: source.url, fetched_at: source.fetched_at, alert_count: (source.alerts || []).length })) });
});
app.get("/api/alerts/refresh", async (req, res) => {
  try {
    const snapshot = await alertEngine.collect({ latitude: req.query.lat, longitude: req.query.lon });
    const queued = alertEngine.queueSnapshot(snapshot);
    record("ALERTS_REFRESH", `${snapshot.status} queued=${queued.queued}`);
    res.json({ ...snapshot, offline_delivery: queued });
  } catch (error) {
    const snapshot = alertEngine.offlineSnapshot(); record("ALERTS_OFFLINE", error.message); res.status(200).json({ ...snapshot, error: error.message });
  }
});
app.get("/api/alerts/outbox", (req, res) => {
  if (!bridgeAuthorized(req)) return res.status(401).json({ status: "DENIED", detail: "bridge token required" });
  res.json({ schema: "zdos.alert.offline-outbox.v1", status: "READY", transport: "store-and-forward-zcomm", packets: alertEngine.readOutbox(Number(req.query.limit || 100)), policy: "DEFAULT-DENY" });
});
app.post("/api/alerts/explain", (req, res) => {
  const alerts = Array.isArray(req.body?.alerts) ? req.body.alerts : [];
  const deterministic = alertEngine.explain(alerts);
  if (req.body?.online === true && process.env.ZDOS_ALERT_AI_ONLINE === "1") return res.json(alertEngine.explainWithLlm(alerts, root));
  res.json(deterministic);
});
app.get("/api/web3/networks", (_req, res) => res.json({ schema: "zdos.web3.network-registry.v1", status: "READ_ONLY", policy: "DEFAULT-DENY", networks: Object.entries(web3Networks).map(([id, network]) => ({ id, name: network.name, chainId: network.chainId, rpc: new URL(network.rpc).origin, capabilities: ["chain.status", "block.read", "balance.read", "address.validate"] })), denied: ["wallet.sign", "wallet.transfer", "contract.write", "private-key.read"], note: "RPC allowlist HTTPS; ZDOS non custodisce fondi e non firma transazioni." }));
app.get("/api/web3/status", async (req, res) => {
  const requested = String(req.query.network || "").split(",").map((item) => item.trim().toLowerCase()).filter(Boolean);
  const ids = requested.length ? requested.slice(0, 5) : Object.keys(web3Networks);
  const results = await Promise.all(ids.map(async (id) => {
    const network = web3Network(id);
    if (!network) return { id, status: "DENIED", error: "network non allowlisted" };
    try { return { id, name: network.name, chainId: await web3Rpc(network, "eth_chainId"), blockNumber: await web3Rpc(network, "eth_blockNumber"), status: "ONLINE" }; }
    catch (error) { return { id, name: network.name, status: "OFFLINE", error: error.message }; }
  }));
  record("WEB3_STATUS_READ", ids.join(","));
  res.json({ schema: "zdos.web3.observation-status.v1", policy: "DEFAULT-DENY", results, denied: ["eth_sendRawTransaction", "personal_sign", "wallet.sign", "contract.write"] });
});
app.get("/api/web3/address", async (req, res) => {
  const address = String(req.query.address || "");
  const network = web3Network(req.query.network || "ethereum");
  if (!network || !isHexAddress(address)) return res.status(400).json({ status: "DENIED", error: "network o indirizzo EVM non valido" });
  try {
    const balance = await web3Rpc(network, "eth_getBalance", [address, "latest"]);
    res.json({ schema: "zdos.web3.address-observation.v1", status: "READ_ONLY", network: network.name, chainId: network.chainId, address, balanceWei: balance, balanceUnit: "wei", policy: "DEFAULT-DENY", note: "Saldo osservato via RPC; nessuna chiave o firma letta." });
  } catch (error) { res.status(200).json({ schema: "zdos.web3.address-observation.v1", status: "OFFLINE", network: network.name, address, policy: "DEFAULT-DENY", error: error.message }); }
});
app.get("/api/web3/validate", (req, res) => {
  const result = validateWeb3Zlang(req.query.source || "web3.networks\nweb3.chain.status\nweb3.block.read\nwallet.sign.deny\nwallet.transfer.deny\ncontract.write.deny\nhalt");
  res.json({ schema: "zdos.web3.zlang-validation.v1", profile: "zdos.web3.observe.v1", ...result, execution: "DENIED", policy: "DEFAULT-DENY" });
});
app.get("/api/local/browser", async (req, res) => {
  const raw = String(req.query.url || "https://app.x-zdos.it/");
  let target;
  try { target = new URL(raw); } catch { return res.status(400).json({ status: "DENIED", error: "URL non valido" }); }
  if (target.protocol !== "https:" || !allowedBrowserHosts.has(target.hostname)) return res.status(403).json({ status: "DENIED", policy: "BROWSER_ALLOWLIST", error: "host o protocollo non allowlisted" });
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), 7000);
  try {
    const response = await fetch(target, { signal: controller.signal, redirect: "manual", headers: { accept: "text/html,text/plain", "user-agent": "ZDOS-Read-Gateway/1" } });
    if (!response.ok) return res.status(200).json({ status: "REMOTE_ERROR", http_status: response.status, url: target.toString(), policy: "READ_ONLY" });
    const body = await response.text();
    if (body.length > 2 * 1024 * 1024) return res.status(413).json({ status: "DENIED", error: "pagina oltre 2 MiB" });
    const text = body.replace(/<script[\s\S]*?<\/script>/gi, " ").replace(/<style[\s\S]*?<\/style>/gi, " ").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim().slice(0, 12000);
    record("BROWSER_READ", target.hostname);
    res.json({ schema: "zdos.browser.page-read.v1", status: "READ_ONLY", url: target.toString(), title: text.slice(0, 160), text, policy: "HTTPS_ALLOWLIST_NO_COOKIES_NO_FORMS" });
  } catch (error) { res.status(200).json({ status: "OFFLINE", url: target.toString(), policy: "READ_ONLY", error: error.message }); }
  finally { clearTimeout(timer); }
});

for (const [route, procedure] of Object.entries({ "/api/remote/ecosystem": "ecosystem.list", "/api/remote/evidence": "evidence.list", "/api/remote/zcomm": "zcomm.catalog", "/api/remote/status": "node.status" })) {
  app.get(route, async (_req, res) => { try { const data = await remoteQuery(procedure); record("REMOTE_READ", procedure); res.json({ schema: "zdos.glass-engine.remote.v1", status: "ONLINE", procedure, source: remoteOrigin, data }); } catch (err) { record("REMOTE_OFFLINE", `${procedure}: ${err.message}`); remoteError(res, err); } });
}
app.get("/api/remote/health", async (_req, res) => {
  const procedures = ["ecosystem.list", "evidence.list", "zcomm.catalog", "node.status"];
  const results = await Promise.all(procedures.map(async (procedure) => { try { return { procedure, status: "ONLINE", data: await remoteQuery(procedure) }; } catch (err) { return { procedure, status: "OFFLINE", error: err.message }; } }));
  record("REMOTE_HEALTH", results.map((item) => `${item.procedure}:${item.status}`).join(" "));
  res.json({ schema: "zdos.glass-engine.remote-health.v1", source: remoteOrigin, policy: "DEFAULT-DENY", results });
});
app.get("/api/remote/validate", async (req, res) => {
  const source = String(req.query.source || "emit hello");
  if (source.length > 4096) return res.status(413).json({ status: "DENIED", error: "source oltre 4096 caratteri" });
  try { const data = await remoteQuery("zlang.validate", { profile: "zdos.zlang.microterm.v1", source }); record("REMOTE_VALIDATE", data?.accepted ? "accepted" : "denied"); res.json({ schema: "zdos.glass-engine.validation.v1", status: "ONLINE", source: remoteOrigin, data }); } catch (err) { remoteError(res, err); }
});
app.get("/api/ping", (_req, res) => res.json({ pong: true, policy: "DEFAULT-DENY" }));
app.use((_req, res) => res.status(404).json({ error: "not_found" }));
app.listen(port, host, () => { record("SYSTEM_BOOT", `Glass Engine read-only listening on http://${host}:${port}`); console.log(`ZDOS Glass Engine read-only listening on http://${host}:${port}`); });
