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
    gr.msg -v2
    gr.msg -v1 -c white "guru-client android help "
    gr.msg -v0  "usage:    $GURU_CALL android [s|add|open|rm|check|media|camera|all|install] "
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1  " terminal          open terminal to android "
    gr.msg -v1  " media             download all media from phone "
    gr.msg -v1  " mount             mount android user folder "
    gr.msg -v1  " unmount           unmount android "
    gr.msg -v1  " install           install server to android (google play) "
    gr.msg -v1  " help              help printout "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1  "             $GURU_CALL android mount "
    gr.msg -v1  "             $GURU_CALL android camera "
    gr.msg -v1  "             $GURU_CALL android terminal "
    gr.msg -v2
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
    gr.msg -v1 -N -c white "mounting $_mount_point"

    if [[ -d "$_mount_point" ]] ; then mkdir -p "$_mount_point" ; fi
    sshfs -o HostKeyAlgorithms=androiddss -p "$GURU_ANDROID_LAN_PORT" \
        "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP:/storage/emulated/0" \
        "$_mount_point"
    return $?
}


android.unmount () {
    # unmount folder
    local _mount_point="$HOME/android-$GURU_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    gr.msg -v1 -N -c white "unmounting $_mount_point"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] &&androidr "$_mount_point"
    return $?
}


android.rmdir () {
    # remove folder in phone
    local _target_folder="$1" ; shift
    gr.msg -v1 -N -c white "removing: $_target_folder"

    if sshpass -p "$GURU_ANDROID_PASSWORD" \
        ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -rf $_target_folder"

        then
            gr.msg -c green "removed"
            return 0

        else
            gr.msg -c dark_gold_rod "ignored"
            return 101
        fi
}


android.rm () {
    # remove files from phone
    local _target_files="$1" ; shift
    gr.msg -v1 -N -c white "removing: $_target_files"

    if sshpass -p "$GURU_ANDROID_PASSWORD" \
        ssh "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP" \
        -p "$GURU_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -f $_target_files"
        then
            gr.msg -c green "removed"
            return 0
        else
            gr.msg -c dark_gold_rod "ignored"
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
            gr.msg -c dark_crey "no new photos"
            return 0
        fi

    gr.msg -c white "tagging and moving photos to $GURU_MOUNT_PHOTOS "

    local _year=1970
    local _month=1
    local _date=
    local _recognized=

    for _file in ${_file_list[@]}; do

            # count and printout
            android_file_count=$((android_file_count+1))

            # get date for location
            _date=${_file#*_} ; _date=${_date%_*} ; _date=${_date%_*} ; _date=${_date%_*}
            gr.msg -v2 "date: $_date"
            _year=$(date -d $_date +'%Y' || date +'%Y')
            gr.msg -v2 "year: $_year"
            _month=$(date -d $_date +'%m' || date +'%m')
            gr.msg -v2 "month: $_month"

            # tag file   # $_recognized
            tag_main "$android_temp_folder/photos/$_file" add "phone photo $_date" >/dev/null 2>&1

            # move file to target location
            if ! [[ -d $GURU_MOUNT_PHOTOS/$_year/$_month ]] ; then
                    mkdir -p "$GURU_MOUNT_PHOTOS/$_year/$_month"
                    gr.msg -n -v1 -V2 "o"
                    gr.msg -N -v2 "$GURU_MOUNT_PHOTOS/$_year/$_month"
                fi

            # place photos to right folders
            if mv "$android_temp_folder/photos/$_file" "$GURU_MOUNT_PHOTOS/$_year/$_month" ; then
                    gr.msg -n -v1 -V2 "."
                    gr.msg -n -v2 "$_file "
                else
                    gr.msg -N -c yellow  "$FUNCNAME error: file $android_temp_folder/photos/$_file not found"
                fi


        done

    gr.msg -N -v1 -c green "done"
    return 0
}


android.process_videos () {
    # analyze, tag and relocate video files

    local _video_format="$1" ; shift
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video

    # read file list
    local _file_list=($(ls "$android_temp_folder/videos" | grep ".$_video_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gr.msg -c dark_crey "no new videos"
            return 0
        fi

    gr.msg -n -c white "moving videos to $GURU_MOUNT_VIDEO "
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
                    gr.msg -n -v1 -V2 "o"
                    gr.msg -N -v2 "$GURU_MOUNT_VIDEO/$_year"
                fi

            # place videos to right folders
            if mv "$android_temp_folder/videos/$_file" "$GURU_MOUNT_VIDEO/$_year" ; then
                    gr.msg -n -v1 -V2 "."
                    gr.msg -n -v2 "$_file "
                else
                    gr.msg -N -c yellow  "$FUNCNAME error: $android_temp_folder/videos/$_file not found"
                fi

        done

    gr.msg -v1
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
            gr.msg -v1 "left over files:"
            gr.msg -v1 -c light_blue "$_left_over"

            if gr.ask "remove leftovers from temp" ; then
                    [[ -d "$android_temp_folder" ]] && rm -rf "$android_temp_folder"
                fi
        fi

    if ((android_file_count<1)) ; then
            return 0
        fi

    gr.msg -c white "$android_file_count files processed"

    if [[ $GURU_FORCE ]] || gr.ask "remove source files from phone" ; then
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

    gr.msg -n -v1 "copying files "
    while IFS= read -r _line ; do

            gr.msg -v3 -c dark_cyan ":$_line:"
            _ifs=$IFS ; IFS='>' ; _list=($_line) ; IFS=$_ifs

            gr.msg -v3 -c green ":${_list[@]}:"

            _action=${_list[0]}
            gr.msg -v3 -c deep_pink ":$_action:"   # cp=copy, mv=move

            _type=${_list[1]}
            gr.msg -v3 -c deep_pink ":$_type:"     # filetype

            _title=${_list[2]}
            _source=${_list[3]}
            _target=$(eval echo "${_list[4]}")
            gr.msg -v3 -c deep_pink ":$_title:"
            gr.msg -v3 -c deep_pink ":$_source:"
            gr.msg -v3 -c deep_pink ":$_target:"

            gr.msg -v1 -V2 -n "."
            gr.msg -n -v2 -c dark_crey "$_title > $_target "
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
                    gr.msg -c deep_pink -v3 "$GURU_ANDROID_USERNAME@$GURU_ANDROID_LAN_IP $_source not exist"
                fi

            case $_error in
                    0)  gr.msg -v1 -c green "done"
                        [[ "$_action" == "mv" ]] && echo android.rmdir "$_source"
                        ;;
                    *)  gr.msg -c yellow "$_source $_type failed"
                        ;;
                esac

        done < "$android_config_file"
}


android.install () {
    sshpass -V >/dev/null || sudo apt install sshpass
}


android.status () {
    gr.msg "nothing to report"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
        android.main "$@"
    fi

