from pathlib import Path
from z_cortex.modules.flyrouter import (
    load_connectome,
    build_graph,
    compress_graph,
    FlyRouter
)

# Dummy dataset
neurons_path = Path("test_neurons.tsv")
synapses_path = Path("test_synapses.tsv")

# Create dummy files
neurons_path.write_text(
    "id\tx\ty\tz\tregion\n"
    "A\t0\t0\t0\tR1\n"
    "B\t1\t1\t1\tR2\n"
)

synapses_path.write_text(
    "pre_id\tpost_id\tweight\n"
    "A\tB\t3\n"
)

# Load
neurons, synapses = load_connectome(neurons_path, synapses_path)
print("[OK] Loaded:", neurons, synapses)

# Graph
graph = build_graph(neurons, synapses)
print("[OK] Graph nodes:", graph.nodes)
print("[OK] Graph edges:", graph.edges)

# Compress
compressed = compress_graph(graph)
print("[OK] Fingerprint:", compressed["fingerprint"])

# Router
router = FlyRouter(graph)
path = router.shortest_path("A", "B")
print("[OK] Path:", path)
