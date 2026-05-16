from typing import Any, Dict
from dataclasses import dataclass


@dataclass
class NeuroSignal:
    domain: str
    payload: Dict[str, Any]
    context: Dict[str, Any]
