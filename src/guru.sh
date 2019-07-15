#!/bin/bash
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019

version="0.2.5"

export GURU_USER="$USER"
export GURU_BIN=$HOME/bin
export GURU_CFG=$HOME/.config/guru

. $HOME/.gururc
. $GURU_BIN/functions.sh

command="$1"
shift

case $command in 

		status)
			status $@
            ;;  

		set)
			settings $@
			error_code=$? 			
			;;

		notes)
			notes.sh $@
			error_code=$? 			
			;;

		project)
			project $@
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

		play)
			play.sh $@
			;;
		
		document)
			dozer $@
			;;

		disable)
			disable
			;;

		silence|-i)
			fade_low
			guru play stop
			error_code=$?
			;;

		uninstall)
			uninstall
			;;

		upgrade)
			upgrade
			;;

		install|-i)
			installer.sh $@
			error_code=$?
			;;

		demo)
			guru play demo $@
			;;

		fuck_you|fu)
			guru play vt monkey
			error_code=$?
			;;

		--test|-t)
			test_guru $@
			error_code=$? 			
			;;

		--ver|version)
			printf "$0 version $version\n"
			;;

		--help|-h|help|*)
		 	printf "ujo.guru command line toolkit @ $(guru version) \n"
		 	printf "usage: guru [TOOL] [COMMAND] [VARIABLES] \ncommands: \n"
			printf 'timer     timing tools ("guru timer help" for more info) \n'
			printf 'notes     open daily notes \n'
			printf 'project   opens project to edotor \n'
			printf 'document  turns markdown to libre office file using templates \n'
			printf 'play      play videos and music ("guru play help" for more info) \n'			
			printf 'phone     get data from android phone \n'
			printf 'stamp     timestamp to clopboard and terminal\n'
			printf 'silence   kill all audio and lights \n'
			printf 'demo      run demo ("guru set audio true" to play with audio)\n'			
			printf 'status    status of guru user \n'
			printf 'install   install tools: conda|django \n'
			printf 'set       set options ("guru set help" for more information)' 
			printf 'disable   disables guru toolkit \n'
			printf 'upgrade   upgrade giocon.client \n'
			printf 'uninstall uninstall guru toolkit \n'
			printf 'version   printout version \n'
esac	

[ -z $error_code ] || logger "$0 $command: $error_code"
exit $error_code

