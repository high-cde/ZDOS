from pathlib import Path
import csv
from typing import Dict, Any, List, Tuple

def _read_tsv(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        return list(reader)

def load_connectome(neurons_path: Path, synapses_path: Path):
    neurons_raw = _read_tsv(neurons_path)
    synapses_raw = _read_tsv(synapses_path)

    neurons = []
    for n in neurons_raw:
        neurons.append({
            "id": n.get("id") or n.get("neuron_id"),
            "type": n.get("type") or n.get("cell_type"),
            "x": float(n.get("x", 0.0)),
            "y": float(n.get("y", 0.0)),
            "z": float(n.get("z", 0.0)),
            "region": n.get("region") or n.get("neuropil"),
            "props": {k: v for k, v in n.items() if k not in {"id","neuron_id","type","cell_type","x","y","z","region","neuropil"}},
        })

    synapses = []
    for s in synapses_raw:
        synapses.append({
            "pre_id": s.get("pre_id") or s.get("pre_neuron_id"),
            "post_id": s.get("post_id") or s.get("post_neuron_id"),
            "weight": float(s.get("weight", 1.0)),
            "x": float(s.get("x", 0.0)),
            "y": float(s.get("y", 0.0)),
            "z": float(s.get("z", 0.0)),
            "confidence": float(s.get("confidence", 1.0)),
        })

    neuron_ids = {n["id"] for n in neurons}
    synapses = [s for s in synapses if s["pre_id"] in neuron_ids and s["post_id"] in neuron_ids]

    return neurons, synapses
