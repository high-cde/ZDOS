const $ = (selector) => document.querySelector(selector);
const output = $("#terminal-output");
const modal = $("#modal");
const modalContent = $("#modal-content");
const remotePill = $("#remote-pill");

function pretty(value) { return JSON.stringify(value, null, 2); }
function showModal(title, body) {
  modalContent.innerHTML = `<h2>${title}</h2><div class="data-block">${body}</div>`;
  modal.classList.remove("hidden");
}
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#039;"}[c])); }
function writeTerminal(text) { output.innerHTML += `\n<span>${escapeHtml(text)}</span>`; output.scrollTop = output.scrollHeight; }

async function getJson(path) {
  const response = await fetch(path, { headers: { accept: "application/json" } });
  return response.json();
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
  } catch (error) {
    remotePill.textContent = "REMOTE · OFFLINE";
    remotePill.className = "pill pending";
    $("#metric-remote").textContent = "OFFLINE";
    $("#footer-remote").textContent = "Remote: offline";
  }
  try {
    const evidence = await getJson("/api/remote/evidence");
    $("#metric-evidence").textContent = Array.isArray(evidence.data) ? `${evidence.data.length} RECORDS` : "READY";
  } catch { $("#metric-evidence").textContent = "OFFLINE"; }
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
  if (name === "zlang") {
    modalContent.innerHTML = `<h2>Zlang Runtime Studio</h2><p>Validazione server-side del profilo <b>zdos.zlang.microterm.v1</b>. Esecuzione sempre negata.</p><textarea id="validate-source" class="validate-box">emit hello</textarea><br><button class="modal-action" id="validate-button">VALIDATE CONTRACT</button><div id="validate-result" class="data-block" style="margin-top:12px">READY</div>`;
    modal.classList.remove("hidden");
    $("#validate-button").addEventListener("click", async () => {
      const source = $("#validate-source").value;
      const result = $("#validate-result");
      result.textContent = "VALIDATING…";
      try { result.textContent = pretty(await getJson(`/api/remote/validate?source=${encodeURIComponent(source)}`)); }
      catch (error) { result.textContent = `OFFLINE\n${error.message}`; }
    });
  }
}

document.querySelectorAll("[data-open]").forEach((button) => button.addEventListener("click", () => openModule(button.dataset.open)));
$("#modal-close").addEventListener("click", () => modal.classList.add("hidden"));
modal.addEventListener("click", (event) => { if (event.target === modal) modal.classList.add("hidden"); });

$("#terminal-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const input = $("#terminal-input");
  const command = input.value.trim();
  input.value = "";
  if (!command) return;
  writeTerminal(`zdos@glass:~$ ${command}`);
  const [verb, ...rest] = command.split(" ");
  if (verb === "help") writeTerminal("help | status | remote | evidence | zcomm | validate <source> | clear");
  else if (verb === "clear") output.innerHTML = "CLEARED · bounded local console";
  else if (verb === "status") { try { writeTerminal(pretty(await getJson("/status"))); } catch { writeTerminal("LOCAL STATUS OFFLINE"); } }
  else if (verb === "remote") { try { writeTerminal(pretty(await getJson("/api/remote/health"))); } catch { writeTerminal("REMOTE OFFLINE · no mutation attempted"); } }
  else if (verb === "evidence") { try { writeTerminal(pretty(await getJson("/api/remote/evidence"))); } catch { writeTerminal("EVIDENCE REMOTE OFFLINE"); } }
  else if (verb === "zcomm") { try { writeTerminal(pretty(await getJson("/api/remote/zcomm"))); } catch { writeTerminal("ZCOMM REMOTE OFFLINE"); } }
  else if (verb === "validate") { const source = rest.join(" ") || "emit hello"; try { writeTerminal(pretty(await getJson(`/api/remote/validate?source=${encodeURIComponent(source)}`))); } catch { writeTerminal("VALIDATOR OFFLINE"); } }
  else writeTerminal("DENIED · command outside Glass Engine safe catalog; no shell invoked");
});

refreshHealth();
setInterval(refreshHealth, 30000);
