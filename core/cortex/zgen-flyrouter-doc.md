# FLY-ROUTER — Z-CORTEX MODULE

## Overview
Modulo di routing neurale ispirato a FlyWire:
- parsing TSV (FlyWire-like)
- costruzione grafo diretto
- compressione (hook AAAK v2-ready)
- routing (shortest path)

## API
from z_cortex.modules.flyrouter import load_connectome, build_graph, compress_graph, FlyRouter

## Example
neurons, synapses = load_connectome("neurons.tsv", "synapses.tsv")
graph = build_graph(neurons, synapses)
fp = compress_graph(graph)
router = FlyRouter(graph)
path = router.shortest_path("A", "B")
