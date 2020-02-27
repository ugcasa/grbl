#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 

GURU_CALL="guru"
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru

source src/lib/common.sh
source src/keyboard.sh

check_python_module () {			# Does work, but returns funny
	python -c "import $1"; 	
	return $?
}

target_rc="$HOME/.bashrc"
disabler_flag_file="$HOME/.gururc.disabled"

## already installed? reinstall?

if grep -q ".gururc" "$target_rc"; then	
	read -p "already installed, force re-install [y/n] : " answer	
	if ! [[ "$answer" == "y" ]]; then
		echo "aborting.."
		exit 2
	fi	
	[ -f "$GURU_BIN/uninstall.sh" ] && bash "$GURU_BIN/uninstall.sh" || echo "uninstaller not found"
fi

# Default is server

 if [ "$1" ]; then 
 	platform="$1"
 else
 	lsb_release -crid | grep "Mint" >/dev/null && platform="desktop" || platform="server"
 fi

### .bashrc

[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$target_rc" "$HOME/.bashrc.giobackup"
grep -q ".gururc" "$target_rc" || cat ./src/tobashrc.sh >>"$target_rc"

[ -f "$disabler_flag_file" ] && rm -f "$disabler_flag_file" 	

## folder structure copy files

cp -f ./src/gururc.sh "$HOME/.gururc"
source $HOME/.gururc													# rise default environmental variables

[ -d $GURU_BIN ] || mkdir -p $GURU_BIN
[ -d $GURU_CFG ] || mkdir -p $GURU_CFG
[ -d $GURU_APP ] || mkdir -p $GURU_APP
cp -f ./src/guru.sh "$GURU_BIN/guru"							# to able to call just "guru"
cp -f ./cfg/* "$GURU_CFG"										# guru toolkit configurations
cp -f -r ./src/* -f "$GURU_BIN"									# guru toolkit scripts
cp -f ./src/datestamp.py "$GURU_BIN/gio.datestamp"  			# compatibility bubblegum

## Basic requirements, even dough user cannot get this far whit out these 

git --version >/dev/null || sudo apt install git
pip3 help >/dev/null || sudo apt install python3-pip

platform=$(check_distro)

case "$platform" in 
	
	linuxmint) 
		echo "installed" | xclip -i -selection clipboard >/dev/null || sudo apt install xclip
		xterm -v >/dev/null || sudo apt install xterm		
		dconf help >/dev/null || sudo apt install dconf-cli
		add_cinnamon_guru_shortcuts 
		;;

	ubuntu)	# Server/ubuntu server no gui		
		joe --help >/dev/null || sudo apt install joe
		add_ubuntu_guru_shortcuts
		;;


	rpi) # Rasberrypi/rasbian
		echo "TODO"
		;;
	*)
		echo "non valid platform"
		exit 4
esac

counter add guru-installed >/dev/null
echo "successfully installed"
exit 0



