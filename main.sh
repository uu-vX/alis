#!/usr/bin/env bash
:' 
    TO-DO :

'
#   Automated Arch Linux Installer With Btrfs Sxhkd Snapper
#   Pre-installation
   #   Setting up mirrors for optimal download
       countryIso=$(curl -4 ifconfig.co/country-iso)
       timedatectl set-ntp true
   pacman -Syu
   pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
   pacman -S --noconfirm --needed pacman-contrib terminus-font
   setfont ter-v22b
   sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
   pacman -S --noconfirm --needed reflector rsync grub snapper
       #cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
   #   Setting up $iso mirrors for faster downloads
       reflector -a 48 -c $countryIso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
   #   Installing Prerequisites
       pacman -S --noconfirm --needed gptfdisk glibc #btrfs-progs
   #   User info
       read -p " Please enter username " $username
       read -p " Please enter password " $password
 
#   File system (Creates and manipulates partition tables and partitions on a storage.)
   lsblk -f
   read  -p "Please enter disk :  " disk
   
   sh ./btrfs.sh

#   Packages
   #   Microcode   #?grep processor name"
       processorMicrocode="intel-ucode"
 
   #   Kernel choice  # Ask for kernel choice and define essential packages with related packages(linux-lts-headers)
       kernelPackage="linux-lts"
       headerAndScript="linux-lts-header"
 
   #   Text editor
       terminalTextEditor="vim"
 
   #   Install essential packages
       pacstrap /mnt base ${kernelPackage} linux-firmware ${terminalTextEditor} ${processorMicrocode} git ${fileSystem}
 
#   User choice
   genfstab -U /mnt >> /mnt/etc/fstab
   arch-chroot /mnt
  
#   Localization
   ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
 
   hwclock --systohc
 
   sed -i '178s/.//' /etc/locale.gen
   locale-gen
 
   echo "LANG=en_US.UTF-8" >> /etc/locale.conf
   echo "KEYMAP=en_US.UTF-8" >>  /etc/vconsole.conf
   echo "${username}" >> /etc/hostname
   echo "127.0.0.1 localhost" >> /etc/hosts
   echo "::1       localhost" >> /etc/hosts
   echo "127.0.1.1 ${username}.localdomain ${username}" >> /etc/hosts
   useradd -m ${username}
   echo ${username}:${password} | chpasswd
   echo "${username} ALL=(ALL) ALL" >> /etc/sudoers.d/${username}

   sed -i 's/^# %ALL=(ALL:ALL) ALL/%ALL=(ALL:ALL) ALL/' /etc/pacman.conf
 
   exit
   umount -a
   
   sh ./option.sh

#   Personification : my dot files
#   Post-installation
   snapper -c root list
   snapper -c root create -c timeline --description AfterInstall
   sudo btrfs property set -ts /.snapshots/1/snapshot/ ro false


   exec bspwm