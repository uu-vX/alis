#!/usr/bin/env bash
:' 
    TO-DO :
    1- Add  bspwm/sxhkdrc
    2- 
'

#   Human-machine interaction interface
    ws="xorg "#   Window System
    dm=""    #   Display Manager
    #   Window Manager
        wm="bspwm sxhkd "    # bspwm/sxhkdrc Btrfs Sxhkd
    
    hmi=" ${ws} ${wm}"


    workFlow="rofi ranger pdftoppm ueberzug "
        

   #   Application
       applications="${developmentEnvironment} ${webBrowser}"
       developmentEnvironment="  "
       webBrowser=" qutebrowser "
       electronicComputer-aidedDesign=" KiCad FreeCAD "
          #kvm
          #transmission-cli
      
sudo pacman -S ${hmi} ${workFlow} ${applications}

sudo mkdir -p /home/$USER/.config/bspwm && touch /home/$USER/.config/bspwm/bspwmrc
sudo mkdir -p /home/$USER/.config/sxhkd/ && touch /home/$USER/.config/sxhkd/sxhkdrc
sudo chmod 774 /home/$USER/.config/bspwm/bspwmrc
sudo chmod 774 /home/$USER/.config/sxhkd/sxhkdrc

cp ./interface/bspwm/bspwmrc /home/$USER/.config/bspwm/bspwmrc
cp ./interface/bspwm/sxhkdrc /home/$USER/.config/bspwm/sxhkdrc
cp ./interface/bspwm/autostart /home/$USER/.config/bspwm/autostart

