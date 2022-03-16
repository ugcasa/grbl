#!/bin/bash

source common.sh

declare -g yle_run_folder="$(pwd)"
declare -g yle_temp="$HOME/tmp/yle"
declare -g yle_media_title="no media"
declare -g yle_episodes=()
declare -g yle_media_address=
declare -g yle_media_filename=


yle.help () {

    gmsg -v1 "guru-cli yle help " -c white
    gmsg -v2
    gmsg -v0  "usage:    $GURU_CALL yle get|play|radio|radio|news|episodes|sub|metadata|install|uninstall|help"
    gmsg -v2
    gmsg -v1 "commands: " -c white
    gmsg -v2
    gmsg -v1 "  get|dl <id|url>     download media to media folder "
    gmsg -v1 "  play <id|url>       play episode from stream"
    gmsg -v1 "  radio <station>     listen radio <station>"
    gmsg -v1 "  radio ls            list of known yle radio stations"
    gmsg -v1 "  news                play latest yle tv news "
    gmsg -v1 "  episodes <url>      get episodes of collection page"
    gmsg -v1 "  sub <id|url>        get subtitles for video"
    gmsg -v1 "  metadata            get media metadata"
    gmsg -v1 "  install             install requirements"
    gmsg -v1 "  uninstall           remove requirements "
    gmsg -v1 "  help                this help window"
    gmsg -v2
    gmsg -v1 "examples: " -c white
    gmsg -v2
    gmsg -v1 "  $GURU_CALL yle get 1-4454526    # download media id (or url)"
    gmsg -v1 "  $GURU_CALL yle play 1-2707315   # play media id (or url)"
    gmsg -v1 "  $GURU_CALL yle radio puhe       # to play yle puhe stream"
    gmsg -v1 "  $GURU_CALL yle episodes https://areena.yle.fi/audio/1-1792200   "
    gmsg -v2
}


yle.main () {

    local command=$1
    shift

    case "$command" in

        listen|radio)
            yle.radio_listen $@
            ;;

        install|uninstall)
            yle.$command $@
            ;;

        play)
            echo "$1" | grep "https://" && base_url="" || base_url="https://areena.yle.fi/"
            gmsg "getting from url $base_url$1"
            yle-dl --pipe "$base_url$1" 2>/dev/null | mpv -
            return $?
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
            yle-dl --pipe --latestepisode "$news_core" 2>/dev/null | mpv -
            ;;

        episode|episodes)

            yle.get_metadata $@ || return 127

            if ! [[ $yle_episodes ]] ; then
                gmsg -c white "single episode"
                return 0
            fi

            gmsg -c light_blue "${yle_episodes[@]}"

            # if [[ $2 == "dl" ]] || gask "download all ${#yle_episodes[@]} episodes?" ; then
            if gask "download all ${#yle_episodes[@]} episodes?" ; then

                    for episode in ${yle_episodes[@]} ; do
                        yle.get_metadata $episode && \
                        yle.get_media && \
                        yle.place_media
                        done
                fi
            ;;

        play)
            yle.get_metadata "$command" || return 127
            echo "osoite: $yle_media_address"
            yle-dl --pipe "$yle_media_address" 2>/dev/null | mpv -
            ;;

        subtitle|subtitles|sub|subs)
            yle.get_metadata $command || return 127
            yle.get_subtitles
            yle.place_media "$yle_run_folder"
            ;;

        status)  echo "no status data" ;;

        meta|data|metadata|information|info)

            for item in "$@"
                do
                   yle.get_metadata $item && yle.get_media
                done
            ;;

        help)
            yle.help $@
            ;;
        *)
            for item in "$@"
                do
                   yle.get_metadata $item
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

    local error=
    local meta_data="$yle_temp/meta.json"

    # make temp if not exist already
    [[ -d "$yle_temp" ]] || mkdir -p "$yle_temp"
    cd "$yle_temp"

    local base_url="https://areena.yle.fi/"
    # do not add base url if it already given
    if echo $1 | grep "http" ; then
            base_url=
        fi

    media_url="$base_url$1"

    gmsg -v3 -c deep_pink "media_url: $media_url"

    # Check if id contain yle_episodes, then select first one (newest)
    yle_episodes=($(yle-dl --showepisodepage $media_url | grep -v $media_url))
    # episode_ids=($(yle-dl $media_url --showmetadata | jq '.[].program_id'))
    gmsg -v3 -c light_blue "yle_episodes: ${yle_episodes[@]}"

    # change media address poin to first episode
    [[ ${yle_episodes[0]} ]] && media_url=${yle_episodes[0]}

    # Get metadata
    yle-dl $media_url --showmetadata > $meta_data

    grep "error" $meta_data && error=$(cat $meta_data | jq '.[].flavors[].error')

    if [[ $error ]] ; then
            echo "$error"
            return 100
        fi

    # set variables (like they be local anyway)
    yle_media_title="$(cat "$meta_data" | jq '.[].title')"
    gmsg -v2 "${yle_media_title//'"'/""}"

    yle_media_address="$media_url "
    #$(cat "$meta_data" | jq '.[].webpage')
    #yle_media_address=${yle_media_address//'"'/""}
    yle_media_filename=$(cat "$meta_data" | jq '.[].filename')
}


yle.get_media () {
    # get media from server and place it to /$USER/tmp

    # detox filename
    output_filename=${yle_media_filename//. /-}
    output_filename=${output_filename//.: /-}
    output_filename=${output_filename//: /-}
    output_filename=${output_filename// /-}
    output_filename=${output_filename//-_-/-}
    output_filename=${output_filename//--/-}
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
            yle_media_filename=$got_filename
            return 0
        else
            # update global variables
            yle_media_filename=$output_filename
            return 0
        fi

    return 127
}


yle.get_subtitles () {


    [ -d "$yle_temp" ] && rm -rf "$yle_temp"
    mkdir -p "$yle_temp"
    cd "$yle_temp"
    yle-dl "$media_url" --subtitlesonly #2>/dev/null
    #yle_media_filename=$(detox -v * | grep -v "Scanning")
    #yle_media_filename=${yle_media_filename#*"-> "}
}


yle.radio_listen () {

    case $1 in
        ls|list)
            local possible=('puhe' 'radio1' 'kajaani' 'klassinen' 'x' 'x3 m' 'vega' 'kemi' 'turku' \
                            'pohjanmaa' 'kokkola' 'pori' 'kuopio' 'mikkeli' 'oulu' 'lahti' 'kotka' 'rovaniemi' \
                            'hameenlinna' 'tampere' 'vega aboland' 'vega osterbotten' 'vega ostnyland' 'vega vastnyland' 'sami')
            gmsg -c light_blue ${possible[@]}
            return 0
            ;;
        esac

    local channel="yle $@"
    local options=
    [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"
    channel=$(echo $channel | sed -r 's/(^| )([a-z])/\U\2/g' )
    local url="https://icecast.live.yle.fi/radio/$channel/icecast.audio"
    mpv $options $url
}


yle.place_media () {

    #location="$@"

    media_file_format="${yle_media_filename: -5}"
    media_file_format="${media_file_format#*.}"
    #media_file_format="${media_file_format^^}"
    gmsg -c deep_pink "media_file_format: $media_file_format, yle_media_filename $yle_media_filename"

    if ! [[ -f $yle_media_filename ]] ; then
            gmsg -c yellow "file $yle_media_filename not found"
            return 124
        fi

    #$GURU_CALL tag "$yle_media_filename" "yle $(date +$GURU_FILE_DATE_FORMAT) $yle_media_title $media_url"

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
    gmsg -c white "saving to: $location/$yle_media_filename"
    mv -f $yle_media_filename $location

}


yle.play_media () {
    mpv --play-and-exit "$1" &
}


yle.install() {
    pip3 install --upgrade pip
    [[ -f /home/casa/.local/bin/yle-dl ]] || pip3 install --user --upgrade yle-dl
    ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
    jq --version >/dev/null || sudo apt install jq -y
    sudo apt install detox mpv
    echo "Successfully installed"
}


yle.uninstall(){

    sudo -H pip3 unisntall --user yle-dl
    sudo apt remove ffmpeg jq  -y
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