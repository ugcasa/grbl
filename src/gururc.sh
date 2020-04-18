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
	export GURU_USER_PHONE="+358 295 419 800"
	export GURU_NOTE_HEADER="Daily notes $GURU_REAL_NAME"

# Server setup
	export GURU_ACCESS_POINT_USER="$GURU_USER"
	export GURU_ACCESS_POINT="ujo.guru"
	export GURU_ACCESS_POINT_PORT="2010"

# (to teamrc)
	export GURU_TEAM="test"
	export GURU_TEAM_NAME="test user"

# mountpoints
	export GURU_LOCAL_NOTES="$HOME/$GURU_CALL/Notes"
	export GURU_LOCAL_PICTURES="$HOME/$GURU_CALL/Pictures"
	export GURU_LOCAL_TEMPLATES="$HOME/$GURU_CALL/Templates"
	export GURU_LOCAL_VIDEO="$HOME/$GURU_CALL/Videos"
	export GURU_LOCAL_AUDIO="$HOME/$GURU_CALL/Audio"
	export GURU_LOCAL_MUSIC="$HOME/$GURU_CALL/Music"
	export GURU_LOCAL_SCAN="$HOME/$GURU_CALL/Documents"
	export GURU_LOCAL_TRACK="$HOME/$GURU_CALL/Track"
	export GURU_LOCAL_PHOTOS="$HOME/$GURU_CALL/Photos"
	export GURU_LOCAL_FAMILY=
	export GURU_LOCAL_COMPANY=


# locations
	export GURU_SOMEDIA="$GURU_LOCAL_PICTURES/some"
	export GURU_TEST="$GURU_LOCAL_TRACK/Test-data"
	export GURU_ACCOUNTING="$HOME/Economics"
	export GURU_PERSONAL_ACCOUNTING="$HOME/Economics/Personal"
	export GURU_LOG="$HOME/Track/log"
	export GURU_WORKTRACK="$HOME/Track/timetrack"
	export GURU_COUNTER="$HOME/Track/counters"
	export GURU_RECEIPTS="invoices"												# bad monkey!

# clound locations
	export GURU_CLOUD_TRACK="$HOME/$GURU_CALL/Track"
	export GURU_CLOUD_NOTES=
	export GURU_CLOUD_PICTURES=
	export GURU_CLOUD_TEMPLATES=
	export GURU_CLOUD_VIDEO=
	export GURU_CLOUD_AUDIO=
	export GURU_CLOUD_MUSIC=
	export GURU_CLOUD_SCAN=
	export GURU_CLOUD_PHOTOS=
	export GURU_CLOUD_FAMILY=
	export GURU_CLOUD_COMPAN

# Phone ssh connection (requres ssh server running on phone)
	export GURU_PHONE_IP=
	export GURU_PHONE_USER=
	export GURU_PHONE_PORT=
	export GURU_PHONE_PASSWORD=		# optinal

# Preferred applications
	export GURU_TERMINAL="gnome-terminal"
	export GURU_EDITOR="subl"
	export GURU_BROWSER="firefox"
	export GURU_OFFICE_DOC="libreoffice"
	export GURU_OFFICE_SPR="libreoffice"

# Keyboard bindings (ubuntu)
	export GURU_KEYBIND_TERMINAL="F1"
	export GURU_KEYBIND_NOTE="<Ctrl>n"
	export GURU_KEYBIND_TIMESTAMP="<Ctrl>t"
	export GURU_KEYBIND_DATESTAMP=
	export GURU_KEYBIND_SIGNATURE=
	export GURU_KEYBIND_PICTURE_MD=

# Formats
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

# Decorations
	export GURU_TERMINAL_COLOR=""
fi

#alias "$GURU_CALL"=$GURU_BIN/guru

