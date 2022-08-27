#!  /usr/bin/env bash

#   Console keyboard layout choice
    keyboardSelector () {
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
#   Setting up a password for the user account
    userSelector () {
        input_print "Please enter name for a user account (enter empty to not create one): "
        read -r username
        if [[ -z "$username" ]]; then
            return 0
        fi
        input_print "Please enter a password for $username (you're not going to see the password): "
        read -r -s userpass
        if [[ -z "$userpass" ]]; then
            echo
            error_print "You need to enter a password for $username, please try again."
            return 1
        fi
        echo
        input_print "Please enter the password again (you're not going to see it): " 
        read -r -s userpass2
        echo
        if [[ "$userpass" != "$userpass2" ]]; then
            echo
            error_print "Passwords don't match, please try again."
            return 1
        fi
        return 0
    }
#   Setting up the hostname
    hostnameSelector () {
        input_print "Please insert the hostname.(Enter empty to use same as username): "
        read -r hostname
        if [ -z $hostname ]; then
            hostname="$username"
            echo "$hostname" > /mnt/etc/hostname
            echo "127.0.0.1 localhost" >> /mnt/etc/hostname
            echo "::1       localhost" >> /mnt/etc/hostname
            echo "127.0.1.1 $hostname.localdomain $hostname" >> /mnt/etc/hostname
        else
            echo "$hostname" > /mnt/etc/hostname
            echo "127.0.0.1 localhost" >> /mnt/etc/hostname
            echo "::1       localhost" >> /mnt/etc/hostname
            echo "127.0.1.1 $hostname.localdomain $hostname" >> /mnt/etc/hostname
        fi
    }
#   Setting up a password ford the root account 
    rootpassSelector () {
        input_print "Please enter a password for the root user (you're not going to see it): "
        read -r -s rootpass
        if [[ -z "$rootpass" ]]; then
            echo
            error_print "You need to enter a password for the root user, please try again."
            return 1
        fi
        echo
        input_print "Please enter the password again (you're not going to see it): " 
        read -r -s rootpass2
        echo
        if [[ "$rootpass" != "$rootpass2" ]]; then
            error_print "Passwords don't match, please try again."
            return 1
        fi
        return 0
    }

#   Setting user preferences
    userInfoSelector () {
        until keyboardSelector; do : ; done
        until userSelector; do : ; done
        until hostnameSelector; do : ; done
        until rootpassSelector; do : ; done

        #   Configure timezone
        ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime

        # Configure locale
        sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
        echo "LANG=$locale" > /mnt/etc/locale.conf

        # Configure console keymap
        echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

        #   Adding user account
        useradd -m "$username"
        echo "$username":"$userpass" | chpasswd
        echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/"$username"

        #   Provide root privileges to users
        sed -i 's/^# %ALL=(ALL:ALL) ALL/%ALL=(ALL:ALL) ALL/' /etc/pacman.conf

        #   Setting root password
        echo "root:$rootpass" | arch-chroot /mnt chpasswd
        }

