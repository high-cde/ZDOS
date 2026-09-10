const els = {
  connection: document.getElementById("connection"),
  liveDot: document.getElementById("live-dot"),
  nodeCount: document.getElementById("node-count"),
  messageCount: document.getElementById("message-count"),
  rate: document.getElementById("rate"),
  lastEvent: document.getElementById("last-event"),
  updated: document.getElementById("updated"),
  nodes: document.getElementById("nodes"),
  feed: document.getElementById("feed"),
  bus: document.getElementById("bus"),
};

function time(value) {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? "—" : date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

function render(data) {
  const messages = data.messages || [];
  const minuteAgo = Date.now() - 60_000;
  const rate = messages.filter((message) => Number(message.created_at) / 1e6 > minuteAgo).length;
  els.nodeCount.textContent = data.node_count;
  els.messageCount.textContent = data.message_count;
  els.rate.textContent = rate;
  els.lastEvent.textContent = messages.length ? time(Number(messages[messages.length - 1].created_at) / 1e6) : "—";
  els.updated.textContent = `updated ${time(data.generated_at)}`;
  els.bus.textContent = `BUS: ${data.bus_directory}`;
  els.nodes.replaceChildren();
  (data.nodes || []).forEach((node) => {
    const card = document.createElement("div");
    card.className = "node";
    const name = document.createElement("strong");
    name.textContent = node;
    const state = document.createElement("span");
    state.textContent = "OBSERVED / LOCAL";
    card.append(name, state);
    els.nodes.append(card);
  });
  if (!data.nodes?.length) {
    const empty = document.createElement("p");
    empty.className = "muted";
    empty.textContent = "Nessun nodo attivo nel feed locale.";
    els.nodes.append(empty);
  }
  els.feed.replaceChildren();
  messages.slice().reverse().forEach((message) => {
    const row = document.createElement("div");
    row.className = "message";
    const meta = document.createElement("div");
    meta.className = "message-meta";
    meta.textContent = `${time(Number(message.created_at) / 1e6)} · ${message.sender} → ${message.recipient}`;
    const body = document.createElement("div");
    body.className = "message-body";
    body.textContent = message.body;
    row.append(meta, body);
    els.feed.append(row);
  });
  if (!messages.length) {
    const empty = document.createElement("p");
    empty.className = "muted";
    empty.textContent = "Nessun messaggio zretro.chat ricevuto.";
    els.feed.append(empty);
  }
}

function connected(value) {
  els.connection.textContent = value ? "LIVE" : "RECONNECTING";
  els.liveDot.classList.toggle("offline", !value);
}

fetch("/zretro/chat").then((response) => response.json()).then(render).catch(() => connected(false));
const stream = new EventSource("/zretro/chat/stream");
stream.addEventListener("open", () => connected(true));
stream.addEventListener("snapshot", (event) => { connected(true); render(JSON.parse(event.data)); });
stream.addEventListener("error", () => connected(false));
