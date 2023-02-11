echo "helloWorld"

pacman -Syu --noconfirm reflector 

reflector -l 10 --country 'Brazil' --sort rate --save /etc/pacman.d/mirrorlist

pacman -S --noconfirm linux linux-lts linux-firmware base-devel  
pacman -S --noconfirm vim git wget curl network-manager grub efibootmgr os-prober

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "yuri" > /etc/hostname


mkinitcpio -p linux
# mkinitcpio -P linux-lts

# echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg



### after install

#sudo pacman -S polybar