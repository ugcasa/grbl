# ujo.guru tool kit ENVIRONMENT VARIABLES
# only for static variables for individual sessions 
# called from .bashrc (will be every time bash session starts)




# User information
export GURU_USER="$USER"
export GURU_CFG="$HOME/.config/guru"
export GURU_USER_RC="$GURU_CFG/$GURU_USER/userrc"

if [ -f "$GURU_USER_RC" ]; then 			# if user setting exist  
	. $GURU_USER_RC							# run those
	alias "$GURU_CALL"=$GURU_BIN/guru
	return 0
fi

export GURU_CALL="guru"
export GURU_BIN="$HOME/bin"

alias "$GURU_CALL"=$GURU_BIN/guru

export GURU_TEAM="guru"
export GURU_REAL_NAME="input your full name"
export GURU_NOTE_HEADER="Memoradium"
export GURU_INSTALL="desktop"
export GURU_AUDIO_ENABLED=true

# Folders 
export GURU_BIN="$HOME/bin"
export GURU_CFG="$HOME/.config/guru"
export GURU_APP="$HOME/apps"
export GURU_NOTES="$HOME/Documents"
export GURU_VIDEO="$HOME/Videos"
export GURU_AUDIO="$HOME/Music"
export GURU_COUNTER="$HOME/.counters"
export GURU_WORKTRACK="$HOME/.timetrack"
export GURU_CHROME_USER_DATA="$HOME/.config/chromium/$EMAIL"
export GURU_ACCOUNTING="$HOME/Documents/Accounting"
export GURU_RECEIPTS="invoices"										# benetah previous folder + /year/month 
export GURU_PERSONAL_ACCOUNTING="$HOME/Documents/personal"
export GURU_SCAN="$HOME/Documents" 		
export GURU_TEMPLATES="$HOME/template"

# Files
export GURU_TRACKDATA="$GURU_WORKTRACK/current_work.csv"
export GURU_TRACKLAST="$GURU_WORKTRACK/timer.last"
export GURU_TRACKSTATUS="$GURU_WORKTRACK/timer.status"
export GURU_ERROR_MSG="/tmp/guru-last.error"

# Preferred applications
export GURU_EDITOR="subl"
export GURU_BROWSER="chromium-browser"
export GURU_OFFICE_DOC="libreoffice"
export GURU_OFFICE_SPR="libreoffice"



