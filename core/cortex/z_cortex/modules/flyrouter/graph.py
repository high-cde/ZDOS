from typing import Dict, Any
from collections import defaultdict

class ConnectomeGraph:
    def __init__(self):
        self.nodes = {}
        self.edges = defaultdict(dict)

    def add_neuron(self, neuron):
        self.nodes[neuron["id"]] = neuron

    def add_synapse(self, synapse):
        pre = synapse["pre_id"]
        post = synapse["post_id"]
        w = synapse["weight"]
        self.edges[pre][post] = self.edges[pre].get(post, 0.0) + w

    def neighbors(self, nid):
        return self.edges.get(nid, {})

def build_graph(neurons, synapses):
    g = ConnectomeGraph()
    for n in neurons:
        g.add_neuron(n)
    for s in synapses:
        g.add_synapse(s)
    return g
