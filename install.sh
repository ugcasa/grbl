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

[ "$1" ] && platform="$1" || platform="desktop"


## Common files

### .bashrc
[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
grep -q ".gururc" "$bashrc" || cat ./src/tobashrc.sh >>"$bashrc"

## folder structure copy files
[ -d $GURU_CFG ] || mkdir -p $GURU_CFG
[ -d $GURU_BIN ] || mkdir -p $GURU_BIN

[ -f $disable ] && rm -f $disable 			# remove gio.disabler file
cp -f ./src/gururc.sh "$HOME/.gururc"
. $HOME/.gururc
cp -f ./src/guru.sh "$GURU_BIN/$GURU_CALL"
cp -f ./cfg/* "$GURU_CFG"
cp -f ./src/* -f "$GURU_BIN"
cp -f ./src/datestamp.py "$GURU_BIN/gio.datestamp"

## Common debian requirements
git --version >/dev/null || sudo apt install git
[ -f /usr/bin/mosquitto_pub ] || sudo apt install mosquitto-clients
pip3 help >/dev/null || sudo apt install python3-pip

case $platform in 

	desktop|cinnamon) # debian/ubuntu/mint
	
		subl -v >/dev/null || sudo apt install sublime-text
		pandoc -v >/dev/null || sudo apt install pandoc		
		echo "installed" |xclip -i -selection clipboard >/dev/null || sudo apt install xclip

		# mint/cinnamon 
		dconf help >/dev/null || sudo apt install dconf-cli
		new=./cfg/kbbind.guruio.cfg				
		if [ ! -f $current ]; then 		
			dconf dump /org/cinnamon/desktop/keybindings/ > $current && cat $current |grep binding=
		fi
		dconf load /org/cinnamon/desktop/keybindings/ < $new
		
		# set up		
		# mpsyt --version || guru install mpsyt
		# guru set audio true
		;;

	server)	# Server/ubuntu server no gui
	
		# debian
		joe --help >/dev/null || sudo apt install joe

		# set up
		# guru set audio false
		;;


	rpi) # Rasberrypi/rasbian
		echo "TODO"
		;;
	*)
		echo "non valid platform"
		exit 4
esac

echo "successfully installed"


