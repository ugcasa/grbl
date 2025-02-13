#!/bin/bash
#grbl caps-launcher.sh
source $HOME/.grblrc
source os.sh

# set capslock off if its on. user can active capsloc by pressin 'capslock+ca' of 'gr os capslock on'
if os.capslock state ; then
	os.capslock off
	exit 0
fi

gnome-terminal --hide-menubar --geometry 1x1 --zoom 3 --hide-menubar --title "caps-launcher"  -- $GRBL_BIN/caps-launcher.sh
