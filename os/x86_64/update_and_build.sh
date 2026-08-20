#!/bin/bash
# ==========================================
# ZDOS-SEC // Universal Build & Sync Tool
# Scegli quale modulo compilare nello userland
# ==========================================

echo "Seleziona il modulo Z-Lang da compilare ed eseguire:"
echo "1) zdos_license.zlang (Scudo Anti-Clonazione xCLOUD)"
echo "2) calc.zlang          (Calcolatrice Nativa ALU)"
echo "3) notes.zlang         (Blocco Note di Sicurezza)"
read -p "Inserisci il numero della scelta [1-3]: " choice

case $choice in
    1) MODULE="userland/zdos_license.zlang";;
    2) MODULE="userland/calc.zlang";;
    3) MODULE="userland/notes.zlang";;
    *) echo "Scelta non valida. Default su Calcolatrice."; MODULE="userland/calc.zlang";;
esac

echo "🚀 Avvio compilazione per: $MODULE"

# 1. Copia come programma di boot
cp "$MODULE" programs/boot.zlang

# 2. Pulizia header e rigenerazione bytecode
rm -f build/generated/zlang_program.h
mkdir -p build/generated build/programs build/kernel build/boot build/iso/boot/grub

python3 /root/modules/Zlang/tools/zlangc.py programs/boot.zlang --header build/generated/zlang_program.h --bytecode build/programs/boot.zlb

# 3. Pulizia oggetti C e ricompilazione totale
rm -rf build/*.o build/kernel/*.o build/boot/*.o
gcc -m64 -ffreestanding -fno-pie -c boot/boot.S -o build/boot/boot.o
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/kernel.c -o build/kernel/kernel.o
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/zlang.c -o build/kernel/zlang.o

ld -m elf_x86_64 -nostdlib -z max-page-size=0x1000 -T linker.ld -o build/zdos.elf build/boot/boot.o build/kernel/kernel.o build/kernel/zlang.o

# 4. Assemblaggio ISO Multiboot2
cp build/zdos.elf build/iso/boot/zdos.elf
cp boot/grub.cfg build/iso/boot/grub/grub.cfg
grub-mkrescue -o build/zdos-x86_64.iso build/iso >/dev/null

echo "✅ Build completata con successo! ISO pronta in build/zdos-x86_64.iso"
