#!/usr/bin/env bash
set -euo pipefail

# Build non interattiva del kernel ZDOS x86_64 con un programma userland reale.
# Uso: ./update_and_build.sh [calc|notes]

case "${1:-calc}" in
  calc)  module="userland/calc.zlang" ;;
  notes) module="userland/notes.zlang" ;;
  *) echo "Uso: $0 [calc|notes]" >&2; exit 2 ;;
esac

if [[ ! -f "$module" ]]; then
  echo "Programma userland non trovato: $module" >&2
  exit 1
fi

zlang_root="${ZLANG_ROOT:-../../../../Zlang}"
zlangc="${ZLANGC:-$zlang_root/tools/zlangc.py}"
if [[ ! -f "$zlangc" ]]; then
  echo "Compilatore Zlang non trovato: $zlangc (impostare ZLANGC o ZLANG_ROOT)" >&2
  exit 1
fi

mkdir -p build/generated build/programs build/kernel build/boot build/iso/boot/grub
cp "$module" programs/boot.zlang
rm -f build/generated/zlang_program.h build/*.o build/kernel/*.o build/boot/*.o
python3 "$zlangc" programs/boot.zlang --header build/generated/zlang_program.h --bytecode build/programs/boot.zlb
gcc -m64 -ffreestanding -fno-pie -c boot/boot.S -o build/boot/boot.o
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/kernel.c -o build/kernel/kernel.o
gcc -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small -Iinclude -Ibuild/generated -c kernel/zlang.c -o build/kernel/zlang.o
ld -m elf_x86_64 -nostdlib -z max-page-size=0x1000 -T linker.ld -o build/zdos.elf build/boot/boot.o build/kernel/kernel.o build/kernel/zlang.o
cp build/zdos.elf build/iso/boot/zdos.elf
cp boot/grub.cfg build/iso/boot/grub/grub.cfg
grub-mkrescue -o build/zdos-x86_64.iso build/iso >/dev/null
printf 'Build completata: %s\n' "build/zdos-x86_64.iso"
