from typing import Any, Dict, List, Callable


class ParticipationEngine:
    """
    Motore di partecipazione ai segnali.
    Ogni modulo può registrare un hook che osserva o modifica i segnali.
    """

    def __init__(self):
        self.hooks: List[Callable[[Dict[str, Any]], Dict[str, Any]]] = []

    def register(self, fn: Callable[[Dict[str, Any]], Dict[str, Any]]):
        self.hooks.append(fn)

    def process(self, signal: Dict[str, Any]) -> Dict[str, Any]:
        out = signal
        for hook in self.hooks:
            out = hook(out)
        return out
