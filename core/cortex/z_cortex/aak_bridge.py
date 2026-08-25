import hashlib

try:
    import aak  # AAAK reale, se presente
except ImportError:
    aak = None

def quantum_fingerprint(nodes, edges):
    if aak is not None and hasattr(aak, "compress_graph_fingerprint"):
        return aak.compress_graph_fingerprint(nodes, edges)
    # Fallback: fingerprint deterministica semplice
    h = hashlib.sha256()
    h.update(("N" + str(len(nodes))).encode())
    h.update(("E" + str(len(edges))).encode())
    for n in sorted(nodes):
        h.update(str(n).encode())
    for (pre, post, w) in edges:
        h.update(f"{pre}>{post}:{w}".encode())
    return {
        "num_nodes": len(nodes),
        "num_edges": len(edges),
        "density": (len(edges) / max(1, len(nodes))) if nodes else 0.0,
        "signature": h.hexdigest()[:16],
    }
