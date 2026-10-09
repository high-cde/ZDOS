const express = require("express");
const path = require("path");

const app = express();
const port = Number.parseInt(process.env.PORT || "8080", 10);
const host = process.env.HOST || "127.0.0.1";
const api = require("./api");

const capabilities = [
  {
    name: "ZDOS Linux",
    level: "M2",
    label: "Verificato",
    status: "verified",
    description: "Build riproducibile e boot Linux live verificato in QEMU; non è una distro general-purpose.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/blob/main/docs/MATURITY.md",
  },
  {
    name: "ZDOS bare metal",
    level: "M2",
    label: "Verificato",
    status: "verified",
    description: "Build, runtime ZLB2 e boot QEMU verificati secondo il profilo documentato.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/blob/main/docs/MATURITY.md",
  },
  {
    name: "Persistenza ext4",
    level: "M2",
    label: "Verificato",
    status: "verified",
    description: "Volume persistente verificato in QEMU; questo servizio non ispeziona i dischi locali.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/blob/main/docs/OPERATIONS.md",
  },
  {
    name: "Evidence Chain locale",
    level: "M2",
    label: "Disponibile",
    status: "verified",
    description: "Ledger locale append-only con hash concatenati e verifiche dichiarate dal progetto.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/tree/main/evidence",
  },
  {
    name: "Installer e package manager",
    level: "Roadmap",
    label: "Non disponibile",
    status: "roadmap",
    description: "Installazione su hardware e gestione dei pacchetti non sono ancora implementate.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/blob/main/README.md",
  },
  {
    name: "Rete multi-nodo",
    level: "M0",
    label: "Non disponibile",
    status: "roadmap",
    description: "Consenso, discovery, replica e governance sono ancora da definire.",
    evidenceUrl: "https://github.com/high-cde/ZDOS/blob/main/docs/MATURITY.md",
  },
];

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT deve essere un intero compreso tra 1 e 65535");
}

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.set({
    "Cache-Control": "no-store",
    "Content-Security-Policy": "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  });
  next();
});
app.use(express.json({ limit: "16kb" }));
app.use(express.static(path.join(__dirname, "..", "web"), { index: "index.html" }));
app.use("/api", api);

app.get("/status", (_req, res) => {
  res.json({
    status: "LOCAL_READ_ONLY",
    service: "zdos-interface-web",
    mutations: false,
    scope: "local_web_process",
    generatedAt: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    runtime: `Node.js ${process.versions.node}`,
    capabilities,
    disclaimer: "Nessun feed remoto o nodo esterno è collegato.",
  });
});

app.use((_req, res) => {
  res.status(404).json({ error: "not_found" });
});

app.listen(port, host, () => {
  console.log(`ZDOS interface web read-only service listening on http://${host}:${port}`);
});
