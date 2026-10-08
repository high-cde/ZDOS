(() => {
  const screen = document.querySelector("#videotel-screen");
  if (!screen) return;
  const crt = document.querySelector(".videotel-crt");
  const pill = document.querySelector("#videotel-pill");
  const input = document.querySelector("#videotel-input");
  const buttons = [document.querySelector("#videotel-go"), document.querySelector("#videotel-home")];
  const power = document.querySelector("#videotel-power");
  const logo = ["▀█▀ █▀▄ █▀█ █▀▀", " █▄ █▄▀ █▄█ ▄▄█"];
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let online = false;
  let busy = false;
  let history = [];

  function el(cls, text) { const span = document.createElement("span"); if (cls) span.className = cls; span.textContent = text; return span; }
  function setEnabled(value) { online = value; input.disabled = !value; buttons.forEach((b) => { b.disabled = !value; }); power.textContent = value ? "SPEGNI" : "ACCENDI"; pill.textContent = value ? "IN LINEA" : "SPENTO"; }

  async function boot() {
    const steps = ["ATZ", "ATDT 0 ZDOS-SIP", "CONNECT 1200/75 V.23", "HANDSHAKE ...... OK", "CARRIER ......... OK", "SERVIZIO VIDEOTEL ZLANG"];
    screen.textContent = "";
    for (const step of steps) { screen.append(el("", `${step}\n`)); await sleep(reduced ? 0 : 280); }
    await sleep(reduced ? 0 : 300);
  }

  function render(page) {
    screen.textContent = "";
    const head = ("ZDOS-SIP VIDEOTEL ".padEnd(30) + `P.${page.code}`).padEnd(40).slice(0, 40);
    screen.append(el("vt-title", head + "\n"));
    if (page.code === "0") logo.forEach((line) => screen.append(el("vt-logo", `   ${line}\n`)));
    const body = page.lines.map((line) => line.replace(/^(\s+)(\d)(\s\s)/, "$1\u0000$2$3"));
    body.forEach((line) => {
      const idx = line.indexOf("\u0000");
      if (idx === -1) screen.append(el("", line + "\n"));
      else { screen.append(el("", line.slice(0, idx)), el("vt-key", line[idx + 1]), el("", line.slice(idx + 2) + "\n")); }
    });
  }

  async function go(code) {
    if (!online || busy) return;
    busy = true;
    try {
      if (code === "*") { history.pop(); code = history.pop() || "0"; }
      const response = await fetch(`/api/videotel/page/${encodeURIComponent(code)}`, { headers: { accept: "application/json" } });
      if (!response.ok) { screen.append(el("", `\nPAGINA ${code} NON DISPONIBILE\n`)); return; }
      const page = await response.json();
      history.push(page.code);
      render(page);
    } catch { screen.append(el("", "\nLINEA INTERROTTA\n")); } finally { busy = false; input.value = ""; input.focus(); }
  }

  power.addEventListener("click", async () => {
    if (busy) return;
    if (online) { setEnabled(false); history = []; screen.textContent = "LINEA CHIUSA. Premi ACCENDI per ricollegarti."; return; }
    busy = true; power.disabled = true;
    crt.classList.remove("on"); void crt.offsetWidth; crt.classList.add("on");
    await boot();
    busy = false; power.disabled = false;
    setEnabled(true); history = [];
    await go("0");
  });
  document.querySelector("#videotel-form").addEventListener("submit", (event) => { event.preventDefault(); const code = input.value.trim(); if (/^(\d{1,3}|\*)$/.test(code)) go(code); });
  document.querySelector("#videotel-home").addEventListener("click", () => go("0"));
})();
