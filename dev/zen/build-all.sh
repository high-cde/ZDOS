#!/bin/bash

echo "Building FULL ZEN ECOSYSTEM"

# ---------------------------------------------------------
# DIRECTORY STRUCTURE
# ---------------------------------------------------------

mkdir -p src/std
mkdir -p src/compiler
mkdir -p src/runtime
mkdir -p src/distributed
mkdir -p src/zcore
mkdir -p src/debugger

mkdir -p docs
mkdir -p docs/zcore
mkdir -p docs/debugger

mkdir -p examples
mkdir -p examples/zcore
mkdir -p examples/debugger

mkdir -p tests
mkdir -p tests/zcore
mkdir -p tests/debugger

mkdir -p site/assets

# ---------------------------------------------------------
# README
# ---------------------------------------------------------

cat > README.md << 'EOFZEN'
ZEN - Linguaggio Nativo dell'Ecosistema ZDOS

Esempio:

node.start
mesh.sync
shield.raise if threat.detect
worker.spawn type:guardian
EOFZEN

# ---------------------------------------------------------
# TOKENIZER
# ---------------------------------------------------------

cat > src/tokenizer.zc << 'EOFZEN'
KEYWORDS = ["node","mesh","shield","worker","start","sync","raise","spawn","if","type"]

class Token:
    def __init__(self, type, value):
        self.type = type
        self.value = value

def classify(word):
    if word in KEYWORDS:
        return Token("KEYWORD", word)
    if word.isalpha():
        return Token("IDENTIFIER", word)
    return Token("UNKNOWN", word)

def tokenize(source):
    tokens = []
    current = ""
    for char in source:
        if char.isspace():
            if current:
                tokens.append(classify(current))
                current = ""
        elif char in [".", ":"]:
            if current:
                tokens.append(classify(current))
                current = ""
            tokens.append(Token("SYMBOL", char))
        else:
            current += char
    if current:
        tokens.append(classify(current))
    return tokens
EOFZEN

# ---------------------------------------------------------
# PARSER
# ---------------------------------------------------------

cat > src/parser.zc << 'EOFZEN'
class Node:
    def __init__(self, type, args=None):
        self.type = type
        self.args = args or {}

def parse(tokens):
    ast = []
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t.value == "node":
            ast.append(Node("NODE_START"))
        if t.value == "mesh":
            ast.append(Node("MESH_SYNC"))
        if t.value == "shield":
            ast.append(Node("SHIELD_RAISE"))
        if t.value == "worker":
            ast.append(Node("WORKER_SPAWN"))
        i += 1
    return ast
EOFZEN

# ---------------------------------------------------------
# AST
# ---------------------------------------------------------

cat > src/ast.zc << 'EOFZEN'
class ASTNode:
    def __init__(self, type, args=None):
        self.type = type
        self.args = args or {}
EOFZEN

# ---------------------------------------------------------
# RUNTIME
# ---------------------------------------------------------

cat > src/runtime/runtime.zc << 'EOFZEN'
class Runtime:
    def __init__(self):
        self.state = {
            "node": "stopped",
            "mesh": "idle",
            "shield": "down",
            "workers": []
        }

    def execute(self, ast):
        for node in ast:
            if node.type == "NODE_START":
                self.state["node"] = "running"
            if node.type == "MESH_SYNC":
                self.state["mesh"] = "synced"
            if node.type == "SHIELD_RAISE":
                self.state["shield"] = "raised"
            if node.type == "WORKER_SPAWN":
                self.state["workers"].append("worker")
        return self.state
EOFZEN

# ---------------------------------------------------------
# COMPILER
# ---------------------------------------------------------

cat > src/compiler/compiler.zc << 'EOFZEN'
BYTECODES = {
    "NODE_START": 1,
    "MESH_SYNC": 2,
    "SHIELD_RAISE": 3,
    "WORKER_SPAWN": 4
}

def compile(ast):
    bytecode = []
    for node in ast:
        bytecode.append(BYTECODES[node.type])
    return bytecode
EOFZEN

# ---------------------------------------------------------
# DISTRIBUTED RUNTIME
# ---------------------------------------------------------

cat > src/distributed/runtime-distributed.zc << 'EOFZEN'
class DistributedRuntime:
    def __init__(self):
        self.nodes = []

    def broadcast(self, message):
        for n in self.nodes:
            n.receive(message)

class Node:
    def __init__(self, id):
        self.id = id

    def receive(self, message):
        print("[Node {}] {}".format(self.id, message))
EOFZEN

# ---------------------------------------------------------
# ZCORE OPCODES
# ---------------------------------------------------------

cat > src/zcore/opcodes.zc << 'EOFZEN'
OPCODES = {
    "NODE_START": 16,
    "NODE_STOP": 17,
    "MESH_SYNC": 32,
    "MESH_BROADCAST": 33,
    "SHIELD_RAISE": 48,
    "SHIELD_LOWER": 49,
    "WORKER_SPAWN": 64,
    "WORKER_KILL": 65
}
EOFZEN

# ---------------------------------------------------------
# ZCORE BRIDGE
# ---------------------------------------------------------

cat > src/zcore/bridge.zc << 'EOFZEN'
from src.zcore.opcodes import OPCODES

ZEN_TO_ZCORE = {
    "NODE_START": OPCODES["NODE_START"],
    "MESH_SYNC": OPCODES["MESH_SYNC"],
    "SHIELD_RAISE": OPCODES["SHIELD_RAISE"],
    "WORKER_SPAWN": OPCODES["WORKER_SPAWN"]
}

def translate(ast):
    bytecode = []
    for node in ast:
        if node.type in ZEN_TO_ZCORE:
            bytecode.append(ZEN_TO_ZCORE[node.type])
    return bytecode
EOFZEN

# ---------------------------------------------------------
# ZCORE RUNTIME
# ---------------------------------------------------------

cat > src/zcore/runtime.zc << 'EOFZEN'
class ZCoreRuntime:
    def __init__(self):
        self.state = {
            "node": "stopped",
            "mesh": "idle",
            "shield": "down",
            "workers": []
        }

    def execute_opcode(self, opcode):
        if opcode == 16:
            self.state["node"] = "running"
        if opcode == 17:
            self.state["node"] = "stopped"
        if opcode == 32:
            self.state["mesh"] = "synced"
        if opcode == 33:
            self.state["mesh"] = "broadcast"
        if opcode == 48:
            self.state["shield"] = "raised"
        if opcode == 49:
            self.state["shield"] = "lowered"
        if opcode == 64:
            self.state["workers"].append("worker")
        if opcode == 65:
            if self.state["workers"]:
                self.state["workers"].pop()
        return self.state
EOFZEN

# ---------------------------------------------------------
# ZCORE LOADER
# ---------------------------------------------------------

cat > src/zcore/loader.zc << 'EOFZEN'
from src.zcore.runtime import ZCoreRuntime

class ZCoreLoader:
    def __init__(self):
        self.runtime = ZCoreRuntime()

    def load(self, bytecode):
        for op in bytecode:
            self.runtime.execute_opcode(op)
        return self.runtime.state
EOFZEN

# ---------------------------------------------------------
# DEBUGGER
# ---------------------------------------------------------

cat > src/debugger/ast_viewer.zc << 'EOFZEN'
def view_ast(ast):
    print("AST VIEW")
    for node in ast:
        print(" -", node.type)
EOFZEN

cat > src/debugger/bytecode_viewer.zc << 'EOFZEN'
def view_bytecode(bytecode):
    print("BYTECODE VIEW")
    for op in bytecode:
        print(" -", op)
EOFZEN

cat > src/debugger/runtime_inspector.zc << 'EOFZEN'
def inspect_runtime(state):
    print("RUNTIME STATE")
    for key in state:
        print(key, ":", state[key])
EOFZEN

cat > src/debugger/debugger.zc << 'EOFZEN'
from src.tokenizer import tokenize
from src.parser import parse
from src.compiler.compiler import compile
from src.zcore.bridge import translate
from src.zcore.loader import ZCoreLoader

from src.debugger.ast_viewer import view_ast
from src.debugger.bytecode_viewer import view_bytecode
from src.debugger.runtime_inspector import inspect_runtime

class ZenDebugger:
    def __init__(self):
        self.loader = ZCoreLoader()

    def debug(self, source):
        print("TOKENIZING")
        tokens = tokenize(source)

        print("PARSING")
        ast = parse(tokens)

        print("AST")
        view_ast(ast)

        print("COMPILING")
        bytecode = compile(ast)

        print("BYTECODE")
        view_bytecode(bytecode)

        print("TRANSLATING TO ZCORE")
        zcore_code = translate(ast)

        print("EXECUTING")
        state = self.loader.load(zcore_code)

        print("RUNTIME")
        inspect_runtime(state)

        return state
EOFZEN

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------

echo "FULL ZEN ECOSYSTEM BUILD COMPLETE"
