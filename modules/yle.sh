#!/bin/bash

#source common.sh

declare -g yle_run_folder="$(pwd)"
declare -g yle_temp="$HOME/tmp/yle"
declare -g yle_media_title="no media"
declare -g yle_episodes=()
declare -g yle_media_address=
declare -g yle_media_filename=
declare -g yle_playlist_folder=$GURU_DATA/yle/playlists

yle.help () {

    gr.msg -v1 "guru-cli yle help " -c white
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL yle get|play|radio|playlist|news|episodes|sub|metadata|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v2
    gr.msg -v1 "  get|dl <id|url>     download media to media folder "
    gr.msg -v1 "  play <id|url>       play episode from stream"
    gr.msg -v1 "  radio ls            list of known yle radio stations"
    gr.msg -v1 "  radio <station>     listen radio <station>"
    gr.msg -v1 "  news                play latest yle tv news "
    gr.msg -v1 "  episodes <url>      get episodes of collection page"
    gr.msg -v1 "  sub <id|url>        get subtitles for video"
    gr.msg -v1 "  playlist <name>     play playlist"
    gr.msg -v2 "    list              list of playlists"
    gr.msg -v2 "    add               add new playlist"
    gr.msg -v2 "    edit              open playlist in $GURU_PREFERRED_EDITOR"
    gr.msg -v2 "    mv                rename playlist"
    gr.msg -v2 "    rm                remove playlist"
    gr.msg -v2 "    <name> nro        play list item nro"
    gr.msg -v1 "  metadata            get media metadata"
    gr.msg -v1 "  install             install requirements"
    gr.msg -v1 "  uninstall           remove requirements "
    gr.msg -v1 "  help                this help window"
    gr.msg -v2
    gr.msg -v1 "examples: " -c white
    gr.msg -v2
    gr.msg -v1 "  $GURU_CALL yle get 1-4454526        # download media id (or url)"
    gr.msg -v1 "  $GURU_CALL yle play 1-2707315       # play media id (or url)"
    gr.msg -v1 "  $GURU_CALL yle playlist default 4   # play default playlist item 4"
    gr.msg -v1 "  $GURU_CALL yle radio puhe           # to play yle puhe stream"
    gr.msg -v1 "  $GURU_CALL yle episodes https://areena.yle.fi/audio/1-1792200   "
    gr.msg -v2
}


yle.main () {

    local command=$1
    shift

    case "$command" in

        listen|radio)
            yle.radio_listen $@
            ;;

        list|playlist)
            yle.playlist $@
            ;;

        install|uninstall|upgrade)
            yle.$command $@
            ;;

        play)
            # echo "$1" | grep "https://" && base_url="" || base_url="https://areena.yle.fi/" >/dev/null
            # gr.msg "getting from url $base_url$1"
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
            # yle-dl --pipe --latestepisode "$news_core" 2>/dev/null | mpv -
            # issue 20221206.2 --latestepisode broken, fix below
            yle-dl --pipe $(yle-dl --showepisodepage $news_core | tail -n2 | head -n1)  2>/dev/null | mpv -
            ;;

        episode|episodes)

            yle.get_metadata $@ || return 127

            if ! [[ $yle_episodes ]] ; then
                gr.msg -c white "single episode"
                return 0
            fi

            gr.msg -c light_blue "${yle_episodes[@]}"

            # if [[ $2 == "dl" ]] || gr.ask "download all ${#yle_episodes[@]} episodes?" ; then
            if gr.ask "download all ${#yle_episodes[@]} episodes?" ; then

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


yle.playlist () {
# play playlists

    local url=
    local name="default"
    local line=0
    local lines=
    local ans1= ; local ans2= ; local ans3=
    if [[ $1 ]] ; then name=$1 ; shift ; fi

    local playlist="$yle_playlist_folder/$name"

    case $name in
        list) ls ${playlist%/*} ; return 0 ;;
        rm) rm "${playlist%/*}/$1" ; return 0  ;;
        add|edit) $GURU_PREFERRED_EDITOR "${playlist%/*}/$1" ; return 0 ;;
        mv|rename) mv ${playlist%/*}/$1 ${playlist%/*}/$2 ; return 0;;
        show|view) cat ${playlist%/*}/$1 ; return 0;;
    esac

    [[ $1 ]] && line=$(($1 - 1 ))

    # create folder and files
    [[ -d ${playlist%/*} ]] || mkdir -p ${playlist%/*}
    [[ $playlist ]] || touch $playlist

    while true ; do

        # check condition of playlist file
        if ! [[ $(head -n1 $playlist) ]] ; then
            $GURU_PREFERRED_EDITOR $playlist
            gr.msg -c yellow "playlist file empty, please add link to https://areena.yle.fi content"
            gr.ask "ready to continue" || break
            line=0
        fi

        # check is file emty
        [[ $(head -n1 $playlist) ]] || break

        # add enpty line to playlist file
        [[ -s "$playlist" && -z "$(tail -c 1 "$playlist")" ]] || echo >>$playlist

        # clean up
        sed -i '/^[ \t]*$/d' $playlist

        # set variables
        lines=$(wc -l $playlist | cut -d' ' -f1)
        line=$(( line + 1 ))

        # limits
        [[ $line -gt $lines ]] && line=1
        [[ $line -lt 1 ]] && line=$lines

        # playing
        gr.msg -h -v1 "playing playlist item $line/$lines"
        gr.msg -c white -v2 "press 'qq' to quit, 'q' for next, 'qp' for previous, 'q + <number>' to play item or 'qe' to edit playlist"
        item=$(sed "${line}q;d" $playlist)

        if grep "https://areena.yle.fi" <<<$item ; then
            yle.main play $item
        else
            gr.msg -v2 -c yellow "'$item' is not an yle.fi link, skipping"
            continue
        fi

        # user control
        read -n1 -t1 ans1
        read -n1 -t1 ans2
        read -n1 -t1 ans3
        echo

        case $ans1 in
            q|Q) break ;;
            e|E) $GURU_PREFERRED_EDITOR $playlist & ;;
            p|P) line=$(( line - 2 )) ; [[ $ans2 == "p" ]] && line=$(( line - 1 )) ; continue ;;
            [0-9]*) line="$ans1$ans2$ans3" ; line=$(( line - 1 )) ;;
        esac

    done

    gr.msg -v2 "guru say bye bye"
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

#         gr.msg "name: $name"
#         gr.msg "episode: $episode"
#         gr.msg "ending: $ending"
#         gr.msg "day: $day"
#         gr.msg "month: $month"
#         gr.msg "time: $time"

#         }

#     files=($(find_files '*mp4 *mkv'))
#     gr.msg -v3 -c light_blue "files: ${files[@]}"

#     sepa='-'
#     left=(name name name name name episode episode episode episode episode episode episode)


#     #right_rev=(ending time day month year code)
#     right=(code year month day time ending)

#     # gr.msg "order: ${left[@]} $(block_rev ${right_rev[@]})"
#     gr.msg "order: ${left[@]} ${right[@]}"

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

    gr.msg -v3 -c deep_pink "media_url: $media_url"

    # Check if id contain yle_episodes, then select first one (newest)
    yle_episodes=($(yle-dl --showepisodepage $media_url | grep -v $media_url))
    # episode_ids=($(yle-dl $media_url --showmetadata | jq '.[].program_id'))
    gr.msg -v3 -c light_blue "yle_episodes: ${yle_episodes[@]}"

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
    gr.msg -v2 "${yle_media_title//'"'/""}"

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

    gr.msg -v3 -c deep_pink "output filename: $output_filename"

    # check is tmp file alredy there
    if [[ -f $output_filename ]] ; then
            gr.msg -c yellow "file exist, overwriting "
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
            gr.msg -c light_blue ${possible[@]}
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
    gr.msg -c deep_pink "media_file_format: $media_file_format, yle_media_filename $yle_media_filename"

    if ! [[ -f $yle_media_filename ]] ; then
            gr.msg -c yellow "file $yle_media_filename not found"
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
    gr.msg -c white "saving to: $location/$yle_media_filename"
    mv -f $yle_media_filename $location

}


yle.play_media () {
    mpv --play-and-exit "$1" &
}


yle.upgrade() {
    pip3 install --user --upgrade yle-dl
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
    # source "$GURU_RC"
    yle.main "$@"
fi


# same but for youtube

# video.build () {

#     data_location="/home/casa/karsulle"
#     data_file="karsulle_katsottavaa.cfg"
#     url_base="https://www.youtube.com/watch?v"

#     [[ -d $data_location ]] || mkdir -p $data_location
#     [[ -f $data_file ]] || gr.msg -x 100 -c yellow "data tiedosto $data_file puuttuu"

#     ids=$(cut -d " " -f 1 $data_file)
#     headers=$(cut -d " " -f 2- $data_file)

#     lines=$(cat $data_file)
#     youtube-dl --version || video.install

#     for id in ${ids[@]} ; do
#         gr.msg -c white "downloading $url_base=$id to $data_location.. "
#         youtube-dl --ignore-errors --continue --no-overwrites \
#                --output "$data_location/%(title)s.%(ext)s" \
#                "$url_base=$id"
#     done


# }


# video.install () {
#     sudo apt update || gr.msg -x 101 -c yellow "apt update failed"
#     sudo apt install youtube-dl ffmpeg
# }



# video.build