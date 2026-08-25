import json

def load_node(config_path):
    with open(config_path) as f:
        return json.load(f)

def heartbeat(node):
    return {"node": node["name"], "status": "online"}
