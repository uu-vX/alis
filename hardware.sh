#!  /usr/bin/env bash

#   Virtualization detection
    virtualizationCheck () {
        hypervisor=$(systemd-detect-virt)
        case $hypervisor in
            kvm )   
                info_print "KVM has been detected, setting up guest tools."
                pacstrap /mnt qemu-guest-agent &>/dev/null
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
            vmware )   
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
    kernelSelector () {
        info_print "List of kernels:"
        info_print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
        info_print "2) Hardened: A security-focused Linux kernel"
        info_print "3) Longterm: Long-term support (LTS) Linux kernel"
        info_print "4) Zen Kernel: A Linux kernel optimized for desktop usage"
        input_print "Please select the number of the corresponding kernel (e.g. 1): " 
        read -r kernel_choice
        case $kernel_choice in
            1 ) kernel="linux"
            return 0;;
            2 ) kernel="linux-hardened"
            return 0;;
            3 ) kernel="linux-lts"
            return 0;;
            4 ) kernel="linux-zen"
            return 0;;
            * ) error_print "You did not enter a valid selection, please try again."
            return 1
        esac
    }

#   Graphics processing unit code
    gpucode () {
    gpuinfo=$(lshw -class display | grep vendor)
    if [[ "$gpuinfo" == *"Intel"* ]]; then
            info_print "An Intel GPU has been detected, the Intel software will be installed."
            mkinitcpioModules+=" i915 "
            gpuPackages+=" xf86-video-intel "
        if [[ "$gpuinfo" == *"AuthenticAMD"* ]]; then
            info_print "An AMD GPU has been detected, the AMD software will be installed."
            mkinitcpioModules+=" amdgpu "
            gpuPackages+=" xf86-video-amdgpu "
        fi
        if [[ "$gpuinfo" == *"NVIDIA"* ]]; then
            info_print "An NVIDIA GPU has been detected, the NVIDIA software will be installed."
            mkinitcpioModules+=" nvidia "
            gpuPackages+=" nvidia nvidia-utils nvidia-settings "
        fi
        else
            info_print "not detected."
    fi
    }

#   Hardware preferences
    hardwareInfoSelector () {
        until virtualizationCheck; do : ; done
        until microcode; do : ; done
        until kernelSelector; do : ; done

    #           FIX         

#   System configuration
    #   Generating /etc/fstab
        genfstab -U /mnt >> /mnt/etc/fstab
        arch-chroot /mnt
    #   Synchronize System Clock with the Hardware Clock
        hwclock --systohc
    # Generating locales.
        locale-gen &>/dev/null

    #   Create a new reproducible initramfs
    sed -i "s/^MODULES=()/MODULES=(${mkinitcpioModules})/" /etc/mkinitcpio.conf
    sudo mkinitcpio -p "$kernel"
 
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    exit
    umount -a

    #until here
    
    }
