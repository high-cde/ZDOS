import json

class NodeAgent:
    def __init__(self, config):
        self.config = json.load(open(config))

    def heartbeat(self):
        return {"node": self.config["name"], "status": "online"}
