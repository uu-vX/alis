#!  /usr/bin/env bash
:' 
    TO-DO :
'

#   Automated Arch Linux Installer
#   Cleaning the TTY
    clear
#   Style
    BOLD='\e[1m'
    BRED='\e[91m'
    BBLUE='\e[34m'  
    BGREEN='\e[92m'
    BYELLOW='\e[93m'
    RESET='\e[0m'
    info_print () {
        echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
        }
    input_print () {
        echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
        }
    error_print () {
        echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
        }
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
   sh ./filesystem/btrfs.sh

#   Virtualization check
    virtualization () {
        hypervisor=$(systemd-detect-virt)
        case $hypervisor in
            kvm )   
                info_print "KVM has been detected, setting up guest tools."
                pacstrap /mnt qemu-guest-agent &>/dev/null
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
            vmware  )   
                    info_print "VMWare Workstation/ESXi has been detected, setting up guest tools."
                    pacstrap /mnt open-vm-tools >/dev/null
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
            oracle )    
                    info_print "VirtualBox has been detected, setting up guest tools."
                    pacstrap /mnt virtualbox-guest-utils &>/dev/null
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
            microsoft ) 
                    info_print "Hyper-V has been detected, setting up guest tools."
                    pacstrap /mnt hyperv &>/dev/null
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
        esac
    }

#   Microcode
    microcode () {
    cpuinfo=$(grep vendor_id /proc/cpuinfo)
    if [[ "$cpuinfo" == *"AuthenticAMD"* ]]; then
        info_print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        info_print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
    }

#   Kernel choice  
    # Ask for kernel choice and define essential packages with related packages(example: headers)
    kernel_selector () {
        info_print "List of kernels:"
        info_print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
        info_print "2) Hardened: A security-focused Linux kernel"
        info_print "3) Longterm: Long-term support (LTS) Linux kernel"
        info_print "4) Zen Kernel: A Linux kernel optimized for desktop usage"
        input_print "Please select the number of the corresponding kernel (e.g. 1): " 
        read -r kernel_choice
        case $kernel_choice in
            1 ) kernel="linux" headers="linux-headers"
            return 0;;
            2 ) kernel="linux-hardened" headers="linux-hardened-headers"
            return 0;;
            3 ) kernel="linux-lts"  headers="linux-lts-headers"
            return 0;;
            4 ) kernel="linux-zen"  headers="linux-zen-headers"
            return 0;;
            * ) error_print "You did not enter a valid selection, please try again."
            return 1
        esac
    }

#   Console keyboard layout choice
    keyboard () {
        input_print "Please insert the keyboard layout to use in console (enter empty to use US, or \"/\" to look up for keyboard layouts): "
        read -r kblayout
        case "$kblayout" in
            '') kblayout="us"
            info_print "The standard US keyboard layout will be used."
            return 0;;
            '/') localectl list-keymaps
             clear
             return 1;;
            *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
                error_print "The specified keymap doesn't exist."
                return 1
            fi
            info_print "Changing console layout to $kblayout."
            loadkeys "$kblayout"
        return 0
        esac
    }

   #   Text editor
       terminalTextEditor="vim"
 #   Packages
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