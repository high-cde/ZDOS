from .router_registry import get as get_module
from .modules.flyrouter.aak_quantum import quantum_compress_graph
from .modules.flyrouter import build_graph

def build_graph_from_dataset(dataset_loader):
    neurons, synapses = dataset_loader()
    return build_graph(neurons, synapses)

def route_with_flyrouter(pre_id, post_id, dataset_loader):
    flyrouter_cls = get_module("flyrouter")
    if flyrouter_cls is None:
        raise RuntimeError("flyrouter not registered")
    graph = build_graph_from_dataset(dataset_loader)
    router = flyrouter_cls(graph)
    return router.shortest_path(pre_id, post_id)

def quantum_fingerprint_flyrouter(dataset_loader):
    graph = build_graph_from_dataset(dataset_loader)
    return quantum_compress_graph(graph)
