#!/bin/bash
echo "🚀 Avvio ZDOS in QEMU..."
echo "💡 TIP: Per uscire rapidamente da QEMU in modalità -nographic, premi: CTRL+A poi X"
echo "--------------------------------------------------------"
qemu-system-x86_64 -cdrom build/zdos-x86_64.iso -nographic -no-reboot
