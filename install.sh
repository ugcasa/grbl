#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 2019

bashrc="$HOME/.bashrc"
disable="$HOME/.gururc.disabled"
gio_bin="/opt/gio/bin"
gio_cfg="$HOME/.config/gio"
gio_log="/tmp"



## check and permissions to edit

if grep -q ".gururc" "$bashrc"; then
	echo "Already installed, run gio.uninstall before re-install. To apply changes system wide pls. logout"
	exit 1
fi

read -p "modifying .bashrc and .profile files [Y/n] : " edit	
if [[ "$edit" == "n" ]]; then
	echo "aborting.. modifications are needed to run giocon client"
	exit 2
fi	

### .bashrc

[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
cat ./src/tobashrc.sh >>"$bashrc"

### .profile

if ! grep -q "$gio_bin" "$HOME/.profile"; then
	[ -f "$HOME/.profile.giobackup" ] || cp -f "$HOME/.profile" "$HOME/.profile.giobackup"
	cat ./src/toprofile.sh >>"$HOME/.profile"
fi


## folder structure copy files

[ -d $gio_cfg ] || mkdir -p $gio_cfg
[ -d $gio_bin ] || sudo mkdir -p $gio_bin
[ -d $gio_log ] || sudo mkdir -p $gio_log

[ -f $disable ] && rm -f $disable 			# remove gio.disabler file
cp -f ./src/gururc.sh "$HOME/.gururc"
cp -f ./cfg/* "$gio_cfg"
sudo cp -f ./src/notes.sh "$gio_bin/gio.notes"
sudo cp -f ./src/stamp.sh "$gio_bin/gio.stamp"
sudo cp -f ./src/timer.sh "$gio_bin/gio.timer"
sudo cp -f ./src/datestamp.py "$gio_bin/gio.datestamp"
sudo cp -f ./src/phoneflush_lite.sh "$gio_bin/gio.phone"


## check and install requirements

git --version 	|| sudo apt install git
pandoc -v 		|| sudo apt install pandoc
xclip -version  || sudo apt install xclip
subl -v 		|| sudo apt install sublime-text
ls /usr/bin/mosquitto_pub || sudo apt install mosquitto-clients


### keyboard bindings (for cinnamon only)


read -p "set keyboard bindings? :" answer
if [ "$answer" == "y" ]; then 
	dconf help >/dev/null || sudo apt install dconf-cli
	current=$HOME/.kbbind.backup.cfg
	new=./cfg/kbbind.guruio.cfg
		
	if [ ! -f $current ]; then 		
		dconf dump /org/cinnamon/desktop/keybindings/ > $current && cat $current |grep binding=
	fi

	read -p "WARNING! WILL OWERWRITE CURRENT SETTINGS! Continue? :" answer
	if [ "$answer" == "y" ]; then 
		dconf load /org/cinnamon/desktop/keybindings/ < $new
	else
		echo "Canceled - no changes made"
	fi
fi


echo "success, logout to apply settings system wide."



