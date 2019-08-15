# ujo.guru tool kit ENVIRONMENT VARIABLES
# only for static variables for individual sessions 
# called from .bashrc (will be every time bash session starts)

# User information
export GURU_USER="casa"
export GURU_TEAM="guru"
export GURU_REAL_NAME="Juha Palm"
export GURU_NOTE_HEADER="Muistiinpanot"

# System variables
export GURU_CALL="guru"
export GURU_INSTALL="desktop"
export GURU_AUDIO_ENABLED=true

# Folders 
export GURU_BIN="$HOME/bin"
export GURU_CFG="$HOME/.config/guru"
export GURU_NOTES="$HOME/Dropbox/Notes"
export GURU_VIDEO="$HOME/Dropbox/Video"
export GURU_AUDIO="$HOME/Dropbox/Audio"
export GURU_COUNTER="$HOME/Dropbox/Notes/$GURU_USER/counters"
export GURU_WORKTRACK="$HOME/Dropbox/Notes/$GURU_USER/WorkTimeTrack"
export GURU_CHROME_USER_DATA="/home/casa/.config/chromium/regressio@gmail.com"
#export GURU_PHOTO="$HOME/bubblebay/Photos"
#export GURU_PICTURE="$HOME/Dropbox/Pictures"
export GURU_ACCOUNTING="$HOME/Dropbox/Accounting"
export GURU_PERSONAL_ACCOUNTING="$HOME/bubblebay/Talous"
export GURU_RECEIPTS="Ostolaskut"
export GURU_SCAN="$GURU_PICTURE"
export GURU_TEMPLATES="$GURU_NOTES/$GURU_USER/template"

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
