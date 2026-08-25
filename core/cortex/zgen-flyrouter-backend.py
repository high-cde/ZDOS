from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import json
from pathlib import Path

from zgen_flywire_ingest_lite import load_flywire_dataset
from z_cortex.modules.flyrouter import build_graph, FlyRouter
from z_cortex.modules.flyrouter.aak_quantum import quantum_compress_graph

HOST = "0.0.0.0"
PORT = 8088

def _load_graph():
    neurons_path = Path("flywire_neurons.tsv")
    synapses_path = Path("flywire_synapses.tsv")
    neurons, synapses = load_flywire_dataset(neurons_path, synapses_path)
    graph = build_graph(neurons, synapses)
    return graph, neurons

class Handler(BaseHTTPRequestHandler):
    def _json(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode("utf-8"))

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            return self._json(200, {"status": "ok", "service": "flyrouter"})
        if parsed.path == "/fingerprint":
            graph, _ = _load_graph()
            fp = quantum_compress_graph(graph)
            return self._json(200, fp)
        if parsed.path == "/route":
            qs = parse_qs(parsed.query)
            pre = qs.get("pre", [None])[0]
            post = qs.get("post", [None])[0]
            if not pre or not post:
                return self._json(400, {"error": "missing pre/post"})
            graph, _ = _load_graph()
            router = FlyRouter(graph)
            path = router.shortest_path(pre, post)
            return self._json(200, {"path": path})
        return self._json(404, {"error": "not found"})

def main():
    server = HTTPServer((HOST, PORT), Handler)
    print(f"[DSN-LIVE] FLY-ROUTER backend on http://{HOST}:{PORT}")
    server.serve_forever()

if __name__ == "__main__":
    main()
