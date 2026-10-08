const test = require("node:test");
const assert = require("node:assert");
const express = require("express");
const { createRouter, loadPages, COLS } = require("./videotel");

test("le pagine rispettano il formato 40 colonne e hanno un indice", () => {
  const { pages } = loadPages();
  assert.ok(pages["0"]);
  for (const page of Object.values(pages)) for (const line of page.lines) assert.ok([...line].length <= COLS);
});

test("API videotel: indice, pagina dinamica, errori", async () => {
  const app = express();
  app.use("/api/videotel", createRouter());
  const server = await new Promise((resolve) => { const s = app.listen(0, "127.0.0.1", () => resolve(s)); });
  const base = `http://127.0.0.1:${server.address().port}/api/videotel`;
  try {
    assert.strictEqual((await (await fetch(`${base}/status`)).json()).mode, "READ_ONLY");
    assert.strictEqual((await fetch(`${base}/page/0`)).status, 200);
    assert.strictEqual((await (await fetch(`${base}/page/9`)).json()).title, "STATO DEL SERVIZIO");
    assert.strictEqual((await fetch(`${base}/page/777`)).status, 404);
    assert.strictEqual((await fetch(`${base}/page/..%2Fx`)).status, 400);
  } finally { server.closeAllConnections(); server.close(); }
});
