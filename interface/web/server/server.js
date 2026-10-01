const express = require("express");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

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
app.use(express.static(path.join(__dirname, "..", "web"), { index: "index.html" }));

app.get("/status", (_req, res) => res.json({ schema: "zdos.glass-engine.status.v1", status: "LOCAL_READ_ONLY", service: "zdos-interface-web", console: "GLASS_ENGINE", version: "2026.2", started_at: startedAt, mutations: false, remote_origin: remoteOrigin, policy: "DEFAULT-DENY" }));
app.get("/api/local/audit", (_req, res) => {
  const statusFile = path.join(root, "var/organism/status.json");
  let organism = { state: "NOT_CONNECTED" };
  try { if (fs.existsSync(statusFile)) organism = JSON.parse(fs.readFileSync(statusFile, "utf8")); } catch { organism = { state: "INVALID_STATUS_FILE" }; }
  res.json({ schema: "zdos.glass-engine.local.v1", policy: "DEFAULT-DENY", mutations: false, organism, evidence: tailJsonl(path.join(root, "evidence/ledger.jsonl")), events: tailJsonl(path.join(root, "var/organism/events.jsonl")), audit });
});
app.get("/api/local/system", (_req, res) => { record("LOCAL_SYSTEM_READ", "safe inventory"); res.json(localSystemSnapshot()); });
app.get("/api/local/network", (_req, res) => res.json({ schema: "zdos.glass-engine.local-network.v1", read_only: true, interfaces: safeCommand("ip", ["-brief", "link"]).output, addresses: safeCommand("ip", ["-brief", "addr"]).output, wifi: safeCommand("nmcli", ["-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi"]).output, policy: "DEFAULT-DENY", note: "Rileva Wi-Fi e rete ma non salva password e non cambia connessioni." }));
app.get("/api/local/zcomm", (_req, res) => res.json({ schema: "zdos.zcomm.desktop-bridge.v1", status: "LOCAL_QUEUE_READY", chat: "NOT_CONFIGURED", video: "NOT_CONFIGURED", capabilities: ["zcomm.page.read", "zcomm.message.queue"], transport: "local-first", policy: "DEFAULT-DENY", note: "Chat tra due utenti: signaling autenticato. Video: WebRTC/STUN/TURN. Non simulati." }));
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
