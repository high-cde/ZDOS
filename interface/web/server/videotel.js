const express = require("express");
const fs = require("fs");
const path = require("path");

const COLS = 40;
const ROWS = 24;
const pagesFile = process.env.ZDOS_VIDEOTEL_PAGES || path.resolve(__dirname, "../../../services/videotel/pages.json");
const startedAt = new Date().toISOString();

function loadPages(file = pagesFile) {
  const data = JSON.parse(fs.readFileSync(file, "utf8"));
  const pages = data.pages || {};
  for (const [code, page] of Object.entries(pages)) {
    if (!/^\d{1,3}$/.test(code)) throw new Error(`codice pagina non valido: ${code}`);
    if (!Array.isArray(page.lines) || page.lines.length > ROWS - 2) throw new Error(`pagina ${code}: troppe righe`);
    for (const line of page.lines) if (typeof line !== "string" || [...line].length > COLS) throw new Error(`pagina ${code}: riga oltre ${COLS} colonne`);
  }
  if (!pages["0"]) throw new Error("pagina indice 0 mancante");
  return { service: data.service || "ZDOS-SIP VIDEOTEL", pages };
}

function statusPage() {
  const up = Math.round(process.uptime());
  return {
    title: "STATO DEL SERVIZIO",
    lines: ["", "   9  STATO DEL SERVIZIO", "   ---------------------", "", "   Servizio ..... IN LINEA", "   Modalita' .... SOLA LETTURA", `   Avvio ........ ${startedAt.slice(0, 19).replace("T", " ")}Z`, `   Uptime ....... ${up} s`, "", "   Dati di processo, non stato", "   dell'host ne' attestazioni.", "", "   0 = indice"],
    links: ["0"],
  };
}

function createRouter(file = pagesFile) {
  const { service, pages } = loadPages(file);
  const router = express.Router();
  router.get("/status", (_req, res) => res.json({ schema: "zdos.videotel.status.v1", status: "ONLINE", service, mode: "READ_ONLY", columns: COLS, rows: ROWS, pages: Object.keys(pages).length + 1, started_at: startedAt, policy: "DEFAULT-DENY" }));
  router.get("/page/:code", (req, res) => {
    const code = req.params.code;
    if (!/^\d{1,3}$/.test(code)) return res.status(400).json({ error: "invalid_code" });
    const page = code === "9" ? statusPage() : pages[code];
    if (!page) return res.status(404).json({ error: "page_not_found", code });
    res.json({ schema: "zdos.videotel.page.v1", code, columns: COLS, rows: ROWS, ...page });
  });
  return router;
}

module.exports = { createRouter, loadPages, COLS, ROWS };
