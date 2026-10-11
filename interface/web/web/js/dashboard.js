const capabilityContainer = document.getElementById("capabilities");
const summary = document.getElementById("service-summary");
const updatedAt = document.getElementById("updated-at");
const refreshButton = document.getElementById("refresh-button");
const liveDot = document.querySelector(".live-dot");
const dsnConnectButton = document.getElementById("dsn-connect-button");
const dsnStatus = document.getElementById("dsn-status");
const dsnContract = "0xfc90516a1f736FaC557e09D8853dB80dA192c296";
const polygonChainId = "0x89";
let connectedAccount = "";
let dsnRefreshId = 0;

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

function decodeAbiString(value) {
  if (!/^0x[0-9a-f]+$/i.test(value)) throw new Error("metadata");
  const data = value.slice(2);
  if (data.length === 64) {
    return new TextDecoder().decode(Uint8Array.from(
      data.match(/.{2}/g).map((byte) => Number.parseInt(byte, 16)),
    )).replace(/\0+$/, "");
  }
  const offset = Number.parseInt(data.slice(0, 64), 16) * 2;
  const length = Number.parseInt(data.slice(offset, offset + 64), 16);
  if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset + 64 + length * 2 > data.length) {
    throw new Error("metadata");
  }
  const encoded = data.slice(offset + 64, offset + 64 + length * 2);
  return new TextDecoder().decode(Uint8Array.from(
    encoded.match(/.{2}/g) || [],
    (byte) => Number.parseInt(byte, 16),
  ));
}

function formatTokenBalance(rawBalance, decimals) {
  const divisor = 10n ** BigInt(decimals);
  const whole = rawBalance / divisor;
  const fractionalDigits = (rawBalance % divisor).toString().padStart(decimals, "0").replace(/0+$/, "");
  const firstSignificantDigit = fractionalDigits.search(/[1-9]/);
  const significantDigitsEnd = firstSignificantDigit + 6;
  const fraction = firstSignificantDigit === -1
    ? ""
    : `${fractionalDigits.slice(0, significantDigitsEnd)}${fractionalDigits.length > significantDigitsEnd ? "…" : ""}`;
  const formattedWhole = new Intl.NumberFormat("it-IT", { maximumFractionDigits: 0 }).format(whole);
  return fraction ? `${formattedWhole},${fraction}` : formattedWhole;
}

function setDsnUnavailable(message) {
  document.getElementById("dsn-account").textContent = "—";
  document.getElementById("dsn-balance").textContent = "—";
  dsnStatus.textContent = message;
}

async function readDsnBalance(account) {
  const refreshId = ++dsnRefreshId;
  dsnConnectButton.disabled = true;
  dsnStatus.textContent = "Verifica rete e saldo on-chain…";

  try {
    const provider = window.ethereum;
    const chainId = await provider.request({ method: "eth_chainId" });
    if (refreshId !== dsnRefreshId) return;
    if (chainId.toLowerCase() !== polygonChainId) throw new Error("network");

    const code = await provider.request({
      method: "eth_getCode",
      params: [dsnContract, "latest"],
    });
    if (refreshId !== dsnRefreshId) return;
    if (!/^0x[0-9a-f]+$/i.test(code) || /^0x0*$/i.test(code)) throw new Error("contract");

    const [symbolResult, decimalsResult] = await Promise.all([
      provider.request({
        method: "eth_call",
        params: [{ to: dsnContract, data: "0x95d89b41" }, "latest"],
      }),
      provider.request({
        method: "eth_call",
        params: [{ to: dsnContract, data: "0x313ce567" }, "latest"],
      }),
    ]);
    if (refreshId !== dsnRefreshId) return;
    const symbol = decodeAbiString(symbolResult);
    const decimals = Number(BigInt(decimalsResult));
    if (!symbol || !Number.isInteger(decimals) || decimals < 0 || decimals > 36) {
      throw new Error("contract");
    }

    const address = account.slice(2).toLowerCase().padStart(64, "0");
    const balanceResult = await provider.request({
      method: "eth_call",
      params: [{ to: dsnContract, data: `0x70a08231${address}` }, "latest"],
    });
    if (refreshId !== dsnRefreshId) return;
    if (!/^0x[0-9a-f]+$/i.test(balanceResult)) throw new Error("contract");

    document.getElementById("dsn-symbol").textContent = symbol;
    document.getElementById("dsn-account").textContent = `${account.slice(0, 6)}…${account.slice(-4)}`;
    document.getElementById("dsn-balance").textContent = `${formatTokenBalance(BigInt(balanceResult), decimals)} ${symbol}`;
    document.getElementById("dsn-network").textContent = "Polygon PoS · chain ID 137";
    dsnStatus.textContent = "Saldo letto dalla blockchain. Nessuna transazione è stata inviata.";
  } catch (error) {
    if (refreshId !== dsnRefreshId) return;
    if (error.message === "network") {
      document.getElementById("dsn-network").textContent = "Rete wallet diversa da Polygon PoS";
      setDsnUnavailable("Passa a Polygon PoS nel wallet e aggiorna il saldo.");
    } else if (error.message === "contract" || error.message === "metadata") {
      setDsnUnavailable("Il contratto non ha restituito metadati ERC-20 validi su Polygon.");
    } else {
      setDsnUnavailable("Lettura del saldo non riuscita. Verifica il wallet e riprova.");
    }
  } finally {
    if (refreshId === dsnRefreshId) dsnConnectButton.disabled = false;
  }
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
dsnConnectButton.addEventListener("click", async () => {
  if (!window.ethereum || typeof window.ethereum.request !== "function") {
    dsnStatus.textContent = "Nessun wallet compatibile rilevato in questo browser.";
    return;
  }

  dsnConnectButton.disabled = true;
  dsnStatus.textContent = "Richiesta di connessione al wallet…";
  try {
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    const account = accounts?.[0];
    if (!/^0x[a-f0-9]{40}$/i.test(account || "")) {
      setDsnUnavailable("Il wallet non ha fornito un indirizzo valido.");
      dsnConnectButton.disabled = false;
      return;
    }
    connectedAccount = account;
    await readDsnBalance(account);
  } catch (error) {
    dsnStatus.textContent = error.code === 4001
      ? "Connessione rifiutata nel wallet."
      : "Connessione al wallet non riuscita.";
    dsnConnectButton.disabled = false;
  }
});

if (window.ethereum?.on) {
  window.ethereum.on("accountsChanged", (accounts) => {
    const account = accounts?.[0];
    if (!account) {
      connectedAccount = "";
      dsnRefreshId += 1;
      setDsnUnavailable("Wallet non collegato.");
      dsnConnectButton.disabled = false;
    } else if (account.toLowerCase() !== connectedAccount.toLowerCase()) {
      connectedAccount = account;
      readDsnBalance(account);
    }
  });
  window.ethereum.on("chainChanged", () => {
    if (connectedAccount) readDsnBalance(connectedAccount);
  });
}

refreshStatus();
