#!/bin/bash
set -e
export PYTHONPATH="$PYTHONPATH:$(pwd)"

python - << 'PY'
from pathlib import Path
from zgen_flywire_ingest_lite import load_flywire_dataset
from z_cortex.modules.flyrouter import (
    build_graph,
    compress_graph,
    FlyRouter,
)
import z_cortex.modules.flyrouter.registry_hook  # side-effect: register

neurons_path = Path("flywire_neurons.tsv")
synapses_path = Path("flywire_synapses.tsv")

neurons, synapses = load_flywire_dataset(neurons_path, synapses_path)
print("[RUN] Loaded:", len(neurons), "neurons,", len(synapses), "synapses")

graph = build_graph(neurons, synapses)
compressed = compress_graph(graph)
print("[RUN] Fingerprint:", compressed["fingerprint"])

router = FlyRouter(graph)
print("[RUN] Example route:", router.shortest_path(neurons[0]["id"], neurons[-1]["id"]))
PY
