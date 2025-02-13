#!/bin/bash
# play and get from youtube casa@ujo.guru 2022

declare -g youtube_rc="/tmp/$USER/guru-cli_youtube.rc"
# more global variables downstairs (after sourcing rc file)

youtube.help () {

    gr.msg -v1 "guru-cli youtube help " -c white
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL youtube play|get|list|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "  <search string> --<args>  search and play (more info -v2)" -V1
    gr.msg -v2 "  <search string>   search and play, options below "
    gr.msg -v2 "   --video          optimized for video quality"
    gr.msg -v2 "   --audio          optimized for audio quality"
    gr.msg -v2 "   --loop           play it forever"
    gr.msg -v2 "   --save           save media, audio is converted to mp3"
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
# module command parser

    local command=$1
    shift

    case "$command" in

        install|uninstall|upgrade|play|help)
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

        status)
            gr.msg -c dark_grey "no status data"
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


youtube.arguments () {
# module argument parser

    local got_args=($@)

    for (( i = 0; i < ${#got_args[@]}; i++ )); do
        gr.debug "${FUNCNAME[0]}: argument: $i:${got_args[$i]}"

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
            #     gr.debug "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;

            # --list|--l)            ## TBD play search result list
            #     i=$((i+1))
            #     gr.debug "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;


            # --start|--s)          ## TBD mpv does not support this ffmpg can, but not too important
            #     i=$((i+1))
            #     gr.debug "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;
            # --end|--e)
            #     i=$((i+1))
            #     gr.debug "got position: ${got_args[$i]} "
            #     position=${got_args[$i]}
            #     ;;
            *)
                module_options+=("${got_args[$i]}")
                ;;
        esac
    done

        # media format options given based on media saving location, yes not the best i konw
        if [[ $save_to_file ]] ; then

            [[ "$save_location" == "$GURU_MOUNT_AUDIO" ]] \
                && youtube_options="$youtube_options -x --audio-format mp3"

            [[ "$save_location" == "$GURU_MOUNT_VIDEO" ]] \
                && youtube_options="$youtube_options --recode-video mp4"
        fi

    # debug stuff (TBD remove later)
    gr.debug "${FUNCNAME[0]}: passing args: ${module_options[@]}"
    gr.debug "${FUNCNAME[0]}: youtube_options: $youtube_options"
    gr.debug "${FUNCNAME[0]}: mpv_options: $mpv_options"
}


youtube.rc () {
# source configurations (to be faster)

    if [[ ! -f $youtube_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/youtube.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]] \
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
    config.make_rc "$GURU_CFG/$GURU_USER/youtube.cfg" $youtube_rc append
    chmod +x $youtube_rc
}


youtube.search () {
# search from youtube and return json of $1 amount of results

    # deliver decimal value for inline python
    export result_count=$1

    # if output format is specified, set it and remove it from input string
    case $2 in
        dict) return_format=dict ; shift ;;
        json) return_format=json ; shift ;;
        *) return_format=json
    esac

    # remove result count
    shift
    export search_string="$@"

    # with python, indentation is critical, therefore following lines needs to be like this
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
    youtube.arguments $@

    # make search and get media data and address
    local query=$(youtube.search 1 json ${module_options[@]})

    # get information of found media
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
        #new_name=$(detox -v *mp4 -n | grep ">" | cut -d '>' -f 2 |xargs)
        detox -v *mp3 *mp4 $save_location 2>/dev/null

        #source tag.sh
        #tag.main add $new_name "guru-cli youtube.sh $title"
        return $?
    fi

    # make now playing info available for audio module
    echo $title >$GURU_AUDIO_NOW_PLAYING

    # start stream and play
    yt-dlp $youtube_options $media_address -o - 2>/tmp/$USER/youtube.error \
        | mpv $mpv_options - >/tmp/$USER/mpv.error

    # in some cases there is word fuck or exposed tits in video, therefore:
    if grep 'Sign in to' /tmp/$USER/youtube.error; then
        [[ -f /tmp/$USER/mpv.error ]] && rm /tmp/$USER/mpv.error
        [[ -f /tmp/$USER/youtube.error ]] && rm /tmp/$USER/youtube.error

        # if user willing to save password in configs (who would?) serve him/her anyway
        [[ $GURU_YOUTUBE_PASSWORD ]] \
            && sing_in="-u $GURU_YOUTUBE_USER -p $GURU_YOUTUBE_PASSWORD" \
            || sing_in="-u $GURU_YOUTUBE_USER"

            gr.msg -v2 "signing in as $GURU_YOUTUBE_USER"

            # then perform re-try
            yt-dlp -v $youtube_options $sing_in $media_address -o - 2>/tmp/$USER/youtube.error \
                | mpv $mpv_options - >/tmp/$USER/mpv.error
    fi

    # lacy error printout
    if [[ -f /tmp/$USER/mpv.error ]]; then
        _error=$(grep 'ERROR:' /tmp/$USER/youtube.error)
        [[ $_error ]] && gr.msg -v2 -c red $_error
        [[ -f /tmp/$USER/mpv.error ]] && rm /tmp/$USER/mpv.error
    fi

    if [[ -f /tmp/$USER/youtube.error ]]; then
        _error=$(grep 'Failed' /tmp/$USER/mpv.error)
        [[ $_error ]] && gr.msg -v2 -c yellow $_error
        [[ -f /tmp/$USER/youtube.error ]] && rm /tmp/$USER/youtube.error
    fi
    # remove now playing and error data
    [[ -f $GURU_AUDIO_NOW_PLAYING ]] && rm $GURU_AUDIO_NOW_PLAYING

    return 0
}


youtube.search_list () {
# search input and play it from youtube, optimized for audio, no video at all

    local base_url=https://www.youtube.com/watch?v=

    # check is installed
    yt-dlp --version || youtube.install

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
        yt-dlp $youtube_options "$_url" -o - 2>/dev/null| mpv $mpv_options --no-video - >/tmp/$USER/mpv.error

        #remove now playing data
        rm $GURU_AUDIO_NOW_PLAYING
    done
    return 0
}


youtube.get_media () {
# download videos from tube by youtube id

    id=$1
    url_base="https://www.youtube.com/watch?v"

    # check is installed
    yt-dlp --version || youtube.install

    # source mount module and mount video file folder in cloud
    source mount.sh
    mount.main video

    [[ -d $data_location ]] || mkdir -p $GURU_MOUNT_VIDEO

    gr.msg -c white "downloading $url_base=$id to $GURU_MOUNT_VIDEO.. "
    yt-dlp --ignore-errors --continue --no-overwrites \
           --output "$GURU_MOUNT_VIDEO/%(title)s.%(ext)s" \
           "$url_base=$id"
    return $?
}


youtube.get_audio () {
# download audio from tube by youtube id

    local id=$1
    local url_base="https://www.youtube.com/watch?v"

    # source mount module and mount audio file forlder in cloud
    source mount.sh
    mount.main audio

    [[ -d $GURU_MOUNT_AUDIO/new ]] || mkdir -p $GURU_MOUNT_AUDIO/new

    # check is installed
    yt-dlp --version || youtube.install

    # inform user
    gr.msg -c white "downloading $url_base=$id to $GURU_MOUNT_AUDIO.. "

    # download and convert to mp3 format, then save to audio base location named by title
    yt-dlp -x --audio-format mp3 --ignore-errors --continue --no-overwrites \
           --output "$GURU_MOUNT_AUDIO/%(title)s.%(ext)s" \
           "$url_base=$id"
    return $?
}


youtube.play () {
# play input file

    # check is user input url or id
    echo "$@" | grep "https://" && base_url="" || base_url="https://www.youtube.com/watch?v="

    # set playing and saving options and generate url
    youtube.arguments $@
    local media_address="$base_url${module_options[0]}"

    # indicate playing
    gr.msg -c aqua "$media_address" -k $GURU_AUDIO_INDICATOR_KEY
    echo $media_address >$GURU_AUDIO_NOW_PLAYING

    # get staream and play
    yt-dlp -v $youtube_options $media_address -o - 2>/tmp/$USER/youtube.error \
        | mpv $mpv_options - >/dev/null
    local _error=$?

    # remove playing indications
    gr.msg -c reset -k $GURU_AUDIO_INDICATOR_KEY
    rm $GURU_AUDIO_NOW_PLAYING

    # (( $_error > 0 )) && gr.msg -c yellow "${FUNCNAME[0]} returned $_error"
    return $_error
}


youtube.upgrade() {
# upgrade needed tools, ofter youtube changes shit causing weird errors

    # get new version of
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    pip3 install --upgrade pip
    pip3 install --user --upgrade yt-dlp
    return 0
}


youtube.install() {
# install requirements

    # install players, alternative youtube-dl, filename fixer and youtube seacher
    sudo apt-get update
    sudo apt-get install mpv ffmpeg yt-dlp detox
    pip3 install --upgrade pip
    pip3 install youtube-search

    # install patched yt-dlp
    sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    sudo ln -s /usr/local/bin/yt-dlp /usr/bin/yt-dlp

    # install json tools
    jq --version >/dev/null || sudo apt install jq -y

    #gr.msg -c green "mpv, ffmpeg, yt-dlp, detox and youtube-search installed"
    return 0
}


youtube.uninstall(){
# remove requirements

    # remove only youtube special requiderements, leave players etc.
    rm -y /usr/bin/yt-dlp /usr/local/bin/yt-dlp
    sudo apt-get remove yt-dlp -y
    pip3 uninstall youtube-search
    gr.msg -c green "uninstalled"
    return 0
}


# get configs and set variables
youtube.rc
declare -g module_options=()
declare -g save_location=$GURU_MOUNT_DOWNLOADS
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_SOCKET --stream-record=/tmp/$USER/mpv_audio.cache"
declare -g youtube_options="-f worst"
declare -g save_to_file=

# run main only if run, not sourced
if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    youtube.main $@
fi
