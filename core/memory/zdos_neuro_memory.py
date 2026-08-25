from typing import Any, Dict, List


class NeuroMemory:
    """
    Memoria episodica semplice: conserva tracce dei segnali.
    """

    def __init__(self) -> None:
        self.buffer: List[Dict[str, Any]] = []

    def store(self, signal: Dict[str, Any]) -> None:
        self.buffer.append(signal)

    def last(self, n: int = 5) -> List[Dict[str, Any]]:
        return self.buffer[-n:]
