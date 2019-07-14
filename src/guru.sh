#!/bin/bash
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019

version="0.2.3"

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
			install $@
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
		 	printf "ujo.guru command line toolkit @ $(guru version)\n"
		 	printf "Usage guru [TOOL] [COMMAND] [VARIABLES]\n"
            echo "Commands:"            
			printf 'notes     \t open daily notes \n'
			printf 'set       \t sets options:  editor|conda\n' 
			printf 'project   \t opens project to edotor \n'
			printf 'timer     \t timing tools ("guru timer help" for more info) \n'
			printf 'stamp     \t timestamp to clopboard and terminal\n'
			printf 'phone     \t get data from android phone \n'
			printf 'status    \t status of guru user \n'
			printf 'play      \t play videos and music ("guru play help" for more info) \n'			
			printf 'document  \t turns markdown to libre office file using templates \n'
			printf 'disable   \t disables guru toolkit \n'
			printf 'silence   \t kill all audio and lights \n'
			printf 'uninstall \t uninstall guru toolkit \n'
			printf 'install   \t install tools: conda|django \n'
			printf 'version   \t printout version \n'
esac	

[ -z $error_code ] || logger "$0 $command: $error_code"
exit $error_code

