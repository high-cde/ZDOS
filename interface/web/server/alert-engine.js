const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { spawnSync } = require("child_process");

const CACHE_FILE = process.env.ZDOS_ALERT_CACHE_FILE || path.join(require("os").homedir(), ".local/share/zdos-glass-engine/alerts/cache.json");
const OUTBOX_FILE = process.env.ZDOS_ALERT_OUTBOX_FILE || path.join(require("os").homedir(), ".local/share/zdos-glass-engine/alerts/outbox.jsonl");
const SOURCES = {
  meteoalarm: "https://feeds.meteoalarm.org/api/v1/warnings/feeds-italy",
  protezione_civile: "https://mappe.protezionecivile.gov.it/it/mappe-rischi/bollettino-di-criticita/",
  open_meteo: "https://api.open-meteo.com/v1/forecast",
};

function digest(value) { return crypto.createHash("sha256").update(JSON.stringify(value)).digest("hex"); }
function ensureDir(file) { fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 }); }
function readJson(file, fallback) { try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch { return fallback; } }
function writeJson(file, value) { ensureDir(file); const tmp = `${file}.${process.pid}.tmp`; fs.writeFileSync(tmp, JSON.stringify(value, null, 2), { mode: 0o600 }); fs.renameSync(tmp, file); }
function readCache() { return readJson(CACHE_FILE, null); }
function fetchWithTimeout(url, options = {}, timeoutMs = 9000) {
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), timeoutMs);
  return fetch(url, { ...options, signal: controller.signal, headers: { accept: "application/json,text/html,application/xhtml+xml", "user-agent": "ZDOS-Alert-Observer/1", ...(options.headers || {}) } }).finally(() => clearTimeout(timer));
}
function compactText(value) { return String(value || "").replace(/<script[\s\S]*?<\/script>/gi, " ").replace(/<style[\s\S]*?<\/style>/gi, " ").replace(/<[^>]+>/g, " ").replace(/&nbsp;/gi, " ").replace(/&amp;/gi, "&").replace(/\s+/g, " ").trim(); }
function awarenessLevel(event = "") { const value = event.toLowerCase(); return value.includes("red") || value.includes("rossa") ? "RED" : value.includes("orange") || value.includes("arancione") ? "ORANGE" : value.includes("yellow") || value.includes("gialla") ? "YELLOW" : "GREEN"; }
function alertType(event = "") { const value = event.toLowerCase(); if (value.includes("snow") || value.includes("neve") || value.includes("avalanche") || value.includes("valang")) return "SNOW"; if (value.includes("landslide") || value.includes("frana") || value.includes("hydrogeological") || value.includes("idrogeologico")) return "LANDSLIDE_HYDROGEOLOGICAL"; return "WEATHER"; }

async function meteoAlarm() {
  const response = await fetchWithTimeout(SOURCES.meteoalarm); if (!response.ok) throw new Error(`MeteoAlarm HTTP ${response.status}`);
  const data = await response.json();
  const alerts = (data.warnings || []).flatMap((item) => {
    const infoList = (item.alert?.info || []).filter((info) => info.language === "it-IT" || info.language === "it" || !info.language);
    return infoList.map((info) => ({
      id: item.alert.identifier || item.uuid, source: "MeteoAlarm", source_url: info.web || SOURCES.meteoalarm,
      type: alertType(info.event), level: awarenessLevel(info.event), event: info.event, headline: info.headline,
      description: info.description, instruction: info.instruction, area: (info.area || []).map((area) => area.areaDesc),
      effective: info.effective, onset: info.onset, expires: info.expires, official: true, received_at: new Date().toISOString(),
    }));
  });
  return { source: "MeteoAlarm", url: SOURCES.meteoalarm, fetched_at: new Date().toISOString(), alerts: alerts.slice(0, 250) };
}
async function protezioneCivile() {
  const response = await fetchWithTimeout(SOURCES.protezione_civile, { headers: { accept: "text/html" } }); if (!response.ok) throw new Error(`Protezione Civile HTTP ${response.status}`);
  const text = compactText(await response.text());
  const markers = [...text.matchAll(/(?:ALLERTA|CRITICITÀ|CRITICITA)[^.!?]{0,420}/gi)].map((match) => match[0]).filter((value, index, list) => list.indexOf(value) === index).slice(0, 30);
  const alerts = markers.map((summary, index) => ({ id: `dpc-${digest(summary).slice(0, 20)}-${index}`, source: "Dipartimento Protezione Civile", source_url: SOURCES.protezione_civile, type: /idrogeolog|fran/i.test(summary) ? "LANDSLIDE_HYDROGEOLOGICAL" : "WEATHER", level: awarenessLevel(summary), event: /idrogeolog|fran/i.test(summary) ? "Rischio idrogeologico / frane" : "Bollettino meteo-idro", headline: summary.slice(0, 260), description: "Estratto dal bollettino ufficiale DPC; consultare la fonte per dettaglio territoriale e validità.", area: [], official: true, received_at: new Date().toISOString() }));
  return { source: "Dipartimento Protezione Civile", url: SOURCES.protezione_civile, fetched_at: new Date().toISOString(), alerts, note: "Il rischio idrogeologico è il proxy ufficiale per scenari di frana; non è una previsione puntuale di frana." };
}
async function openMeteo(latitude, longitude) {
  const lat = Number(latitude); const lon = Number(longitude); if (!Number.isFinite(lat) || !Number.isFinite(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180) throw new Error("coordinate WGS84 non valide");
  const url = new URL(SOURCES.open_meteo); url.search = new URLSearchParams({ latitude: String(lat), longitude: String(lon), timezone: "auto", forecast_days: "3", current: "temperature_2m,precipitation,snowfall,snow_depth,weather_code,wind_gusts_10m", hourly: "precipitation,snowfall,precipitation_probability,snow_depth,freezing_level_height", daily: "snowfall_sum,precipitation_sum,precipitation_probability_max,wind_gusts_10m_max" });
  const response = await fetchWithTimeout(url); if (!response.ok) throw new Error(`Open-Meteo HTTP ${response.status}`); const data = await response.json();
  const snow = Number(data.current?.snowfall || 0); const dailySnow = Math.max(...(data.daily?.snowfall_sum || []).map(Number).filter(Number.isFinite), 0); const probability = Math.max(...(data.daily?.precipitation_probability_max || []).map(Number).filter(Number.isFinite), 0);
  return { source: "Open-Meteo", url: url.toString(), fetched_at: new Date().toISOString(), location: { latitude: lat, longitude: lon }, current: data.current || {}, daily: data.daily || {}, alert_signals: { snow_now_cm: snow, snow_next_3_days_cm: dailySnow, precipitation_probability_max: probability, snow_signal: dailySnow >= 10 || snow >= 2 ? "WATCH" : "NORMAL" }, official: false, note: "Previsione modellistica; non sostituisce un'allerta ufficiale." };
}
async function collect({ latitude, longitude } = {}) {
  const tasks = [meteoAlarm(), protezioneCivile()]; if (latitude !== undefined && longitude !== undefined) tasks.push(openMeteo(latitude, longitude));
  const settled = await Promise.allSettled(tasks); const sources = settled.map((item) => item.status === "fulfilled" ? { status: "ONLINE", ...item.value } : { status: "OFFLINE", error: item.reason?.message || String(item.reason) });
  const snapshot = { schema: "zdos.alerts.snapshot.v1", status: sources.some((source) => source.status === "ONLINE") ? "ONLINE_PARTIAL" : "OFFLINE", generated_at: new Date().toISOString(), stale: false, sources, policy: "DEFAULT-DENY", integrity_sha256: "" };
  snapshot.integrity_sha256 = digest({ ...snapshot, integrity_sha256: "" }); writeJson(CACHE_FILE, snapshot); return snapshot;
}
function offlineSnapshot() { const cached = readCache(); if (!cached) return { schema: "zdos.alerts.snapshot.v1", status: "NO_DATA", stale: true, sources: [], policy: "DEFAULT-DENY", note: "Nessun dato verificato disponibile offline." }; return { ...cached, status: "OFFLINE_STALE", stale: true, stale_since: cached.generated_at, note: "Rete non disponibile: dato conservato localmente, non equivalente ad allerta attuale." }; }
function queueSnapshot(snapshot) { const active = snapshot.sources.flatMap((source) => source.alerts || []).slice(0, 100); if (!active.length) return { queued: 0, file: OUTBOX_FILE }; ensureDir(OUTBOX_FILE); const existing = new Set(fs.existsSync(OUTBOX_FILE) ? fs.readFileSync(OUTBOX_FILE, "utf8").split("\n").filter(Boolean).map((line) => { try { return JSON.parse(line).id; } catch { return ""; } }) : []); const packets = active.filter((alert) => !existing.has(alert.id)).map((alert) => { const packet = { schema: "zdos.alert.offline-packet.v1", id: alert.id, created_at: new Date().toISOString(), priority: alert.level, alert, transport: "store-and-forward-zcomm", execution: "NONE", policy: "DEFAULT-DENY" }; return { ...packet, integrity_sha256: digest(packet) }; }); fs.appendFileSync(OUTBOX_FILE, packets.map((packet) => `${JSON.stringify(packet)}\n`).join(""), { mode: 0o600 }); return { queued: packets.length, file: OUTBOX_FILE, packets: packets.map((packet) => packet.id) }; }
function readOutbox(limit = 100) { return fs.existsSync(OUTBOX_FILE) ? fs.readFileSync(OUTBOX_FILE, "utf8").split("\n").filter(Boolean).slice(-limit).map((line) => { try { return JSON.parse(line); } catch { return { invalid: true }; } }) : []; }
function explain(alerts) { const list = Array.isArray(alerts) ? alerts.slice(0, 20) : []; const counts = list.reduce((acc, alert) => { acc[alert.level || "UNKNOWN"] = (acc[alert.level || "UNKNOWN"] || 0) + 1; return acc; }, {}); const highest = ["RED", "ORANGE", "YELLOW", "GREEN"].find((level) => counts[level]); return { schema: "zdos.alert.ai-explanation.v1", mode: "BOUNDED_DETERMINISTIC", status: "READY", summary: list.length ? `${list.length} alert osservati; livello massimo ${highest || "UNKNOWN"}.` : "Nessun alert disponibile.", signals: counts, guardrail: "L'AI spiega fonti e segnali ma non dichiara emergenze, non sostituisce Protezione Civile e non invia ordini.", next: highest === "RED" || highest === "ORANGE" ? "Consultare immediatamente la fonte ufficiale e le istruzioni locali." : "Monitorare la fonte ufficiale e mantenere aggiornato il piano locale." }; }
function explainWithLlm(alerts, root) {
  const bridge = path.join(root, "ai/zdos_llm_bridge.py"); if (!fs.existsSync(bridge)) return { status: "OFFLINE_READY", detail: "LLM bridge non trovato" };
  const safe = (Array.isArray(alerts) ? alerts : []).slice(0, 20).map((alert) => ({ source: alert.source, type: alert.type, level: alert.level, area: alert.area, headline: alert.headline, effective: alert.effective, expires: alert.expires }));
  const prompt = `Analizza questi alert reali già raccolti da ZDOS. Non creare fatti, non cambiare livelli, non dare ordini e non dichiarare emergenze. Restituisci un breve riassunto in italiano con fonti da consultare e incertezza esplicita. Dati JSON: ${JSON.stringify(safe)}`;
  const result = spawnSync("python3", [bridge, prompt], { encoding: "utf8", timeout: 15000, maxBuffer: 128 * 1024 });
  if (result.status !== 0) return { status: "DEGRADED", detail: "LLM non disponibile; usare spiegazione deterministica", fallback: explain(alerts) };
  try { return { ...JSON.parse(result.stdout), mode: "BOUNDED_LLM_ASSISTED", guardrail: "Il testo è assistivo: i livelli restano quelli delle fonti e nessuna azione viene eseguita." }; } catch { return { status: "DEGRADED", detail: "risposta LLM non valida", fallback: explain(alerts) }; }
}
module.exports = { SOURCES, collect, offlineSnapshot, queueSnapshot, readOutbox, explain, explainWithLlm, CACHE_FILE, OUTBOX_FILE };
