#!/bin/bash
echo "Building zSEC"
mkdir -p modules/zsec/src
cat > modules/zsec/src/zsec.zc << 'EOSEC'
class Sandbox:
    def allow(self, action):
        print("Allow:", action)

    def deny(self, action):
        print("Deny:", action)
EOSEC
echo "zSEC Build Complete"
