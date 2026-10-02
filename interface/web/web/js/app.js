const $ = (selector) => document.querySelector(selector);
const output = $("#terminal-output");
const modal = $("#modal");
const modalContent = $("#modal-content");
const remotePill = $("#remote-pill");

function pretty(value) { return JSON.stringify(value, null, 2); }
function showModal(title, body) { modalContent.innerHTML = `<h2>${title}</h2><div class="data-block">${body}</div>`; modal.classList.remove("hidden"); }
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#039;"}[c])); }
function writeTerminal(text) { output.innerHTML += `\n<span>${escapeHtml(text)}</span>`; output.scrollTop = output.scrollHeight; }
async function getJson(path) { const response = await fetch(path, { headers: { accept: "application/json" } }); return response.json(); }

function updateClock() {
  const now = new Date();
  $("#system-date").textContent = now.toLocaleDateString("it-IT", { weekday: "short", day: "2-digit", month: "2-digit", year: "numeric" }).toUpperCase();
  $("#system-time").textContent = now.toLocaleTimeString("it-IT", { hour12: false });
}

async function refreshHealth() {
  try {
    const health = await getJson("/api/remote/health");
    const online = health.results.filter((item) => item.status === "ONLINE").length;
    remotePill.textContent = `REMOTE · ${online}/${health.results.length} ONLINE`;
    remotePill.className = `pill ${online ? "green" : "pending"}`;
    $("#metric-remote").textContent = `${online}/${health.results.length} ONLINE`;
    $("#footer-remote").textContent = `Remote: ${online}/${health.results.length} online`;
    const node = health.results.find((item) => item.procedure === "node.status");
    $("#metric-node").textContent = node?.data?.status || node?.status || "OFFLINE";
  } catch {
    remotePill.textContent = "REMOTE · OFFLINE"; remotePill.className = "pill pending";
    $("#metric-remote").textContent = "OFFLINE"; $("#footer-remote").textContent = "Remote: offline";
  }
  try { const evidence = await getJson("/api/remote/evidence"); $("#metric-evidence")?.replaceWith(Object.assign(document.createElement("strong"), { id: "metric-evidence", textContent: Array.isArray(evidence.data) ? `${evidence.data.length} RECORDS` : "READY" })); } catch {}
  try {
    const system = await getJson("/api/local/system");
    $("#metric-pc").textContent = system.os?.replace(" GNU/Linux", "").slice(0, 18) || "READY";
    const wifi = system.wifi?.available ? "RADIO READY" : "NO NMCLI";
    $("#metric-wifi").textContent = wifi;
  } catch { $("#metric-pc").textContent = "OFFLINE"; $("#metric-wifi").textContent = "UNKNOWN"; }
}

async function openData(title, endpoint) {
  showModal(title, "READING…");
  try { const data = await getJson(endpoint); modalContent.querySelector(".data-block").textContent = pretty(data); }
  catch (error) { modalContent.querySelector(".data-block").textContent = `OFFLINE\n${error.message}`; }
}

function openModule(name) {
  if (name === "xcloud") showModal("xCLOUD-by-zdos Enterprise", "COLLEGAMENTO DICHIARATIVO\n\nLa superficie xCLOUD resta disponibile senza inventare un backend o una sessione autenticata.\n\nRepository: https://github.com/high-cde/xCLOUD-by-zdos");
  if (name === "dashboards") openData("System & Mesh Dashboards", "/api/remote/health");
  if (name === "files") showModal("Cloud File Manager", "READ-ONLY SURFACE\n\nLa console conserva il modulo originale come accesso documentale. Nessuna scrittura GitHub, GitLab o Discord viene eseguita dal browser.");
  if (name === "audit") openData("Backend Audit Logs", "/api/local/audit");
  if (name === "evidence") openData("Evidence Chain Ledger", "/api/remote/evidence");
  if (name === "browser") showModal("Anon Browser", "LINK SURFACE\n\nLa console non dichiara un circuito Tor attivo. Apri il browser autorizzato del sistema separatamente se necessario.");
  if (name === "system") openData("PC Analysis / Kali Ops", "/api/local/system");
  if (name === "network") openData("Wi-Fi & Network Radar", "/api/local/network");
  if (name === "zcomm") openData("ZComm / Microcosm Link", "/api/local/zcomm");
  if (name === "zlang") {
    modalContent.innerHTML = `<h2>Zlang Runtime Studio</h2><p>Validazione server-side del profilo <b>zdos.zlang.microterm.v1</b>. Esecuzione sempre negata.</p><textarea id="validate-source" class="validate-box">emit hello</textarea><br><button class="modal-action" id="validate-button">VALIDATE CONTRACT</button><div id="validate-result" class="data-block" style="margin-top:12px">READY</div>`;
    modal.classList.remove("hidden");
    $("#validate-button").addEventListener("click", async () => { const source = $("#validate-source").value; const result = $("#validate-result"); result.textContent = "VALIDATING…"; try { result.textContent = pretty(await getJson(`/api/remote/validate?source=${encodeURIComponent(source)}`)); } catch (error) { result.textContent = `OFFLINE\n${error.message}`; } });
  }
}

document.querySelectorAll("[data-open]").forEach((button) => button.addEventListener("click", () => openModule(button.dataset.open)));
$("#modal-close").addEventListener("click", () => modal.classList.add("hidden"));
modal.addEventListener("click", (event) => { if (event.target === modal) modal.classList.add("hidden"); });

$("#terminal-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const input = $("#terminal-input"); const command = input.value.trim(); input.value = ""; if (!command) return;
  writeTerminal(`zdos@glass:~$ ${command}`); const [verb, ...rest] = command.split(" ");
  if (verb === "help") writeTerminal("help | status | remote | system | wifi | evidence | zcomm | validate <source> | clear");
  else if (verb === "clear") output.innerHTML = "CLEARED · bounded local console";
  else if (verb === "status") { try { writeTerminal(pretty(await getJson("/status"))); } catch { writeTerminal("LOCAL STATUS OFFLINE"); } }
  else if (verb === "remote") { try { writeTerminal(pretty(await getJson("/api/remote/health"))); } catch { writeTerminal("REMOTE OFFLINE · no mutation attempted"); } }
  else if (verb === "system") { try { writeTerminal(pretty(await getJson("/api/local/system"))); } catch { writeTerminal("LOCAL SYSTEM OFFLINE"); } }
  else if (verb === "wifi") { try { writeTerminal(pretty(await getJson("/api/local/network"))); } catch { writeTerminal("WIFI RADAR OFFLINE"); } }
  else if (verb === "evidence") { try { writeTerminal(pretty(await getJson("/api/remote/evidence"))); } catch { writeTerminal("EVIDENCE REMOTE OFFLINE"); } }
  else if (verb === "zcomm") { try { writeTerminal(pretty(await getJson("/api/local/zcomm"))); } catch { writeTerminal("ZCOMM LOCAL OFFLINE"); } }
  else if (verb === "validate") { const source = rest.join(" ") || "emit hello"; try { writeTerminal(pretty(await getJson(`/api/remote/validate?source=${encodeURIComponent(source)}`))); } catch { writeTerminal("VALIDATOR OFFLINE"); } }
  else writeTerminal("DENIED · command outside Glass Engine safe catalog; no shell invoked");
});

updateClock(); setInterval(updateClock, 1000); refreshHealth(); setInterval(refreshHealth, 30000);

const browserUrl = $("#browser-url");
const browserFeed = $("#browser-feed");
const browserStatus = $("#browser-status-text");
const browserExternal = $("#browser-external");

function setBrowserStatus(text, error = false) {
  browserStatus.textContent = text;
  browserStatus.style.color = error ? "var(--red)" : "var(--green)";
}

async function readBrowserPage() {
  const url = browserUrl.value.trim();
  if (!/^https:\/\//i.test(url)) { setBrowserStatus("DENIED · HTTPS REQUIRED", true); browserFeed.textContent = "Il Read Gateway accetta soltanto URL HTTPS."; return; }
  setBrowserStatus("READING · ALLOWLIST CHECK…"); browserFeed.textContent = "Lettura read-only in corso…";
  try {
    const data = await getJson(`/api/local/browser?url=${encodeURIComponent(url)}`);
    if (data.status !== "READ_ONLY") { setBrowserStatus(`${data.status} · ${data.error || "nessun contenuto"}`, true); browserFeed.textContent = pretty(data); return; }
    browserFeed.textContent = `${data.title}\n\n${data.text}`;
    setBrowserStatus(`READY · ${new URL(data.url).hostname} · NO COOKIES · NO FORMS`);
  } catch (error) { setBrowserStatus(`OFFLINE · ${error.message}`, true); browserFeed.textContent = "Gateway non disponibile."; }
}

document.querySelectorAll("[data-browser-action]").forEach((button) => button.addEventListener("click", () => {
  const action = button.dataset.browserAction;
  if (action === "read") readBrowserPage();
  if (action === "reload") readBrowserPage();
  if (action === "back" || action === "forward") setBrowserStatus(`${action.toUpperCase()} · cronologia locale non ancora popolata`);
}));
browserUrl?.addEventListener("input", () => { if (browserExternal) browserExternal.href = browserUrl.value; });

const walletStatus = $("#wallet-chain-status");
const walletDetail = $("#wallet-chain-detail");
const walletIdentity = $("#wallet-identity");
const walletDid = $("#wallet-did");
const walletRole = $("#wallet-role");
const walletEntries = $("#wallet-entries");
const walletHead = $("#wallet-head");
const walletFeed = $("#wallet-feed");

async function refreshEvidenceWallet() {
  if (!walletStatus) return;
  try {
    const data = await getJson("/api/local/evidence/wallet");
    const verification = data.ledger?.verification?.status || "EMPTY";
    walletStatus.textContent = verification;
    walletStatus.style.color = verification === "VERIFIED" ? "var(--green)" : verification === "INVALID" ? "var(--red)" : "var(--amber)";
    walletDetail.textContent = data.ledger?.verification?.detail || "local ledger";
    walletIdentity.textContent = data.identity?.status || "NOT INITIALIZED";
    walletDid.textContent = data.identity?.did || "did:zdos:—";
    walletRole.textContent = data.identity?.role ? `role: ${data.identity.role}` : "local identity required for capabilities";
    walletEntries.textContent = `${data.ledger?.entries || 0} EVENTS`;
    walletHead.textContent = data.ledger?.head ? `${data.ledger.head.slice(0, 18)}…` : "0000000000000000…";
    walletFeed.textContent = pretty(data);
  } catch (error) { walletStatus.textContent = "OFFLINE"; walletDetail.textContent = error.message; }
}

document.querySelectorAll("[data-wallet-action]").forEach((button) => button.addEventListener("click", refreshEvidenceWallet));
refreshEvidenceWallet();

const dashboardFeeds = {
  health: $("#health-feed"), system: $("#system-feed"), audit: $("#audit-feed"), zcomm: $("#zcomm-feed"), files: $("#files-feed"), zlang: $("#zlang-feed")
};

async function refreshDashboard(name) {
  const feed = dashboardFeeds[name];
  if (feed) feed.textContent = "LOADING…";
  try {
    const endpoint = { health: "/api/remote/health", system: "/api/local/system", audit: "/api/local/audit", zcomm: "/api/local/zcomm" }[name];
    const data = endpoint ? await getJson(endpoint) : name === "files" ? { schema: "zdos.storage.scope.v1", capability: "storage.read-v1", namespace: "explicit-root", root: "ZDOS workspace", allowed: ["read metadata", "read bounded files"], denied: ["write", "delete", "path traversal", "remote mutation"] } : { schema: "zdos.zlang.studio.v1", profile: "zdos.zlang.microterm.v1", status: "VALIDATE_ONLY", execution: "DENIED", source: "emit hello", capabilities: ["validate", "hash", "evidence.read-v1"] };
    if (feed) feed.textContent = pretty(data);
    if (name === "health") {
      const online = (data.results || []).filter((item) => item.status === "ONLINE").length;
      $("#health-online").textContent = `${online}/${(data.results || []).length} ONLINE`;
      $("#health-local").textContent = "ACTIVE";
    }
    if (name === "system") {
      $("#system-host").textContent = data.hostname || "READY";
      $("#system-os").textContent = data.os || "OS unavailable";
      $("#system-resources").textContent = data.cpu ? `${data.cpu.count} CORES` : "READY";
      $("#system-uptime").textContent = `uptime ${Math.round(data.uptime_seconds || 0)}s`;
      $("#system-tools").textContent = data.tools ? `${Object.values(data.tools).filter(Boolean).length}/${Object.keys(data.tools).length}` : "—";
    }
    if (name === "audit") $("#audit-count").textContent = `${(data.audit || []).length} EVENTS`;
    if (name === "zcomm") {
      $("#zcomm-status").textContent = data.status || "LOCAL_QUEUE_READY";
      $("#zcomm-chat").textContent = data.chat || "NOT CONFIGURED";
      $("#zcomm-video").textContent = data.video || "NOT CONFIGURED";
    }
  } catch (error) { if (feed) feed.textContent = `OFFLINE\n${error.message}`; }
}

document.querySelectorAll("[data-dashboard]").forEach((button) => button.addEventListener("click", () => refreshDashboard(button.dataset.dashboard)));
["health", "system", "audit", "zcomm", "files", "zlang"].forEach(refreshDashboard);
