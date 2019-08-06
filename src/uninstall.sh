#!/bin/bash

uninstall () {	 

	if [ ! -f "$HOME/.bashrc.giobackup" ]; then 
		echo "not installed, aborting.."
		return 135
	fi		

	if [ -f $HOME/.gururc ]; then 
		 . $HOME/.gururc 
	else
		echo "no variables setup file exists, aborting.."
		return 136	
	fi	

	if [ $GURU_BIN == "" ]; then 
		echo "no environment variables set, aborting.."
		return 137		
	fi

#	printf "1:$HOME/.bashrc.giobackup \n2:$HOME/.gururc \n3:$GURU_BIN/$GURU_CALL $HOME/.kbbind.backup.cfg \n4:$GURU_CFG\n"
	mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"		
	rm -f "$HOME/.gururc"	
	rm -f "$GURU_BIN/$GURU_CALL"		
	rm -fr "$GURU_CFG"
	
	if [[ -f "$HOME/.kbbind.backup.cfg" ]]; then 
		dconf load /org/cinnamon/desktop/keybindings/ < $HOME/.kbbind.backup.cfg
	fi
	
	case "$GURU_INSTALL" in 			# Installation type 

		desktop)			
			;;
		server)			
			;;
			*)
			
	esac
	
	#rm -f "$GURU_BIN"				# TODO: own folder meaby?
	echo "successfully un-installed"
	return 0
}


remove-sw() { 		
	# not fully tested
	echo "pandoc xterm dconf-cli mosquitto-clients mps-youtube youtube_dl mpsyt"
	sudo apt remove pandoc xterm dconf-cli mosquitto-clients
	#rm /usr/bin/mpsyt
	#pip3 remove mps-youtube youtube_dl 
	
	if [ "$1" == "all" ]; then 
		echo "sublime-text git setuptools "
		#sudo apt remove sublime-text git 
		#pip3 remove setuptools 

	fi
}


command=$1
shift

case "$command" in 
	
	software)
		remove-sw $@
		exit $?
		;;

	*)
		uninstall $@
		exit $?

esac

