# Supporto Hardware ZDOS

ZDOS supporta due famiglie di target.

## New Hardware (principale)

- Architettura: x86_64
- Boot: UEFI (target) / QEMU
- RAM: ≥ 1 GB consigliato
- Storage: virtio / SATA / NVMe
- Build: `./distro/build.sh` nel repo ZDOS
- Stato: M2 (reproducible in QEMU)

## Old Hardware (legacy)

- Architettura: x86 (32/64 bit limitato)
- Boot: Legacy BIOS (GRUB)
- Esempio: Compaq Evo N610c / e660 (Pentium 4-M, DDR, IDE, max ~1 GB)
- Repo dedicato: https://github.com/high-cde/ZDOS-e660-Security
- Stato: skeleton di build + documentazione. Integra kernel da ZDOS principale e testa su ferro.

## Note

Il security agent (`ZDOS-Security-Agent`) è indipendente dall'hardware e può girare su entrambi i target.
