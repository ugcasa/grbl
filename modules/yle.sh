#!/bin/bash

source common.sh

declare -g run_folder="$(pwd)"
declare -g yle_temp="$HOME/tmp/yle"
declare -g media_title="no media"
declare -g episodes=()
declare -g media_address
declare -g media_filename

yle.main () {

    local command=$1
    shift

    case "$command" in

        install|uninstall)
            yle.$command $@
            ;;

        play)
            echo "$command" | grep "http" && base_url="" || base_url="https://areena.yle.fi/"
            yle-dl --pipe "base_url$command" 2>/dev/null | vlc - &
            exit 0
            ;;

        get|dl|download)
            for item in "$@"
                do
                   yle.get_metadata "$item" || return 127
                   yle.get_media
                   yle.place_media
                done
            ;;

        news|uutiset)
            news_core="https://areena.yle.fi/1-3235352"
            yle-dl --pipe --latestepisode "$news_core" | vlc - &
            ;;

        episodes)
            yle.get_metadata "$command" || return 127
            [[ "$episodes" ]] && echo "$episodes" || echo "single episode"
            ;;

        play)
            yle.get_metadata "$command" || return 127
            echo "osoite: $media_address"
            yle-dl --pipe "$media_address" 2>/dev/null | vlc - 2>/dev/null &
            ;;

        subtitle|subtitles|sub|subs)
            yle.get_metadata "$command" || return 127
            yle.get_subtitles
            yle.place_media "$run_folder"
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

            for item in "$@"
                do
                   yle.get_metadata "$item" && yle.get_media
                done
            ;;

        help)
            echo "usage:    $GURU_CALL yle install|uninstall|play|get|news|episodes|play|subtitle|weekly|meta" ;;

        *)
            for item in "$@"
                do
                   yle.get_metadata "$item"
                done
            ;;

        esac

    return 0
}


# block_rev () {
#     # trick to reverse array without reversing strings
#     array=($@)

#     f() { array=("${BASH_ARGV[@]}"); }

#     shopt -s extdebug
#     f "${array[@]}"
#     shopt -u extdebug

#     echo "${array[@]}"
# }


# yle.place () {

#     find_files () {
#         for entry in $@ ; do
#               [[ -f $entry ]] && echo $entry
#             done
#     }

#     split_filename () {
#         local filename=$1
#         local pos=0
#         local episode=
#         local name=

#         sepa='-'

#         for type in ${left[@]} ; do

#             (( pos++ ))

#             case $type in
#                 name)
#                         name="$name$(echo $filename | cut -f $pos -d $sepa) "
#                         ;;
#                 episode)
#                         word="$(echo $filename | cut -f $pos -d $sepa) "

#                         if grep -ve 's0' -ve 'e0' <<<$word ; then
#                             episode="$episode$word"
#                         else
#                             code=$word
#                             break
#                         fi

#                         ;;
#                     esac
#             done

#         pos=0
#         for type in ${right[@]} ; do

#                 (( pos++ ))

#                 case $type in
#                     ending)
#                             sepa='.'
#                             ending="$(echo $filename | cut -f 1 -d $sepa)"
#                             ;;
#                     time)
#                             sepa='t'
#                             time="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     day)
#                             day="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     month)  month="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     year)   year="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                         esac
#                 done

#         gmsg "name: $name"
#         gmsg "episode: $episode"
#         gmsg "ending: $ending"
#         gmsg "day: $day"
#         gmsg "month: $month"
#         gmsg "time: $time"

#         }

#     files=($(find_files '*mp4 *mkv'))
#     gmsg -v3 -c light_blue "files: ${files[@]}"

#     sepa='-'
#     left=(name name name name name episode episode episode episode episode episode episode)


#     #right_rev=(ending time day month year code)
#     right=(code year month day time ending)

#     # gmsg "order: ${left[@]} $(block_rev ${right_rev[@]})"
#     gmsg "order: ${left[@]} ${right[@]}"

#     for file in ${files[@]} ; do
#         split_filename $file

#         done

# }





yle.get_metadata () {

    error=
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

    media_url="$base_url$1"

    # Check if id contain episodes, then select first one (newest)
    episodes=$(yle-dl --showepisodepage $media_url | grep -v $media_url)
    latest=$(echo $episodes | cut -d " " -f 1)
    [[ "$latest" ]] && media_url=$latest

    # Get metadata
    yle-dl $media_url --showmetadata >$meta_data

    grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')
    if [[ "$error" ]] ; then
            echo "$error"
            return 100
        fi

    # set variables (like they be local anyway)
    media_title="$(cat "$meta_data" | jq '.[].title')"
    echo "${media_title//'"'/""}"

    media_address="$media_url "
    #$(cat "$meta_data" | jq '.[].webpage')
    #media_address=${media_address//'"'/""}
    media_filename=$(cat "$meta_data" | jq '.[].filename')
}


yle.get_media () {
    # get media from server and place it to /$USER/tmp

    # detox filename
    output_filename=${media_filename//. /-}
    output_filename=${output_filename//.: /-}
    output_filename=${output_filename//: /-}
    output_filename=${output_filename// /-}
    output_filename=${output_filename//'"'/}
    output_filename=${output_filename,,}

    gmsg -v3 -c deep_pink "output filename: $output_filename"

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


yle.get_subtitles () {


    [ -d "$yle_temp" ] && rm -rf "$yle_temp"
    mkdir -p "$yle_temp"
    cd "$yle_temp"
    yle-dl "$media_url" --subtitlesonly #2>/dev/null
    #media_filename=$(detox -v * | grep -v "Scanning")
    #media_filename=${media_filename#*"-> "}
}

yle.place_media () {

    #location="$@"

    media_file_format="${media_filename: -5}"
    media_file_format="${media_file_format#*.}"
    #media_file_format="${media_file_format^^}"
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
            location="$GURU_MOUNT_TV" ;;
        *)
            mount.main downloads
            location="$GURU_MOUNT_DOWNLOADS" ;;
    esac

    # input overwrites basic shit
    if [[ "$1" ]] ; then
            location="$1"
            shift
        fi

    [[ -d $location ]] || mkdir -p $location

    # moving to default location
    gmsg -c white "saving to: $location/$media_filename"
    mv -f $media_filename $location

}


yle.play_media () {
    vlc --play-and-exit "$1" &
}


yle.install() {
    pip3 install --upgrade pip
    [[ -f /home/casa/.local/bin/yle-dl ]] || pip3 install --user --upgrade yle-dl
    ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
    jq --version >/dev/null || sudo apt install jq -y
    sudo apt install detox vlc
    echo "Successfully installed"
}


uninstall(){

    sudo -H pip3 unisntall --user yle-dl
    sudo apt remove ffmpeg jq -y
    echo "uninstalled"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    yle.main "$@"
fi


# same but for youtube

# video.build () {

#     data_location="/home/casa/karsulle"
#     data_file="karsulle_katsottavaa.cfg"
#     url_base="https://www.youtube.com/watch?v"

#     [[ -d $data_location ]] || mkdir -p $data_location
#     [[ -f $data_file ]] || gmsg -x 100 -c yellow "data tiedosto $data_file puuttuu"

#     ids=$(cut -d " " -f 1 $data_file)
#     headers=$(cut -d " " -f 2- $data_file)

#     lines=$(cat $data_file)
#     youtube-dl --version || video.install

#     for id in ${ids[@]} ; do
#         gmsg -c white "downloading $url_base=$id to $data_location.. "
#         youtube-dl --ignore-errors --continue --no-overwrites \
#                --output "$data_location/%(title)s.%(ext)s" \
#                "$url_base=$id"
#     done


# }


# video.install () {
#     sudo apt update || gmsg -x 101 -c yellow "apt update failed"
#     sudo apt install youtube-dl ffmpeg
# }



# video.build