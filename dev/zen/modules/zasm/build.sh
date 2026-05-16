#!/bin/bash
echo "Building zASM"
mkdir -p modules/zasm/src
cat > modules/zasm/src/zasm.zc << 'EOASM'
def assemble(code):
    print("Assembling:", code)

def disassemble(bytecode):
    print("Disassembling:", bytecode)
EOASM
echo "zASM Build Complete"
