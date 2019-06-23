#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 2019

export GURU_USER="$USER"
export GURU_BIN=$HOME/bin
export GURU_CFG=$HOME/.config/guru

bashrc="$HOME/.bashrc"
disable="$HOME/.gururc.disabled"

## check and permissions to edit

if grep -q ".gururc" "$bashrc"; then
	echo "Already installed, run gio.uninstall before re-install. To apply changes system wide pls. logout"
	exit 1
fi

read -p "modifying .bashrc file [Y/n] : " edit	
if [[ "$edit" == "n" ]]; then
	echo "aborting.. modifications are needed to run giocon client"
	exit 2
fi	

### .bashrc

[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
cat ./src/tobashrc.sh >>"$bashrc"

## folder structure copy files

[ -d $GURU_CFG ] || mkdir -p $GURU_CFG
[ -d $GURU_BIN ] || mkdir -p $GURU_BIN

[ -f $disable ] && rm -f $disable 			# remove gio.disabler file
cp -f ./src/gururc.sh "$HOME/.gururc"
cp -f ./src/guru.sh "$GURU_BIN/guru"
cp -f ./cfg/* "$GURU_CFG"
cp -f ./src/* -f "$GURU_BIN"
cp -f ./src/datestamp.py "$GURU_BIN/gio.datestamp"

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



