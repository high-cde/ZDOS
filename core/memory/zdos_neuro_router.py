from typing import Any, Dict


class NeuroRouter:
    """
    Router modulare ZDOS‑NEURO.
    Ogni modulo può implementare:
    - route_<domain>(signal)
    """

    def dispatch(self, cortex, signal: Dict[str, Any]) -> Dict[str, Any]:
        domain = signal.get("domain")

        # Cerca un metodo route_<domain>
        method_name = f"route_{domain}"
        if hasattr(cortex, method_name):
            return getattr(cortex, method_name)(signal)

        # Fallback: routing CyberCortex (già patchato)
        if hasattr(cortex, "route_cyber"):
            out = cortex.route_cyber(signal)
            if out is not None:
                return out

        return {
            "status": "unhandled",
            "domain": domain,
            "message": "Nessun modulo ha gestito questo segnale."
        }
