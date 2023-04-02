readonly isEFI=false

log_info() {
    local now=$(date +"%H:%M:%S.%3N")
    echo "$now ::> $1"
}
log_err() {
    local now=$(date +"%H:%M:%S.%3N")
    echo "$now ::> $1"
}

OUT="/cmdsout.out"

log_info "Configuring mirror for Brazil"
pacman -Syu --noconfirm reflector &> $OUT 
reflector -l 10 --country 'Brazil' --sort rate --save /etc/pacman.d/mirrorlist &> $OUT 

log_info "Installing linux and linux-lts and firmwares"
pacman -S --noconfirm linux linux-lts linux-headers linux-lts-headers linux-firmware &> $OUT   

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime &> $OUT 
hwclock --systohc &> $OUT 

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf &> $OUT 
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf &> $OUT 
echo "yuri" > /etc/hostname &> $OUT 

echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen &> $OUT 

mkinitcpio -p linux &> $OUT 
mkinitcpio -P linux-lts &> $OUT 


if [ isEFI = true ]; then
    pacman -S --noconfirm vim git wget curl network-manager grub efibootmgr os-prober dosfstools
    mount /dev/sda1 /boot/EFI
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
    # grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
else
    log_info "Installing grub"
    pacman -S --noconfirm grub &> $OUT  #grub os-prober dosfstools &> $OUT 
    if ! grub-install --target=i386-pc /dev/sda &> $OUT; then
        log_err "Could not install grub in /dev/sda"
    fi 
fi

log_info "Generating grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg &> $OUT 

log_info "Installing essential packages for a developer :)"
pacman -S --noconfirm vim sudo git wget curl networkmanager base-devel &> $OUT 
systemctl enable NetworkManager.service &> $OUT 

yes toor | passwd

log_info "Adding liberty user"
groupadd ikary &> $OUT
useradd -G ikary -m -s /bin/bash liberty &> $OUT 
yes liberty | passwd liberty &> $OUT

echo '%ikary ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo &> $OUT

log_info "Installing gnome"
pacman -S --noconfirm xorg xorg-server gnome &> $OUT 
systemctl enable gdm.service &> $OUT
# systemctl start gdm.service


pacman -S --noconfirm vlc firefox &> $OUT