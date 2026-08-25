from typing import Any, Dict


class QuantumRouter:
    """
    Quantum Router:
    - routing probabilistico
    - scelta modulare basata su priorità
    """

    def route(self, cortex, signal: Dict[str, Any]) -> Dict[str, Any]:
        domain = signal.get("domain")

        # Priorità: Cyber → AAAK → DSN → fallback
        if domain == "cybersecurity" and hasattr(cortex, "route_cyber"):
            return cortex.route_cyber(signal)

        if domain == "aaak" and hasattr(cortex, "route_aaak"):
            return cortex.route_aaak(signal)

        if domain == "dsn" and hasattr(cortex, "route_dsn"):
            return cortex.route_dsn(signal)

        return {
            "status": "unhandled",
            "domain": domain,
            "message": "QuantumRouter: nessun modulo ha gestito il segnale."
        }
