#!/bin/bash
# No Fucking Point to Clone Disaster 
# IN case of NFPCP: 
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019
# 
# In case of IOTSIHTOTBACM (installation of this shit in hindsight turned out to be a colossal mistake) do:
# guru uninstall; [ -d $GURU_CFG ] && rm /$GURU_CFG -rf 	# to get totally rig of this worm and all your personal configs



version="0.3.2"

. $HOME/.gururc 						# user and platform settings (implement here, always up to date)
. $GURU_BIN/functions.sh 				# common functions, if no ".sh", check here

main () {

	if [ $1 ]; then 					# guru without parameters starts terminal loop
		parse_argument $@ 
		error_code=$?
	else
		terminal 						# rsplib-legacy-wrappers name collision, not big broblem i think
		
		error_code=$?
	fi

	if (( error_code > 0 )); then
		
		[ -f $GURU_ERROR_MSG ] && error_message=$(tail -n 1 $GURU_ERROR_MSG)
		#error_message=$(cat -n 1 $GURU_ERROR_MSG)
		logger "$0 $argument: $error_code: $error_message"				# log errors
		echo "error: $error_code: $error_message"						# print error
		rm -f $GURU_ERROR_MSG
	fi

	return $error_code
}


parse_argument () {
	# parse arguments and delivery variables to corresponding application, function, bash script, python.. whatever

	argument="$1" 						# store original argument
	shift								# shift arguments left

	case $argument in 

	
			# os commands
			clear|ls|cd|ssh|echo) 
				$argument $@
				return $?
				;;          

			# functions (in functions.sh)
			status|counter|set|project|pro|disable|upgrade| \
					document|slack|terminal|trans|translate| \
					volume|vol|mute|stop|fadedown|fadeup|silence| \
					save|remove|relax)				
				$argument $@
				return $? 
	            ;;  

	        # bash scripts
			note|stamp|timer|phone|play|install|scan) 		
				$argument.sh $@
				return $? 			
				;;

			# python scripts
			uutiset)
				DISPLAY=:0 $argument.py $@
				return $? 			
				;;

			# jostain syystä täällä
			tor)
				[ -d $GURU_APP/tor-browser_en-US ] || guru install tor
				sh -c '"$GURU_APP/tor-browser_en-US/Browser/start-tor-browser" --detach || ([ !  -x "$GURU_APP/tor-browser_en-US/Browser/start-tor-browser" ] && "$(dirname "$*")"/Browser/start-tor-browser --detach)' dummy %k X-TorBrowser-ExecShell=./Browser/start-tor-browser --detach
				error_code=$?
				if (( error_code == 127 )); then 
					rm -rf $GURU_APP/tor-browser_en-US
					echo "failed, try re-install"
					return $error_code
				fi
				return 0
				;;

			# basic stuff
			version|ver|-v|--ver) 		# la versi on
				printf "giocon.client v.$version installed to $0\n"
				return 0
				;;

			uninstall)					# Get rid of this shit 
				bash $GURU_BIN/uninstall.sh $@
				return $? 
				;;


			help|-h|--help) 			# hardly never updated help printout
			 	printf "ujo.guru tool kit client v.$version \n"
			 	printf "usage: '$GURU_CALL' [TOOL] [COMMAND] [VARIABLES] \ncommand: \n"
				printf 'timer     timing tools ("'$GURU_CALL' timer help" for more info) \n'
				printf 'notes     open daily notes \n'
				printf 'project   opens project to editor \n'
				printf 'document  compile markdown to .odt format \n'
				printf 'play      play videos and music ("'$GURU_CALL' play help" for more info) \n'			
				printf 'phone     get data from android phone \n'
				printf 'stamp     time stamp to clipboard and terminal\n'
				printf 'silence   kill all audio and lights \n'
				printf 'terminal  start guru toolkit in terminal mode to exit terminal mode type "exit"\n'				
				printf 'demo      run demo ("'$GURU_CALL' set audio true" to play with audio)\n'			
				printf 'status    status of user \n'
				printf 'install   install tools ("'$GURU_CALL' install help" for more info) \n'
				printf 'set       set options ("'$GURU_CALL' set help" for more information) \n' 
				printf 'upgrade   upgrade guru toolkit \n'
				printf 'disable   disables guru toolkit type "guru.enable" to enable \n'
				printf 'uninstall remove guru toolkit \n'
				printf 'version   printout version \n'
				return 0
				;;
			
			"")					
				;;

			*)	
				printf "$argument: command not found\n"
	esac	
}


terminal() { 
	# Terminal looper	
	echo $GURU_CALL' in terminal mode (type "help" enter for help)'
	while :											
		do
			. $HOME/.gururc
			read -e -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd" 
			[ "$cmd" == "exit" ] && exit 0
			parse_argument $cmd
		done
	return 123
}


## main check (like like often in python)

me=${BASH_SOURCE[0]}
if [[ "$me" == "${0}" ]]; then
	main $@
	exit $?
fi

