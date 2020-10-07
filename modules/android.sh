#!/bin/bash
# guru-client android phone tools
# get files from android phone by connecting sshd running on phone
# install this to android phone: https://play.google.com/store/apps/details?id=com.theolivetree.sshserver

source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/tag.sh

if ((GURU_VERBOSE>1)) ; then android_verb="-v" ; fi

android_first_time="$HOME/.data/android-suveren"

android_temp_folder="/tmp/guru/android"
android_file_count=0
android_server_url="https://play.google.com/store/apps/details?id=com.theolivetree.sshserver"
android_config_file="$GURU_CFG/$GURU_USER/android.locations.cfg"


android.main () {
    # android phone command parser

    [[ "$1" == "help" ]] && android.help
    [[ $GURU_ANDROID_LAN_IP ]]        || read -p "phone ip: "     GURU_ANDROID_LAN_IP
    [[ $GURU_ANDROID_LAN_PORT ]]      || read -p "sshd port: "    GURU_ANDROID_LAN_PORT
    [[ $GURU_ANDROID_USERNAME ]]      || read -p "ssh user: "     GURU_ANDROID_USERNAME
    [[ $GURU_ANDROID_PASSWORD ]]      || read -p "password: "     GURU_ANDROID_PASSWORD

    local _cmd="$1" ; shift
    case "$_cmd" in
                    mount|unmount|terminal)  android.$_cmd "$1"         ;;  # tools
                              media|camera)  android.$_cmd              ;;  # phone locations
                                      help)  android.help               ;;
                                       all)  android.media
                                             android.camera             ;;
                                    status)  gmsg -c black "not connected" ;;
                            install|server)  sudo apt install sshpass sshfs fusermount
                                             $GURU_BROWSER $android_server_url ;;
                                         *)  echo "unknown action $_cmd"
        esac
}

android.help () {
    # printout help
    gmsg -v2
    gmsg -v1 -c white "guru-client android help "
    gmsg -v0  "usage:    $GURU_CALL android [s|add|open|rm|check|media|camera|all|install] "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1  " terminal          open terminal to android "
    gmsg -v1  " mount             mount android user folder "
    gmsg -v1  " unmount           unmount android "
    gmsg -v1  " camera            get, tag and relocate photos and videos from android "
    gmsg -v1  " whatsapp          get WhatsApp media from android "
    gmsg -v1  " telegram          get Telegram media from android "
    gmsg -v1  " downloads         get download folder from android "
    gmsg -v1  " pictures          get pictures from android "
    gmsg -v1  " install           install server to android (google play) "
    gmsg -v1  " help              help printout "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1  "             $GURU_CALL android mount "
    gmsg -v1  "             $GURU_CALL android camera "
    gmsg -v1  "             $GURU_CALL android terminal "
    gmsg -v2
    exit 0
}

android.confirm_key () {
    ssh -o HostKeyAlgorithms=+ssh-dss "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" -p "$GURU_ANDROID_LAN_PORT" &&  touch $android_first_time
}


android.terminal () {             # open ssh terminal connection to phone
    [[ -f $android_first_time ]] || android.confirm_key
    sshpass -p "$GURU_ANDROID_PASSWORD" ssh -o HostKeyAlgorithms=+ssh-dss "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" -p "$GURU_ANDROID_LAN_PORT"
    echo $?
}

android.mount () {                # mount phone folder set as in phone ssh server settings
    [[ -f $android_first_time ]] || android.confirm_key
    local _mount_point="$HOME/android-$GURU_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    if [[ -d "$_mount_point" ]] ; then mkdir -p "$_mount_point" ; fi
    sshfs -o HostKeyAlgorithms=androiddss -p "$GURU_ANDROID_LAN_PORT" "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:/storage/emulated/0" "$_mount_point"
    return $?
}

android.unmount () {              # unmount folder
    local _mount_point="$HOME/android-$GURU_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] &&androidr "$_mount_point"
    return $?
}

android.rmdir () {                # remove folder in phone

    local _target_folder="$1"
    msg "\n${WHT}removing: $_target_folder ${NC}"
    if sshpass -p "$GURU_ANDROID_PASSWORD" ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" -p "$GURU_ANDROID_LAN_PORT" -o "HostKeyAlgorithms=+ssh-dss" "rm -rf $_target_folder" ; then
            REMOVED
            return 0
        else
            IGNORED
            return 101
        fi
}

android.rm () {                   # remove files from phone

    local _target_files="$1"
    msg "\n${WHT}removing: $_target_files ${NC}"
    if sshpass -p "$GURU_ANDROID_PASSWORD" ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" -p "$GURU_ANDROID_LAN_PORT" -o "HostKeyAlgorithms=+ssh-dss" "rm -f $_target_files" ; then
            REMOVED
            return 0
        else
            IGNORED
            return 101
        fi
}

android.process_photos () {       # analyze, tag and relocate photo files
    local _photo_format="jpg"
    mount.online $GURU_LOCAL_PHOTOS || mount.known_remote photos

    local _file_list=($(ls "$android_temp_folder" | grep ".$_photo_format" ))                                      # read file list

    if [[ ${_file_list[@]} ]]; then
            msg "${WHT}tagging and moving photos to $GURU_LOCAL_PHOTOS ${NC}"
            local _year=1970
            local _month=1
            local _date=
            local _recognized=

            for _file in ${_file_list[@]}; do
                    # count and printout
                    android_file_count=$((android_file_count+1))
                    [[ "$GURU_VERBOSE" ]] && printf "."

                    # get date for location
                    _date=${_file#*_} ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}   #; echo "date: $_date"
                    _year=$(date -d $_date +'%Y' || date +'%Y')                                     #; echo "year: $_year"
                    _month=$(date -d $_date +'%m' || date +'%m')                                    #; echo "month: $_month"

                    # tag file
                    tag_main "$android_temp_folder/$_file" add "phone photo $_date" >/dev/null 2>&1         # $_recognized

                    # move file to target location
                    if ! [[ -d $GURU_LOCAL_PHOTOS/$_year/$_month ]] ; then mkdir -p "$GURU_LOCAL_PHOTOS/$_year/$_month" ; fi
                    mv "$android_temp_folder/$_file" "$GURU_LOCAL_PHOTOS/$_year/$_month" || FAILED "android.get_camera_files: file $android_temp_folder/$_file nto found"  # place pictures to right folders
                done
                [[ "$GURU_VERBOSE" ]] && DONE
        else
            echo "no new photos"
        fi
}

android.process_videos () {       # analyze, tag and relocate video files
    local _video_format="mp4"
    mount.online $GURU_LOCAL_VIDEO || mount.known_remote video

    local _file_list=($(ls "$android_temp_folder" | grep ".$_video_format" ))                             # read file list

    if [[ ${_file_list[@]} ]]; then
            msg "${WHT}moving videos to $GURU_LOCAL_VIDEO ${NC}"
            local _year=1970

            for _file in ${_file_list[@]}; do
                    # count and printout
                    android_file_count=$((android_file_count+1))
                    [[ "$GURU_VERBOSE" ]] && printf "."

                    # get date for location
                    _date=${_file#*_} ; _date=${_date%_*}                                   #; echo "date: $_date"
                    _year=$(date -d $_date +'%Y') || _year=$(date +'%Y')                    #; echo "year: $_year"

                    # move file to target location
                    if ! [[ -d $GURU_LOCAL_VIDEO/$_year ]] ; then mkdir -p "$GURU_LOCAL_VIDEO/$_year" ; fi
                    mv "$android_temp_folder/$_file" "$GURU_LOCAL_VIDEO/$_year" || FAILED "android.get_camera_files: file $android_temp_folder/$_file not found"            # place videos to right folders
                done
                [[ "$GURU_VERBOSE" ]] && echo
        else
            echo "no new videos"
        fi
}

android.camera () {               # flush camera

    android.process_photos
    android.process_videos

    local _left_over=$(ls $android_temp_folder)
    if [[ "$_left_over" ]] ; then
            echo "leftover files: $(ls $android_temp_folder)"
            read -t 10 -p "remove leftovers from temp? : " _answ
            if [[ "$_answ" == "y" ]] ; then
                    # few checks to avoid 'rm -rf $HOME' or 'sudo rm -rf /' type if some of the variables are emty
                    [[ ${#android_temp_folder} > 5 ]] && [[ -d "$android_temp_folder" ]] && rm -rf "$android_temp_folder"
                fi
        fi

    if ((android_file_count<1)) ; then
            return 0
        fi

    printf "${WHT}%s files processed${NC}\n" "$android_file_count"
    read -t 10 -p "remove source files from phone? : " _answ
    if [[ $GURU_FORCE ]] || [[ "$_answ" == "y" ]] ; then
            android.rmdir "/storage/emulated/0/DCIM/Camera"
        fi
}

android.media () {                # Get all media files from phone

    mount.online $GURU_LOCAL_PICTURES || mount.known_remote pictures
    mount.online $GURU_LOCAL_DOCUMENTS || mount.known_remote documents
    mount.online $GURU_LOCAL_VIDEO || mount.known_remote video
    mount.online $GURU_LOCAL_AUDIO || mount.known_remote audio

    while IFS= read -r _line ; do
            IFS='>' ; _list=($_line) ; IFS=           #; echo "${_list[0]}:${_list[1]}:${_list[2]}"
            _action=${_list[0]}                       #; echo ":$_action:"   # cp=copy, mv=move
            _type=${_list[1]}                         #; echo ":$_type:"     # filetype
            _title=${_list[2]}                        #; echo ":$_title:$_source:$_target:"
            _source=${_list[3]}
            _target=$(eval echo "${_list[4]}")

            msg "${WHT}$_title > $_target.. ${NC}"
            if ! [[ -d "$_target" ]] ; then mkdir -p "$_target" ; fi

            sshpass -p $GURU_ANDROID_PASSWORD \
            scp $android_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_ANDROID_LAN_PORT \
            $GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:"$_source/*.$_type" $_target

            case $? in
                    0)  DONE ; [[ "$_action" == "mv" ]] && echo android.rmdir "$_source" ;;  # /*.$_type" ;; # does not work cause *
                    *)  FAILED
                esac

        done < "$android_config_file"
}


android.install () {
    sshpass -V >/dev/null || sudo apt install sshpass
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$HOME/.gururc2"
        android.main "$@"
    fi



# "Telegram/Telegram Audio"
# "Telegram/Telegram Documents"
# "WhatsApp/Media/WhatsApp Documents"
# "Telegram/Telegram Images"
# "Telegram/Telegram Video"
# "WhatsApp/Media/WhatsApp Animated Gifs"
# "WhatsApp/Media/WhatsApp Audio"
# "WhatsApp/Media/WhatsApp Images"
# "WhatsApp/Media/WhatsApp Video"
# "WhatsApp/Media/WhatsApp Voice Notes"

# if [[ "$GURU_ANDROID_USERNAME" = "casa" ]]; then
#   sshpass -p $GURU_ANDROID_PASSWORD scp -v -r -p -oHostKeyAlgorithms=+ssh-dss -P $GURU_ANDROID_LAN_PORT $GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:/storage/emulated/0/MyTinyScan/Documents/* $HOME/Documents
# fi
#${WHT}Timer${NC}

# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_ANDROID_LAN_PORT" maea@192.168.1.50:/storage/emulated/0/WhatsApp/Media/* $GURU_LOCAL_PHOTOS/2019/wa
# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_ANDROID_LAN_PORT" casa@192.168.1.29:/storage/emulated/0/WhatsApp/Media/* $GURU_LOCAL_PHOTOS/2019/wa
#   casa@192.168.1.29's password:
#   exec request failed on channel 0
#   rsync: connection unexpectedly closed (0 bytes received so far) [Receiver]
#   rsync error: unexplained error (code 255) at io.c(235) [Receiver=3.1.2]


# ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_ANDROID_LAN_PORT casa@192.168.1.29
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
# tag_main "$_target_files/$_file" rm  >/dev/null 2>&1                         # remove current tag (debug, new files should not be tagged)