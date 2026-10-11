const express = require("express");
const chain = require("./chain");
const router = express.Router();

let capabilities = [];

router.get("/ping", (req, res) => {
  res.json({ pong: true });
});

router.get("/chain", (_req, res) => {
  res.json(chain.snapshot(capabilities));
});

router.setCapabilities = (list) => {
  capabilities = list;
};

module.exports = router;
