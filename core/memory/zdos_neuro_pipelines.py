from typing import Any, Dict, List, Callable


class NeuroPipeline:
    """
    Pipeline cognitiva multi‑stadio.
    Ogni stadio è una funzione che trasforma il segnale.
    """

    def __init__(self):
        self.stages: List[Callable[[Dict[str, Any]], Dict[str, Any]]] = []

    def add_stage(self, fn: Callable[[Dict[str, Any]], Dict[str, Any]]):
        self.stages.append(fn)

    def run(self, signal: Dict[str, Any]) -> Dict[str, Any]:
        out = signal
        for stage in self.stages:
            out = stage(out)
        return out


class NeuroPipelines:
    """
    Gestore globale delle pipeline cognitive.
    """

    def __init__(self):
        self.pipelines: Dict[str, NeuroPipeline] = {}

    def create(self, name: str):
        self.pipelines[name] = NeuroPipeline()

    def add_stage(self, name: str, fn: Callable[[Dict[str, Any]], Dict[str, Any]]):
        self.pipelines[name].add_stage(fn)

    def run(self, name: str, signal: Dict[str, Any]) -> Dict[str, Any]:
        return self.pipelines[name].run(signal)
