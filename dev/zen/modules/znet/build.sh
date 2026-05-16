#!/bin/bash
echo "Building zNET"
mkdir -p modules/znet/src
cat > modules/znet/src/znet.zc << 'EONET'
class ZNetSocket:
    def send(self, msg):
        print("Sending:", msg)

    def receive(self):
        print("Receiving message")
EONET
echo "zNET Build Complete"
