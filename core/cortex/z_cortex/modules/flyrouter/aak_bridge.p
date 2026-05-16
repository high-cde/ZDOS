from aak import compress_graph_fingerprint

def aak_compress(graph):
    nodes = list(graph.nodes.keys())
    edges = [
        (pre, post, w)
        for pre, posts in graph.edges.items()
        for post, w in posts.items()
    ]
    return compress_graph_fingerprint(nodes, edges)
