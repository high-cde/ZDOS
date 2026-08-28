const express = require("express");
const app = express();
app.use(express.json());
app.use(express.static("web"));

app.get("/status", (req, res) => {
  res.json({ status: "LOCAL_READ_ONLY", service: "zdos-interface-web", mutations: false, disclaimer: "Nessun feed remoto o nodo esterno è collegato." });
});

app.listen(process.env.PORT || 8080, () => console.log("ZDOS interface web read-only service started"));
