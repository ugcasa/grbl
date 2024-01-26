#!/bin/bash
#guru-cli caps-launcher.sh
source $HOME/.gururc
source os.sh

# set capslock off if its on. user can active capsloc by pressin 'capslock+ca' of 'gr os capslock on'
if os.capslock state ; then
	os.capslock off
	exit 0
fi

gnome-terminal --hide-menubar --geometry 8x1 --zoom 2.5 --hide-menubar --title "caps-launcher"  -- $GURU_BIN/caps-launcher.sh
