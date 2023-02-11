#! /bin/bash
readonly device=/dev/sda


parted --script --align optimal "$device" \
mklabel gpt \
mkpart primary ext4 1MiB 512MiB \
mkpart primary linux-swap 512MiB 4512MiB \
mkpart primary ext4 4512MiB 25% \
mkpart primary ext4 25% 100% 
# name 1 'ESP' \
# name 2 'Swap' \
# name 3 'Root' \
# name 4 'Home' 

mkfs.fat -F 32 "${device}1"
mkfs.ext4 -F "${device}3"
mkfs.ext4 -F "${device}4"

mkswap "${device}2"
swapon "${device}2"


mkdir -p /mnt/boot/efi
mkdir /mnt/etc

mount "${device}3" /mnt
mount "${device}4" /mnt/home
mount "${device}1" /mnt/boot/efi

pacman-key --init
pacman-key --populate archlinux
pacman -Sc
pacstrap -K /mnt base 

genfstab -U /mnt >> /mnt/etc/fstab

cp /media/sf_MyArch/install_chroot.sh /mnt

arch-chroot /mnt ./install_chroot.sh

umount -R /mnt
reboot