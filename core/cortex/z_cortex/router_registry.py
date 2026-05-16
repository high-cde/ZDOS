REGISTRY = {}

def register(name, module):
    REGISTRY[name] = module

def get(name):
    return REGISTRY.get(name)
