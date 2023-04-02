#! /bin/bash
readonly device=/dev/sda
readonly isEFI=false


log_info() {
    local now=$(date +"%H:%M:%S.%3N")
    echo "$now ::> $1"
}
log_err() {
    local now=$(date +"%H:%M:%S.%3N")
    echo "$now ::> $1"
}
OUT="/mnt/cmdsout.out"


DISK_SIZE=$(blockdev --getsize64 "$device")
DISK_SIZE_GB=$(bc <<< $DISK_SIZE/1073741824)

if [ $DISK_SIZE_GB -lt 20 ]; then
    echo "Disk should be at least 20Gb"
fi

if [[ $ROOT_SIZE -gt 50 ]]; then
    ROOT_SIZE=$(bc <<< 1024*30)
else 
    ROOT_SIZE=$(bc <<< $DISK_SIZE/2097152)
fi


if [ isEFI = true ]; then
echo ""
    # parted --script --align optimal "$device" \
    # mklabel msdos \
    # mkpart primary ext4 1MiB 512MiB \
    # mkpart primary linux-swap 512MiB 4512MiB \
    # mkpart primary ext4 4512MiB 40% \
    # mkpart primary ext4 40% 100% &> $OUT 

    # mkfs.fat -F 32 "${device}1" &> $OUT
    # mkfs.ext4 -F "${device}3" &> $OUT
    # mkfs.ext4 -F "${device}4" &> $OUT

    # mkdir /mnt/home 
    # mkdir /mnt/boot
    # mkdir /mnt/boot/efi

    # mount "${device}1" /mnt/boot/efi
    # mount "${device}3" /mnt
    # mount "${device}4" /mnt/home
else
    ROOT_END=$(bc <<< $ROOT_SIZE+1024)
    log_info "Partitioning $device ..."
    parted --script --align optimal "$device" \
    mklabel msdos \
    mkpart primary linux-swap 1MiB 1024MiB \
    mkpart primary ext4 1024MiB "${ROOT_SIZE}MiB" \
    mkpart primary ext4 "${ROOT_END}MiB" 100% &> $OUT
    if [ $? -ne 0 ];then 
        log_err "Was not possible to parted $device"
        exit 1
    fi
    log_info "$device was successfully partitioned"

    log_info "Creating ext4 file system for ${device}2 ..."
    if ! mkfs.ext4 -F "${device}2" &> $OUT; then
        log_err "Failed on ext4 creating for ${device}2"
    fi
    log_info "ext4 file system was successfully created for ${device}2 ..."


    log_info "Creating ext4 file system for ${device}3 ..."
    if ! mkfs.ext4 -F "${device}3" &> $OUT; then 
        log_err "Failed on ext4 creating for ${device}3"
    fi
    log_info "ext4 file system was successfully created for ${device}3 ..."

    log_info "Creating swap file system for ${device}1 ..."
    if ! mkswap "${device}1" &> $OUT; then
        log_err "Not possible to create swap on ${device}1"
    fi
    log_info "swap file system was successfully created for ${device}1"

    log_info "Activating swap on ${device}1 ..."
    if ! swapon "${device}1" &> $OUT; then
        log_err "Not possible to activate swap on ${device}1"
    fi
    log_info "swap was successfully activated on ${device}1"

    log_info "Mounting ${device}2 on /mnt"
    mount "${device}2" /mnt &> $OUT
    mkdir /mnt/home  &> $OUT
    log_info "Mounting ${device}3 on /mnt/home"
    mount "${device}3" /mnt/home &> $OUT
fi

# pacman-key --init
# pacman-key --populate archlinux
# pacman -Sc --noconfirm
# pacman -Sy --noconfirm

log_info "Installing base package..."
pacstrap -K /mnt base &> $OUT

log_info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab &> $OUT

cp /media/sf_MyArch/install_chroot.sh /mnt
arch-chroot /mnt ./install_chroot.sh

# umount -R /mnt
# reboot