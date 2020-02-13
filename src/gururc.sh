#!/bin/bash
# ujo.guru tool kit environmental variables
# called from .bashrc every time bash session starts

# User information

export GURU_USER="$USER"
export GURU_CFG="$HOME/.config/guru"
export GURU_USER_RC="$GURU_CFG/$GURU_USER/userrc"

if [ -f "$GURU_USER_RC" ]; then 					# if user setting file exist

	. $GURU_USER_RC									# execute personal settings

else 												# Defaults

	export GURU_BIN="$HOME/bin"
	export GURU_CALL="guru"
	export GURU_DOMAIN_NAME="ujo.guru"

# userrc
	export GURU_REAL_NAME="Roger von Gullit"

# (to teamrc)
	export GURU_TEAM="guru"
	export GURU_TEAM_NAME="ujo.guru"
	export GURU_NOTE_HEADER="Notes" 				# TODO koostetaan valmiiksi sringi tässä
	export GURU_USER_PHONE="-your phone number-"
	export GURU_USER_EMAIL="$GURU_USER@ujo.guru"

# Formats (in teamrc)
	export GURU_DATE_FORMAT='%d.%-m.%Y'
	export GURU_TIME_FORMAT='%H:%M:%S'
	export GURU_FILE_DATE_FORMAT='%Y%m%d'
	export GURU_FILE_TIME_FORMAT='%H%M%S'

# Folders (in teamrc)
	export GURU_NOTES="$HOME/Documents"
	export GURU_WORKTRACK="$HOME/Documents/.timetrack"
	export GURU_TEMPLATES="$HOME/Templates"
	export GURU_VIDEO="$HOME/Videos"
	export GURU_MEDIA="$HOME/Downloads"
	export GURU_AUDIO="$HOME/Audio"
	export GURU_MUSIC="$HOME/Music"
	export GURU_COUNTER="$HOME/Documents/.counters"
	export GURU_RECEIPTS="invoices"										
	export GURU_SCAN="$HOME/Documents" 		
	export GURU_ACCOUNTING="$HOME/Economics"
	export GURU_PERSONAL_ACCOUNTING="$HOME/Documents"

# Folders 
	export GURU_BIN="$HOME/bin"
	export GURU_CFG="$HOME/.config/guru"
	export GURU_APP="$HOME/apps"
	export GURU_CHROME_USER_DATA="$HOME/.config/chromium/$EMAIL"

# Files
	export GURU_TRACKDATA="$GURU_WORKTRACK/current_work.csv"
	export GURU_TRACKLAST="$GURU_WORKTRACK/timer.last"
	export GURU_TRACKSTATUS="$GURU_WORKTRACK/timer.status"
	export GURU_ERROR_MSG="/tmp/guru-last.error"

# Flags
	export GURU_AUDIO_ENABLED=true
	export GURU_INSTALL="desktop"

# Preferred applications
	export GURU_EDITOR="subl"
	export GURU_BROWSER="firefox"
	export GURU_OFFICE_DOC="libreoffice"
	export GURU_OFFICE_SPR="libreoffice"

fi

alias "$GURU_CALL"=$GURU_BIN/guru 					

