#!/bin/bash
# guru tool-kit phoneflush
# get files from phone by connecting phone sshd (modified old "phoneflush")

source $GURU_BIN/lib/common.sh

sshpass -V >/dev/null || sudo apt install sshpass

[[ $GURU_PHONE_IP ]]        || read -p "phone IP: "         GURU_PHONE_IP
[[ $GURU_PHONE_PORT ]]      || read -p "port: "             GURU_PHONE_PORT
[[ $GURU_PHONE_PASSWORD ]]  || read -p "input password: "   GURU_PHONE_PASSWORD
[[ $GURU_PHONE_USER ]]      || read -p "input user: "       GURU_PHONE_USER

case "$1" in
                   mount)   sshpass -p $GURU_PHONE_PASSWORD sshfs -oHostKeyAlgorithms=\
                            +ssh-dss -p $GURU_PHONE_PORT $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0 $HOME/puhelin ;;
              whatsup|wa)   whatsup=True      ;;
            photos|photo)   photos=True       ;;
      download|downloads)   download=True     ;;
        pictures|picture)   pictures=True     ;;
                     all)   pictures=True
                            download=True
                            photos=True
                            whatsup=True      ;;
                       *)   echo "unknown action $1"
    esac


remove_folder () {

    if ! [[ "$remove_files" == "y" ]]; then
            read -n1 -r -p "really delete $1?: " _answ
            [[ "$_answ" == "y" ]] || return 1
        fi
    printf "\e[1mremoving: $1\e[0m\n"
    sshpass -p "$GURU_PHONE_PASSWORD" \
    ssh "$GURU_PHONE_USER@$GURU_PHONE_IP" -p $GURU_PHONE_PORT -oHostKeyAlgorithms=+ssh-dss \
    "rm -rf $1 ; mkdir -rf $1"
}


copy_photos() {

    mount.check $GURU_LOCAL_PHOTOS || return 100

    local _target_folder="/tmp/guru/photos"
    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    printf "\e[1mcopying photos to $_target_folder\e[0m\n"

    sshpass -p $GURU_PHONE_PASSWORD \
    scp -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/DCIM/Camera/* $_target_folder

    printf "\e[1mplasing photos to $GURU_LOCAL_PHOTOS \e[0m\n"

    _file_list=($(ls "$_target_folder/*jpg"))               # read file list
    echo "file list: ${_file_list[@]}"

    for $_file in ${_file_list[@]}; do
            # read first file datestamp
            # place needed data to variables
            echo "mv $_target_folder/$_file $GURU_LOCAL_PHOTOS/$_year/$_month/"
        done

    [[ "$_target_folder" ]] || return 1
    [[ -d "$_target_folder" ]] && rm -rf "$_target_folder"

    [ "$?" = "0" ] && remove_folder "/storage/emulated/0/DCIM/Camera/"
}


copy_whatsapp() {

    mount.check $GURU_LOCAL_PICTURES || return 100

    local _target_folder="$GURU_SOMEDIA/wa-pictures"

    printf "\e[1mcopying whatsup images to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    sshpass -p $GURU_PHONE_PASSWORD \
    scp -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Images/*' $_target_folder

    [ "$?" = "0" ] && remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Images/'

    _target_folder="$GURU_SOMEDIA/wa-videos"

    printf "\e[1mcopying whatsup videos to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p $_target_folder

    sshpass -p $GURU_PHONE_PASSWORD \
    scp -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Video/*' $_target_folder

    [ "$?" = "0" ] && remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Video/'
}


copy_download () {

    local _target_folder="$HOME/Downloads"

    printf "\e[1mcopying whatsup videos to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p $_target_folder

    sshpass -p $GURU_PHONE_PASSWORD \
    scp -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/Download/* $_target_folder

    [ "$?" = "0" ] && remove_folder "/storage/emulated/0/Download"
}


copy_pictures () {

    mount.check $GURU_LOCAL_PICTURES || return 100

    printf "\e[1mcopying pictures..\e[0m\n"
    sshpass -p $GURU_PHONE_PASSWORD scp -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/Pictures/Screenshots/* $GURU_LOCAL_PICTURES
    [ "$?" = "0" ] && remove_folder "/storage/emulated/0/Pictures/Screenshots"
}


read -p "remove photos and videos from phone after copying? [y/N]: " remove_files
[ $photos ] && copy_photos
[ $whatsup ] && copy_whatsapp
[ $download ] && copy_download
[ $pictures ] && copy_pictures



# if [[ "$GURU_PHONE_USER" = "casa" ]]; then
#   sshpass -p $GURU_PHONE_PASSWORD scp -v -r -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/MyTinyScan/Documents/* $HOME/Documents
# fi
#\e[1mTimer\e[0m

# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_PHONE_PORT" maea@192.168.1.50:/storage/emulated/0/WhatsApp/Media/* $GURU_LOCAL_PHOTOS/2019/wa
# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_PHONE_PORT" casa@192.168.1.29:/storage/emulated/0/WhatsApp/Media/* $GURU_LOCAL_PHOTOS/2019/wa
#   casa@192.168.1.29's password:
#   exec request failed on channel 0
#   rsync: connection unexpectedly closed (0 bytes received so far) [Receiver]
#   rsync error: unexplained error (code 255) at io.c(235) [Receiver=3.1.2]


# ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_PHONE_PORT casa@192.168.1.29
#   casa@192.168.1.29's password:
#   PTY allocation request failed on channel 0
#   /system/bin/sh: can't find tty fd: No such device or address
#   /system/bin/sh: warning: won't have full job control
#   casa@hwH60:/storage/emulated/0
