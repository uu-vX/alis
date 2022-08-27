#!  /usr/bin/env bash

#   Human-machine interaction graphical user interface
    interfaceSelector () {
    info_print "List of graphical user interface:"
    info_print "1) Clean design: BSPWM (Binary Space Partitioning Window Manager)"
    info_print "2) Under development.!:[Beginner-Friendly: XFCE desktop environment]"
    input_print "Please select the number of the corresponding kernel (e.g. 1): " 
    read -r interfaceChoice
    case $interfaceChoice in
        #   bspwm/sxhkd
        1 ) #status bar??
            interface+=( "xorg" "bspwm" "sxhkd" "urxvtc" "feh" "rofi" "ranger" "pdftoppm" "ueberzug" "ncpamixer" "picom" "redshift" "geoclue" )
            applications+=( "qutebrowser" "chromium" )  #ncmpcpp mvp 
            workspace+=( "${interface[@]}" "${applications[@]}" )
            
            cp ./interface/bspwm/bspwmrc /home/$USER/.config/bspwm/bspwmrc && sudo chmod 774 /home/$USER/.config/bspwm/bspwmrc
            cp ./interface/bspwm/sxhkdrc /home/$USER/.config/sxhkd/sxhkdrc && sudo chmod 774 /home/$USER/.config/sxhkd/sxhkdrc
            cp ./interface/bspwm/autostart /home/$USER/.config/bspwm/autostart && sudo chmod 774 /home/$USER/.config/sxhkd/autostart
            #.xinitrc

            systemService+=" "
        return 0;;
        #   xfce
        2 ) interface=""
        return 0;;
        * ) error_print "You did not enter a valid selection, please try again."
        return 1
    esac
    }

#   Network management packages
    networkPackages=" networkManager network-manager-applet wpa_supplicant inetutils " 
    systemService+=( "NetworkManager" )
#   Power management packages
    powerManagementPackages=" auto-cpufreq acpid acpi acpi_call acpi-support tlp tlp-rdw powertop " 
    systemService+=( "auto-cpufreq" "acpid" "acpi" "acpi_call" "tlp" "tld-rdw" "powertop")
#   Graphics processing unit packages
    gpuPackages=" nvidia-prime glxinfo" #to handle GPU switching #prime-run 'applicationName'
    aurPackages+=( "optimus-manager" "optimus-manager-qt")
#   Audio packages
    audioPackages=" pulseaudio pulseaudio-alsa alsa-utils  " 
    
#   Utility packages
    utilityPackages= " base-devel xdg-utils xdg-user-dirs mtools dosfstools bash-completion dialog efibootmgr  cups " 
    systemService+=( "cups" )
    systemService+=( "avahi-daemon" )
    
#   Wireless packages
    wirelessPackages=" pulseaudio-bluetooth "
    systemService+=( "bluetooth" )
#   Security packages
    #securityPackages+=( "firewalld")
    #systemService+=( "firewalld" )

#   Pacman wrapper and Arch User Repository helper
    aurHelper="yay"
    aurHelper () {
        git clone https://aur.archlinux.org/"$aurHelper" && cd "$aurHelper"
        makepkg -si PKGBUILD && cd
    }

#   Arch user repository packages
    aurPackages+=( "snap-pac-grub" "snapper-gui" "optimus-manager" "optimus-manager-qt")
    
#   Gaming
    gamingPackages=" "

#   Arch user repository packages installation
    aurPackagesInstaller () {
        aurHelper
        for t in ${!aurPackages[@]}; do
            yay -S ${aurPackages[t]}
        done 
    }

#   Packages installation
    packagesInstaller () {
        until interfaceSelector; do : ; done
        for t in ${!packages[@]}; do
            sudo pacman -S --noconfirm --needed ${packages[t]}
        done
        for t in ${!workspace[@]}; do
            sudo pacman -S --noconfirm --needed ${workspace[t]}
        done 
    }

#   Install packages to the specified new root directory
    basePackagesInstaller () {
        textEditor=" vim "
        pacstrap /mnt base "$microcode" "$kernel" linux-firmware "$kernel"-headers "$textEditor" "$fileSystem"
    }

#   Service manager
    serviceManager () {
    for t in ${!systemService[@]}; do
        systemctl enable ${systemService[t]} && systemctl start ${systemService[t]}
    done
    }
