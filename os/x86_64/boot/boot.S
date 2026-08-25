.section .multiboot
.align 8
header_start:
    .long 0xe85250d6
    .long 0
    .long header_end - header_start
    .long -(0xe85250d6 + 0 + (header_end - header_start))
    .short 0
    .short 0
    .long 8
header_end:

.section .bss
.align 4096
boot_pml4:
    .skip 4096
boot_pdpt:
    .skip 4096
boot_pd:
    .skip 4096

.align 16
boot_stack:
    .skip 16384
boot_stack_top:

.section .rodata
.align 8
gdt64:
    .quad 0x0000000000000000
    .quad 0x00209a0000000000
    .quad 0x0000920000000000
gdt64_end:
gdt64_pointer:
    .word gdt64_end - gdt64 - 1
    .long gdt64

.section .text
.code32
.global _start
.type _start, @function
.extern kernel_main
_start:
    cli

    movl $boot_pml4, %edi
    xorl %eax, %eax
    movl $3072, %ecx
    rep stosl

    movl $boot_pdpt, %eax
    orl $0x3, %eax
    movl %eax, boot_pml4

    movl $boot_pd, %eax
    orl $0x3, %eax
    movl %eax, boot_pdpt

    movl $0x00000083, boot_pd

    movl %cr4, %eax
    orl $0x20, %eax
    movl %eax, %cr4

    movl $boot_pml4, %eax
    movl %eax, %cr3

    movl $0xc0000080, %ecx
    rdmsr
    orl $0x00000100, %eax
    wrmsr

    movl %cr0, %eax
    orl $0x80000001, %eax
    movl %eax, %cr0

    lgdt gdt64_pointer
    ljmp $0x08, $long_mode_start

.code64
long_mode_start:
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss

    movq $boot_stack_top, %rsp
    andq $-16, %rsp
    call kernel_main

halt:
    cli
    hlt
    jmp halt

.section .note.GNU-stack,"",@progbits
