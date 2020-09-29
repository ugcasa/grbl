#!/bin/bash
# guru-client user configuration file
# to send configurations to server type 'guru remote push' and
# to get configurations from server type 'guru remote pull'
# backup is kept at .config/guru/<user>/userrc.backup
export GURU_BIN="$HOME/bin"
export GURU_CFG="$HOME/.config/guru"
export GURU_USER_RC="$GURU_CFG/$GURU_USER/userrc"
# User settings
#export GURU_USER="casa"
#echo "userrc $(date)" >> /home/casa/user.log

export GURU_REAL_NAME="Juha Palm - userrc"
export GURU_USER_PHONE="+358 400810 055"
export GURU_USER_EMAIL="casa@ujo.guru"
export GURU_TEAM="guru"
export GURU_TEAM_NAME="ujo.guru"
export GURU_NOTE_HEADER="Muistiinpanot $GURU_REAL_NAME"
export GURU_DOMAIN_NAME="ujo.guru"

# Remote accesspoint
export GURU_ACCESS_POINT="ujo.guru"
export GURU_ACCESS_POINT_USER="$GURU_USER"
export GURU_ACCESS_POINT_PORT="2010"

# Clound server on local newtwork
export GURU_CLOUD_NEAR="192.168.1.10"
export GURU_CLOUD_NEAR_USER="$GURU_USER"
export GURU_CLOUD_NEAR_PORT="22"

# Clound server on public route
export GURU_CLOUD_FAR="ujo.guru"
export GURU_CLOUD_FAR_USER="$GURU_USER"
export GURU_CLOUD_FAR_PORT="2010"

# Phone ssh connection
export GURU_PHONE_IP="192.168.1.29"
export GURU_PHONE_USER="casa"
export GURU_PHONE_PORT="2223"
export GURU_PHONE_MOUNTPOINT="$HOME/Phone"
export GURU_PHONE_PASSWORD="kuurilaakeri0"


export GURU_SYSTEM_MOUNT="$HOME/.data"

# Local mountpoints
export GURU_LOCAL_DOCUMENTS="/home/casa/Documents"
export GURU_LOCAL_NOTES="$HOME/Notes"
export GURU_LOCAL_TEMPLATES="$HOME/Templates"
export GURU_LOCAL_COMPANY="$HOME/ujo.guru"
export GURU_LOCAL_FAMILY="$HOME/bubble.bay"
export GURU_LOCAL_PICTURES="$HOME/Pictures"
export GURU_LOCAL_PHOTOS="$HOME/Photos"
export GURU_LOCAL_AUDIO="$HOME/Audio"
export GURU_LOCAL_VIDEO="$HOME/Videos"
export GURU_LOCAL_MUSIC="$HOME/Music"

# Remote file locations
export GURU_CLOUD_DOCUMENTS="/home/casa/Documents"
export GURU_CLOUD_TRACK="/home/casa/Track"
export GURU_CLOUD_NOTES="/home/casa/Notes"
export GURU_CLOUD_TEMPLATES="/home/casa/Templates"
export GURU_CLOUD_COMPANY="/home/casa/ujo.guru"
export GURU_CLOUD_FAMILY="/home/casa/bubble"
export GURU_CLOUD_PICTURES="/home/casa/Pictures"
export GURU_CLOUD_PHOTOS="/home/casa/Photos"
export GURU_CLOUD_VIDEO="/home/casa/Videos"
export GURU_CLOUD_AUDIO="/home/casa/Audio"
export GURU_CLOUD_MUSIC="/home/casa/Music"

# System
# export GURU_BIN="$HOME/bin"
export GURU_CALL="guru"
export GURU_INSTALL="desktop"

# Locations
export GURU_TRASH="$GURU_LOCAL_TRACK/trash"
export GURU_COUNTER="$HOME/Track/counters"
export GURU_PROJECT="$HOME/Track/project"
export GURU_WORKTRACK="$HOME/Track/timetrack"
export GURU_ACCOUNTING="$HOME/Economics"
export GURU_PERSONAL_ACCOUNTING="$HOME/Economics/Personal"
export GURU_RECEIPTS="invoices"

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

# Formats
export GURU_DATE_FORMAT='%-d.%-m.%Y'
export GURU_TIME_FORMAT='%H:%M:%S'
export GURU_FILE_DATE_FORMAT='%Y%m%d'
export GURU_FILE_TIME_FORMAT='%H%M%S'

# Tool folders
export GURU_APP="$HOME/apps"
export GURU_CHROME_USER_DATA="$HOME/.config/chromium/$GURU_USER_EMAIL"

# Files
export GURU_LOG="$GURU_LOCAL_TRACK/guru-client.log"
export GURU_CORE_DUMP="$GURU_LOCAL_TRACK/guru-client.CORE_DUMP"
export GURU_TRACKDATA="$GURU_WORKTRACK/current_work.csv"
export GURU_TRACKLAST="$GURU_WORKTRACK/timer.last"
export GURU_TRACKSTATUS="$GURU_WORKTRACK/timer.status"
export GURU_ERROR_MSG="/tmp/guru-last.error"

# Flags
export GURU_USER_VERBOSE=true
export GURU_TERMINAL_COLOR=true
export GURU_USE_VERSION="0.5.2"
export GURU_AUDIO_ENABLED=true

# export GURU_MOUNT_DOCUMENTS=("/home/casa/Documents" "/home/casa/Documents")
# export GURU_MOUNT_TRACK=("/home/casa/Track" "/home/casa/Track")
# export GURU_MOUNT_NOTES=("/home/casa/Notes" "/home/casa/Notes")
# export GURU_MOUNT_TEMPLATES=("/home/casa/Templates" "/home/casa/Templates")
# export GURU_MOUNT_COMPANY=("/home/casa/ujo.guru" "/home/casa/ujo.guru")
# export GURU_MOUNT_FAMILY=("/home/casa/bubble" "/home/casa/bubble.bay")
# export GURU_MOUNT_PICTURES=("/home/casa/Pictures" "/home/casa/Pictures")
# export GURU_MOUNT_PHOTOS=("/home/casa/Photos" "/home/casa/Photos")
# export GURU_MOUNT_AUDIO=("/home/casa/Videos" "/home/casa/Audio")
# export GURU_MOUNT_VIDEO=("/home/casa/Audio" "/home/casa/Videos")
# export GURU_MOUNT_MUSIC=("/home/casa/Music" "/home/casa/Music")