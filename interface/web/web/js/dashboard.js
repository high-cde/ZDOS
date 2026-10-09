const capabilityContainer = document.getElementById("capabilities");
const summary = document.getElementById("service-summary");
const updatedAt = document.getElementById("updated-at");
const refreshButton = document.getElementById("refresh-button");
const liveDot = document.querySelector(".live-dot");

function appendText(parent, tagName, className, text) {
  const element = document.createElement(tagName);
  if (className) element.className = className;
  element.textContent = text;
  parent.append(element);
  return element;
}

function formatUptime(seconds) {
  const total = Math.max(0, Math.floor(seconds));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const remainingSeconds = total % 60;
  if (hours > 0) return `${hours} h ${minutes} min`;
  if (minutes > 0) return `${minutes} min ${remainingSeconds} s`;
  return `${remainingSeconds} s`;
}

function renderCapabilities(capabilities) {
  capabilityContainer.replaceChildren();

  for (const capability of capabilities) {
    const card = document.createElement("article");
    card.className = "capability-card";
    const top = document.createElement("div");
    top.className = "capability-top";
    appendText(top, "span", "step", capability.level);
    appendText(top, "span", `maturity ${capability.status}`, capability.label);
    card.append(top);
    appendText(card, "h3", "", capability.name);
    appendText(card, "p", "", capability.description);

    if (capability.evidenceUrl) {
      const evidence = document.createElement("a");
      evidence.className = "evidence-link";
      evidence.href = capability.evidenceUrl;
      evidence.textContent = "Documentazione ed evidenze ↗";
      card.append(evidence);
    }
    capabilityContainer.append(card);
  }
}

function setUnavailable(message) {
  summary.textContent = message;
  liveDot.classList.add("is-error");
  document.getElementById("api-status").textContent = "Non raggiungibile";
  document.getElementById("api-mode").textContent = "Dato non disponibile";
  document.getElementById("uptime").textContent = "—";
  document.getElementById("runtime").textContent = "—";
  updatedAt.textContent = "Ultimo aggiornamento non disponibile";
  capabilityContainer.replaceChildren();
  appendText(capabilityContainer, "p", "error-message", "Lo stato non è disponibile. Verifica che il servizio web locale sia avviato.");
}

async function refreshStatus() {
  refreshButton.disabled = true;
  summary.textContent = "Aggiornamento dello stato locale…";
  liveDot.classList.remove("is-error");

  try {
    const response = await fetch("/status", {
      cache: "no-store",
      headers: { Accept: "application/json" },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);

    const data = await response.json();
    if (data.status !== "LOCAL_READ_ONLY" || data.mutations !== false) {
      throw new Error("Contratto locale inatteso");
    }

    summary.textContent = "Servizio web locale raggiungibile · sola lettura";
    document.getElementById("api-status").textContent = "Raggiungibile";
    document.getElementById("api-mode").textContent = data.mutations ? "Modifiche abilitate" : "Sola lettura";
    document.getElementById("uptime").textContent = formatUptime(data.uptimeSeconds);
    document.getElementById("runtime").textContent = data.runtime;
    updatedAt.textContent = `Aggiornato ${new Intl.DateTimeFormat("it-IT", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(data.generatedAt))}`;
    renderCapabilities(data.capabilities);
  } catch {
    setUnavailable("Servizio web locale non raggiungibile");
  } finally {
    refreshButton.disabled = false;
  }
}

refreshButton.addEventListener("click", refreshStatus);
refreshStatus();
