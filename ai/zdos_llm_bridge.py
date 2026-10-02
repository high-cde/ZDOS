#!/usr/bin/env python3
"""ZDOS LLM bridge: bounded text reasoning, default offline, no tool execution."""
from __future__ import annotations
import json, os, sys, urllib.request
from datetime import datetime, timezone

POLICY = {
    "mode": "BOUNDED_REASONING",
    "default": "OFFLINE",
    "allowed": ["text.analysis", "text.plan", "text.explain"],
    "denied": ["shell.exec", "network.scan", "credential.read", "wallet.sign", "radio.tx", "file.write"],
    "audit": "evidence.chain.candidate",
}

def envelope(status: str, answer: str = "", model: str = "offline") -> dict:
    return {"schema": "zdos.llm.response.v1", "status": status, "answer": answer, "model": model, "policy": POLICY, "observed_at": datetime.now(timezone.utc).isoformat()}

def complete(prompt: str) -> dict:
    base = os.environ.get("ZDOS_LLM_BASE_URL") or os.environ.get("OPENAI_API_BASE")
    key = os.environ.get("ZDOS_LLM_API_KEY") or os.environ.get("OPENAI_API_KEY")
    model = os.environ.get("ZDOS_LLM_MODEL", "gpt-5-mini")
    if not base or not key:
        return envelope("OFFLINE_READY", "LLM non configurato: usa una policy locale o imposta ZDOS_LLM_BASE_URL e ZDOS_LLM_API_KEY.")
    url = base.rstrip("/") + "/chat/completions"
    body = {"model": model, "messages": [{"role": "system", "content": "You are ZDOS Intelligence, a bounded assistant. Never execute tools, access secrets, change files, scan networks, sign transactions, or claim actions you did not perform. Return concise, auditable reasoning."}, {"role": "user", "content": prompt}], "temperature": 0.2}
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=45) as response:
            data = json.load(response)
        answer = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        return envelope("ONLINE", answer, model)
    except Exception as exc:
        return envelope("DEGRADED", f"LLM non raggiungibile: {type(exc).__name__}. Nessuna azione è stata eseguita.", model)

def main() -> int:
    prompt = " ".join(sys.argv[1:]).strip() or sys.stdin.read().strip()
    if not prompt:
        print(json.dumps(envelope("READY"), indent=2)); return 0
    print(json.dumps(complete(prompt), ensure_ascii=False, indent=2)); return 0

if __name__ == "__main__":
    raise SystemExit(main())
