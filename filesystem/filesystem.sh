#!  /usr/bin/env bash

fileSystemSelector () {
   #   Choosing the target for the installation.
   info_print "Available disks for the installation:"
   PS3="Please select the number of the corresponding disk (e.g. 1): "
   select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
   do
      DISK="$ENTRY"
      info_print "Arch Linux will be installed on the following disk: $DISK"
      break
   done

#   Warn user about deletion of old partition scheme.
   input_print "This will delete the current partition table on $DISK once installation starts. Do you agree [y/N]?: "
   read -r disk_response
   if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
      error_print "Quitting."
      exit
   fi
   info_print "Wiping $DISK."
   wipefs -af "$DISK" &>/dev/null
   sgdisk -Zo "$DISK" &>/dev/null
   fileSystemTypeSelector
}
fileSystemTypeSelector (){
   sh ./filesystem/btrfs.sh
   fileSystem=" grub-btrfs btrfs-progs "
   mkinitcpioModules+=" btrfs "
}