def compress_graph(graph):
    num_nodes = len(graph.nodes)
    num_edges = sum(len(v) for v in graph.edges.values())

    fingerprint = {
        "num_nodes": num_nodes,
        "num_edges": num_edges,
        "density": num_edges / max(1, num_nodes),
        "signature": f"fly-{num_nodes}-{num_edges}"
    }

    return {
        "fingerprint": fingerprint,
        "graph_ref": graph
    }
