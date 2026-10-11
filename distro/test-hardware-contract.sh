#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODULES="$ROOT/distro/prepare-persistence-modules.sh"
INIT="$ROOT/distro/rootfs/init"

for path in \
  kernel/drivers/ata/ahci.ko \
  kernel/drivers/nvme/host/nvme.ko \
  kernel/drivers/usb/host/xhci-pci.ko \
  kernel/drivers/usb/storage/usb-storage.ko \
  kernel/drivers/hid/usbhid/usbhid.ko \
  kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko \
  kernel/drivers/net/ethernet/realtek/r8169.ko; do
  grep -Fq "$path" "$MODULES" || {
    printf 'ZDOS_HARDWARE_CONTRACT_FAILED missing module=%s\n' "$path" >&2
    exit 1
  }
done

grep -Fq 'depmod -b "$extract" "$release"' "$MODULES"
grep -Fq 'for module in ahci nvme sd_mod xhci_pci' "$INIT"
grep -Fq 'for interface in /sys/class/net/*' "$INIT"
grep -Fq '/bin/udhcpc -i "$interface"' "$INIT"
printf 'ZDOS_HARDWARE_BASELINE_CONTRACT_PASSED\n'
