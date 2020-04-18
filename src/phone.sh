#!/bin/bash
# guru tool-kit phone tools
# - get files from phone by connecting phone sshd

source $GURU_BIN/lib/common.sh
source $GURU_BIN/tag.sh
source $GURU_BIN/mount.sh


phone.main () {

    [[ $GURU_PHONE_IP ]]        || read -p "phone ip: "     GURU_PHONE_IP
    [[ $GURU_PHONE_PORT ]]      || read -p "sshd port: "    GURU_PHONE_PORT
    [[ $GURU_PHONE_USER ]]      || read -p "ssh user: "     GURU_PHONE_USER
    [[ $GURU_PHONE_PASSWORD ]]  || read -p "password: "     GURU_PHONE_PASSWORD

    local _cmd="$1" ; shift
    remove_files=
    case "$_cmd" in
                        help)   phone.help              ;;
                    terminal)   phone.terminal "$1"     ;;
                       mount)   phone.mount "$1"        ;;
                     unmount)   phone.unmount "$1"      ;;
                  whatsup|wa)   phone.get_whatsapp      ;;
                 telegram|tg)   phone.get_telegram      ;;
                      camera)   phone.get_camera        ;;
          download|downloads)   phone.get_download      ;;
      screenshot|screenshots)   phone.get_screenshots      ;;
                         all)   phone.get_camera
                                phone.get_whatsapp
                                phone.get_telegram
                                phone.get_screenshots
                                phone.get_download      ;;
                           *)   echo "unknown action $_cmd"
        esac
}


phone.help () {
    echo "-- guru tool-kit phone help -----------------------------------------------"
    printf "usage:\t %s phone [action] \n" "$GURU_CALL"
    printf "\nactions:\n"
    printf " terminal          open terminal to phone \n"
    printf " mount             mount phone user folder \n"
    printf " unmount           unmount phone \n"
    printf " camera            get, tag and relocate photos and videos from phone \n"
    printf " whatsapp          get WhatsApp media from phone \n"
    printf " telegram          get Telegram media from phone \n"
    printf " downloads         get download folder from phone \n"
    printf " screenshots       get screenshots from phone \n"
    printf " help              help printout \n"
    printf "\nexample:     %s phone mount \n" "$GURU_CALL"
    printf "             %s phone camera \n" "$GURU_CALL"
    printf "             %s phone terminal \n" "$GURU_CALL"
}


phone.terminal () {
    ssh -oHostKeyAlgorithms=+ssh-dss "$GURU_PHONE_USER@$GURU_PHONE_IP" -p "$GURU_PHONE_PORT"
}


phone.mount () {
    # mount phone folder set as home in phone ssd server app
    # input mount point (optional)
    local _mount_point="$HOME/phone-$GURU_PHONE_USER" ; [[ "$1" ]] && _mount_point="$1"
    [[ -d "$_mount_point" ]] || mkdir -p "$_mount_point"
    #sshpass -p "$GURU_PHONE_PASSWORD"
    sshfs -oHostKeyAlgorithms=+ssh-dss -p "$GURU_PHONE_PORT" "$GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0" "$_mount_point"
    return $?
}


phone.unmount () {
    # input mount point (optional)
    local _mount_point="$HOME/phone-$GURU_PHONE_USER" ; [[ "$1" ]] && _mount_point="$1"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] && rmdir "$_mount_point"
    return $?

}


phone.remove_folder () {
    # makes empty folder in phone by removing and then creating target folder
    local _target_folder="$1"

    if [[ "$remove_files" == "y" ]]; then
            read -n1 -r -p "really delete $1?: " _answ
            [[ "$_answ" == "y" ]] || return 1
        fi

    printf "\e[1mremoving: $_target_folder\e[0m\n"
    echo sshpass -p "$GURU_PHONE_PASSWORD" \
    ssh "$GURU_PHONE_USER@$GURU_PHONE_IP" -p $GURU_PHONE_PORT -oHostKeyAlgorithms=+ssh-dss \
    "rm -rf $_target_folder ; mkdir -rf $_target_folder"
}


phone.get_camera () {

    mount.online $GURU_LOCAL_PHOTOS || return 100
    local _photo_format="jpg"
    local _video_format="mp4"
    local _target_folder="/tmp/guru/photos"
    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    printf "${WHT}copying camera files.. ${NC}\n"

    # get all files from phone DCIM folder and place to temp
    echo sshpass -p $GURU_PHONE_PASSWORD \
    scp -q -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/DCIM/Camera/* $_target_folder

    detox $_target_folder/*

    # analyze, tag and relocate photo files
    printf "${WHT}plasing photos to $GURU_LOCAL_PHOTOS ${NC}\n"
    _file_list=($(ls "$_target_folder" | grep ".$_photo_format" ))                      # read file list
    if [[ $?=0 ]]; then
            local _year=1970
            local _month=1
            local _date=
            local _recognized=

            for _file in ${_file_list[@]}; do
                    _date=${_file#*_} ; _date=${_date%_*}                               # echo ":::: $_date"
                    _year=$(date -d $_date +'%Y')
                    _month=$(date -d $_date +'%m')
                    # _recognized="$(yolo.regonize $_file)"                             # "a dig"
                    tag_main "$_target_folder/$_file" add "$GURU_USER $_date"           # $_recognized
                    mv "$_target_folder/$_file" "$GURU_LOCAL_PHOTOS/$_year/$_month"     # place pictures to right folders
                done
        else
            echo "no photos found"
        fi


    # analyze, tag and relocate video files
    _file_list=($(ls "$_target_folder" | grep ".$_video_format" ))                                  # read file list
    if [[ $?=0 ]]; then
            local _year=1970
            #echo "file list: ${_file_list[@]}"
            for _file in ${_file_list[@]}; do
                    _date=${_file#*_} ; _date=${_date%_*}                               # echo ":::: $_date"
                    _year=$(date -d $_date +'%Y')
                    mv "$_target_folder/$_file" "$GURU_LOCAL_VIDEOS/$_year"          # place videos to right folders
                done
        else
            echo "no videos found"
        fi

    [[ ${#_target_folder} < 5 ]] || return 1                                 # to avoid 'rm -rf $HOME' or 'sudo rm -rf /' type if some of the variables are emty
    [[ -d "$_target_folder" ]] && rm -rf "$_target_folder"

    # [ "$?" = "0" ] && phone.remove_folder "/storage/emulated/0/DCIM/Camera/"
}


phone.get_telegram () {
    # "Telegram/Telegram Audio"
    # "Telegram/Telegram Documents"
    # "Telegram/Telegram Images"
    # "Telegram/Telegram Video"
    echo "telegram"
}


phone.get_whatsapp() {
    # "WhatsApp/Media/WallPaper
    # "WhatsApp/Media/WhatsApp Animated Gifs"
    # "WhatsApp/Media/WhatsApp Audio"
    # "WhatsApp/Media/WhatsApp Documents"
    # "WhatsApp/Media/WhatsApp Images"
    # "WhatsApp/Media/WhatsApp Profile Photos"
    # "WhatsApp/Media/WhatsApp Stickers"
    # "WhatsApp/Media/WhatsApp Video"
    # "WhatsApp/Media/WhatsApp Voice Notes"

    mount.online $GURU_LOCAL_PICTURES || return 100

    local _target_folder="$GURU_SOMEDIA/wa-pictures"

    printf "\e[1mcopying whatsup images to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    echo sshpass -p $GURU_PHONE_PASSWORD \
    scp -q -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Images/*' $_target_folder

    [ "$?" = "0" ] && phone.remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Images/'

    _target_folder="$GURU_SOMEDIA/wa-videos"

    printf "\e[1mcopying whatsup videos to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p $_target_folder

    echo sshpass -p $GURU_PHONE_PASSWORD \
    scp -q -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Video/*' $_target_folder

    [ "$?" = "0" ] && phone.remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Video/'
}


phone.get_download () {

    local _target_folder="$HOME/Downloads"

    printf "\e[1mcopying whatsup videos to $_target_folder \e[0m\n"
    [[ -d "$_target_folder" ]] || mkdir -p $_target_folder

    echo sshpass -p $GURU_PHONE_PASSWORD \
    scp -q -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/Download/* $_target_folder

    [ "$?" = "0" ] && phone.remove_folder "/storage/emulated/0/Download"
}


phone.get_screenshots () {

    mount.online $GURU_LOCAL_PICTURES || return 100

    printf "\e[1mcopying pictures..\e[0m\n"
    echo sshpass -p $GURU_PHONE_PASSWORD scp -q -v -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/Pictures/Screenshots/* $GURU_LOCAL_PICTURES
    [ "$?" = "0" ] && phone.remove_folder "/storage/emulated/0/Pictures/Screenshots"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        sshpass -V >/dev/null || sudo apt install sshpass
        source "$HOME/.gururc"
        phone.main "$@"
    fi



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
