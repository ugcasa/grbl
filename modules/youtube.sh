#!/bin/bash
# play and get from youtube casa@ujo.guru 2022

declare -g youtube_rc="/tmp/guru-cli_youtube.rc"
# more global variables downstairs (after sourcing rc file)

youtube.help () {

    gr.msg -v1 "guru-cli youtube help " -c white
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL youtube play|get|list|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "  <search string> --<args>  search and play (more info -v2)" -V1
    gr.msg -v2 "  <search string>   search and play, options below "
    gr.msg -v2 "   --video          optimized for video quality"
    gr.msg -v2 "   --audio          optimized for audio quality, may not contain video"
    gr.msg -v2 "   --loop           play it forever"
    gr.msg -v2 "   --get            get video or audio, if not specified save to downloads"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v2
    gr.msg -v1 "  play <id|url>           play media from stream"
    gr.msg -v1 "  list <search string>    play list of search results, no video playback"
    gr.msg -v1 "  get <ids|urls>          download list of media to media folder "
    gr.msg -v3 "  song <id|url>           download audio to audio folder "
    gr.msg -v1 "  install                 install requirements"
    gr.msg -v1 "  uninstall               remove requirements "
    gr.msg -v1 "  help                    this help window"
    gr.msg -v2
    gr.msg -v1 "examples: " -c white
    gr.msg -v2
    gr.msg -v1 "  $GURU_CALL youtube juna kulkee taas"
    gr.msg -v1 "  $GURU_CALL youtube play eF1D-W27Wzg"
    gr.msg -v1 "  $GURU_CALL youtube get https://www.youtube.com/watch?v=eF1D-W27Wzg"
    gr.msg -v2
    gr.msg -v2 "alias 'tube' to replace '$GURU_CALL youtube' is available"
}


youtube.main () {

    local command=$1
    shift

    case "$command" in

        install|uninstall|upgrade|play)
            youtube.$command $@
            ;;

        get|dl|download)
            for item in "$@"
                do
                   youtube.get_media $item
                done
            ;;

        search)
            local query=$(youtube.search 10 json $@)
            echo $query | jq
            ;;

        song|music)
            youtube.get_audio $@
            ;;

        status) gr.msg -c dark_grey "no status data" ;;

        help)
            youtube.help $@
            ;;
        list)
            youtube.search_list $@
            ;;
        *)
            youtube.search_n_play $command $@
            ;;

        esac
    return 0
}


youtube.parse_arguments () {

    local got_args=($@)

    for (( i = 0; i < ${#got_args[@]}; i++ )); do
        gr.msg -v4 "${FUNCNAME[0]}: argument: $i:${got_args[$i]}"

        case ${got_args[$i]} in

            --get|--download|--save)
                youtube_options="-f b"
                save_to_file=true
                ;;

            --repeat|--l|--loop)
                mpv_options="$mpv_options --loop"
                ;;

            --video|--v)
                youtube_options=
                save_location=$GURU_MOUNT_VIDEO
                ;;

            --audio|--a)
                youtube_options="-f bestaudio --no-resize-buffer --ignore-errors"
                mpv_options="$mpv_options --no-video"
                save_location=$GURU_MOUNT_AUDIO
                ;;

            # --playlist|--pl)        ## TBD search for playlists
            #     i=$((i+1))
            #     gr.msg -v4 "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;

            # --list|--l)            ## TBD play search result list
            #     i=$((i+1))
            #     gr.msg -v4 "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;


            # --start|--s)          ## TBD mpv does not support this ffmpg can, but not too important
            #     i=$((i+1))
            #     gr.msg -v4 "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;
            # --end|--e)
            #     i=$((i+1))
            #     gr.msg -v4 "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;
            *)
                youtube_arguments+=("${got_args[$i]}")
                ;;
            esac
        done

        # save format
        if [[ $save_to_file ]] ; then
            [[ "$save_location" == "$GURU_MOUNT_AUDIO" ]] && youtube_options="$youtube_options -x --audio-format mp3"
            [[ "$save_location" == "$GURU_MOUNT_VIDEO" ]] && youtube_options="$youtube_options --recode-video mp4"
        fi

    # debug stuff (TBD remove later)
    gr.msg -v4 "${FUNCNAME[0]}: passing args: ${youtube_arguments[@]}"
    gr.msg -v4 "${FUNCNAME[0]}: youtube_options: $youtube_options"
    gr.msg -v4 "${FUNCNAME[0]}: mpv_options: $mpv_options"
}


youtube.rc () {
# source configurations (to be faster)

    if [[ ! -f $youtube_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/google.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mount.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]]
        then
            youtube.make_rc && \
                gr.msg -v1 -c dark_gray "$youtube_rc updated"
        fi
    source $youtube_rc
}

youtube.make_rc () {
# # make rc out of config file and run it

    source config.sh

    if [[ -f $youtube_rc ]] ; then
            rm -f $youtube_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $youtube_rc
    config.make_rc "$GURU_CFG/$GURU_USER/audio.cfg" $youtube_rc append
    config.make_rc "$GURU_CFG/$GURU_USER/google.cfg" $youtube_rc append
    chmod +x $youtube_rc
}


youtube.search () {
# search from youtube and return json of $1 amount of results
    export result_count=$1

    case $2 in
            json) return_format=json ; shift ;;
            dict) return_format=dict ; shift ;;
            *) return_format=json
        esac

    shift
    export search_string="$@"
python3 - << EOF
import os
from youtube_search import YoutubeSearch
results = YoutubeSearch(os.environ['search_string'], max_results=int(os.environ['result_count'])).to_$return_format()
print(results)
EOF
}


youtube.search_n_play () {
# search input and play it from youtube. use long arguments --video or --audio to select optimization
    local base_url="https://www.youtube.com"
    local _error=

    # to fulfill global variables: save_to_file save_location mpv_options youtube_options
    youtube.parse_arguments $@

    # make search and get media data and address
    local query=$(youtube.search 1 json ${youtube_arguments[@]})

    # format information of found media
    # TBD make able to parse multiple search results ans for them trough to replace search_list function"
    local title=$(echo $query | jq | grep title | cut -d':' -f2 | sed 's/"//g' | sed 's/,//g' | xargs -0 )
    local duration=$(echo $query | jq | grep duration | cut -d':' -f2 | xargs | sed 's/,//g')
    local media_address=$base_url$(echo $query | jq | grep url_suffix | cut -d':' -f 2 | xargs)

    gr.msg -v1 -h "$title ($duration) "
    gr.msg -v2 $media_address

    # if just saving the file
    if [[ $save_to_file ]]; then
            #save the file to media folder
            youtube_options="$youtube_options --continue --output $save_location/%(title)s.%(ext)s"
            gr.msg -v1 "downloading to $save_location.. "
            # save file
            yt-dlp $youtube_options $media_address
            # a bit dangero if some of location variables are empty
            detox -v *mp3 *mp4 $save_location 2>/dev/null
            return $?
        fi

    # make now playing info available for audio module
    echo $title >$GURU_AUDIO_NOW_PLAYING

    # start stream and play
    yt-dlp $youtube_options $media_address -o - 2>/tmp/youtube.error \
        | mpv $mpv_options - >/dev/null

    # in some cases there is word fuck or exposed tits in video, therefore:
    if grep 'Sign in to' /tmp/youtube.error; then
        rm /tmp/mpv.error /tmp/youtube.error

        # if user willing to save password in configs (who would?) serve him/her anyway
        [[ $GURU_YOUTUBE_PASSWORD ]] \
            && sing_in="-u $GURU_YOUTUBE_USER -p $GURU_YOUTUBE_PASSWORD" \
            || sing_in="-u $GURU_YOUTUBE_USER"

            gr.msg -v2 "signing in as $GURU_YOUTUBE_USER"

            # then perform re-try
            yt-dlp -v $youtube_options $sing_in $media_address -o - 2>/tmp/youtube.error \
                | mpv $mpv_options - >/dev/null
    fi

    # lacy error printout
    if [[ -f /tmp/mpv.error ]]; then
            _error=$(grep 'ERROR:' /tmp/youtube.error)
            [[ $_error ]] && gr.msg -v2 -c red $_error
            rm /tmp/mpv.error
        fi

    if [[ -f /tmp/youtube.error ]]; then
            _error=$(grep 'Failed' /tmp/mpv.error)
            [[ $_error ]] && gr.msg -v2 -c yellow $_error
            rm /tmp/youtube.error
        fi
    # remove now playing and error data
    [[ -f $GURU_AUDIO_NOW_PLAYING ]] && rm $GURU_AUDIO_NOW_PLAYING

    return 0
}


youtube.search_list () {
# search input and play it from youtube, optimized for audio, no video at all

    local base_url=https://www.youtube.com/watch?v=

    # overwrite global variables, optimize for audio
    youtube_options="-f bestaudio --no-resize-buffer --ignore-errors"

    # make search and get media data and address
    local query=$(youtube.search 20 json $@)

    # format information of found media
    declare -a id_list=($(echo $query | jq | grep url_suffix \
        | sed 's/"url_suffix"://g' \
        | sed 's/ //g' \
        | sed 's/"\/watch?v=//g'\
        | sed 's/"//g' ))
    # TBD declare -a title_list="$(echo $query | jq | grep title | sed 's/"title": "//g' | sed 's/"//g')"

    # go trough list of search results
    for (( i = 0; i < ${#id_list[@]}; i++ )); do
        _url="$base_url$(echo ${id_list[$i]} | cut -d':' -f2 | xargs | sed 's/"//g' | cut -d' ' -f 1)"

        # TBD _title="$(echo ${title_list[$i]} | cut -d':' -f2 | xargs | sed 's/,//g')"
        # gr.msg -v1 -h "${id_list[$i]} [$(($i+1))/${#id_list[@]}]" # might contain '-' and its read as an option =/
        echo "${id_list[$i]} [$(($i+1))/${#id_list[@]}]"

        # make now playing info available for audio module
        echo $_url >$GURU_AUDIO_NOW_PLAYING

        # start stream and play
        yt-dlp $youtube_options "$_url" -o - 2>/dev/null| mpv $mpv_options --no-video -

        #remove now playing data
        rm $GURU_AUDIO_NOW_PLAYING
    done
    return 0
}


youtube.get_media () {
# get media from tube
    id=$1
    url_base="https://www.youtube.com/watch?v"
    source mount.sh
    mount.main video

    [[ -d $data_location ]] || mkdir -p $GURU_MOUNT_VIDEO

    gr.msg -c white "downloading $url_base=$id to $GURU_MOUNT_VIDEO.. "
    yt-dlp --ignore-errors --continue --no-overwrites \
           --output "$GURU_MOUNT_VIDEO/%(title)s.%(ext)s" \
           "$url_base=$id"
    return 0
}


youtube.get_audio () {
# get media from tube
    local id=$1
    local url_base="https://www.youtube.com/watch?v"
    source mount.sh
    mount.main audio

    [[ -d $GURU_MOUNT_AUDIO/new ]] || mkdir -p $GURU_MOUNT_AUDIO/new

    yt-dlp --version || video.install

    gr.msg -c white "downloading $url_base=$id to $GURU_MOUNT_AUDIO.. "
    yt-dlp -x --audio-format mp3 --ignore-errors --continue --no-overwrites \
           --output "$GURU_MOUNT_AUDIO/%(title)s.%(ext)s" \
           "$url_base=$id"
    return 0
}


youtube.play () {
# play input file
    echo "$@" | grep "https://" && base_url="" || base_url="https://www.youtube.com/watch?v="
    youtube.parse_arguments $@
    local media_address="$base_url${youtube_arguments[0]}"
    gr.msg -c aqua "$media_address" -k $GURU_AUDIO_INDICATOR_KEY
    echo $media_address >$GURU_AUDIO_NOW_PLAYING
    yt-dlp -v $youtube_options $media_address -o - 2>/tmp/youtube.error \
                | mpv $mpv_options - >/dev/null
    gr.msg -c reset -k $GURU_AUDIO_INDICATOR_KEY
    rm $GURU_AUDIO_NOW_PLAYING
}


youtube.upgrade() {
# pip3 install --user --upgrade yt-dlp
    gr.msg -c blue "${FUNCNAME[0]}: TBD"
    return 0
}


youtube.install() {
# install requirements
    sudo apt install detox mpv yt-dlp ffmpeg
    pip3 install --upgrade pip
    # pip3 install youtube-search

    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    sudo ln -s /usr/local/bin/yt-dlp /usr/bin/yt-dlp

    jq --version >/dev/null || sudo apt install jq -y
    gr.msg -c green "Successfully installed"
    return 0
}


youtube.uninstall(){
# remove requirements
    sudo -H pip3 unisntall --user yt-dlp youtube-search
    rm -y /usr/bin/yt-dlp /usr/local/bin/yt-dlp
    sudo apt remove yt-dlp -y
    gr.msg -c green "uninstalled"
    return 0
}

youtube.rc
declare -g save_location=$GURU_MOUNT_DOWNLOADS
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_SOCKET --stream-record=/tmp/mpv_audio.cache"
declare -g youtube_arguments=()
declare -g youtube_options="-f worst"
declare -g save_to_file=

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    source $GURU_RC
    youtube.main $@
fi

# some tests
# query=$(python3 - << EOF
# print("$@")
# from youtube_search import YoutubeSearch
# results = YoutubeSearch('$@', max_results=1).to_json()
# print(results)
# EOF
# )

# code=$(cat <<EOF
# print($1)
# from youtube_search import YoutubeSearch
# results = YoutubeSearch('$1', max_results=1).to_json()
# print(results)
# EOF
# )
# query=$(python3 -c "$code")

# printf $@ >/tmp/to.find

# code=$(cat <<EOF
# f = open("/tmp/to.find","r")
# lines = str(f.readlines())

# from youtube_search import YoutubeSearch
# results = YoutubeSearch(lines, max_results=1).to_json()
# print(results)
# EOF
# )

# query=$(python3 -c "$code")



# youtube.get_subtitles () {

#     [ -d "$youtube_temp" ] && rm -rf "$youtube_temp"
#     mkdir -p "$youtube_temp"
#     cd "$youtube_temp"
#     yt-dlp "$media_url" --subtitlesonly #2>/dev/null
#     #youtube_media_filename=$(detox -v * | grep -v "Scanning")
#     #youtube_media_filename=${youtube_media_filename#*"-> "}
# }

# block_rev () {
#     # trick to reverse array without reversing strings
#     array=($@)

#     f() { array=("${BASH_ARGV[@]}"); }

#     shopt -s extdebug
#     f "${array[@]}"
#     shopt -u extdebug

#     echo "${array[@]}"
# }


# youtube.place () {

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


# youtube.get_metadata () {
# # CANNOT WORK copy from yle.sh

#     local error=
#     local meta_data="$youtube_temp/meta.json"

#     # make temp if not exist already
#     [[ -d "$youtube_temp" ]] || mkdir -p "$youtube_temp"
#     cd "$youtube_temp"

#     local base_url="https://areena.youtube.fi/"
#     # do not add base url if it already given
#     if echo $1 | grep "http" ; then
#             base_url=
#         fi

#     media_url="$base_url$1"

#     gr.msg -v3 -c deep_pink "media_url: $media_url"

#     # Check if id contain youtube_episodes, then select first one (newest)
#     youtube_episodes=($(yt-dlp --showepisodepage $media_url | grep -v $media_url))
#     # episode_ids=($(yt-dlp $media_url --showmetadata | jq '.[].program_id'))
#     gr.msg -v3 -c light_blue "youtube_episodes: ${youtube_episodes[@]}"

#     # change media address poin to first episode
#     [[ ${youtube_episodes[0]} ]] && media_url=${youtube_episodes[0]}

#     # Get metadata
#     yt-dlp $media_url --showmetadata > $meta_data

#     grep "error" $meta_data && error=$(cat $meta_data | jq '.[].flavors[].error')

#     if [[ $error ]] ; then
#             echo "$error"
#             return 100
#         fi

#     # set variables (like they be local anyway)
#     youtube_media_title="$(cat "$meta_data" | jq '.[].title')"
#     gr.msg -v2 "${youtube_media_title//'"'/""}"

#     youtube_media_address="$media_url "
#     #$(cat "$meta_data" | jq '.[].webpage')
#     #youtube_media_address=${youtube_media_address//'"'/""}
#     youtube_media_filename=$(cat "$meta_data" | jq '.[].filename')
# }

