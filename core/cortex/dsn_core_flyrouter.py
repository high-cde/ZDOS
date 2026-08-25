from pathlib import Path
from zgen_flywire_ingest_lite import load_flywire_dataset
from z_cortex.cortex_unified import route_with_flyrouter, quantum_fingerprint_flyrouter

def _dataset_loader():
    neurons_path = Path("flywire_neurons.tsv")
    synapses_path = Path("flywire_synapses.tsv")
    return load_flywire_dataset(neurons_path, synapses_path)

def dsn_route(pre_id, post_id):
    return route_with_flyrouter(pre_id, post_id, _dataset_loader)

def dsn_quantum_fingerprint():
    return quantum_fingerprint_flyrouter(_dataset_loader)
