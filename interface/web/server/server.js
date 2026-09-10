const express = require("express");
const path = require("path");
const { snapshot } = require("./zretro-chat");

const app = express();
const port = Number.parseInt(process.env.PORT || "8080", 10);
const host = process.env.HOST || "127.0.0.1";

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT deve essere un intero compreso tra 1 e 65535");
}

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.set({
    "Cache-Control": "no-store",
    "Content-Security-Policy": "default-src 'self'; base-uri 'none'; frame-ancestors 'none'",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  });
  next();
});
app.use(express.json({ limit: "16kb" }));
app.use(express.static(path.join(__dirname, "..", "web"), { index: "index.html" }));

app.get("/status", (_req, res) => {
  res.json({
    status: "LOCAL_READ_ONLY",
    service: "zdos-interface-web",
    mutations: false,
    disclaimer: "Nessun feed remoto o nodo esterno è collegato.",
  });
});

app.get("/zretro/chat", (_req, res) => {
  res.json(snapshot());
});

app.get("/zretro/chat/stream", (req, res) => {
  res.writeHead(200, {
    "Cache-Control": "no-store",
    "Content-Type": "text/event-stream",
    Connection: "keep-alive",
    "X-Accel-Buffering": "no",
  });
  let closed = false;
  const publish = () => {
    if (!closed) res.write(`event: snapshot\ndata: ${JSON.stringify(snapshot())}\n\n`);
  };
  publish();
  const timer = setInterval(publish, 1000);
  req.on("close", () => {
    closed = true;
    clearInterval(timer);
  });
});

app.use((_req, res) => {
  res.status(404).json({ error: "not_found" });
});

app.listen(port, host, () => {
  console.log(`ZDOS interface web read-only service listening on http://${host}:${port}`);
});
