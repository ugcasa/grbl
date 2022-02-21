#!/bin/bash

source common.sh

declare -g run_folder="$(pwd)"
declare -g yle_temp="$HOME/tmp/yle"
declare -g media_title="no media"
declare -g episodes=()
declare -g media_address
declare -g media_filename

yle_main () {

    case "$1" in

        install)
            pip3 install --upgrade pip
            [[ -f yle-dl ]] || pip3 install --user --upgrade yle-dl
            ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
            jq --version >/dev/null || sudo apt install jq -y
            sudo apt install detox vlc
            echo "Successfully installed"
            ;;

        uninstall)
            sudo -H pip3 remove --user yle-dl
            sudo apt remove ffmpeg jq -y
            echo "uninstalled"
            ;;

        play)
            shift
            echo "$1" | grep "http" && base_url="" || base_url="https://areena.yle.fi/"
            yle-dl --pipe "base_url$1" 2>/dev/null | vlc - &
            exit 0
            ;;

        get|dl|download)
            shift
            for item in "$@"
                do
                   get_media_metadata "$item" || return 127
                   get_media
                   place_media
                done
            ;;

        news|uutiset)
            news_core="https://areena.yle.fi/1-3235352"
            yle-dl --pipe --latestepisode "$news_core" | vlc - &
            ;;

        episodes)
            shift
            get_media_metadata "$1" || return 127
            [[ "$episodes" ]] && echo "$episodes" || echo "single episode"
            ;;

        play)
            shift
            get_media_metadata "$1" || return 127
            echo "osoite: $media_address"
            yle-dl --pipe "$media_address" 2>/dev/null | vlc - 2>/dev/null &
            ;;

        subtitle|subtitles|sub|subs)
            shift
            get_media_metadata "$1" || return 127
            get_subtitles
            place_media "$run_folder"
            ;;

        weekly|relax|suosikit)
            printf "To remove notification do next:  \n 1. In VLC, click Tools ► Preferences \n 2. At the bottom left, for Show settings, click All \n 3. At the top left, for Search, paste the string: unimportant \n 4. In the box below Search, click: Qt \n 5. On the right-side, near the very bottom, uncheck Show unimportant error and warnings dialogs \n 6. Click Save \n 7. Close VLC to commit the pref change (otherwise, if VLC crashes, this change {or some changes} might not be saved) \n 8. Run VLC & see if that fixes the problem\n"
            yle-dl --pipe --latestepisode https://areena.yle.fi/1-3251215 2>/dev/null | vlc -
            yle-dl --pipe --latestepisode https://areena.yle.fi/1-3245752 2>/dev/null | vlc -
            yle-dl --pipe --latestepisode https://areena.yle.fi/1-4360930 2>/dev/null | vlc -
            exit 0
            ;;

        status)  echo "no status data" ;;

        meta|data|metadata|information|info)
            shift
            for item in "$@"
                do
                   get_media_metadata "$item" && get_media
                done
            ;;

            help)
                echo "usage:    $GURU_CALL yle [install|uninstall|play|get|news|episodes|play|subtitle|weekly|meta]" ;;

        *)
            for item in "$@"
                do
                   get_media_metadata "$item"
                done
            ;;

        esac

    return 0
}


get_media_metadata () {

    error=""
    meta_data="$yle_temp/meta.json"

    # make temp if not exist already
    [[ -d "$yle_temp" ]] || mkdir -p "$yle_temp"
    cd "$yle_temp"

    # do not add base url if it already given
    if echo $1 | grep "https" ; then
        base_url=""
    else
        base_url="https://areena.yle.fi/"
    fi

    media_url="$base_url$1"                              #;echo "$media_url"; exit 0

    # Check if id contain episodes, then select first one (newest)
    episodes=$(yle-dl --showepisodepage $media_url |grep -v $media_url)
    latest=$(echo $episodes | cut -d " " -f 1)          #; echo "latest: $latest"; exit 0
    [[ "$latest" ]] && media_url=$latest              #; echo "media_url: $media_url"; exit 0

    # Get metadata
    yle-dl "$media_url" --showmetadata >"$meta_data"

    grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')
    if [[ "$error" ]] ; then
        echo "$error"
        return 100
    fi

    # set variables (like they be local anyway)
    media_title="$(cat "$meta_data" | jq '.[].title')"          #;echo "title: $media_title"
    media_address="$media_url "
    #$(cat "$meta_data" | jq '.[].webpage')                     #;echo "address: $media_address"
    #media_address=${media_address//'"'/""}                     #;echo "$media_address"                         # remove " signs
    media_filename=$(cat "$meta_data" | jq '.[].filename')     #;echo "meta: $media_filename"
    echo "${media_title//'"'/""}"
}


get_media () {
    # get media from server and place it to /$USER/tmp

    # detox filename
    output_filename=${media_filename//:/-}
    output_filename=${output_filename// /}
    output_filename=${output_filename//'"'/}

    #gmsg -c deep_pink "output filename: $output_filename"

    # check is tmp file alredy there
    if [[ -f $output_filename ]] ; then
            gmsg -c yellow "file exist, overwriting "
            rm $output_filename
        fi

    # download stuff
    yle-dl "$media_url" -o "$output_filename" --sublang all

    # to check did yle-dl change format
    local got_filename=$(echo ${output_filename%.*}*)

    if [[ -f $got_filename ]] ; then
            # got valid filename, update global variables
            media_filename=$got_filename
            return 0
        else
            # update global variables
            media_filename=$output_filename
            return 0
        fi

    return 127
}


get_subtitles () {


    [ -d "$yle_temp" ] && rm -rf "$yle_temp"
    mkdir -p "$yle_temp"
    cd "$yle_temp"
    yle-dl "$media_url" --subtitlesonly #2>/dev/null
    #media_filename=$(detox -v * | grep -v "Scanning")          #;echo "detox: $media_filename"
    #media_filename=${media_filename#*"-> "}                   #;echo "cut: $media_filename"
}

place_media () {

    #location="$@"

    media_file_format="${media_filename: -5}"      #; echo "media_file_format:$media_file_format|"     # read last characters of filename
    media_file_format="${media_file_format#*.}"     #; echo "media_file_format:$media_file_format|"     # read after separator
    #media_file_format="${media_file_format^^}"      #; echo "media_file_format:$media_file_format|"     # upcase
    gmsg -c deep_pink "media_file_format: $media_file_format, media_filename $media_filename"

    if ! [[ -f $media_filename ]] ; then
            gmsg -c yellow "file $media_filename not found"
            return 124
        fi

    #$GURU_CALL tag "$media_filename" "yle $(date +$GURU_FILE_DATE_FORMAT) $media_title $media_url"

    source mount.sh
    case "$media_file_format" in

        mp3|wav)
            mount.main audio
            location="$GURU_MOUNT_AUDIO" ;;


        mkv|mp4|src|sub|avi)
            mount.main video
            location="$GURU_MOUNT_VIDEO" ;;
        *)
            mount.main downloads
            location="$GURU_MOUNT_DOWNLOADS" ;;
    esac

    # input overwrites
    [[ "$1" ]] && location="$1"

    # moving to default location
    echo "saving to: $location/$media_filename"
    mv -f "$media_filename" "$location"

    # play after download
    media_file=$location/$media_filename
    [ "$2" == "play" ] && play_media "$media_file"
}


play_media () {
    vlc --play-and-exit "$1" &
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    yle_main "$@"
fi




