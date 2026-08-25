const express = require("express");
const app = express();
app.use(express.json());
app.use(express.static("web"));

app.get("/status", (req, res) => {
  res.json({ status: "DSN‑LIVE online" });
});

app.listen(8080, () => console.log("DSN‑LIVE running on 8080"));
