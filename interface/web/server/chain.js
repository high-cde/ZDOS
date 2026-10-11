const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const SOURCE = path.join(__dirname, "..", "..", "..", "blockchain", "zdoschain.zlang");
const GENESIS_PREV = "0".repeat(64);

function hashBlock(block) {
  const body = {
    height: block.height,
    previousHash: block.previousHash,
    type: block.type,
    payload: block.payload,
  };
  return crypto.createHash("sha256").update(JSON.stringify(body)).digest("hex");
}

function buildChain(entries) {
  const blocks = [];
  let previousHash = GENESIS_PREV;
  const items = [{ type: "genesis", payload: "ZDOSChain genesis" }, ...entries];
  items.forEach((item, height) => {
    const block = { height, previousHash, type: item.type, payload: item.payload };
    block.hash = hashBlock(block);
    blocks.push(block);
    previousHash = block.hash;
  });
  return blocks;
}

function verifyChain(blocks) {
  let previousHash = GENESIS_PREV;
  for (const [i, block] of blocks.entries()) {
    if (block.height !== i || block.previousHash !== previousHash || block.hash !== hashBlock(block)) {
      return false;
    }
    previousHash = block.hash;
  }
  return true;
}

function sourceInfo() {
  try {
    const source = fs.readFileSync(SOURCE);
    return {
      path: "blockchain/zdoschain.zlang",
      language: "zlang",
      sha256: crypto.createHash("sha256").update(source).digest("hex"),
      bytes: source.length,
    };
  } catch {
    return null;
  }
}

function snapshot(capabilities) {
  const blocks = buildChain(
    capabilities.map((c) => ({ type: "capability", payload: `${c.name}|${c.level}|${c.status}` })),
  );
  return {
    name: "ZDOSChain",
    scope: "local_deterministic",
    consensus: "none",
    network: "none",
    mutations: false,
    valid: verifyChain(blocks),
    height: blocks.length - 1,
    tip: blocks[blocks.length - 1].hash,
    source: sourceInfo(),
    blocks,
    disclaimer:
      "Catena locale, deterministica e in sola lettura derivata dalle capacità dichiarate. Non è una rete, non ha consenso, token né attestazione indipendente.",
  };
}

module.exports = { snapshot, buildChain, verifyChain };
