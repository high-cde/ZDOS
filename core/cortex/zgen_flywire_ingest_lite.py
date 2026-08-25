from pathlib import Path
import csv
from z_cortex.modules.flyrouter import (
    build_graph,
    compress_graph,
    FlyRouter,
)

def read_tsv(path: Path):
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        return list(reader)

def load_flywire_dataset(neurons_file: Path, synapses_file: Path):
    neurons_raw = read_tsv(neurons_file)
    synapses_raw = read_tsv(synapses_file)

    neurons = []
    for n in neurons_raw:
        neurons.append({
            "id": n.get("pt_root_id"),
            "type": n.get("cell_type"),
            "x": float(n.get("x", 0.0)),
            "y": float(n.get("y", 0.0)),
            "z": float(n.get("z", 0.0)),
            "region": n.get("neuropil"),
        })

    synapses = []
    for s in synapses_raw:
        synapses.append({
            "pre_id": s.get("pre_pt_root_id"),
            "post_id": s.get("post_pt_root_id"),
            "weight": float(s.get("syn_count", 1.0)),
        })

    return neurons, synapses

def main():
    neurons_file = Path("flywire_neurons.tsv")
    synapses_file = Path("flywire_synapses.tsv")

    if not neurons_file.exists() or not synapses_file.exists():
        print("[ERR] flywire_neurons.tsv / flywire_synapses.tsv mancanti.")
        return

    neurons, synapses = load_flywire_dataset(neurons_file, synapses_file)
    print("[INGEST-LITE] Loaded:", len(neurons), "neurons,", len(synapses), "synapses")

    graph = build_graph(neurons, synapses)
    compressed = compress_graph(graph)
    print("[INGEST-LITE] Fingerprint:", compressed["fingerprint"])

    router = FlyRouter(graph)
    print("[INGEST-LITE] Router ready.")

if __name__ == "__main__":
    main()
