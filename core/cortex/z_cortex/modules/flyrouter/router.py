import heapq

class FlyRouter:
    def __init__(self, graph):
        self.graph = graph

    def shortest_path(self, start, target, max_steps=1000):
        queue = [(0.0, start, [start])]
        visited = set()

        while queue and len(visited) < max_steps:
            cost, node, path = heapq.heappop(queue)
            if node == target:
                return path
            if node in visited:
                continue
            visited.add(node)

            for nbr, weight in self.graph.neighbors(node).items():
                if nbr in visited:
                    continue
                new_cost = cost + 1.0 / max(weight, 1e-6)
                heapq.heappush(queue, (new_cost, nbr, path + [nbr]))

        return None

    def step(self, current):
        neighbors = self.graph.neighbors(current)
        total = sum(neighbors.values()) or 1.0
        return {k: v / total for k, v in neighbors.items()}
