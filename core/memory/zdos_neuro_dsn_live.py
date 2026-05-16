from typing import Any, Dict


class DSNLive:
    """
    DSN‑LIVE — Dynamic Signal Network
    - feed in tempo reale
    - pannello segnali
    """

    def ingest(self, signal: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "mode": "dsn_live",
            "received": signal,
            "status": "ok",
        }
