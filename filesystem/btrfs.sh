#!  /usr/bin/env bash

#   B-Tree Filesystem(BTRFS) & Snapper 

#   Creating a new partition scheme.
    info_print "Creating the partitions on $DISK."
    parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 520MiB \
    set 1 esp on \
    mkpart primary linux-swap 520MiB 16520MiB \
    set 2 swap on \
    mkpart primary btrfs 16520MiB 100% \
    set 3 root on \

    ESP="/dev/disk/by-partlabel/ESP"

#   Informing the Kernel of the changes.
    info_print "Informing the Kernel about the disk changes."
    partprobe "$DISK"

#   Formatting the ESP as FAT32.
    info_print "Formatting the EFI Partition as FAT32."
    mkfs.fat -F 32 "$ESP" &>/dev/null

#   Formatting the BTRFS
    info_print "Formatting the BTRFS."
    mkfs.btrfs "$BTRFS" &>/dev/null
    mount "$BTRFS" /mnt

#   Configure the file system
    subvols=(.snapshots root home srv var)
    mountopts="noatime,compress=lzo,space_cache=v2,discard=async"

#   Creating BTRFS subvolumes
    info_print "Creating BTRFS subvolumes."
    for subvol in '' "${subvols[@]}"; do
        echo    " btrfs subvolume create /mnt/@"$subvol" &>/dev/null "
    done
    umount /mnt

#   Mounting the newly created subvolumes
    for subvol in "${subvols[@]:1}"; do
        echo " mount -o "$mountopts",subvol=@"$subvol" "$BTRFS" /mnt/"${subvol//_//}" "
    done
    snapper -c root create-config /
    mkdir -p /mnt/{home,root,srv,.snapshots,var/{log,cache/pacman/pkg},boot} #?
    chmod 750 /mnt/root 
    chmod 759 /.snapshots
    mount -o "$mountopts",subvol=@snapshots "$BTRFS" /mnt/.snapshots

    mount -o nodatacow,subvol=@var "$BTRFS" /mnt/var
    chattr +C /mnt/var/log
    mount "$ESP" /mnt/boot/

#   Snapper timeline
    aurPackages+=( "snap-pac-grub" "snapper-gui" )

    sed -i "s/^ALLOW_USERS=""/ALLOW_USERS="${username}"/" /etc/snapper/configs/root
    sed -i "s/^TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/" /etc/snapper/configs/root
    sed -i "s/^TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="8"/" /etc/snapper/configs/root
    sed -i "s/^TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="10"/" /etc/snapper/configs/root
    sed -i "s/^TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="7"/" /etc/snappers/config/root
    sed -i "s/^TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/" /etc/snapper/configs/root

    chown :${username} /.snapshots/

    sudo systemctl enable snapper-timeline.timer && sudo systemctl start snapper-timeline.timer
    sudo systemctl enable snapper-cleanup.timer && sudo systemctl start snapper-cleanup.timer
    sudo systemctl enable grub-btrfs.path && sudo systemctl start grub-btrfs.path
        
#   Hook
    sudo mkdir /etc/pacman.d/hooks
    sudo echo "[Trigger]" > /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Operation = Upgrade" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Operation = Install" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Operation = Remove" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Type = Path" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Target = boot/*" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "     " >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "[Action]" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Depends = rysnc" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Description = Backing up /boot..." >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "When = PreTransaction" >> /etc/pacman.d/hooks/95-bootbackup.hook
    sudo echo "Exec = /ustr/bin/rsync -a --delete /boot /.bootbackup" >> /etc/pacman.d/hooks/95-bootbackup.hook


cleanSnapshot () {
    snapper -c root list
    snapper -c root create -c timeline --description AfterInstall
    sudo btrfs property set -ts /.snapshots/1/snapshot/ ro false
}