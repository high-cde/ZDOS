const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const modulePath = require.resolve("./zretro-chat");

test("snapshot exposes only valid zretro.chat traffic", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "zdos-chat-"));
  const previous = process.env.ZDOS_ZRETRO_BUS_DIR;
  process.env.ZDOS_ZRETRO_BUS_DIR = root;
  try {
    fs.writeFileSync(path.join(root, "messages.jsonl"), [
      JSON.stringify({ schema: "zdos-zretro-bus/v1", id: "chat-1", sender: "c64-01", recipient: "amiga-01", channel: "zretro.chat", body: "hello", created_at: "1000000000" }),
      JSON.stringify({ schema: "zdos-zretro-bus/v1", id: "other-1", sender: "c64-01", recipient: "amiga-01", channel: "zretro.system", body: "hidden", created_at: "1000000001" }),
    ].join("\n") + "\n");
    delete require.cache[modulePath];
    const { snapshot } = require("./zretro-chat");
    const data = snapshot();
    assert.equal(data.channel, "zretro.chat");
    assert.equal(data.message_count, 1);
    assert.deepEqual(data.nodes, ["amiga-01", "c64-01"]);
    assert.equal(data.messages[0].body, "hello");
  } finally {
    if (previous === undefined) delete process.env.ZDOS_ZRETRO_BUS_DIR;
    else process.env.ZDOS_ZRETRO_BUS_DIR = previous;
  }
});
