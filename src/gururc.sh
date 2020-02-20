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
	export GURU_USER_EMAIL="$GURU_USER@ujo.guru"
	export GURU_USER_PHONE="-your phone number-"
	export GURU_NOTE_HEADER="Notes" 				# TODO koostetaan valmiiksi sringi tässä

# (to teamrc)
	export GURU_TEAM="test"
	export GURU_TEAM_NAME="tester-group"

# Folders 
	export GURU_NOTES="$HOME/Notes"
	export GURU_PICTURES="$HOME/Pictures"
	export GURU_TEMPLATES="$HOME/Templates"
	export GURU_VIDEO="$HOME/Videos"
	export GURU_AUDIO="$HOME/Audio"
	export GURU_MUSIC="$HOME/Music"
	export GURU_SCAN="$HOME/Documents" 		
	export GURU_ACCOUNTING="$HOME/Economics"
	export GURU_PERSONAL_ACCOUNTING="$HOME/Economics/Personal"

	export GURU_WORKTRACK="$HOME/Track/timetrack"
	export GURU_COUNTER="$HOME/Track/counters"
	export GURU_RECEIPTS="invoices"												# bad monkey!

# Server setup 
	export GURU_REMOTE_FILE_SERVER_USER="$USER"	
	export GURU_LOCAL_FILE_SERVER="192.168.1.10"
	export GURU_LOCAL_FILE_SERVER_PORT="22"
	export GURU_REMOTE_FILE_SERVER="ujo.guru"
	export GURU_REMOTE_FILE_SERVER_PORT="2010"

	export GURU_CLOUD_NOTES="/home/$GURU_REMOTE_FILE_SERVER_USER/ujo.guru/Notes"
	export GURU_CLOUD_PICTURES="/home/$GURU_REMOTE_FILE_SERVER_USER/ujo.guru/Pictures"
	export GURU_CLOUD_TEMPLATES="/home/$GURU_REMOTE_FILE_SERVER_USER/Templates"
	export GURU_CLOUD_VIDEO="/home/$GURU_REMOTE_FILE_SERVER_USER/bubble/Videos"
	export GURU_CLOUD_AUDIO="/home/$GURU_REMOTE_FILE_SERVER_USER/bubble/Audio"
	export GURU_CLOUD_MUSIC="/home/$GURU_REMOTE_FILE_SERVER_USER/bubble/Music"
	export GURU_CLOUD_ACCOUNTING="/home/$GURU_REMOTE_FILE_SERVER_USER/ujo.guru/Accounting"
	export GURU_CLOUD_RECEIPTS="invoices"										# bad monkey!

# Preferred applications
	export GURU_TERMINAL="gnome-terminal"
	export GURU_EDITOR="subl"
	export GURU_BROWSER="firefox"
	export GURU_OFFICE_DOC="libreoffice"
	export GURU_OFFICE_SPR="libreoffice"

# Keyboard bindings 
	export GURU_KEYBIND_TERMINAL="F1"
	export GURU_KEYBIND_NOTE="<Ctrl>n"
	export GURU_KEYBIND_DATESTAMP=""
	export GURU_KEYBIND_TIMESTAMP="<Ctrl>t"
	export GURU_KEYBIND_SIGNATURE=""
	export GURU_KEYBIND_PICTURE_MD=""

# Formats (in teamrc)
	export GURU_DATE_FORMAT='%d.%-m.%Y'
	export GURU_TIME_FORMAT='%H:%M:%S'
	export GURU_FILE_DATE_FORMAT='%Y%m%d'
	export GURU_FILE_TIME_FORMAT='%H%M%S'

# Tool folders (lowercase)
	export GURU_BIN="$HOME/bin"
	export GURU_CFG="$HOME/.config/guru"
	export GURU_APP="$HOME/apps"
	export GURU_CHROME_USER_DATA="$HOME/.config/chromium/$GURU_USER_EMAIL"

# Files
	export GURU_TRACKDATA="$GURU_WORKTRACK/current_work.csv"
	export GURU_TRACKLAST="$GURU_WORKTRACK/timer.last"
	export GURU_TRACKSTATUS="$GURU_WORKTRACK/timer.status"
	export GURU_ERROR_MSG="/tmp/guru-last.error"

# Flags
	export GURU_AUDIO_ENABLED=true
	export GURU_INSTALL="desktop"
fi

alias "$GURU_CALL"=$GURU_BIN/guru 					

