const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const port = Number.parseInt(process.env.PORT || "8080", 10);
const host = process.env.HOST || "127.0.0.1";
const root = path.resolve(__dirname, "../../..");
const remoteOrigin = "https://app.x-zdos.it";
const remoteApi = `${remoteOrigin}/api/trpc`;
const allowedRemote = new Set(["ecosystem.list", "evidence.list", "zcomm.catalog", "node.status", "zlang.validate"]);
const audit = [];
const startedAt = new Date().toISOString();

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT deve essere un intero compreso tra 1 e 65535");
}

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

async function remoteQuery(procedure, input = {}) {
  if (!allowedRemote.has(procedure)) throw new Error("procedura remota non allowlisted");
  const url = new URL(`${remoteApi}/${procedure}`);
  url.searchParams.set("input", JSON.stringify({ json: input }));
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 7000);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: { accept: "application/json", "user-agent": "ZDOS-Glass-Engine/1 read-only" },
    });
    if (!response.ok) throw new Error(`remote HTTP ${response.status}`);
    const contentLength = Number(response.headers.get("content-length") || 0);
    if (contentLength > 1024 * 1024) throw new Error("risposta remota oltre il limite");
    const body = await response.json();
    if (body?.error) throw new Error(body.error.json?.message || "errore tRPC remoto");
    return body?.result?.data?.json ?? body?.result?.data ?? body;
  } finally {
    clearTimeout(timer);
  }
}

function remoteError(res, err) {
  res.status(200).json({ status: "OFFLINE", policy: "DEFAULT-DENY", source: remoteOrigin, error: err instanceof Error ? err.message : String(err) });
}

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.set({
    "Cache-Control": "no-store",
    "Content-Security-Policy": "default-src 'self'; connect-src 'self'; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  });
  next();
});
app.use(express.json({ limit: "16kb" }));
app.use(express.static(path.join(__dirname, "..", "web"), { index: "index.html" }));

app.get("/status", (_req, res) => {
  res.json({
    schema: "zdos.glass-engine.status.v1",
    status: "LOCAL_READ_ONLY",
    service: "zdos-interface-web",
    console: "GLASS_ENGINE",
    version: "2026.2",
    started_at: startedAt,
    mutations: false,
    remote_origin: remoteOrigin,
    policy: "DEFAULT-DENY",
  });
});

app.get("/api/local/audit", (_req, res) => {
  const statusFile = path.join(root, "var/organism/status.json");
  res.json({
    schema: "zdos.glass-engine.local.v1",
    policy: "DEFAULT-DENY",
    mutations: false,
    organism: fs.existsSync(statusFile) ? JSON.parse(fs.readFileSync(statusFile, "utf8")) : { state: "NOT_CONNECTED" },
    evidence: tailJsonl(path.join(root, "evidence/ledger.jsonl")),
    events: tailJsonl(path.join(root, "var/organism/events.jsonl")),
    audit,
  });
});

for (const [route, procedure] of Object.entries({
  "/api/remote/ecosystem": "ecosystem.list",
  "/api/remote/evidence": "evidence.list",
  "/api/remote/zcomm": "zcomm.catalog",
  "/api/remote/status": "node.status",
})) {
  app.get(route, async (_req, res) => {
    try {
      const data = await remoteQuery(procedure);
      record("REMOTE_READ", procedure);
      res.json({ schema: "zdos.glass-engine.remote.v1", status: "ONLINE", procedure, source: remoteOrigin, data });
    } catch (err) {
      record("REMOTE_OFFLINE", `${procedure}: ${err.message}`);
      remoteError(res, err);
    }
  });
}

app.get("/api/remote/health", async (_req, res) => {
  const procedures = ["ecosystem.list", "evidence.list", "zcomm.catalog", "node.status"];
  const results = await Promise.all(procedures.map(async (procedure) => {
    try { return { procedure, status: "ONLINE", data: await remoteQuery(procedure) }; }
    catch (err) { return { procedure, status: "OFFLINE", error: err.message }; }
  }));
  record("REMOTE_HEALTH", results.map((item) => `${item.procedure}:${item.status}`).join(" "));
  res.json({ schema: "zdos.glass-engine.remote-health.v1", source: remoteOrigin, policy: "DEFAULT-DENY", results });
});

app.get("/api/remote/validate", async (req, res) => {
  const source = String(req.query.source || "emit hello");
  if (source.length > 4096) return res.status(413).json({ status: "DENIED", error: "source oltre 4096 caratteri" });
  try {
    const data = await remoteQuery("zlang.validate", { profile: "zdos.zlang.microterm.v1", source });
    record("REMOTE_VALIDATE", data?.accepted ? "accepted" : "denied");
    res.json({ schema: "zdos.glass-engine.validation.v1", status: "ONLINE", source: remoteOrigin, data });
  } catch (err) { remoteError(res, err); }
});

app.get("/api/ping", (_req, res) => res.json({ pong: true, policy: "DEFAULT-DENY" }));
app.use((_req, res) => res.status(404).json({ error: "not_found" }));

app.listen(port, host, () => {
  record("SYSTEM_BOOT", `Glass Engine read-only listening on http://${host}:${port}`);
  console.log(`ZDOS Glass Engine read-only listening on http://${host}:${port}`);
});
