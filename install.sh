#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 

export GURU_USER="$USER"
export GURU_BIN=$HOME/bin
export GURU_CFG=$HOME/.config/guru

bashrc="$HOME/.bashrc"
disable="$HOME/.gururc.disabled"

## already installed? reinstall?

if grep -q ".gururc" "$bashrc"; then	
	
	read -p "already installed, force re-install [y/n] : " edit	
	if ! [[ "$edit" == "y" ]]; then
		echo "aborting.."
		exit 2
	fi
fi

# Default is desktop

if [ "$1" ]; then 
	platform="$1"
else
	platform="desktop" 
fi

## Common files

### .bashrc

[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
grep -q ".gururc" "$bashrc" || cat ./src/tobashrc.sh >>"$bashrc"

## folder structure copy files
[ -d $GURU_CFG ] || mkdir -p $GURU_CFG
[ -d $GURU_BIN ] || mkdir -p $GURU_BIN

[ -f $disable ] && rm -f $disable 			# remove gio.disabler file
cp -f ./src/gururc.sh "$HOME/.gururc"
cp -f ./src/guru.sh "$GURU_BIN/guru"
cp -f ./cfg/* "$GURU_CFG"
cp -f ./src/* -f "$GURU_BIN"
cp -f ./src/datestamp.py "$GURU_BIN/gio.datestamp"

## Common requirements
git --version 	>/dev/null|| sudo apt install git
ls /usr/bin/mosquitto_pub >>/dev/null|| sudo apt install mosquitto-clients

case $platform in 

	desktop|cinnamon) # debian/ubuntu
	
		pandoc -v 		>/dev/null|| sudo apt install pandoc
		echo "installed" |xclip -i -selection clipboard >/dev/null || sudo apt install xclip
		subl -v 		>/dev/null|| sudo apt install sublime-text

		# mint/cinnamon 
		dconf help >/dev/null || sudo apt install dconf-cli
		new=./cfg/kbbind.guruio.cfg				
		if [ ! -f $current ]; then 		
			dconf dump /org/cinnamon/desktop/keybindings/ > $current && cat $current |grep binding=
		fi
		dconf load /org/cinnamon/desktop/keybindings/ < $new
		
		# set up
		guru set audio true
		;;


	server)	# Server/ubuntu server no gui
	
		# debian
		joe -v 		>/dev/null|| sudo apt install joe
		#ls /usr/bin/mosquitto server >>/dev/null|| sudo apt install mosquitto-server

		# set up
		guru set audio false
		;;


	rpi) # Rasberrypi/rasbian
		echo "TODO"
		;;
	*)
		echo "non valid plaform"
		exit 4
esac

echo "success, logout to apply settings system wide."


