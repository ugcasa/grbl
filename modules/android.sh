#!/bin/bash
# guru-client android phone tools
# get files from android phone by connecting sshd running on phone
# install this to android phone: https://play.google.com/store/apps/details?id=com.theolivetree.sshserver

source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/tag.sh
android_verb="-q"
if ((GURU_VERBOSE>2)) ; then android_verb="-v" ; fi
android_first_time="$HOME/.data/android-suveren"
android_temp_folder="/tmp/guru/android"
android_file_count=0
android_server_url="https://play.google.com/store/apps/details?id=com.theolivetree.sshserver"
android_config_file="$GURU_CFG/android.locations.cfg"


android.main () {
    # android phone command parser
    [[ $GURU_ANDROID_LAN_IP ]]        || read -p "phone ip: "     GURU_ANDROID_LAN_IP
    [[ $GURU_ANDROID_LAN_PORT ]]      || read -p "sshd port: "    GURU_ANDROID_LAN_PORT
    [[ $GURU_ANDROID_USERNAME ]]      || read -p "ssh user: "     GURU_ANDROID_USERNAME
    [[ $GURU_ANDROID_PASSWORD ]]      || read -p "password: "     GURU_ANDROID_PASSWORD

    local _cmd="$1" ; shift
    case "$_cmd" in
        mount|unmount|terminal|status|help|media|camera|install)
                                 android.$_cmd "$@" ; return $? ;;
                           all)  android.media
                                 android.camera     ; return $? ;;
                             *)  echo "unknown action $_cmd"
        esac
}


android.isntall () {
    sudo apt install sshpass sshfs fusermount
    $GURU_BROWSER $android_server_url
}


android.help () {
    # printout help
    gmsg -v2
    gmsg -v1 -c white "guru-client android help "
    gmsg -v0  "usage:    $GURU_CALL android [s|add|open|rm|check|media|camera|all|install] "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1  " terminal          open terminal to android "
    gmsg -v1  " media             download all media from phone "
    gmsg -v1  " mount             mount android user folder "
    gmsg -v1  " unmount           unmount android "
    gmsg -v1  " install           install server to android (google play) "
    gmsg -v1  " help              help printout "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1  "             $GURU_CALL android mount "
    gmsg -v1  "             $GURU_CALL android camera "
    gmsg -v1  "             $GURU_CALL android terminal "
    gmsg -v2
    return 0
}


android.confirm_key () {
    if ssh -o HostKeyAlgorithms=+ssh-dss "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT"
        then
            touch $android_first_time
        fi
}


android.terminal () {
    # open ssh terminal connection to phone
    [[ -f $android_first_time ]] || android.confirm_key
    sshpass -p "$GURU_ANDROID_PASSWORD" \
        ssh -o HostKeyAlgorithms=+ssh-dss "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT"
    echo $?
    return $?
}


android.mount () {
    # mount phone folder set as in phone ssh server settings
    [[ -f $android_first_time ]] || android.confirm_key
    local _mount_point="$HOME/android-$GURU_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    gmsg -v1 -N -c white "mounting $_mount_point"

    if [[ -d "$_mount_point" ]] ; then mkdir -p "$_mount_point" ; fi
    sshfs -o HostKeyAlgorithms=androiddss -p "$GURU_ANDROID_LAN_PORT" \
        "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:/storage/emulated/0" \
        "$_mount_point"
    return $?
}


android.unmount () {
    # unmount folder
    local _mount_point="$HOME/android-$GURU_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    gmsg -v1 -N -c white "unmounting $_mount_point"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] &&androidr "$_mount_point"
    return $?
}


android.rmdir () {
    # remove folder in phone
    local _target_folder="$1" ; shift
    gmsg -v1 -N -c white "removing: $_target_folder"

    if sshpass -p "$GURU_ANDROID_PASSWORD" \
        ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -rf $_target_folder"

        then
            gmsg -c green "removed"
            return 0

        else
            gmsg -c dark_gold_rod "ignored"
            return 101
        fi
}


android.rm () {
    # remove files from phone
    local _target_files="$1" ; shift
    gmsg -v1 -N -c white "removing: $_target_files"

    if sshpass -p "$GURU_ANDROID_PASSWORD" \
        ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -f $_target_files"
        then
            gmsg -c green "removed"
            return 0
        else
            gmsg -c dark_gold_rod "ignored"
            return 101
        fi
}


android.process_photos () {
    # analyze, tag and relocate photo files

    local _photo_format="$1" ; shift
    mount.online $GURU_MOUNT_PHOTOS || mount.known_remote photos

    # when $android_temp_folder/photos if filled?

    # read file list
    local _file_list=($(ls "$android_temp_folder/photos" | grep ".$_photo_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gmsg -c dark_crey "no new photos"
            return 0
        fi

    gmsg -c white "tagging and moving photos to $GURU_MOUNT_PHOTOS "

    local _year=1970
    local _month=1
    local _date=
    local _recognized=

    for _file in ${_file_list[@]}; do

            # count and printout
            android_file_count=$((android_file_count+1))

            # get date for location
            _date=${_file#*_} ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}
            gmsg -v2 "date: $_date"
            _year=$(date -d $_date +'%Y' || date +'%Y')
            gmsg -v2 "year: $_year"
            _month=$(date -d $_date +'%m' || date +'%m')
            gmsg -v2 "month: $_month"

            # tag file   # $_recognized
            tag_main "$android_temp_folder/photos/$_file" add "phone photo $_date" >/dev/null 2>&1

            # move file to target location
            if ! [[ -d $GURU_MOUNT_PHOTOS/$_year/$_month ]] ; then
                    mkdir -p "$GURU_MOUNT_PHOTOS/$_year/$_month"
                    gmsg -n -v1 -V2 "o"
                    gmsg -N -v2 "$GURU_MOUNT_PHOTOS/$_year/$_month"
                fi

            # place photos to right folders
            if mv "$android_temp_folder/photos/$_file" "$GURU_MOUNT_PHOTOS/$_year/$_month" ; then
                    gmsg -n -v1 -V2 "."
                    gmsg -n -v2 "$_file "
                else
                    gmsg -N -c yellow  "$FUNCNAME error: file $android_temp_folder/photos/$_file not found"
                fi


        done

    gmsg -N -v1 -c green "done"
    return 0
}


android.process_videos () {
    # analyze, tag and relocate video files

    local _video_format="$1" ; shift
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video

    # read file list
    local _file_list=($(ls "$android_temp_folder/videos" | grep ".$_video_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gmsg -c dark_crey "no new videos"
            return 0
        fi

    gmsg -n -c white "moving videos to $GURU_MOUNT_VIDEO "
    local _year=1970

    for _file in ${_file_list[@]}; do
            # count and printout
            android_file_count=$((android_file_count+1))

            # get date for location
            _date=${_file#*_} ; _date=${_date%_*}
            # echo "date: $_date"
            _year=$(date -d $_date +'%Y') || _year=$(date +'%Y')
            # echo "year: $_year"

            # move file to target location
            if ! [[ -d $GURU_MOUNT_VIDEO/$_year ]] ; then
                    mkdir -p "$GURU_MOUNT_VIDEO/$_year"
                    gmsg -n -v1 -V2 "o"
                    gmsg -N -v2 "$GURU_MOUNT_VIDEO/$_year"
                fi

            # place videos to right folders
            if mv "$android_temp_folder/videos/$_file" "$GURU_MOUNT_VIDEO/$_year" ; then
                    gmsg -n -v1 -V2 "."
                    gmsg -n -v2 "$_file "
                else
                    gmsg -N -c yellow  "$FUNCNAME error: $android_temp_folder/videos/$_file not found"
                fi

        done

    gmsg -v1
    return 0
}


android.camera () {
    # process photos and videos from camera
    # expects that filesa are already copied/moved from home to $android_temp_folder

    mount.online $GURU_MOUNT_PHOTOS || mount.known_remote photos
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video

    android.process_photos "jpg"
    android.process_videos "mp4"

    local _left_over=$(ls $android_temp_folder)

    if [[ "$_left_over" ]] ; then
            gmsg -v1 "left over files:"
            gmsg -v1 -c light_blue "$_left_over"

            if gask "remove leftovers from temp" ; then
                    [[ -d "$android_temp_folder" ]] && rm -rf "$android_temp_folder"
                fi
        fi

    if ((android_file_count<1)) ; then
            return 0
        fi

    gmsg -c white "$android_file_count files processed"

    if [[ $GURU_FORCE ]] || gask "remove source files from phone" ; then
            android.rmdir "/storage/emulated/0/DCIM/Camera"
        fi
}


android.media () {
    # Get all media files from phone

    mount.online $GURU_MOUNT_PHOTOS || mount.known_remote photos
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video
    mount.online $GURU_MOUNT_PICTURES || mount.known_remote pictures
    mount.online $GURU_MOUNT_DOCUMENTS || mount.known_remote documents
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video
    mount.online $GURU_MOUNT_AUDIO || mount.known_remote audio

    gmsg -n -v1 "copying files "
    while IFS= read -r _line ; do

            gmsg -v3 -c dark_cyan ":$_line:"
            _ifs=$IFS ; IFS='>' ; _list=($_line) ; IFS=$_ifs

            gmsg -v3 -c green ":${_list[@]}:"

            _action=${_list[0]}
            gmsg -v3 -c deep_pink ":$_action:"   # cp=copy, mv=move

            _type=${_list[1]}
            gmsg -v3 -c deep_pink ":$_type:"     # filetype

            _title=${_list[2]}
            _source=${_list[3]}
            _target=$(eval echo "${_list[4]}")
            gmsg -v3 -c deep_pink ":$_title:"
            gmsg -v3 -c deep_pink ":$_source:"
            gmsg -v3 -c deep_pink ":$_target:"

            gmsg -v1 -V2 -n "."
            gmsg -n -v2 -c dark_crey "$_title > $_target "
            if ! [[ -d "$_target" ]] ; then mkdir -p "$_target" ; fi



            # check folder exits
            if sshpass -p $GURU_ANDROID_PASSWORD \
                    ssh -o HostKeyAlgorithms=+ssh-dss -o StrictHostKeyChecking=no -p $GURU_ANDROID_LAN_PORT \
                    $GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP stat "$_source"
                then
                    # copy all files in requested type $android_verb
                    sshpass -p $GURU_ANDROID_PASSWORD \
                    scp $android_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GURU_ANDROID_LAN_PORT \
                    $GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:"$_source/*.$_type" $_target
                    _error=$?
                else
                    gmsg -c deep_pink -v3 "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP $_source not exist"
                fi

            case $_error in
                    0)  gmsg -v1 -c green "done"
                        [[ "$_action" == "mv" ]] && echo android.rmdir "$_source"
                        ;;
                    *)  gmsg -c yellow "$_source $_type failed"
                        ;;
                esac

        done < "$android_config_file"
}


android.install () {
    sshpass -V >/dev/null || sudo apt install sshpass
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
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

# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_ANDROID_LAN_PORT" maea@192.168.1.50:/storage/emulated/0/WhatsApp/Media/* $GURU_MOUNT_PHOTOS/2019/wa
# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p$GURU_ANDROID_LAN_PORT" casa@192.168.1.29:/storage/emulated/0/WhatsApp/Media/* $GURU_MOUNT_PHOTOS/2019/wa
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