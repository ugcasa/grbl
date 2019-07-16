#!/bin/bash
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019

version="0.2.6"

. $HOME/.gururc 				# user and platform settings (implement here, always up to date)
. $GURU_BIN/functions.sh 		# common functions, if no ".sh", check here

command="$1" 					# store original command
shift							# shift arguments left

case $command in 

		status) 				# Print out all statuses
			status $@
			error_code=$? 
            ;;  

		settings|set)			# set environmental variables
			settings $@
			error_code=$? 			
			;;

		notes|note) 			# create, manipulate and make format changes
			notes.sh $@
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
			guru play stop
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
			guru play demo $@
			error_code=$? 
			;;

		fu)						# fuck you animation
			guru play vt monkey 	
			error_code=$?
			;;

		test) 					# unused test interface
			test_guru $@
			error_code=$? 			
			;;

		version|ver|-v|--ver) 	# la versíon
			printf "$0 version $version\n"
			;;

		help|-h|--help|*) 		# hardly never updated help printout
		 	printf "ujo.guru command line toolkit @ $(guru version) \n"
		 	printf "usage: guru [TOOL] [COMMAND] [VARIABLES] \ncommands: \n"
			printf 'timer     timing tools ("guru timer help" for more info) \n'
			printf 'notes     open daily notes \n'
			printf 'project   opens project to edotor \n'
			printf 'document  compile markdown to .odt format \n'
			printf 'play      play videos and music ("guru play help" for more info) \n'			
			printf 'phone     get data from android phone \n'
			printf 'stamp     time stamp to clipboard and terminal\n'
			printf 'silence   kill all audio and lights \n'
			printf 'demo      run demo ("guru set audio true" to play with audio)\n'			
			printf 'status    status of guru user \n'
			printf 'install   install tools ("guru install help" for more info)\n'
			printf 'set       set options ("guru set help" for more information)' 
			printf 'upgrade   upgrade guru toolkit \n'
			printf 'disable   disables guru toolkit type "guru.enable" to enable \n'
			printf 'uninstall uninstall guru toolkit \n'
			printf 'version   printout version \n'
			;;
esac	

if [ $error_code -gt 0 ]; then
	logger "$0 $command: $error_code $error_msg"					# log errors
	echo "function exited with error: $error_code $error_msg"		# print error
fi

exit $error_code 													# relay error

