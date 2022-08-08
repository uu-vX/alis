#!/usr/bin/env bash
:' 
    TO-DO :

'
#   Install packages
   network=" networkManager network-manager-applet wpa_supplicant inetutils "
       # AUR helper
       git clone https://aur.archlinux.org/yay
       cd yay
       makepkg -si PKGBUILD
 
   # GPU
   mkinitcpioModules+="i915 "
   mkinitcpioModules+="nvidia "
      
   gpuDriver+="xf86-video-intel"
   #gpuDriver+="xf86-video-amdgpu"
   gpuDriver+="nvidia nvidia-utils nvidia-settings"
   gpuSoftware=" nvidia-prime glxinfo" #to handle GPU switching #prime-run 'applicationName'
      
#   Utilities
  
   pacman -S  ${headerAndScript} base-devel xdg-utils xdg-user-dirs mtools dosfstools bash-completion dialog efibootmgr ${gpuDriver} ${powerManagement} ${ssecureManagement} xterm ${gpuSoftware} pulseaudio pulseaudio-bluetooth alsa-utils bluez blue-utils cups

   yay -S snap-pac-grub snapper-gui optimus-manager optimus-manager-qt

#   Gaming
#   System configuration
       sed -i "s/^MODULES=()/MODULES=(${mkinitcpioModules})/" /etc/mkinitcpio.conf
       sudo mkinitcpio -p ${kernelPackage}
 
       grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi
       grub-mkconfig -o /boot/grub/grub.cfg
 
       sudo systemctl enable NetworkManager
       sudo systemctl enable bluetooth
       sudo systemctl enable cups
       sudo systemctl enable avahi-daemon
       sudo systemctl enable firewalld
       sudo systemctl enable auto-cpufreq
       sudo systemctl enable acpid
       sudo systemctl enable acpi
       sudo systemctl enable acpi_call
       sudo systemctl enable tlp
       sudo systemctl enable tld-rdw
       sudo systemctl enable powertop
 
   #   Configure the power management of the system
   powerManagement=" auto-cpufreq acpid acpi acpi_call tlp tlp-rdw powertop "
 
   #   Configure the system's secure
   #secureManagement=" firewalld "
   
   #   Human-machine interaction interface
   sh ./hmi.sh