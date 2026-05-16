#!/bin/bash
echo "Building zBOOT"
mkdir -p modules/zboot/src
cat > modules/zboot/src/zboot.zc << 'EOBOOT'
def boot():
    print("Booting GENESIS OS...")
EOBOOT
echo "zBOOT Build Complete"
