#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 

export GURU_USER="$USER"
export GURU_BIN=$HOME/bin
export GURU_CFG=$HOME/.config/guru

bashrc="$HOME/.bashrc"
disable="$HOME/.gururc.disabled"

## check and permissions to edit

if grep -q ".gururc" "$bashrc"; then
	echo "Already installed, run gio.uninstall before re-install. To apply changes system wide pls. logout, or"	
	read -p "force re-install [y/n] : " edit	
	if ! [[ "$edit" == "y" ]]; then
		echo "aborting.. modifications are needed to run giocon client"
		exit 2
	fi
	reinstall=true
fi

if [ "$1" ]; then 
	platform="$1"
else
	platform="desktop" 
fi

if [ "$platform" == "server" ] || ! [ "$platform" == "desktop" ]; then 
	echo '"server" of "desktop" are only valid platforms'
	exit 3
fi



# read -p "modifying .bashrc file [y/n] : " edit	
# if ! [[ "$edit" == "y" ]]; then
# 	echo "aborting.. modifications are needed to run giocon client"
# 	exit 2
# fi	


### .bashrc

if ! $reinstall; then 
	[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
	cat ./src/tobashrc.sh >>"$bashrc"
fi

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

git --version 	>/dev/null|| sudo apt install git
ls /usr/bin/mosquitto_pub >>/dev/null|| sudo apt install mosquitto-clients

if [ $platform == "desktop" ]; then 
	pandoc -v 		>/dev/null|| sudo apt install pandoc
	echo "installed" |xclip -i -selection clipboard >/dev/null || sudo apt install xclip
	subl -v 		>/dev/null|| sudo apt install sublime-text
	dconf help >/dev/null || sudo apt install dconf-cli
fi


### keyboard bindings (for cinnamon only)


if [ $platform == "desktop" ]; then 

	# read -p "set keyboard bindings? :" answer
	# if [ "$answer" == "y" ]; then 
	# 	current=$HOME/.kbbind.backup.cfg
		new=./cfg/kbbind.guruio.cfg
			
		if [ ! -f $current ]; then 		
			dconf dump /org/cinnamon/desktop/keybindings/ > $current && cat $current |grep binding=
		fi

		# read -p "WARNING! WILL OWERWRITE CURRENT SETTINGS! Continue? :" answer
		# if [ "$answer" == "y" ]; then 
			dconf load /org/cinnamon/desktop/keybindings/ < $new
		# else
			# echo "Canceled - no changes made"
		# fi
	# fi
fi

echo "success, logout to apply settings system wide."


