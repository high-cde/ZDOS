#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
ZDOS BIOS installer

Usage: sudo distro/install.sh --iso zdos-linux-x86_64.iso --device /dev/sdX
       add --yes to skip the exact-device confirmation prompt.

The selected whole disk is erased and formatted. This installer currently
supports legacy BIOS boot on MBR disks; it does not install UEFI or Secure Boot.
EOF
}

ISO= DEVICE= YES=0
while (($#)); do
  case $1 in
    --iso) ISO=${2:?missing ISO path}; shift 2 ;;
    --device) DEVICE=${2:?missing target disk}; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ -n $ISO && -n $DEVICE ]] || { usage >&2; exit 2; }
ISO=$(readlink -f -- "$ISO")
DEVICE=$(readlink -f -- "$DEVICE")
[[ $EUID -eq 0 ]] || { echo 'installer must run as root' >&2; exit 1; }
[[ -f $ISO && -b $DEVICE ]] || { echo 'ISO file or target block device not found' >&2; exit 1; }
for tool in lsblk findmnt sfdisk partprobe mkfs.ext4 mount mountpoint umount blkid grub-install gzip cpio chroot blockdev swapon wipefs sync; do
  command -v "$tool" >/dev/null || { echo "missing required command: $tool" >&2; exit 1; }
done
device_type=$(lsblk -dnro TYPE "$DEVICE")
if [[ $device_type != disk ]] && ! { [[ ${ZDOS_INSTALL_TEST:-0} == 1 && $device_type == loop ]]; }; then
  echo 'target must be a whole disk, not a partition' >&2
  exit 1
fi
size=$(lsblk -b -dnro SIZE "$DEVICE")
(( size <= 2199023255552 )) || { echo 'MBR installation is limited to disks up to 2 TiB' >&2; exit 1; }
[[ $(blockdev --getro "$DEVICE") == 0 ]] || { echo 'target disk is read-only' >&2; exit 1; }

while IFS= read -r mounted; do
  [[ -z $mounted ]] || { echo "target has mounted filesystems; unmount them first: $mounted" >&2; exit 1; }
done < <(lsblk -nrpo MOUNTPOINT "$DEVICE" | sed '/^[[:space:]]*$/d')
while IFS= read -r active_swap; do
  [[ -n $active_swap ]] || continue
  if lsblk -s -nro PATH "$active_swap" 2>/dev/null | grep -Fxq "$DEVICE"; then
    echo "target contains active swap; disable it first: $active_swap" >&2
    exit 1
  fi
done < <(swapon --noheadings --raw --show=NAME)
root_source=$(findmnt -nro SOURCE / || true)
if [[ -n $root_source ]] && lsblk -s -nro PATH "$root_source" 2>/dev/null | grep -Fxq "$DEVICE"; then
  echo 'refusing to overwrite the disk containing this running system' >&2
  exit 1
fi
iso_source=$(findmnt -T "$ISO" -nro SOURCE || true)
if [[ -n $iso_source ]] && lsblk -s -nro PATH "$iso_source" 2>/dev/null | grep -Fxq "$DEVICE"; then
  echo 'the installer ISO is on the target disk; move it before installing' >&2
  exit 1
fi

printf 'Set the installed system root password (minimum 12 characters): ' >&2
read -r -s root_password; printf '\n' >&2
printf 'Repeat root password: ' >&2
read -r -s root_password_confirm; printf '\n' >&2
[[ ${#root_password} -ge 12 && $root_password != *:* && $root_password != *$'\n'* ]] || {
  echo 'password must be at least 12 characters and may not contain a colon' >&2; exit 1;
}
[[ $root_password == "$root_password_confirm" ]] || { echo 'passwords do not match' >&2; exit 1; }
unset root_password_confirm

if [[ $YES -ne 1 ]]; then
  printf 'This will ERASE every partition on %s. Type the exact device path to continue: ' "$DEVICE" >&2
  read -r confirmation
  [[ $confirmation == "$DEVICE" ]] || { echo 'installation cancelled' >&2; exit 1; }
fi

tmp=$(mktemp -d)
media=$tmp/media
target=$tmp/target
mkdir -p "$media" "$target"
cleanup() {
  mountpoint -q "$target" && umount "$target" || true
  mountpoint -q "$media" && umount "$media" || true
  rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mount -o loop,ro "$ISO" "$media"
[[ -f $media/boot/vmlinuz && -f $media/boot/initramfs.cpio.gz && -f $media/boot/MANIFEST.sha256 ]] || {
  echo 'ISO is missing the ZDOS boot files or checksum manifest' >&2; exit 1;
}
(cd "$media" && sha256sum -c boot/MANIFEST.sha256)

wipefs --all --force "$DEVICE"
printf 'label: dos\nunit: sectors\n\nstart=2048, type=83, bootable\n' | sfdisk --wipe always "$DEVICE"
partprobe "$DEVICE"
udevadm settle 2>/dev/null || true
partition=${DEVICE}1
[[ ${DEVICE##*/} =~ [0-9]$ ]] && partition=${DEVICE}p1
for _ in {1..50}; do [[ -b $partition ]] && break; sleep 0.1; done
[[ -b $partition ]] || { echo "partition node did not appear: $partition" >&2; exit 1; }
mkfs.ext4 -F -L ZDOS_ROOT "$partition"
mount "$partition" "$target"
gzip -dc "$media/boot/initramfs.cpio.gz" | (cd "$target" && cpio -idmu --no-absolute-filenames)
mkdir -p "$target/boot/grub"
cp "$media/boot/vmlinuz" "$media/boot/initramfs.cpio.gz" "$target/boot/"
printf 'installed\n' > "$target/etc/zdos/installed"
printf 'root:%s\n' "$root_password" | chroot "$target" /usr/sbin/chpasswd
unset root_password
root_uuid=$(blkid -s UUID -o value "$partition")
[[ $root_uuid =~ ^[A-Fa-f0-9-]+$ ]] || { echo 'could not read root filesystem UUID' >&2; exit 1; }
cat > "$target/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry "ZDOS Linux (installed)" {
  search --no-floppy --fs-uuid --set=root $root_uuid
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200n8 init=/init zdos.root_uuid=$root_uuid
  initrd /boot/initramfs.cpio.gz
}
EOF
grub-install --target=i386-pc --boot-directory="$target/boot" --recheck "$DEVICE"
sync
umount "$target"
umount "$media"
printf 'ZDOS_INSTALL_COMPLETE disk=%s partition=%s uuid=%s\n' "$DEVICE" "$partition" "$root_uuid"
printf 'Remove the installer media and reboot. Legacy BIOS mode is required.\n'
