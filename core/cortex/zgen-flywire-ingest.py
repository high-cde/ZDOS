from pathlib import Path
import pandas as pd
from z_cortex.modules.flyrouter import (
    build_graph,
    compress_graph,
    FlyRouter,
)

def load_flywire_dataset(neurons_file: Path, synapses_file: Path):
    neurons = pd.read_csv(neurons_file, sep="\t")
    synapses = pd.read_csv(synapses_file, sep="\t")

    neurons = neurons.rename(columns={
        "pt_root_id": "id",
        "cell_type": "type",
        "x": "x",
        "y": "y",
        "z": "z",
        "neuropil": "region",
    })

    synapses = synapses.rename(columns={
        "pre_pt_root_id": "pre_id",
        "post_pt_root_id": "post_id",
        "syn_count": "weight",
    })

    neurons = neurons[["id", "type", "x", "y", "z", "region"]]
    synapses = synapses[["pre_id", "post_id", "weight"]]

    return neurons.to_dict("records"), synapses.to_dict("records")

def main():
    neurons_file = Path("flywire_neurons.tsv")
    synapses_file = Path("flywire_synapses.tsv")

    if not neurons_file.exists() or not synapses_file.exists():
        print("[ERR] flywire_neurons.tsv / flywire_synapses.tsv mancanti.")
        return

    neurons, synapses = load_flywire_dataset(neurons_file, synapses_file)
    print("[INGEST] Loaded:", len(neurons), "neurons,", len(synapses), "synapses")

    graph = build_graph(neurons, synapses)
    compressed = compress_graph(graph)
    print("[INGEST] Fingerprint:", compressed["fingerprint"])

    router = FlyRouter(graph)
    print("[INGEST] Ready for routing.")

if __name__ == "__main__":
    main()
