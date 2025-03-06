#!/bin/bash
# grbl single file place template casa@ujo.guru 2022

declare -g temp_file="/tmp/$USER/grbl-place.tmp"
declare -g place_indicator_key="f5"
declare -g place_rc="/tmp/$USER/grbl_place.rc"
declare -g undo_script=/tmp/$USER/grbl-place-undo.rc

place.help () {
    # user help
    gr.msg -h "grbl place help "
    gr.msg -v2
    gr.msg -v1 "mime type based and fuzzy logic to place files to right locations."
    gr.msg -v2
    gr.msg -v1 "usage:    " -c white
    gr.msg -v0 "    $GRBL_CALL place ls|help|poll|memes|photos|videos|media"
    gr.msg -v0 "    $GRBL_CALL place mime list|move|dryrun"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v2 " ls             list of places "
    gr.msg -v2 " help           printout this help "
    gr.msg -v1 " memes          move memes to $GRBL_MOUNT_PICTURES/memes"
    gr.msg -v1 " photos         move photos to $GRBL_MOUNT_PHOTOS "
    gr.msg -v1 " videos         move videos to $GRBL_MOUNT_VIDEO"
    gr.msg -v1 " media          move media to somewhere"
    gr.msg -v2
    gr.msg -v1 "mime: " -c white
    gr.msg -v1 " mime list      list files and destination locations based on mime types"
    gr.msg -v1 " mime move      move files from current folder to places specified in user configurations"
    gr.msg -v2 " mime dryrun    act as list+move but do not perform move"
    gr.msg -v1 " mime type      list of available mime type categories"
    gr.msg -v1 " mime <type>    move matched mime type category from list given by user"
    gr.msg -v1 " mime undo      undo last moves. run undo manually: 'bash $undo_script'"
    gr.msg -v2
    gr.msg -v1 "example:  " -c white
    gr.msg -v1      "$GRBL_CALL place ls                # list of found files that can be moved based on name"
    gr.msg -v1      "$GRBL_CALL mime list               # list of found files that can be moved based on mime type"
    gr.msg -v1      "$GRBL_CALL mime move               # move all files to their destination locations"
    gr.msg -v1      "$GRBL_CALL mime image video        # move images and videos to their destination locations"
    gr.msg -v2
}


place.main () {
    # main command parser

    local function="$1" ; shift

    case "$function" in
            mime|ls|help|poll|memes|photos|videos|media|project|status)
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


place.mime () {
# place files to locations by mime type. User configuration specifies destination location.
# contain lot of checks to avoid misbehaving, but still USE CAREFULLY
# to be run in source folder from where files should be moved

    declare -ga type_list dest_list file_names mime_types image video audio other_system archive document code other
    declare -gi file_count=0 moved_files=0 sorted_files=0 ignored_files=0 directory=0

    mime.config () {
    # get configurations

        type_list=($GRBL_PLACE_TYPE_LIST)
        # type_list=(image video audio other_system archive document code other)
        gr.debug "$FUNCNAME type_list: ${type_list[@]}"
        if ! [[ $type_list ]] ; then
            gr.msg -e3 "type list is empty, check place.cfg in user configurations"
            return 98
        fi

        dest_list=($GRBL_PLACE_DEST_LIST)
        # dest_list=($GRBL_MOUNT_PICTURES $GRBL_MOUNT_VIDEO $GRBL_MOUNT_AUDIO $HOME $GRBL_MOUNT_DOCUMENTS $GRBL_MOUNT_DOCUMENTS $HOME/git $HOME)
        gr.debug "$FUNCNAME dest_list: ${dest_list[@]}"
        if ! [[ $dest_list ]] ; then
            gr.msg -e3 "destination list is empty, check place.cfg in user configurations"
            return 99
        fi

        if [[ ${#type_list[@]} != ${#dest_list[@]} ]] ; then
            gr.msg -e3 "type and destination length mismatch, check place.cfg in user configurations"
            return 100
        fi
    }

     mime.given_list () {
    # process list given by user
        local _type_list=()
        local _dest_list=()

        [[ $1 ]] || return 0

        # check list of type given by user
        while [[ $1 ]] ; do
            gr.debug "$FUNCNAME param: '$1'"
            for (( i = 0; i < ${#type_list[@]}; i++ )); do
                if [[ "$1" == "${type_list[$i]}" ]] ; then
                    _type_list+=( "${type_list[$i]}" )
                    _dest_list+=( "${dest_list[$i]}" )
                fi
            done
            shift
        done

        # use list given by user
        if [[ ${_type_list[0]} ]] && [[ ${_dest_list[0]} ]] ; then
            type_list=(${_type_list[*]})
            dest_list=(${_dest_list[*]})
        else
            gr.msg -n -e0 "no mime type matches, available categories: "
            gr.msg -c list "${type_list[@]}"
            return 96
        fi

    }

    mime.sort () {
    # collect files from
        ifs=$IFS
        IFS=$'\n'
        file_list=($(file -i -h -r $PWD/*  | grep -v inode/directory | tr -s " "))
        gr.debug "$FUNCNAME file_list: ${file_list[@]})"
        IFS=$ifs
        # get filenames and mime types to arrows
        for (( i = 0; i < ${#file_list[@]}; i++ )); do
            file_paths="$(cut -d':' -f1 <<<${file_list[$i]})"
            file_names+=( "${file_paths##*/}" )
            mime_types+=( "$(echo ${file_list[$i]} | cut -d':' -f2 | cut -d';' -f1 | xargs)" )
        done
        file_count=$i

        # sort by mime type
        for (( i = 0; i < ${#file_names[@]}; i++ )); do
            gr.msg -v4 -n -c list "${file_names[$i]} "
            gr.msg -v4 -c white "${mime_types[$i]} "

            case ${mime_types[$i]} in
                # inode/directory)
                #     directory+=( "${file_names[$i]}" )
                #     ignored_files=$((ignored_files + 1 ))
                #     ;;
                image*)
                    image+=( "${file_names[$i]}" )
                    ;;
                video*)
                    video+=( "${file_names[$i]}" )
                    ;;
                audio*)
                    audio+=( "${file_names[$i]}" )
                    ;;
                *vnd.ms*|*apple*)
                    other_system+=("${file_names[$i]}" )
                    ;;
                application/*debian*)
                    application+=( "${file_names[$i]}" )
                    ;;
                */zip|*/gzip|*/x-7z-compressed)
                    archive+=( "${file_names[$i]}" )
                    ;;
                text/plain|*csv|*xml|*opendocument*|*officedocument*|*pdf|*calendar|*rtf)
                    document+=( "${file_names[$i]}" )
                    ;;
                *html|*shellscript|*python|*java|*php|*javascript|*java-archive|*x-sh|*json)
                    code+=( "${file_names[$i]}" )
                    ;;
                *symlink)
                    gr.msg -v3 -e1 "ignoring '${file_names[$i]}"
                    ignored_files=$((ignored_files + 1 ))
                    ;;
                *)
                    other+=( "${file_names[$i]}" )
            esac
        done


        # check integrity
        if [[ $file_count == $i ]]; then
            gr.msg -v3 -c green "sorted $i files"
        else
            gr.msg -e2 "file count mismatch found $file_count files, sorted $i files."
            return 101
        fi

        file_count=$(( $file_count - $ignored_files ))
    }

    mime.list () {
    # printout file lists and ask user to continue before copying
        local files=
        local color=(list aqua_marine)
        local c=0
        for (( i = 0; i < ${#type_list[@]}; i++ )); do
            files=$(eval echo '${#'${type_list[$i]}'[@]}')
            if [[ $files -gt 0 ]] ; then
                gr.msg -n -v1 -c white "${type_list[$i]} ($files) >${dest_list[$i]}: "
                for (( ii = 0; ii < $files; ii++ )); do
                    item=$(eval echo '${'${type_list[$i]}'['$ii']}')
                    gr.msg -n -c ${color[$(( $c & 1 ))]} "$item "
                    let c++
                done
                echo
                sorted_files=$(($sorted_files + $files))
            fi
        done
    }

    mime.move () {
    # move files to places set in configuration
        local _error=0
        local _file=
        local _files=
        local _file_list=()
        local _source_folder=$(pwd)

        # initialize undo script
        printf '%s\n%s\n' '#!/bin/bash' "gr.ask 'perform undo for move $(date)?' || exit 0" >$undo_script
        chmod +x $undo_script

        # go trough type list
        for (( i = 0; i < ${#type_list[@]}; i++ )); do

            _files=$(eval echo '${#'${type_list[$i]}'[@]}')

            [[ $_files -lt 1 ]] && continue


            if [[ $_source_folder != ${dest_list[$i]} ]] ; then
                gr.msg -v1 -n "moving $_files ${type_list[$i]} file$([[ $_files -gt 1 ]] && gr.msg -n "s") to ${dest_list[$i]} "
            else
                gr.msg -v2 "skipping files whose target is the current directory"
                continue
            fi

            if ! [[ ${dest_list[$i]} ]] || ! [[ -d ${dest_list[$i]} ]] ; then
                gr.msg -e1 "destination folder '${dest_list[$i]}' does not exist"
                continue
            fi

            _error=0
            for (( t = 0; t < $_files; t++ )); do

                if [[ $dryrun ]] ; then
                    gr.msg -n -c dark_gray "."
                    continue
                fi

                _file="$(eval echo '${'${type_list[$i]}'['$t']}')"

                # move file
                if mv -f "$_file" ${dest_list[$i]} ; then
                    # make undo script
                    echo "mv '${dest_list[$i]}/$_file' '$_source_folder'" >>$undo_script
                    gr.msg -v2 -n -c dark_gray "$_file "
                    gr.msg -V2 -n -c dark_gray "."
                else
                    _file_list+=("$_file")
                    _error=$((_error + 1 ))
                fi
            done

            if [[ $_error -lt 1 ]] ; then
                gr.msg -v1 -c green 'ok'
            else
                gr.msg -v1 -e1 "$_error issues with file$([[ ${#_file_list[@]} -gt 1 ]] && gr.msg -n "s"): ${_file_list[@]}"
            fi

            moved_files=$(($moved_files + $_files))
        done

        if [[ $moved_files -gt 0 ]] ; then
            gr.msg -v2 "moved $moved_files file$([[ $moved_files -gt 1 ]] && gr.msg -n "s")"
            gr.msg -V1
        else
            gr.msg -v1 -e0 "did no found any files"
        fi
    }

    # mime command parser
    local command=$1;
    shift
    gr.debug "$FUNCNAME command: $command"
    case $command in
        list|ls|"")
            mime.config || return $?
            mime.given_list $@ || return $?
            mime.sort
            mime.list
            ;;
        move|mv|all)
            mime.config || return $?
            mime.given_list $@ || return $?
            [[ $GRBL_FORCE ]] || gr.ask "move all types of files?" || return 0
            mime.sort || return $?
            mime.move
            ;;
        type*)
            mime.config
            gr.msg -n "available file type list: "
            gr.msg -c list "${type_list[@]}"
            ;;
        image|video|audio|other_system|archive|document|code|other|application)
            mime.config || return $?
            mime.given_list $command $@ || return $?
            mime.sort || return $?
            mime.move
            ;;
        dryrun|dry)
            local dryrun=true
            mime.config
            mime.given_list $@ || return $?
            mime.sort
            mime.list
            mime.move
            ;;
        undo)
            if [[ -f $undo_script ]]; then
                gr.msg -h "running undo script $undo_script.."
                tail -n +3 $undo_script
                bash $undo_script
            else
                gr.msg "sorry, undo not available"
            fi
            ;;
        help)
            place.help
            ;;
        *)
            gr.msg -e0 "unknown command '$command'"
            place.help
    esac
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
    local meme_folder="$GRBL_MOUNT_PICTURES/memes"

    if ! [[ -f $GRBL_MOUNT_PICTURES/.online ]] ; then
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

    local phone_temp_folder="/tmp/$USER/grbl/android"
    local _photo_format="jpg"
    [[ $1 ]] && _photo_format=$1

    mount.online $GRBL_MOUNT_PHOTOS || mount.known_remote photos

    # when $phone_temp_folder/photos if filled?

    # read file list
    local _file_list=($(ls "$phone_temp_folder/photos" 2>/dev/null | grep ".$_photo_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gr.msg -c dark_crey "no new photos"
            return 0
        fi

    gr.msg -v2 -c white "tagging and moving photos to $GRBL_MOUNT_PHOTOS "

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
            if ! [[ -d $GRBL_MOUNT_PHOTOS/$_year/$_month ]] ; then
                    mkdir -p "$GRBL_MOUNT_PHOTOS/$_year/$_month"
                    gr.msg -n -v1 -V2 "o"
                    gr.msg -N -v2 "$GRBL_MOUNT_PHOTOS/$_year/$_month"
                fi

            # place photos to right folders
            if mv "$phone_temp_folder/photos/$_file" "$GRBL_MOUNT_PHOTOS/$_year/$_month" ; then
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

    local phone_temp_folder="/tmp/$USER/grbl/android"
    local _video_format="mp4"
    [[ $1 ]] && _video_format=$1

    mount.online $GRBL_MOUNT_VIDEO || mount.known_remote video

    # read file list
    local _file_list=($(ls "$phone_temp_folder/videos" 2>/dev/null | grep ".$_video_format" ))

    if ! [[ ${_file_list[@]} ]]; then
            gr.msg -c dark_crey "no new videos"
            return 0
        fi

    gr.msg -n -c white "moving videos to $GRBL_MOUNT_VIDEO "
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
            if ! [[ -d $GRBL_MOUNT_VIDEO/$_year ]] ; then
                    mkdir -p "$GRBL_MOUNT_VIDEO/$_year"
                    gr.msg -n -v1 -V2 "o"
                    gr.msg -N -v2 "$GRBL_MOUNT_VIDEO/$_year"
                fi

            # place videos to right folders
            if mv "$phone_temp_folder/videos/$_file" "$GRBL_MOUNT_VIDEO/$_year" ; then
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
    # expects that files are already copied/moved from home to $phone_temp_folder

    mount.online $GRBL_MOUNT_PHOTOS || mount.known_remote photos
    mount.online $GRBL_MOUNT_VIDEO || mount.known_remote video

    place.photos "jpg"
    place.videos "mp4"

    local phone_temp_folder="/tmp/$USER/grbl/android"
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

    if [[ $GRBL_FORCE ]] || gr.ask "remove source files from phone" ; then
            source android.sh
            android.rmdir "/storage/emulated/0/DCIM/Camera"
        fi
}


place.ls () {
    # list something
    GRBL_VERBOSE=2
    if [[ $GRBL_MOUNT_ENABLED ]] ; then
            # source mount.sh
            [[ $GRBL_VERBOSE -lt 2 ]] \
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


place.rc () {
# source configurations (to be faster)

    if [[ ! -f $place_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/place.cfg) - $(stat -c %Y $place_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $place_rc) )) -gt 0 ]]
        then
            place.make_rc && \
                gr.msg -v1 -c dark_gray "$place_rc updated"
        fi

    source $place_rc
}


place.make_rc () {
# configure place module

    source config.sh

    # make rc out of config file and run it
    if [[ -f $place_rc ]] ; then
            rm -f $place_rc
        fi

    config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $place_rc
    config.make_rc "$GRBL_CFG/$GRBL_USER/place.cfg" $place_rc append
    chmod +x $place_rc
    source $place_rc
}

place.rc

# if called place.sh file configuration is sourced and main place.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GRBL_RC"
    place.main "$@"
    exit "$?"
fi

