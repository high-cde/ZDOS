from z_cortex.aak_bridge import quantum_fingerprint

def quantum_compress_graph(graph):
    nodes = list(graph.nodes.keys())
    edges = [
        (pre, post, w)
        for pre, posts in graph.edges.items()
        for post, w in posts.items()
    ]
    return quantum_fingerprint(nodes, edges)
