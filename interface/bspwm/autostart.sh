#!  /usr/bin/env bash

#	Autostart
sxhkd	&
picom	&
feh	--bg-fill --randomize ~/uuvx/wallpaper/* &
xrandr --rate 144	&
#~/.config/polybar/launch.sh
#redshift &
#telegram-desktop &