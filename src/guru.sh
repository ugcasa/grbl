#!/bin/bash
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019

version="0.2.8"

. $HOME/.gururc 				# user and platform settings (implement here, always up to date)
. $GURU_BIN/functions.sh 		# common functions, if no ".sh", check here

parse_command () {
	# parse commands and delivery variables to corresponding application, function, bash script, python.. whatever
	command="$1" 					# store original command
	shift							# shift arguments left
	case $command in 

			status) 				# Print out all statuses
				status $@
				error_code=$? 
	            ;;  
			
			counter|count|id) 		# Add things 
				counter $@
				error_code=$? 
	            ;;  

			settings|set)			# set environmental variables
				settings $@
				error_code=$? 			
				;;

			notes|note|noter) 		# create, manipulate and make format changes
				noter.sh $@
				#notes.sh $@		# rollback
				error_code=$? 			
				;;

			project|pro) 			# change, create and manage projects
				project $@
				error_code=$? 			
				;;

			timer)	 				# timer tools for work time tracking
				timer.sh $@
				error_code=$? 			
				;;

			stamp) 					# time, date and other like signatures etc. to clipboard
				stamp.sh $@
				error_code=$? 			
				;;

			phone|phoneflush) 		# get pictures/files from phone by ssh 
				phoneflush-lite.sh $@
				error_code=$? 
				;;

			play) 					# media playing tools (later format changes etc.)
				play.sh $@
				error_code=$? 
				;;
			
			document)				# reporting and documentation tools
				dozer $@
				error_code=$? 
				;;

			disable) 				# tool to use if guru pisses you off
				disable
				error_code=$? 
				;;

			silence) 				# "kill all audio and lights"
				fade_low
				$GURU_CALL play stop
				error_code=$?
				;;

			uninstall)				# Get rid of this shit 
				uninstall
				error_code=$? 
				;;

			upgrade) 				# Force upgrade from git
				upgrade
				error_code=$? 
				;;

			install) 				# Installation script collection (later "Install modules")
				installer.sh $@
				error_code=$?
				;;

			demo) 					# Play text based demo (TODO add thanks!)
				$GURU_CALL play demo $@
				error_code=$? 
				;;

			fu)						# fuck you animation
				$GURU_CALL play vt monkey 	
				error_code=$?
				;;

			terminal) 				# unused test interface
				guru_terminal $@
				error_code=$? 			
				;;

			news|uutiset) 					# unused test interface
				DISPLAY=:0 rrs.py $@
				error_code=$? 			
				;;


			version|ver|-v|--ver) 	# la versíon
				printf "giocon.client v.$version installed to $0\n"
				;;

			help|-h|--help|*) 		# hardly never updated help printout
			 	printf "giocon command line toolkit client v.$version \n"
			 	printf "usage: '$GURU_CALL' [TOOL] [COMMAND] [VARIABLES] \ncommands: \n"
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
				printf 'uninstall un-install guru toolkit \n'
				printf 'version   printout version \n'
	esac	

	if (( error_code > 0 )); then
		logger "$0 $command: $error_code: $GURU_ERROR_MSG"				# log errors
		echo "error: $error_code"										# print error
	fi
	
	return $error_code 													# relay error
}


guru_terminal() { 
	# Terminal looper	
	echo "$GURU_CALL in terminal mode. press enter for help."
	while :																
		do
		. $HOME/.gururc
		read -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd" # just a POC, read is terrible input tool, 
																	    # there was to other but no	
																		# guru:>timer start at 00:00 gioco^[[C^[[D 
																		# -> pyhton, sooner then better POC starts to be done

		[ "$cmd" == "exit" ] && exit 3
		parse_command $cmd
		done
	return 123
}


## main 

if [ $1 ]; then 					# guru without parameters starts terminal loop
	parse_command $@ 
	exit $?
	else
	guru_terminal 								
	exit $?
fi


