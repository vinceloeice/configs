#!/bin/bash

echo "Arch Installer"
export EDITOR=vim

# Prereq variables

DRIVE='/dev/sda'
HOSTNAME='hackbox'
TIMEZONE='Poland'
KEYMAP='pl'
MIRRORS='n'

function setup() {
    local boot_dev="${DRIVE}1"

    echo 'Prereq'
    prereq

    echo 'Creating partitions'

    echo "This script will create and format the partitions as follows:"
    echo "/dev/sda1 - 300MiB will be mounted as /boot"
    echo "/dev/sda2 - rest of space will be mounted as /"
    read -p 'Continue? [y/N]: ' fsok

    if [[ $fsok == 'y' || $fsok == 'Y' ]]; then
      partition_drive "$DRIVE"

      echo 'Formatting filesystems'
      format_filesystems "$boot_dev"
    
      echo 'Mounting filesystems'
      mount_filesystems "$boot_dev"

    else
      echo "Skipping..."
      exit
    fi


    if [[ $MIRRORS == 'y' ]]; then
      echo 'Ranking mirrors'
      mirrors
    fi

    echo 'Installing base system'
    install_base

    echo 'Setting fstab'
    set_fstab

    echo 'Chrooting into installed system to continue setup...'
    cp $0 /mnt/setup.sh
    arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
#        echo 'Unmounting filesystems'
#        unmount_filesystems
        echo 'Done! Reboot system.'
    fi
}

function configure() {
    local boot_dev="${DRIVE}1"

    echo 'Clearing package tarballs'
    clean_packages

    echo 'Setting hostname'
    set_hostname "$HOSTNAME"

    echo 'Setting timezone'
    set_timezone "$TIMEZONE"

    echo 'Setting locale'
    set_locale

    echo 'Setting console keymap'
    set_keymap

    echo 'Setting hosts file'
    set_hosts "$HOSTNAME"

    echo 'Network'
    configure_network

    echo 'Setting initial modules to load'
    set_modules_load

    echo 'Configuring initial ramdisk'
    set_initcpio

    echo 'Configuring bootloader'
    configure_bootloader

    if [ -z "$ROOT_PASSWORD" ]
    then
        echo 'Enter the root password:'
        stty -echo
        read ROOT_PASSWORD
        stty echo
    fi
    echo 'Setting root password'
    set_root_password "$ROOT_PASSWORD"

    echo 'Building locate database'
    update_locate

    rm /setup.sh
}

function prereq() {
  # Set up time
  timedatectl set-ntp true
}

function partition_drive() {
    local dev="$1"; shift

    sgdisk -p $DRIVE
    sgdisk -Z $DRIVE
    sgdisk -og $DRIVE
    sgdisk -n 1:0:+300M -t 1:ef00 $DRIVE # UEFI
    sgdisk -n 2:0:0 -t 2:8300 $DRIVE # root
    sgdisk -p $DRIVE
    sgdisk -w $DRIVE
}

function format_filesystems() {
    local boot_dev="$1"; shift

    mkfs.fat -F32 "${DRIVE}1" # EFI
		mkfs.ext4 "${DRIVE}2" # root
}

function mount_filesystems() {
    local boot_dev="$1"; shift

		mount "${DRIVE}2" /mnt
		mkdir -pv /mnt/boot
		mount "${DRIVE}1" /mnt/boot
}

function mirrors() {
  # Init keys
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key --refresh-keys

  # Rank mirrors
  pacman -Sy pacman-contrib
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
  echo '[*] Ranking'
  rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  rm /etc/pacman.d/mirrorlist.tmp
}

function install_base() {
  echo "[*] Starting install"
  local packages=''
  
  # Core packages
  packages+=' base base-devel linux-zen linux-firmware'

  # Nice to have
  packages+=' neovim terminus-font plocate'

  if lscpu | sed -nr '/Model name/ s/.*:\s*(.*) @ .*/\1/p' | grep -i intel
  then
    packages+=' intel-ucode'
  fi

  pacstrap /mnt $packages
}

function set_fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab
}

function clean_packages() {
    yes | pacman -Scc
}

function set_hostname() {
    local hostname="$1"; shift
    echo "$hostname" > /etc/hostname
}

function set_timezone() {
    local timezone="$1"; shift
    ln -sT "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
}

function set_locale() {
    echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
    echo 'LC_COLLATE="C"' >> /etc/locale.conf
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
}

function set_keymap() {
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    echo "FONT=ter-i24n" >> /etc/vconsole.conf
}

function set_hosts() {
    local hostname="$1"; shift

    cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost $hostname
::1       localhost.localdomain localhost $hostname
EOF
}

function set_modules_load() { 
  if lscpu | sed -nr '/Model name/ s/.*:\s*(.*) @ .*/\1/p' | grep -i intel
  then
    echo 'microcode' > /etc/modules-load.d/intel-ucode.conf
  fi
}

function set_initcpio() {
  sed -i 's/^HOOKS.*$/HOOKS=(base systemd sd-vconsole autodetect modconf keyboard block filesystems fsck)/g' /etc/mkinitcpio.conf
  mkinitcpio -P linux-zen
}

function configure_network() {
  cat > /etc/systemd/network/20-wired.network <<EOF
[Match]
Name=en*

[Network]
DHCP=yes
EOF

  chmod 664 /etc/systemd/network/20-wired.network
}

function configure_bootloader() {
#  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
#  grub-mkconfig -o /boot/grub/grub.cfg
  bootctl install

  cat > /boot/loader/loader.conf <<EOF
default arch
timeout 0
console-mode max
editor no
auto-entries 1
EOF
  cat > /boot/loader/entries/arch.conf <<EOF
title   loonix
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
EOF

  DEV_ID="$(blkid -s UUID -o value "${DRIVE}2")"
  echo "options root=UUID="$DEV_ID" sysrq_always_enabled=1 nowatchdog rw" >> /boot/loader/entries/arch.conf

  if [ -x /boot/intel-ucode.img ]; then
    sed -i '3i\initrd  /intel-ucode.img'  /boot/loader/entries/arch.conf
  fi
}

function set_root_password() {
    local password="$1"; shift
    echo -en "$password\n$password" | passwd
}

function update_locate() {
    updatedb
}

function get_uuid() {
    blkid -o export "$1" | grep UUID | awk -F= '{print $2}'
}

#set -xe

if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi
