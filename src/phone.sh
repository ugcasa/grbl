#!/bin/bash
# guru tool-kit phone tools
# get files from phone by connecting phone sshd
# install this to phone: https://play.google.com/store/apps/details?id=com.theolivetree.sshserver

source $GURU_BIN/lib/common.sh
source $GURU_BIN/tag.sh
source $GURU_BIN/mount.sh

#GURU_VERBOSE=true
#GURU_FORCE=true

phone_temp_folder="/tmp/guru/phone"
phone_file_count=0
phone_server_url="https://play.google.com/store/apps/details?id=com.theolivetree.sshserver"

phone.main () {

    [[ $GURU_PHONE_IP ]]        || read -p "phone ip: "     GURU_PHONE_IP
    [[ $GURU_PHONE_PORT ]]      || read -p "sshd port: "    GURU_PHONE_PORT
    [[ $GURU_PHONE_USER ]]      || read -p "ssh user: "     GURU_PHONE_USER
    [[ $GURU_PHONE_PASSWORD ]]  || read -p "password: "     GURU_PHONE_PASSWORD

    local _cmd="$1" ; shift

    case "$_cmd" in
                   telegram|whatsapp)  phone.$_cmd              ;;  # social media
              mount|unmount|terminal)  phone.$_cmd "$1"         ;;  # tools
        screenshots|downloads|camera)  phone.$_cmd              ;;  # phone locations
                                 all)  phone.camera
                                       phone.whatsapp
                                       phone.telegram
                                       phone.screenshots
                                       phone.downloads          ;;
                                help)  phone.help               ;;
                      install|server)  $GURU_BROWSER $phone_server_url ;;
                                   *)  echo "unknown action $_cmd"
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
    printf " install           install server to phone (google play) \n"
    printf " help              help printout \n"
    printf "\nexample:     %s phone mount \n" "$GURU_CALL"
    printf "             %s phone camera \n" "$GURU_CALL"
    printf "             %s phone terminal \n" "$GURU_CALL"
}


phone.terminal () {
    sshpass -p "$GURU_PHONE_PASSWORD" ssh -oHostKeyAlgorithms=+ssh-dss "$GURU_PHONE_USER@$GURU_PHONE_IP" -p "$GURU_PHONE_PORT"
}


phone.mount () {
    # mount phone folder set as in phone ssh server settings
    local _mount_point="$HOME/phone-$GURU_PHONE_USER" ; [[ "$1" ]] && _mount_point="$1"
    if [[ -d "$_mount_point" ]] ; then mkdir -p "$_mount_point" ; fi
    sshfs -o HostKeyAlgorithms=+ssh-dss -p "$GURU_PHONE_PORT" "$GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0" "$_mount_point"
    return $?
}


phone.unmount () {
    local _mount_point="$HOME/phone-$GURU_PHONE_USER" ; [[ "$1" ]] && _mount_point="$1"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] && rmdir "$_mount_point"
    return $?
}


phone.remove_folder () {
    # makes empty folder in phone by removing and then creating target folder
    local _target_folder="$1"
    msg "${WHT}removing: $_target_folder${NC}\n"
    sshpass -p "$GURU_PHONE_PASSWORD" ssh "$GURU_PHONE_USER@$GURU_PHONE_IP" -p "$GURU_PHONE_PORT" -o "HostKeyAlgorithms=+ssh-dss" "rm -rf $_target_folder"
}


phone.process_videos () {
    local _video_format="mp4"
    mount.online $GURU_LOCAL_VIDEO || mount.known_remote video

    # analyze, tag and relocate video files
    local _file_list=($(ls "$phone_temp_folder" | grep ".$_video_format" ))                             # read file list

    if [[ ${_file_list[@]} ]]; then
            msg "${WHT}moving videos to $GURU_LOCAL_VIDEO ${NC}"
            local _year=1970

            for _file in ${_file_list[@]}; do
                    # count and printout
                    phone_file_count=$((phone_file_count+1))
                    [[ "$GURU_VERBOSE" ]] && printf "."

                    # get date for location
                    _date=${_file#*_} ; _date=${_date%_*}                                   #; echo "date: $_date"
                    _year=$(date -d $_date +'%Y') || _year=$(date +'%Y')                    #; echo "year: $_year"

                    # move file to target location
                    if ! [[ -d $GURU_LOCAL_VIDEO/$_year ]] ; then mkdir -p "$GURU_LOCAL_VIDEO/$_year" ; fi
                    mv "$phone_temp_folder/$_file" "$GURU_LOCAL_VIDEO/$_year" || FAILED "phone.get_camera_files: file $phone_temp_folder/$_file not found"            # place videos to right folders
                done
                [[ "$GURU_VERBOSE" ]] && echo
        else
            echo "no new videos"
        fi
}


phone.process_photos () {
    local _photo_format="jpg"
    mount.online $GURU_LOCAL_PHOTOS || mount.known_remote photos

     # analyze, tag and relocate photo files
    local _file_list=($(ls "$phone_temp_folder" | grep ".$_photo_format" ))                                      # read file list

    if [[ ${_file_list[@]} ]]; then
            msg "${WHT}tagging and moving photos to $GURU_LOCAL_PHOTOS ${NC}"
            local _year=1970
            local _month=1
            local _date=
            local _recognized=

            for _file in ${_file_list[@]}; do
                    # count and printout
                    phone_file_count=$((phone_file_count+1))
                    [[ "$GURU_VERBOSE" ]] && printf "."

                    # get date for location
                    _date=${_file#*_} ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}   #; echo "date: $_date"
                    _year=$(date -d $_date +'%Y' || date +'%Y')                                     #; echo "year: $_year"
                    _month=$(date -d $_date +'%m' || date +'%m')                                    #; echo "month: $_month"

                    # tag file
                    tag_main "$phone_temp_folder/$_file" add "phone photo $_date" >/dev/null 2>&1         # $_recognized

                    # move file to target location
                    if ! [[ -d $GURU_LOCAL_PHOTOS/$_year/$_month ]] ; then mkdir -p "$GURU_LOCAL_PHOTOS/$_year/$_month" ; fi
                    mv "$phone_temp_folder/$_file" "$GURU_LOCAL_PHOTOS/$_year/$_month" || FAILED "phone.get_camera_files: file $phone_temp_folder/$_file nto found"  # place pictures to right folders
                done
                [[ "$GURU_VERBOSE" ]] && echo
        else
            echo "no new photos"
        fi
}


phone.get_camera_files () {
    # get tag and place files
    if ! [[ -d "$phone_temp_folder" ]] ; then  mkdir -p "$phone_temp_folder" ; fi
    msg "${WHT}copying camera files from phone.. ${NC}\n"

    # get all files from phone DCIM folder and place to temp
    if [[ "$GURU_VERBOSE" ]] ; then _verb="-v" ; fi
    sshpass -p $GURU_PHONE_PASSWORD \
    scp $_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/DCIM/Camera/* $phone_temp_folder
    return $?
    #[[ -d $phone_temp_folder ]] && detox $phone_temp_folder/*
}


phone.camera () {

    phone.get_camera_files
    phone.process_photos
    phone.process_videos

    local _left_over=$(ls $phone_temp_folder)
    if [[ "$_left_over" ]] ; then
            echo "leftover files: $(ls $phone_temp_folder)"
            read -t 10 -p "remove leftovers from temp? : " _answ
            if [[ "$_answ" == "y" ]] ; then
                    # few checks to avoid 'rm -rf $HOME' or 'sudo rm -rf /' type if some of the variables are emty
                    [[ ${#phone_temp_folder} > 5 ]] && [[ -d "$phone_temp_folder" ]] && rm -rf "$phone_temp_folder"
                fi
        fi

    if ((phone_file_count<1)) ; then
            return 0
        fi

    printf "${WHT}%s files processed${NC}\n" "$phone_file_count"
    read -t 10 -p "remove source files from phone? : " _answ
    if [[ $GURU_FORCE ]] || [[ "$_answ" == "y" ]] ; then
            phone.remove_folder "/storage/emulated/0/DCIM/Camera"
        fi
}


phone.telegram () {
    # "Telegram/Telegram Audio"
    # "Telegram/Telegram Documents"
    # "Telegram/Telegram Images"
    # "Telegram/Telegram Video"
    if [[ "$GURU_VERBOSE" ]] ; then _verb="-v" ; fi

    mount.online $GURU_LOCAL_PICTURES || return 100

    local _target_folder="$GURU_SOMEDIA/telegram-pictures"

    msg "${WHT}copying Telegram images to $_target_folder ${NC}\n"
    if ! [[ -d "$_target_folder" ]] ; then mkdir -p "$_target_folder" ; fi

    sshpass -p $GURU_PHONE_PASSWORD \
    scp $_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/Telegram/Telegram Images/*' $_target_folder

    _target_folder="$GURU_SOMEDIA/telegram-videos"

    msg "${WHT}copying Telegram videos to $_target_folder ${NC}\n"
    if ! [[ -d "$_target_folder" ]] ; then mkdir -p "$_target_folder" ; fi

    sshpass -p $GURU_PHONE_PASSWORD \
    scp $_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/Telegram/Telegram Video/*' $_target_folder
}


phone.whatsapp() {
    # "WhatsApp/Media/WhatsApp Animated Gifs"
    # "WhatsApp/Media/WhatsApp Audio"
    # "WhatsApp/Media/WhatsApp Documents"
    # "WhatsApp/Media/WhatsApp Images"
    # "WhatsApp/Media/WhatsApp Video"
    # "WhatsApp/Media/WhatsApp Voice Notes"
    if [[ "$GURU_VERBOSE" ]] ; then _verb="-v" ; fi

    mount.online $GURU_LOCAL_PICTURES || return 100

    local _target_folder="$GURU_SOMEDIA/whatsapp-pictures"

    msg "${WHT}copying WhatsApp images to $_target_folder ${NC}\n"
    if ! [[ -d "$_target_folder" ]] ; then mkdir -p "$_target_folder" ; fi

    sshpass -p $GURU_PHONE_PASSWORD \
    scp $_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Images/*' $_target_folder

    _target_folder="$GURU_SOMEDIA/whatsapp-videos"

    msg "${WHT}copying WhatsApp videos to $_target_folder ${NC}\n"
    if ! [[ -d "$_target_folder" ]] ; then mkdir -p "$_target_folder" ; fi

    sshpass -p $GURU_PHONE_PASSWORD \
    scp $_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP':/storage/emulated/0/WhatsApp/Media/WhatsApp Video/*' $_target_folder

}


phone.downloads () {

    local _target_folder="$HOME/Downloads"

    msg "${WHT}copying WhatsApp videos to $_target_folder ${NC}\n"
    if ! [[ -d "$_target_folder" ]] ; then mkdir -p "$_target_folder" ; fi

    echo sshpass -p $GURU_PHONE_PASSWORD \
    scp -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
    $GURU_PHONE_USER@$GURU_PHONE_IP:/storage/emulated/0/Download/* $_target_folder

    [ "$?" = "0" ] && phone.remove_folder "/storage/emulated/0/Download"
}


phone.screenshots () {

    mount.online $GURU_LOCAL_PICTURES || return 100

    msg "${WHT}copying pictures..${NC}\n"
    echo sshpass -p $GURU_PHONE_PASSWORD scp -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_PHONE_PORT \
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
#${WHT}Timer${NC}

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


# # get date for location
# if [[ "${_file%_*}" == "IMG" ]] ; then                                          # huaway type
#     _date=${_file#*_} ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}   #; echo "date: $_date"

# elif date -d "${_file%-*}" +'%Y' ; then                                           # samsung type
#     _date="${_file%-*}" ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}   #; echo "date: $_date"


# _recognized="$(yolo.regonize $_file)"                                         # "a dig"
# tag_main "$_target_folder/$_file" rm  >/dev/null 2>&1                         # remove current tag (debug, new files should not be tagged)