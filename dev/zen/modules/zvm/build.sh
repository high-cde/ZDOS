#!/bin/bash
echo "Building zVM"
mkdir -p modules/zvm/src
cat > modules/zvm/src/zvm.zc << 'EOVM'
class ZVM:
    def __init__(self):
        self.stack = []
        self.pc = 0

    def execute(self, bytecode):
        for op in bytecode:
            print("Executing opcode:", op)
EOVM
echo "zVM Build Complete"
