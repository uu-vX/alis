#!  /usr/bin/env bash
:' 
    TO-DO :
'
#   Automated Arch Linux Installer
    installer () {
    #   Cleaning the TTY
        clear
    #   File system (Creates and manipulates partition tables and partitions on a storage.)
        source filesystem.sh
        until fileSystemSelector; do : ; done
    #   Setting user preferences
        source user.sh
        until userInfoSelector; do : ; done
        source hardware.sh
        until hardwareInfoSelector; do : ; done
        source packages.sh
        until basePackagesInstaller; do : ; done
        until packagesInstaller; do : ; done
        until aurPackagesInstaller; do : ; done
        #   Personification : my dot files
        #   Post-installation
        until serviceManager; do : ; done
        until cleanSnapshot; do : ; done
    }


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
    pacman -S --noconfirm --needed gptfdisk glibc

#   Installer
until installer; do : ; done

#   Post-installation

    #   Personification



