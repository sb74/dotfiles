# Arch Install Script
# Largely taken from https://walian.co.uk/arch-install-with-secure-boot-btrfs-tpm2-luks-encryption-unified-kernel-images.html

# For Secure Boot setup: Clear Secure Boot Keys in BIOS
# Set a root password to allow SSH from laptop for ease of install.
passwd

# For SSH connection:
# ip a
# ssh root@<ip>

# Setup disks
# If we have an existing disk:
cryptsetup close linuxroot
wipefs -a /dev/nvme0n1
sgdisk -Z /dev/nvme0n1
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:LINUXROOT /dev/nvme0n1
# Setup LUKS
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 linuxroot
# Create filesystem and mount
mkfs.vfat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -f -L linuxroot /dev/mapper/linuxroot
# Temp mount
mount /dev/mapper/linuxroot /mnt
# Create root subvolume
btrfs subvolume create /mnt/@
# Unmount top-level so we can remount root subvol
umount /mnt
# Mount root subvolume with zstd
mount -o noatime,compress=zstd,subvol=@ /dev/mapper/linuxroot /mnt
# Mount EFI
mkdir -p /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi
# Create subvolumes as directories
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/var/cache
btrfs subvolume create /mnt/var/tmp

# Base install
reflector --country GB --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware intel-ucode nvim cryptsetup btrfs-progs dosfstools util-linux git sbctl openssh networkmanager sudo nvidia-dkms nvidia-utils openssh plymouth man-db man-pages terminus-font efibootmgr zram-generator

# Fix locale
sed -i -e "/^#"en_GB.UTF-8"/s/^#//" /mnt/etc/locale.gen
# Answers: uk, Europe/London
systemd-firstboot --root /mnt --prompt
arch-chroot /mnt locale-gen

#Create user
arch-chroot /mnt useradd -G wheel -m sb74
arch-chroot /mnt passwd sb74
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers

# Unified Linux Kernel
echo "quiet rw rootflags=subvol=@" >/mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux
# Change HOOKS: HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
# Add modules: MODULES=(... nvidia nvidia_modeset nvidia_uvm nvidia_drm ...)
vim /mnt/etc/mkinitcpio.conf
cat <<EOF >/mnt/etc/mkinitcpio.d/linux.preset
# mkinitcpio preset file to generate UKIs

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-zen"

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux-zen.img"
default_uki="/efi/EFI/Linux/arch-linux-zen.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-zen-fallback.img"
fallback_uki="/efi/EFI/Linux/arch-linux-zen-fallback.efi"
fallback_options="-S autodetect"
EOF

#Generate UKIs
arch-chroot /mnt mkinitcpio -P

#Enable services and bootloader
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager sshd
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi

#Reboot and finish
sync
systemctl reboot --firmware-setup

# Secure Boot
sudo sbctl create-keys
sudo sbctl enroll-keys -m
sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /efi/EFI/Linux/arch-linux-zen.efi
sudo sbctl sign -s /efi/EFI/Linux/arch-linux-zen-fallback.efi
# Test to check kernel signing and reboot
sudo pacman -S linux-zen
reboot
# Create recovery key and allow TPM to unlock encrypted drive (note can add a PIN if required)
sudo systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/gpt-auto-root-luks
reboot
# Next.. post-install.sh
