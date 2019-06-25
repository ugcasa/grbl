#!/bin/bash
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019

version="0.2.0"

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

		set)
			settings $@
			error_code=$? 			
			;;

		project)
			project $@
			error_code=$? 			
			;;

		code)
			project git 
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

