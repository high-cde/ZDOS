#!/bin/bash
# ==========================================
# ZDOS-SEC // Universal Build & Sync Tool
# ==========================================

echo "Seleziona il modulo Z-Lang da compilare ed eseguire:"
echo "1) zdos_license.zlang      (Scudo Anti-Clonazione xCLOUD)"
echo "2) calc.zlang               (Calcolatrice Nativa ALU)"
echo "3) notes.zlang              (Blocco Note di Sicurezza)"
echo "4) security_core.zlang      (Tor & Anti-Fingerprint Core)"
echo "5) space_defender.zlang     (Space Defender & Starlink/Z-Chain L1)"
echo "6) starlink_uplink.zlang    (Gateway Starlink LEO Real-Link)"
echo "7) zchain_consensus.zlang   (Z-Chain Layer 1 Consensus Node)"
echo "8) parrot_box.zlang         (Parrot Black Box Sandbox & Jail)"
read -p "Inserisci il numero della scelta [1-8]: " choice

case $choice in
    1) MODULE="userland/zdos_license.zlang";;
    2) MODULE="userland/calc.zlang";;
    3) MODULE="userland/notes.zlang";;
    4) MODULE="userland/security_core.zlang";;
    5) MODULE="userland/space_defender.zlang";;
    6) MODULE="userland/starlink_uplink.zlang";;
    7) MODULE="userland/zchain_consensus.zlang";;
    8) MODULE="userland/parrot_box.zlang";;
    *) MODULE="userland/space_defender.zlang";;
esac

echo "🚀 Avvio compilazione per: $MODULE"

cp "$MODULE" programs/boot.zlang
rm -f build/generated/zlang_program.h
mkdir -p build/generated build/programs build/kernel build/boot build/iso/boot/grub

# Compilazione bytecode e firma con il tool sicuro
python3 /root/modules/Zlang/tools/zlangc.py programs/boot.zlang --header build/generated/zlang_program.h --bytecode build/programs/boot.zlb

# Pulizia vecchi oggetti
rm -rf build/*.o build/kernel/*.o build/boot/*.o

# Compilazione Assembler Bootloader
gcc -m64 -ffreestanding -fno-pie -c boot/boot.S -o build/boot/boot.o

# Compilazione Kernel C (includendo le funzioni seriali direttamente se necessario)
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/kernel.c -o build/kernel/kernel.o

# Compilazione Hypervisor Z-Lang con Verified Boot
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/zlang.c -o build/kernel/zlang.o

# Linking finale
ld -m elf_x86_64 -nostdlib -z max-page-size=0x1000 -T linker.ld -o build/zdos.elf build/boot/boot.o build/kernel/kernel.o build/kernel/zlang.o

# Creazione ISO Multiboot2
cp build/zdos.elf build/iso/boot/zdos.elf
cp boot/grub.cfg build/iso/boot/grub/grub.cfg
grub-mkrescue -o build/zdos-x86_64.iso build/iso >/dev/null

echo "✅ Build completata con successo! ISO pronta in build/zdos-x86_64.iso"
