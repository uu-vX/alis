#!/usr/bin/env bash
:' 
    TO-DO :

'
#   BTRFS Filesystem & Snapper 
   fileSystem="grub-btrfs btrfs-progs "
   mkinitcpioModules+="btrfs "
    #   Partition the disks
       (
       echo g; #GPT
       echo n; # Add a new partition
       echo ;  # First sector (Accept default: 1)
       echo ;  # Last sector (Accept default: varies)
       echo +600M; # partition size     # ?ask for boot partition
 
       echo n; # Add a new partition
       echo ;  # First sector (Accept default: 1)
       echo ;  # Last sector (Accept default: varies)
       echo +17G; # partition size     # ?grep processor name
 
       echo n; # Add a new partition
       echo ;  # First sector (Accept default: 1)
       echo ;  # Last sector (Accept default: varies)
       echo ;  # partition size
 
       echo t; #
       echo 1;
       echo 1;
 
       echo t;
       echo ;
       echo 19; #
 
       echo w; # write changes to disk
       ) | sudo fdisk /dev/${disk}

    #   Format partitions
       mkfs.vfat -F32 -n 'BOOT' /dev/"${disk}1"
       mkswap -L 'SWAP' /dev/"${disk}2"
       mkfs.btrfs -L 'FILESYSTEM' /dev/"${disk}3"

    #   Mount the file systems
       swapon /dev/"${disk}2"
       mount /dev/"${disk}3" /mnt/boot
       mount /dev/"${disk}1" /mnt
    #   Create subvolume
       btrfs subvolume create /mnt/@
       btrfs subvolume create /mnt/@home
       btrfs subvolume create /mnt/@var
       btrfs subvolume create /mnt/@snapshots
       umount /mnt
   #   Mount the subvolume
       mount -o noatime,compress=lzo,space_cache=v2,subvol=@ /dev/"${disk}3" /mnt
       mount -o noatime,compress=lzo,space_cache=v2,subvol=@home /dev/"${disk}3" /mnt/home
       mount -o noatime,compress=lzo,space_cache=v2,subvol=@var /dev/"${disk}3" /mnt/var
 
       snapper -c root create-config /
       mount -o noatime,compress=lzo,space_cache=v2,subvol=@snapshots /dev/"${disk}3" /mnt/.snapshots
      
       sed -i "s/^ALLOW_USERS=""/ALLOW_USERS="${username}"/" /etc/snapper/config/root
       sed -i "s/^TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/" /etc/snapper/config/root
       sed -i "s/^TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="8"/" /etc/snapper/config/root
       sed -i "s/^TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="10"/" /etc/snapper/config/root
       sed -i "s/^TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="7"/" /etc/snapper/config/root
       sed -i "s/^TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/" /etc/snapper/config/root
      
   #   Encrypting an entire system
   #   Configure the file system
 
       #   Hook
           sudo mkdir /etc/pacman.d/hooks
           sudo echo "[Trigger]" > /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Operation = Upgrade" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Operation = Install" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Operation = Remove" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Type = Path" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Target = boot/*" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "     " >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "[Action]" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Depends = rysnc" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Description = Backing up /boot..." >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "When = PreTransaction" >> /etc/pacman.d/hooks/50-bootbackup.hook
           sudo echo "Exec = /ustr/bin/rsync -a --delete /boot /.bootbackup" >> /etc/pacman.d/hooks/50-bootbackup.hook
 
    chmod a+rx /.snapshots/
    chown :${username} /.snapshots/
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
    systemctl start snapper-timeline.timer
    systemctl start snapper-cleanup.timer
    systemctl enable grub-btrfs.path
    systemctl start grub-btrfs.path
