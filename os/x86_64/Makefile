SHELL := /bin/sh

BUILD := build
CC := gcc
LD := ld
PYTHON ?= python3
ZLANGC ?= $(CURDIR)/../../../Zlang/tools/zlangc.py

CFLAGS := -m64 -std=c11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -mcmodel=small
ASFLAGS := -m64 -ffreestanding -fno-pie
LDFLAGS := -m elf_x86_64 -nostdlib -z max-page-size=0x1000 -T linker.ld

PROGRAM := programs/boot.zlang
GENERATED_DIR := $(BUILD)/generated
PROGRAM_HEADER := $(GENERATED_DIR)/zlang_program.h
PROGRAM_BYTECODE := $(BUILD)/programs/boot.zlb
KERNEL := $(BUILD)/zdos.elf
ISO_DIR := $(BUILD)/iso
ISO := $(BUILD)/zdos-x86_64.iso
OBJECTS := $(BUILD)/boot/boot.o $(BUILD)/kernel/kernel.o $(BUILD)/kernel/zlang.o

.PHONY: all iso kernel verify run clean

all: iso

iso: $(ISO)

kernel: $(KERNEL)

$(PROGRAM_HEADER): $(PROGRAM) $(ZLANGC)
	@mkdir -p $(GENERATED_DIR) $(dir $(PROGRAM_BYTECODE))
	$(PYTHON) $(ZLANGC) $(PROGRAM) --target zdos-x86_64 --header $(PROGRAM_HEADER) --bytecode $(PROGRAM_BYTECODE)

$(BUILD)/boot/boot.o: boot/boot.S
	@mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/kernel/%.o: kernel/%.c include/zlang.h $(PROGRAM_HEADER)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -Iinclude -I$(GENERATED_DIR) -c $< -o $@

$(KERNEL): $(OBJECTS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(ISO): $(KERNEL) boot/grub.cfg
	@rm -rf $(ISO_DIR)
	@mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/zdos.elf
	cp boot/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $@ $(ISO_DIR) >/dev/null

verify: $(KERNEL)
	grub-file --is-x86-multiboot2 $(KERNEL)
	@echo "ZDOS: kernel Multiboot2 verificato"

run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -serial stdio -display none -no-reboot

clean:
	rm -rf $(BUILD)
