# ujo.guru tool kit ENVIRONMENT VARIABLES
# only for static variables for individual sessions 
# called from .bashrc (will be every time bash session starts)

# User information
export GURU_USER="$USER"
export GURU_CFG="$HOME/.config/guru"
export GURU_USER_RC="$GURU_CFG/$GURU_USER/userrc"

if [ -f "$GURU_USER_RC" ]; then 			# if user setting exist
	. $GURU_USER_RC							# overwrite defaults
else
	. $templaterc
fi

alias "$GURU_CALL"=$GURU_BIN/guru


# export GURU_TEAM_RC="$GURU_CFG/$GURU_USER/teamrc"
# export GURU_BIN="$HOME/bin"
# #export GURU_REGISTERED=false
# export GURU_CALL="guru"
# alias "$GURU_CALL"=$GURU_BIN/guru

# # userrc
# export GURU_REAL_NAME="your full name"

# # (to teamrc)
# export GURU_TEAM="guru"
# export GURU_TEAM_NAME="ujo.guru"
# export GURU_NOTE_HEADER="Memoradium"
# export GURU_USER_PHONE="your phone number"
# export GURU_USER_EMAIL="$GURU_USER@ujo.guru"

# # Formats (in teamrc)
# export GURU_DATE_FORMAT='%d.%-m.%Y'
# export GURU_TIME_FORMAT='%H:%M:%S'
# export GURU_FILE_DATE_FORMAT='%Y%m%d'
# export GURU_FILE_TIME_FORMAT='%H%M%S'

# # Folders (in teamrc)
# export GURU_NOTES="$HOME/Documents"
# export GURU_WORKTRACK="$HOME/.timetrack"
# export GURU_TEMPLATES="$HOME/template"
# export GURU_VIDEO="$HOME/Videos"
# export GURU_AUDIO="$HOME/Audio"
# export GURU_MUSIC="$HOME/Dropbox/Music"
# export GURU_COUNTER="$HOME/.counters"
# export GURU_RECEIPTS="invoices"										# benetah previous folder + /year/month 
# export GURU_SCAN="$HOME/Documents" 		
# export GURU_ACCOUNTING="$HOME/Documents/Accounting"
# export GURU_PERSONAL_ACCOUNTING="$HOME/Documents/personal"


# # Folders 
# export GURU_BIN="$HOME/bin"
# export GURU_CFG="$HOME/.config/guru"
# export GURU_APP="$HOME/apps"
# export GURU_CHROME_USER_DATA="$HOME/.config/chromium/$EMAIL"

# # Files
# export GURU_TRACKDATA="$GURU_WORKTRACK/current_work.csv"
# export GURU_TRACKLAST="$GURU_WORKTRACK/timer.last"
# export GURU_TRACKSTATUS="$GURU_WORKTRACK/timer.status"
# export GURU_ERROR_MSG="/tmp/guru-last.error"

# # Flags
# export GURU_AUDIO_ENABLED=true
# export GURU_INSTALL="desktop"

# # Preferred applications
# export GURU_EDITOR="subl"
# export GURU_BROWSER="chromium-browser"
# export GURU_OFFICE_DOC="libreoffice"
# export GURU_OFFICE_SPR="libreoffice"


# # if [ -f "$GURU_TEAM_RC" ]; then 			# if team setting exist
# # 	. $GURU_TEAM_RC							# overwrite defaults
# # fi



# # To update user and team settings type "guru user save; guru team save"