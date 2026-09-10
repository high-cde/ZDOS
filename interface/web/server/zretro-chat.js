const fs = require("fs");
const path = require("path");

const CHAT_CHANNEL = "zretro.chat";
const MAX_MESSAGES = 500;

function busDirectory() {
  return path.resolve(process.env.ZDOS_ZRETRO_BUS_DIR || path.join(__dirname, "../../../zretro/build/bus"));
}

function readMessages() {
  const file = path.join(busDirectory(), "messages.jsonl");
  if (!fs.existsSync(file)) return [];
  return fs.readFileSync(file, "utf8")
    .split("\n")
    .filter(Boolean)
    .slice(-MAX_MESSAGES)
    .flatMap((line) => {
      try { return [JSON.parse(line)]; } catch { return []; }
    })
    .filter((message) => message.schema === "zdos-zretro-bus/v1" && message.channel === CHAT_CHANNEL);
}

function snapshot() {
  const messages = readMessages();
  const nodes = new Set();
  messages.forEach((message) => {
    nodes.add(message.sender);
    nodes.add(message.recipient);
  });
  return {
    schema: "zdos-zretro-chat-dashboard/v1",
    status: "LOCAL_READ_ONLY",
    channel: CHAT_CHANNEL,
    bus_directory: busDirectory(),
    generated_at: new Date().toISOString(),
    node_count: nodes.size,
    message_count: messages.length,
    nodes: [...nodes].sort(),
    messages,
    disclaimer: "Feed locale osservativo; nessuna mutazione, rete o capability remota viene abilitata.",
  };
}

module.exports = { CHAT_CHANNEL, busDirectory, readMessages, snapshot };
