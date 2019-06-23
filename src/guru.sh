#!/bin/bash
version="0.2.0"
# Bin:
# - >`/opt/bin` -> `~/bin`
# - -`.profiles` muokkausta ei tarvita
# - +`~/bin`
# - +`~/bin/guru` kutsuu ja välittää argumentit työkaluille - DONE
# Conffit:
# - >`~/.config/guru.io`  ja , `~/.config/gio` -> `~/.config/guru`
# - +`~/.config/guru/guru.conf` <- guru framework bash konfiburaatio 

export GURU_USER="$USER"
export GURU_BIN=$HOME/bin
export GURU_CFG=$HOME/.config/guru

. $GURU_BIN/functions.sh

command="$1"
shift

case $command in 

		notes)
			notes.sh $@
			error_code=$? 			
			;;

		project)
			subl_project $@
			error_code=$? 			
			;;

		code)
			subl_project git 
			error_code=$? 	
			;;

		timer)
			timer.sh $@
			error_code=$? 			
			;;

		stamp)
			stamp.sh $@
			error_code=$? 			
			;;

		phone)
			phoneflush-lite.sh $@
			;;

		status)
			status $@
			;;

		play)
			play.sh $@
			;;

		document)
			dozer $@
			;;

		disable)
			disable
			;;

		uninstall)
			uninstall
			;;

		--test|-t)
			test_guru $@
			error_code=$? 			
			;;

		--ver|version)
			printf "$0 version $version\n"
			;;

		--help|-h|help|*)
		 	printf "Usage $0 [TOOL] [COMMAND] [VARIABLES]\n"

esac	

[ -z $error_code ] || logger "$0 $command: $error_code"
exit $error_code

