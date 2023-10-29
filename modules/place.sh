#!/bin/bash
# guru-client single file place template casa@ujo.guru 2022

declare -g temp_file="/tmp/guru-place.tmp"
declare -g place_indicator_key="f5"

source mount.sh
mount.rc

place.help () {
    # user help
    gr.msg -n -v2 -c white "guru-cli place help "
    gr.msg -v1 "fuzzy logic to place files to right locations."
    gr.msg -v2
    gr.msg -c white -n -v0 "usage:    "
    gr.msg -v0 "$GURU_CALL place ls|help|poll|memes|photos|videos|media"
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v2 " ls       list of places "
    gr.msg -v2 " help     printout this help "
    gr.msg -v1 " memes    move memes to $GURU_MOUNT_PICTURES/memes"
    gr.msg -v1 " photos   move photos to $GURU_MOUNT_PHOTOS "
    gr.msg -v1 " videos   move videos to $GURU_MOUNT_VIDEO"
    gr.msg -v1 " media    move media to somewhere"
    gr.msg -v2
    gr.msg -n -v1 -c white "example:  "
    gr.msg -v1 "$GURU_CALL place ls"
    gr.msg -v2
}


place.main () {
    # main command parser

    local function="$1" ; shift

    case "$function" in
            ls|help|poll|memes|photos|videos|media|project|status)
                place.$function $@
                return $?
                ;;
            *)
                place.help
                return 0
                ;;
        esac
}


place.status () {
    gr.msg -t -n "${FUNCNAME[0]}: "
    gr.msg -v1 -c dark_gray "no status information"
    return 0
}


place.project () {
# place filenames starting with project name to project folder
# just prototyping

    source project.sh
    local _project_list=($(project.list))
    local _project_name=$1
    local _temp_location=
    local _date=

    project.info $_project_name

    for _project in ${_project_list[@]} ; do
        printf "$_project "
    done

    # tag file
    # local _tag_string=
    # [[ $_tag_string ]] && _tag_string="$_project_name $_date ${FUNCNAME[0]}"
    # tag.main "$_temp_location/$_file" add "$_tag_string" # >/dev/null 2>&1

}


place.memes () {
# place pictures and videos with 9gag patterns to meme folder
    local picture_pattern='*bwp.* *swp* *w_0.* *wp_0.*'
    local video_pattern='*_460s* *_700w*'
    local meme_folder="$GURU_MOUNT_PICTURES/memes"

    if ! [[ -f $GURU_MOUNT_PICTURES/.online ]] ; then
            source mount.sh
            mount.main pictures || return 123
        fi

    if ! [[ -d $meme_folder ]] ; then
        mkdir -p $meme_folder
        fi

    # look for 9gag pictures
    mv $(printf '%s\n' $picture_pattern | grep -e webp -e png -e jpg -e avif) $meme_folder >/dev/null 2>/dev/null

    # look for 9gag videos
    mv $(printf '%s\n' $video_pattern | grep -e webm -e mp4) $meme_folder >/dev/null 2>/dev/null

}


place.photos () {
# analyze, tag and relocate photo files

    #source mount.sh

    local phone_temp_folder="/tmp/guru/android"
    local _photo_format="jpg"
    [[ $1 ]] && _photo_format=$1

    mount.online $GURU_MOUNT_PHOTOS || mount.known_remote photos

    # when $phone_temp_folder/photos if filled?

    # read file list
    local _file_list=($(ls "$phone_temp_folder/photos" 2>/dev/null | grep ".$_photo_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gr.msg -c dark_crey "no new photos"
            return 0
        fi

    gr.msg -v2 -c white "tagging and moving photos to $GURU_MOUNT_PHOTOS "

    local _year=1970
    local _month=1
    local _date=
    local _recognized=
    local android_file_count=0

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

            # tag file
            tag.main "$phone_temp_folder/photos/$_file" add "phone photo $_date" >/dev/null 2>&1

            # move file to target location
            if ! [[ -d $GURU_MOUNT_PHOTOS/$_year/$_month ]] ; then
                    mkdir -p "$GURU_MOUNT_PHOTOS/$_year/$_month"
                    gr.msg -n -v1 -V2 "o"
                    gr.msg -N -v2 "$GURU_MOUNT_PHOTOS/$_year/$_month"
                fi

            # place photos to right folders
            if mv "$phone_temp_folder/photos/$_file" "$GURU_MOUNT_PHOTOS/$_year/$_month" ; then
                    gr.msg -n -v1 -V2 "."
                    gr.msg -n -v2 "$_file "
                else
                    gr.msg -N -c yellow  "$FUNCNAME error: file $phone_temp_folder/photos/$_file not found"
                fi
        done
    gr.msg -N -v1 -c green "done"
    return 0
}


place.videos () {
    # analyze, tag and relocate video files

    local phone_temp_folder="/tmp/guru/android"
    local _video_format="mp4"
    [[ $1 ]] && _video_format=$1

    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video

    # read file list
    local _file_list=($(ls "$phone_temp_folder/videos" 2>/dev/null | grep ".$_video_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gr.msg -c dark_crey "no new videos"
            return 0
        fi

    gr.msg -n -c white "moving videos to $GURU_MOUNT_VIDEO "
    local _year=1970
    local android_file_count=0

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
            if mv "$phone_temp_folder/videos/$_file" "$GURU_MOUNT_VIDEO/$_year" ; then
                    gr.msg -n -v1 -V2 "."
                    gr.msg -n -v2 "$_file "
                else
                    gr.msg -N -c yellow  "$FUNCNAME error: $phone_temp_folder/videos/$_file not found"
                fi
        done
    gr.msg -v1
    return 0
}


place.media () {
    # process photos and videos from camera
    # expects that filesa are already copied/moved from home to $phone_temp_folder

    mount.online $GURU_MOUNT_PHOTOS || mount.known_remote photos
    mount.online $GURU_MOUNT_VIDEO || mount.known_remote video

    place.photos "jpg"
    place.videos "mp4"

    local phone_temp_folder="/tmp/guru/android"
    local _left_over=$(ls $phone_temp_folder)

    if [[ "$_left_over" ]] ; then
            gr.msg -v1 "left over files:"
            gr.msg -v1 -c light_blue "$_left_over"

            if gr.ask "remove leftovers from temp" ; then
                    [[ -d "$phone_temp_folder" ]] && rm -rf "$phone_temp_folder"
                fi
        fi

 #   if ((android_file_count<1)) ; then
 #           return 0
 #       fi

    gr.msg -c white "$android_file_count files processed"

    if [[ $GURU_FORCE ]] || gr.ask "remove source files from phone" ; then
            source android.sh
            android.rmdir "/storage/emulated/0/DCIM/Camera"
        fi
}


place.ls () {
    # list something
    GURU_VERBOSE=2
    if [[ $GURU_MOUNT_ENABLED ]] ; then
            # source mount.sh
            [[ $GURU_VERBOSE -lt 2 ]] \
                && mount.main ls \
                || mount.main info
        fi

    # test and return result
    return 0
}



place.poll () {
    # daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $place_indicator_key ]] || \
        place_indicator_key="f$(gr.poll place)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: place status polling started" -k $place_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: place status polling ended" -k $place_indicator_key
            ;;
        status)
            place.status $@
            ;;
        *)  place.help
            ;;
        esac
}


place.install () {

    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gr.msg "nothing to install"
    return 0
}

place.remove () {

    # sudo apt remove -y ...
    # pip3 remove --user ...
    gr.msg "nothing to remove"
    return 0
}

# if called place.sh file configuration is sourced and main place.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GURU_RC"
    place.main "$@"
    exit "$?"
fi

