#!/bin/bash
# guru-cli play and get from youtube casa@ujo.guru 2022

declare -g youtube_rc="/tmp/guru-cli_youtube.rc"
# more global variables downstairs (after sourcing rc file)

youtube.help () {

    gr.msg -v1 "guru-cli youtube help " -c white
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL youtube play|get|list|song|search|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v2
    gr.msg -v1 "  play <id|url>           play media from stream"
    gr.msg -v1 "  get <ids|urls>          download list of media to media folder "
    gr.msg -v1 "  list <search string>    play list of search results, no video playback"
    gr.msg -v3 "  song <id|url>           download audio to audio folder "
    gr.msg -v3 "  search <string>         search, printout list of results "
    gr.msg -v1 "  install                 install requirements"
    gr.msg -v1 "  uninstall               remove requirements "
    gr.msg -v1 "  help                    this help window"
    gr.msg -v2
    gr.msg -v1 "options: " -c white
    gr.msg -v2
    gr.msg -v1 "   --video          optimized for video quality"
    gr.msg -v1 "   --audio          optimized for audio quality (video may not have audio only version)"
    gr.msg -v1 "   --loop           play it forever"
    gr.msg -v1 "   --save           save media, audio is converted to mp3"
    gr.msg -v2
    gr.msg -v1 "examples: " -c white
    gr.msg -v2
    gr.msg -v1 "  $GURU_CALL youtube search nyan cat"
    gr.msg -v1 "  $GURU_CALL youtube juna kulkee taas"
    gr.msg -v1 "  $GURU_CALL youtube play eF1D-W27Wzg"
    gr.msg -v1 "  $GURU_CALL youtube get https://www.youtube.com/watch?v=eF1D-W27Wzg"
    gr.msg -v2
    gr.msg -v2 "alias 'tube' to replace '$GURU_CALL youtube' is available"
}


youtube.main () {
# module command parser

    youtube.arguments $@

    case ${module_command[@]:0:1} in

        install|uninstall|upgrade|play|search|help|status)
            youtube.${module_command[@]:0:1} ${module_command[@]:1}
            ;;

        get|dl|download)
            for item in ${module_command[@]:1} ; do
               youtube.get_media $item
            done
            ;;

        song|music)
            youtube.get_audio ${module_command[@]:1}
            ;;

        list)
            youtube.search_list ${module_command[@]:1}
            ;;

        *)
            youtube.search_n_play ${module_command[@]}
            ;;

    esac
    return 0
}


youtube.status () {
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    if [[ -f /usr/local/bin/yt-dlp ]] || [[ -f /usr/bin/yt-dlp ]] ; then
        gr.msg -c green "installed"
        return 0
    else
        gr.msg -c dark_grey "not installed"
        return 1
    fi

}

youtube.arguments () {
# module argument parser

    local got_args=($@)

    for (( i = 0; i < ${#got_args[@]}; i++ )); do
        # gr.debug "${FUNCNAME[0]}: argument: $i:${got_args[$i]}"

        case ${got_args[$i]} in

            --get|--download|--save)
                export youtube_options="-f b"
                export save_to_file=true
                ;;

            --repeat|--l|--loop)
                export mpv_options="$mpv_options --loop"
                ;;

            --video|--v)
                export youtube_options=
                export save_location=$GURU_MOUNT_VIDEO
                ;;

            --audio|--a)
                export youtube_options="-f bestaudio --no-resize-buffer --ignore-errors"
                export mpv_options="$mpv_options --no-video"
                export save_location=$GURU_MOUNT_AUDIO
                ;;

            --list-formats)
                export youtube_options="$youtube_options --list-formats"
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
                export module_command+=("${got_args[$i]}")
                ;;
        esac
    done

        # media format options given based on media saving location, yes not the best i konw
        if [[ $save_to_file ]] ; then

            [[ "$save_location" == "$GURU_MOUNT_AUDIO" ]] \
                && export youtube_options="$youtube_options -x --audio-format mp3"

            [[ "$save_location" == "$GURU_MOUNT_VIDEO" ]] \
                && export youtube_options="$youtube_options --recode-video mp4"
        fi
    #echo ${module_command[@]}
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
# search termn, print list of results and ask user to select one, then play it

    local search_term=$@

    # user did not give search string
    [[ $search_term ]] || read -p "search term: " search_term

    gr.debug "$search_term"

    # search from youtube
    local query=$(youtube.find 25 json "$search_term")

    # make lists of results (yeah stupid, but it works)
    IFS=$'\n'
    local list=($(echo $query | jq | grep title | cut -d '"' -f 4 | tr -s ' '))
    local urls=($(echo $query | jq | grep url_suffix | cut -d '"' -f 4))

    # printout list of results
    for (( i = 0; i < ${#list[@]}; i++ )); do
        gr.msg -hn "$i: "
        gr.msg -c light_blue "${list[i]}"
    done

    # ask user to input list item number
    read -p "select: " ans
    [[ $ans ]] || ans=0

    # check user input
    case $ans in

        [0-9]|1[0-9]|2[0-9])

            # out of list
            if [[ $ans -ge ${#list[@]} ]] ; then
                gr.msg -c error "list is only $(( ${#list[@]} -1 )) items long"
                return 0
            fi

            # plays stream
            youtube.play "https://www.youtube.com${urls[ans]}"


                # if just saving the file
            if [[ $save_to_file ]]; then
                #save the file to media folder
                youtube_options="$youtube_options --continue --output $save_location/%(title)s.%(ext)s"
                gr.msg -v1 "downloading to $save_location.. "

                yt-dlp $youtube_options $media_address
                # a bit dangero if some of location variables are empty
                #new_name=$(detox -v *mp4 -n | grep ">" | cut -d '>' -f 2 |xargs)
                detox -v *mp3 *mp4 $save_location 2>/dev/null

                #source tag.sh
                #tag.main add $new_name "guru-cli youtube.sh $title"
                return $?
            fi

            ;;

        q|exit|bye|quit)
            # exit
            return 0
            ;;
        *)
            # wrong answer
            gr.msg -c error "please select 0-$(( ${#list[@]} -1 ));"
            ;;
    esac
}


youtube.find () {
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
    local query=$(youtube.find 1 json ${module_command[@]})

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
    yt-dlp $youtube_options $media_address -o - 2>/tmp/youtube.error \
        | mpv $mpv_options - >/tmp/mpv.error

    # in some cases there is word fuck or exposed tits in video, therefore:
    if grep 'Sign in to' /tmp/youtube.error; then
        [[ -f /tmp/mpv.error ]] && rm /tmp/mpv.error
        [[ -f /tmp/youtube.error ]] && rm /tmp/youtube.error

        # if user willing to save password in configs (who would?) serve him/her anyway
        [[ $GURU_YOUTUBE_PASSWORD ]] \
            && sing_in="-u $GURU_YOUTUBE_USER -p $GURU_YOUTUBE_PASSWORD" \
            || sing_in="-u $GURU_YOUTUBE_USER"

            gr.msg -v2 "signing in as $GURU_YOUTUBE_USER"

            # then perform re-try
            yt-dlp -v $youtube_options $sing_in $media_address -o - 2>/tmp/youtube.error \
                | mpv $mpv_options - >/tmp/mpv.error
    fi

    # lacy error printout
    if [[ -f /tmp/mpv.error ]]; then
        _error=$(grep 'ERROR:' /tmp/youtube.error)
        [[ $_error ]] && gr.msg -v2 -c red $_error
        [[ -f /tmp/mpv.error ]] && rm /tmp/mpv.error
    fi

    if [[ -f /tmp/youtube.error ]]; then
        _error=$(grep 'Failed' /tmp/mpv.error)
        [[ $_error ]] && gr.msg -v2 -c yellow $_error
        [[ -f /tmp/youtube.error ]] && rm /tmp/youtube.error
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
    local query=$(youtube.find 20 json $@)

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
        yt-dlp $youtube_options "$_url" -o - 2>/dev/null| mpv $mpv_options --no-video - >/tmp/mpv.error

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
    echo "$@" | grep -q "https://" && base_url="" || base_url="https://www.youtube.com/watch?v="

     # debug stuff (TBD remove later)
    gr.debug "save_to_file" "$save_to_file"
    gr.debug "youtube_options" "$youtube_options"
    gr.debug "module_command" "${module_command[@]}"
    gr.debug "mpv_options" "$mpv_options"
    gr.debug "save_location" "$save_location"

    # set playing and saving options and generate url
    # youtube.arguments $@
    # local media_address="$base_url${module_command[0]}"
    local media_address="$base_url$1"

    # indicate playing
    gr.msg -c aqua "$media_address" -k $GURU_AUDIO_INDICATOR_KEY
    echo $media_address >$GURU_AUDIO_NOW_PLAYING


    # yt-dlp $youtube_options $media_address -o - 2>/tmp/youtube.error \
    #     | mpv $mpv_options - >/tmp/mpv.error


    # get staream and play
    #
    gr.debug "yt-dlp $youtube_options $media_address -o - | mpv $mpv_options -"
    yt-dlp $youtube_options $media_address -o - 2>/tmp/youtube.error | mpv $mpv_options - >/tmp/mpv.error

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

    pip3 install --upgrade pip || rm -r ~/.cache/pip/selfcheck/ && pip3 install --upgrade pip
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
    [[ -f /usr/bin/yt-dlp ]] && rm -y /usr/bin/yt-dlp
    [[ -f /usr/local/bin/yt-dlp ]] && rm -y /usr/local/bin/yt-dlp
    sudo apt-get remove yt-dlp -y
    pip3 uninstall youtube-search
    gr.msg -c green "uninstalled"
    return 0
}


# get configs and set variables
youtube.rc
source $GURU_BIN/audio/audio.sh
declare -g module_command=()
declare -g save_location=$GURU_MOUNT_DOWNLOADS
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_MPV_SOCKET --stream-record=/tmp/mpv_audio.cache"
declare -g youtube_options="-f worst"
declare -g save_to_file=

# run main only if run, not sourced
if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    youtube.main $@
fi
