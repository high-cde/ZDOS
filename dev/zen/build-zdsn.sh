#!/bin/bash

echo "Building zDSN Distributed Runtime"

mkdir -p src/distributed
mkdir -p docs/distributed

cat > src/distributed/zdsn.zc << 'EOF'
class Node:
    def __init__(self, id):
        self.id = id

    def receive(self, msg):
        print("[Node", self.id, "]", msg)

class Mesh:
    def __init__(self):
        self.nodes = []

    def add(self, node):
        self.nodes.append(node)

    def broadcast(self, msg):
        for n in self.nodes:
            n.receive(msg)
EOF

echo "zDSN Build Complete"
