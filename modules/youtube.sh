#!/bin/bash
# grbl play and get from youtube casa@ujo.guru 2022

# youtube on 80x24 terminal window
# based on youtube-dl (before), yt-dlp (currently)
# - no adds (still works)
# - search and download
# - colorful menu view
# - thumbnails (tiv)
# - scalable on terminal size 80x24 > (240x200)
# status: demo is functional, enough

# Features (on above)
# - player gui (mpv) when playing
# - mpv playtime keyboard ui
# - pipe option to communicate with
#  - mpv daemon tools (audio/mpv.sh)
# - scalable on terminal window
#   -tip: remove toolbar (gnome terminal)
#     -scale terminal down
#     -make long slim window
#     -set verbose to 3 to enable thumbnails
#     -scale till numbers are visible
# - lives in grbl module environment
# - audio.sh can be used as interface
#   - now playing (wmctrl)
#   - audio status
#   - modules can control others audio feed
#     - pause and stop and volume (mpv)
#     - skip list, "the Pause" (exit control)
# - options
#   '-video' optimize search for # TODO keywords to cfg
#   '-audio' optimize search for # TODO keywords to cfg < and walk trough argument "audio"
#   '-save' call TODO youtube.get_media < +dl get download
#   '-continue, -loop'

# nice to have
# - tile view with thumbs
# - standalone version with git magic
# - silly rapidness and acronomatis

source flag.sh
source audio.sh

declare -g youtube_rc="/tmp/$USER/grbl_youtube.rc"
declare -g youtube_data=$GRBL_DATA/youtube
declare -g youtube_error=/tmp/$USER/youtube.error
declare -g mpv_error=/tmp/$USER/mpv.error
declare -g continue_to_play=
# more global variables downstairs (after sourcing rc file)

youtube.help () {
# main help of youtube module
    gr.msg -v1 "grbl youtube help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL youtube play|get|list|song|search|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "Commands: " -c white
    gr.msg -v2
    gr.msg -v1 "  play <id|url>           play media from stream"
    gr.msg -v1 "  get <ids|url>           download list of media to media folder "
    gr.msg -v1 "  list <search string>    play list of search results, no video playback"
    gr.msg -v3 "  song <id|url>           download audio to audio folder "
    gr.msg -v3 "  search <string>         search, printout list of results "
    gr.msg -v1 "  install                 install requirements"
    gr.msg -v1 "  uninstall               remove requirements "
    gr.msg -v1 "  help                    this help window"
    gr.msg -v2
    gr.msg -v1 "Options: " -c white
    gr.msg -v2
    gr.msg -v1 "   --video          optimized for video quality and play"
    gr.msg -v1 "   --audio          optimized for audio quality, play without video screen"
    gr.msg -v1 "   --continue       if result is list start to play it and continue to do so "
    gr.msg -v1 "   --loop           play it forever"
    gr.msg -v1 "   --save           save media, audio is converted to mp3"
    gr.msg -v2
    gr.msg -v1 "Search menu: " -c white
    gr.msg -v2
    gr.msg -v1 " Launch by alias 'tubes' or '$GRBL_CALL youtube'"
    gr.msg -v1 " Menu navigation is key based, see command keys below. "
    gr.msg -v1 " Search string can be given as argument. Options should also apply here.  "
    gr.msg -v2
    gr.msg -v1 "    <search phrase>       just type to something to find in youtube"
    gr.msg -v1 "    <1..20>               select media from result list"
    gr.msg -v1 "    (n)ext                jump to next list item "
    gr.msg -v1 "    (p)revious            jump to previous in list"
    gr.msg -v1 "    (w)ait                wait until previous audio is ended"
    gr.msg -v1 "    (a)utoplay            continue to play next item "
    gr.msg -v1 "    (s)ingin              sing in with google account add details to youtube.cfg"
    gr.msg -v1 "    (t)ype                switch between audio or video mode"
    gr.msg -v1 "    (d)onwload            switch between  download ans player mode"
    gr.msg -v1 "    (l)ist                printout list of search result"
    gr.msg -v1 "    (e)rror               print last error "
    gr.msg -v1 "    (v)erbose <1..3>      1= basic, 2=more details, 3= thumbnails"
    gr.msg -v1 "    (q)uit                bye bye"
    gr.msg -v2
    gr.msg -v1 "Functions:" -c white
    gr.msg -v2
    gr.msg -v1 " Fist source script file 'source youtube.sh' and then run functions 'youtube.status'"
    gr.msg -v2
    gr.msg -v3 "  youtube.help                printout help "
    gr.msg -v3 "  youtube.main                main command parser "
    gr.msg -v3 "  youtube.status              status oneliner "
    gr.msg -v3 "  youtube.options             command line option parser"
    gr.msg -v3 "  youtube.rc                  lift configuratios to environment "
    gr.msg -v3 "  youtube.make_rc             configuration changer "
    gr.msg -v3 "  youtube.search              search tool "
    gr.msg -v3 "  youtube.firefox_cookies     get cookies from browser to sync google account"
    gr.msg -v3 "  youtube.search_n_play       search menu "
    gr.msg -v3 "  youtube.get_media           donwload media by url or id"
    gr.msg -v3 "  youtube.get_audio           donwload audio by url or id"
    gr.msg -v3 "  youtube.play                seach an select first hit to play"
    gr.msg -v3 "  youtube.upgrade             updrade yt-dlp and python lib"
    gr.msg -v3 "  youtube.install             install needed softeare and libs"
    gr.msg -v3 "  youtube.uninstall           remove installation"
    gr.msg -v3
    gr.msg -v1 "Examples: " -c white
    gr.msg -v2
    gr.msg -v1 "  $GRBL_CALL youtube get https://www.youtube.com/watch?v=eF1D-W27Wzg"
    gr.msg -v1 "  $GRBL_CALL youtube play eF1D-W27Wzg"
    gr.msg -v1 "  $GRBL_CALL youtube search nyan cat "
    gr.msg -v1 "  $GRBL_CALL youtube juna kulkee taas "
    gr.msg -v2
    gr.msg -v2 "Aliases:" -c white
    gr.msg -v2 " 'tube' and 'tubes' are present"
    gr.msg -v2
    gr.msg -v1 "  tube eF1D-W27Wzg"
    gr.msg -v1 "  tubes mitä kuuluu marja leena"
    gr.msg -v2


}

youtube.main () {
# module command parser

    youtube.options $@

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


youtube.options () {
# module argument parser

    local got_args=($@)

    for (( i = 0; i < ${#got_args[@]}; i++ )); do
        # gr.debug "${FUNCNAME[0]}: argument: $i:${got_args[$i]}"

        case ${got_args[$i]} in

            --get|--download|--save|dl)
                ## TBD why export? sould work without it
                youtube_options="-f b" # export
                save_to_file=true # export
                ;;

            --continue|--c|--cont)
                continue_to_play=true
                ;;

            --repeat|--l|--loop)
                mpv_options="$mpv_options --loop" # export
                ;;

            --fullscreen|--fs|--f)
                mpv_options="$mpv_options --fs" # export
                ;;

            --video|--v)
                youtube_options= # export
                save_location=$GRBL_MOUNT_VIDEO # export
                ;;
            --audio|--a)
                youtube_options="-f bestaudio --no-resize-buffer --ignore-errors" # export
                mpv_options="$mpv_options --no-video" # export
                save_location=$GRBL_MOUNT_AUDIO # export
                ;;

            --list-formats)
                youtube_options="$youtube_options --list-formats" # export
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
                module_command+=("${got_args[$i]}") # export
                ;;
        esac
    done

        # media format options given based on media saving location, yes not the best i konw
        if [[ $save_to_file ]] ; then

            [[ "$save_location" == "$GRBL_MOUNT_AUDIO" ]] \
                && youtube_options="$youtube_options -x --audio-format mp3" # export

            [[ "$save_location" == "$GRBL_MOUNT_VIDEO" ]] \
                && youtube_options="$youtube_options --recode-video mp4" # export
        fi
    #echo ${module_command[@]}
}


youtube.rc () {
# source configurations (to be faster)

    if [[ ! -f $youtube_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/youtube.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/audio.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $youtube_rc) )) -gt 0 ]]
        then
        youtube.make_rc && \
            gr.msg -v1 -c dark_gray "$youtube_rc updated"
    fi
    source $youtube_rc
}


youtube.make_rc () {
# make rc out of config file and run it

    source config.sh

    if [[ -f $youtube_rc ]] ; then
        rm -f $youtube_rc
    fi

    config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $youtube_rc
    config.make_rc "$GRBL_CFG/$GRBL_USER/audio.cfg" $youtube_rc append
    config.make_rc "$GRBL_CFG/$GRBL_USER/youtube.cfg" $youtube_rc append
    chmod +x $youtube_rc
}


youtube.search () {
# search from youtube, print list of results and ask user to select one, then play it

    # initialize
    local items=
    local optimization="video"
    local list=()
    local urls=()
    local duration=()
    local last_item=
    local thubnails=
    local search_phrase=
    local todo="play"
    local mp4=
    # local youtube_data=$GRBL_DATA/youtube

    # terminal type
    case $TERM in
        xterm-256color)
            thubnails=true
            ;;
        linux|*)
            optimization="audio"
            [[ $GRBL_VERBOSE -gt 2 ]] && export GRBL_VERBOSE=2
            export youtube_options=
            export mpv_options="--input-ipc-server=$GRBL_AUDIO_MPV_SOCKET-youtube --vo=null --no-video "
    esac

    # make needed folders
    if ! [[ -d $youtube_data ]] ; then
        source mount.sh
        mount.main system || youtube_data=/tmp
        [[ -d $youtube_data ]] || mkdir $youtube_data
    fi

    [[ -d "$youtube_data/played" ]] || mkdir -p "$youtube_data/played"
    [[ -d "$youtube_data/cache" ]] || mkdir -p "$youtube_data/cache"

    search () {
    # search from by yt-dlp

        # get search phrase
        search_phrase=$@

        # user did not give search string
        [[ $search_phrase ]] || read -p "search term: " search_phrase

        gr.debug "$FUNCNAME search_phrase:'$search_phrase'"
        [[ $search_phrase == "" ]] && return 0

        # search from youtube.com, i think youtube limits results to 20 items
        local _json="/tmp/$USER/youtube_results.json"
        youtube.find $GRBL_YOUTUBE_RESULT_LIMIT json "$search_phrase" >$_json

        # fulfill list variables from data got from youtube search
        ifs=$IFS ; IFS=$'\n'
        id=($(jq '.videos [] | .id ' $_json))
        title=($(jq '.videos [] | .title ' $_json))
        url=($(jq '.videos [] | .url_suffix ' $_json))
        duration=($(jq '.videos [] | .duration ' $_json))
        channel=($(jq '.videos [] | .channel ' $_json))
        views=($(jq '.videos [] | .views ' $_json))
        publish=($(jq '.videos [] | .publish_time ' $_json))
        description=($(jq '.videos [] | .long_desc ' $_json))
        thumb=($(jq '.videos [] | .thumbnails [0] ' $_json | cut -d'?' -f1))
        IFS=$ifs
        last_item=1
    }

    compose_list () {
    # make list from search results
        [[ ${#title[@]} -lt 10 ]] && width=3
        [[ ${#title[@]} -gt 9 ]] && width=4
        [[ ${#title[@]} -gt 99 ]] && width=5

        # go trough found list items
        for (( i = 0; i < ${#title[@]}; i++ )); do
            title[$i]=${title[$i]//'"'}
            url[$i]=${url[$i]//'"'}
            duration[$i]="${duration[$i]//'"'}"
            id[$i]=${id[$i]//'"'}
            publish[$i]=${publish[$i]//'"'}
            [[ ${publish[$i]} == "0" ]] && publish[$i]="" || publish[$i]="${publish[$i]}"
            [[ ${description[$i]} == "null" ]] && description[$i]=""
            thumb[$i]=${thumb[$i]//'"'}
            views[$i]=${views[$i]//'"'}
            channel[$i]="${channel[$i]//'"'}"
            [[ $GRBL_VERBOSE -gt 2 ]] && ! [[ -f $youtube_data/cache/${id[$i]}.jpg ]] \
                && curl -s ${thumb[$i]} --output "$youtube_data/cache/${id[$i]}.jpg"
        done
        items=${#title[@]}
    }

    print_list() {
    # format and printout list of composed search results
        cols=$(echo "cols" | tput -S)

        # print header
        gr.msg -h "youtube search '$(sed -e "s/\b\(.\)/\u\1/g" <<<$([[ $search_phrase ]] && echo $search_phrase || echo $@))'"

        # limit thumbnail size to whatever specified in user conf
        [[ $cols -gt $GRBL_YOUTUBE_THUMBNAIL_SIZE ]] && thumb_cols=$GRBL_YOUTUBE_THUMBNAIL_SIZE || thumb_cols=$cols

        # go trough found list items
        for (( i = 0; i < ${#title[@]}; i++ )); do

            # print list without thumbnails, and try to optimize to column width
            if [[ $GRBL_VERBOSE -lt 3 ]] ; then

                # printout only number add title
                if [[ $cols -lt 80 ]] ; then
                    gr.msg -hn -w $width "$(( $i + 1 )))"
                    gr.msg -w $(($cols - $width - 1)) -c light_blue "${title[$i]} "
                # printout number, title and duration
                elif [[ $cols -ge 80 ]] && [[ $cols -lt 100 ]] ; then
                    gr.msg -hn -w $width "$(( $i + 1 )))"
                    gr.msg -n  -c light_blue "${title[$i]} "
                    gr.msg -c gray "(${duration[$i]}) "
                # printout number, title, duration and publish date
                elif [[ $cols -ge 100 ]] ; then
                    gr.msg -hn -w $width "$(( $i + 1 )))"
                    gr.msg -n  -c light_blue "${title[$i]} "
                    gr.msg -v0 -nc gray "(${duration[$i]}) "
                    gr.msg -c dark_gray "(${publish[$i]}) "
                fi
            # verbosity 3, all information
            else
                # printout number add title
                gr.msg -hn -w $width "$(( $i + 1 )))"
                gr.msg -n -c light_blue "${title[$i]} "
                # printout rest of information
                gr.msg -c gray "(${duration[$i]}) "
                gr.msg -nc dark_gray "[${channel[$i]}] "
                gr.msg -c dark_gray "(${publish[$i]}) "
                gr.msg -c dark_gray "${views[$i]} "
                # printout descriptions (it any)
                [[ ${description[$i]} ]] && gr.msg -c gray "${description[$i]} "
                # printout thumbnail
                [[ $thubnails ]] && tiv -w $thumb_cols "$youtube_data/cache/${id[$i]}.jpg"
                gr.msg
            fi
        done
    }

    print_prompt () {
    # print help and prompt

         # print menu help bar
        [[ $items -lt 1 ]] && gr.msg -N -p "search by typing search phrase and press enter"

        # help width
        if [[ $cols -lt 69  ]] ; then
            _white=('' n p w a s t d l e v q 1 $items $'\n')
            _grey=('[' '|' '|' '|' '|' '|' '|' '|' '|' '|' '|' '|' '..' ']')
            _space=''
        else
            _white=(n p w a s t d l e v q 1 $'\b'$items $'\n')
            _grey=(ext revious ait utoplay ingin ype onwload ist rror erbose uit '..')
            _space=' '
        fi

        for (( i = 0; i < ${#_white[@]}; i++ )); do
            gr.msg -n -c white "${_white[$i]}"
            gr.msg -n -c grey "${_grey[$i]}$_space"
        done

        # prompt width
        if [[ $cols -lt 60  ]] ; then
            _prompt=$'\r'"$last_item${optimization:0:1} search: "
        else
            _prompt=$'\r'"[$last_item/${#title[@]}] search or select $todo $optimization: "
        fi

        # if user hit caps-clock + esc, cancel continue playing
        if flag.get cancel ; then
            flag.rm cancel
            continue_to_play=
        fi

        # if user hit caps-clock + §, continue playing
        if flag.get ok ; then
            flag.rm ok
            continue_to_play=true
        fi

        # if continue playing is set , wait few second and jump to next item
        if [[ $continue_to_play ]] ; then
            read -t4 -p "$_prompt" ans
            ans=${ans:-continue}
        # else check is next pressed from keyboard, then assuming user wants to continue playingq
        else
            # user interrupted by pressing next key
            if flag.get next ; then
                flag.rm next
                continue_to_play=true
                ans=n
            # user interrupted by pressing previous key
            elif flag.get prev ; then
                flag.rm prev
                continue_to_play=true
                ans=p
            else
            # ask user to make action
                read -p "$_prompt" ans
            fi
        fi
    }

    play_item () {
    # play item

        # limit thumbnail size
        local cols=$(echo "cols"|tput -S)
        local _error=0

        [[ $cols -gt 80 ]] && cols=80

        # make shown list number to real list location
        local item=$(($1-1))

        # format header and now playing data
        local np="youtube [$1/$items] ${title[$item]} ${duration[$item]}"

        # place formatted headers, sleep one second cause last player might delete updated file
        echo "$np" >$GRBL_AUDIO_NOW_PLAYING
        create_time=$(stat -c %Y $GRBL_AUDIO_NOW_PLAYING)
        gr.msg -N -h "$np"

        # log what played today
        echo "$(date -d now +%Y-%m-%d-%H:%M:%S) ${id[$item]} ${title[$item]}" >>"$youtube_data/played/$(date -d now +%Y-%m-%d).list"

        # fetch thumbnail if not done already
        if [[ $thubnails ]] && [[ $GRBL_VERBOSE -ge 1 ]] && [[ ! $save_to_file ]]; then
            [[ -f $youtube_data/cache/${id[$item]}.jpg ]] || curl -s ${thumb[$item]} --output "$youtube_data/cache/${id[$item]}.jpg"
            tiv -w $cols "$youtube_data/cache/${id[$item]}.jpg"
        fi

        local media_address="https://www.youtube.com${url[$item]}"

        # if download selected
        if [[ $save_to_file ]] ; then
            # open repository to select quality separately for video and audio
            youtube.get_media $media_address
            # nothing more to do here?
            return $?
        fi

        # print media address below the thumbnail (link to youtube)
        gr.msg -c dark_grey "$media_address"

        # if corsair enabled, control keyboard rgb leds to indicate statuses.
        gr.ind playing -k play

        # this is shown only then debug mote '-d' is flagged (or verbose 4+)
        gr.debug "yt-dlp $youtube_options $sing_in_option $media_address -o - 2>$youtube_error | mpv $mpv_options -"

        # at the moment, debug = dryrun in 25% modules, others just run shit, this good habit is
        if [[ $GRBL_DEBUG ]]; then
            echo "yt-dlp $youtube_options $sing_in_option $media_address -o - 2>$youtube_error | mpv $mpv_options -"
            return 0
        fi

        yt-dlp $youtube_options $sing_in_option $media_address -o - 2>$youtube_error | mpv $mpv_options -
        # in every module, function error is returned to core in continued return chain, and can be processed by core to
        # exits from module function are logged specially old method gr.msg -x 128 exits can cause extra logging, more for lacy prototyping
        _error=$?

        # remove playing indications
        gr.end play
        #gr.msg -c reset -k $GRBL_AUDIO_INDICATOR_KEY

        # transfer errors for future processing in main loop
        gr.debug "$FUNCNAME _error:$_error"

        # remove now playing only if it's created by current me. made by checking creation time
        # Okey, here is late night implementation, but it seem to work, stay there then.
        [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && [[ $(($(stat -c %Y $GRBL_AUDIO_NOW_PLAYING) - $create_time)) -lt 1 ]] \
            && rm $GRBL_AUDIO_NOW_PLAYING

        # module maker (2025) declare module error as $_error=(), compatible with below
        (( $_error > 0 )) && gr.msg -c yellow "${FUNCNAME[0]} returned $_error"
        return $_error
    }

    set_sing_in () {
    # get cookies from firefox and set youtube sing in options for user set in configuration
    # NOTE: this might not work anymore: https://github.com/yt-dlp/yt-dlp/issues/8079

        if ! [[ -f $youtube_data/cookies.txt ]] ; then
            yt-dlp --cookies-from-browser $GRBL_PREFERRED_BROWSER --cookies $youtube_data/cookies.txt --skip-download 2>$youtube_error
            gr.msg -c white "cookies saved to $youtube_data/cookies.txt"
            gr.ask "file contains all your cookies, so you might like to delete it on exit? " && delete_cookies=true
        fi
        if ! [[ $GRBL_YOUTUBE_USER ]] ; then
            gr.msg -e1 "no youtube user set in configuration "
            return 122
        fi

        [[ $GRBL_YOUTUBE_PASSWORD ]] \
            && sing_in_option="-u $GRBL_YOUTUBE_USER -p $GRBL_YOUTUBE_PASSWORD" \
            || sing_in_option="-u $GRBL_YOUTUBE_USER"

        sing_in_option="$sing_in_option --cookies $youtube_data/cookies.txt"
    }

    local cols=$(echo "cols" | tput -S)

    # search and printout search results
    [[ $1 ]] && search "$@"
    compose_list
    print_list

    # main menu loop
    while true ; do

        print_prompt

        # parse user input
        case ${ans%% *} in

            # play selected search result
            [1-9]|1[0-9]|2[0-9]|3[0-9])
                if [[ $ans -gt $items ]] ; then
                    gr.msg -c error "list is $items items long"
                    continue
                fi
                last_item=$ans
                ;;

            continue) # continuous playing, increase item number
                [[ $last_item -ge ${#title[@]} ]] && last_item=0
                last_item=$(( last_item + 1 ))
                ;;

            v*)  # set verbosity
                [[ ${#ans} -le 1 ]] && read -p "set verbosity 0..2: " ans
                [[ ${#ans} == 2 ]] && ans=${ans:1}
                [[ "${#ans}" -ge 3 ]] && ans=${ans#* }
                gr.debug "VERBOSE:'$ans"
                [[ ! $thubnails ]] && [[ $ans -gt 2 ]] && ans=2
                export GRBL_VERBOSE=$ans
                [[ $GRBL_VERBOSE -gt 2 ]] && compose_list
                print_list
                continue
                ;;

            d)  if [[ $save_to_file ]] ; then
                    save_to_file=
                    todo="to play"
                else
                    save_to_file=true
                    todo="to download"
                    # if [[ $optimization == "video" ]] ; then
                    #     gr.ask "convert to webm files to mp4 format?" && mp4=true || mp4=
                    # fi
                fi
                gr.msg "selected $todo"
                continue
                ;;

            t)  # content type selector, video or audio
                if [[ $optimization == "audio" ]] ; then
                    optimization=video
                    youtube_options="-f best"
                    mpv_options="--input-ipc-server=$GRBL_AUDIO_MPV_SOCKET-youtube"
                else
                    optimization=audio
                    youtube_options=
                    mpv_options="--input-ipc-server=$GRBL_AUDIO_MPV_SOCKET-youtube --vo=null --no-video "
                fi
                gr.msg "$optimization selected"
                continue
                ;;

            a)  # toggle continuous and normal playing
                if [[ $continue_to_play ]] ; then
                    gr.msg "continues playing canceled"
                    continue_to_play=
                else
                    gr.msg "continues playing set"
                    continue_to_play=true
                fi
                continue
                ;;

            f) # not really sure what this were
                if ! [[ $mpv_temp_options ]] ; then
                    mpv_temp_options=$mpv_options
                    mpv_options="$mpv_options --fs"
                else
                    mpv_options=$mpv_temp_options
                    mpv_temp_options=
                fi
                continue
                ;;

            n)  # play next item
                last_item=$(( last_item + 1 ))
                [[ $last_item -ge ${#title[@]} ]] && last_item=1
                ;;

            p)  # play previous item
                last_item=$(( last_item - 1 ))
                [[ $last_item -le 0 ]] && last_item=${#title[@]}
                ;;
            l)  # print list of results again
                print_list
                continue
                ;;
            w)  # wait until now playing is empty and start to play
                [[ "${#ans}" -ge 3 ]] && last_item=${ans#* }
                item=$(( $last_item - 1 ))
                sleep 1
                gr.msg -n "waiting [$last_item/$items] ${title[$item]} ${duration[$item]} (press any key to play now)"
                while [[ -f $GRBL_AUDIO_NOW_PLAYING ]] ; do
                    read -s -n1 -t1 && break
                done
                ;;
            s)  # sing in toggle
                if [[ $sing_in_option ]] ; then
                    gr.msg -c dark_grey "removing login options"
                    sing_in_option=
                else
                    gr.msg -c white "setting $GRBL_YOUTUBE_USER login options"
                    set_sing_in
                fi
                continue
                ;;
            e)  #show last error log
                gr.msg -h "printing error log from $youtube_error "
                [[ -f $youtube_error ]] && cat $youtube_error || gr.msg "no error log found"
                continue
                ;;
            q*|exit|bye) # exit
                break
                ;;
            "") # play current item
                true
                ;;
            *)  # new search
                search "$ans"
                compose_list
                print_list
                continue
                ;;
        esac

        # pause other players, but only once
        if ! [[ $stopped ]] && [[ $optimization == audio ]] ; then
            local stopped=true
            audio.pause others youtube
        fi

        play_item $last_item

        if [[ $? -eq 143 ]] ; then

            # some module asked to hold on a moment
            if flag.get audio_hold ; then
                while flag.get audio_hold >/dev/null ; do
                    sleep 2
                done
            else
                gr.msg "continues playing canceled"
                continue_to_play=
            fi
        fi
    done

    # do not compromise user privacy
    if [[ $delete_cookies ]] && [[ -f $youtube_data/cookies.txt ]] ; then
        gr.msg -n "deleting cookies $youtube_data/cookies.txt.. "
        rm $youtube_data/cookies.txt && gr.msg -c green "ok" || gr.msg -e3 "failed"
    fi

    return 0
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


youtube.firefox_cookies () {

    local cookie_db="/tmp/$USER/fox-cookies.sqlite"

    get_database () {

        local profiles="$HOME/.mozilla/firefox/profiles.ini"

        if ! [[ -f $profiles ]] ; then
            gr.msg -e2 no profiles '$profiles' found
            return 112
        fi

        # fast way to get default profile
        head -n 3 $profiles | grep "Default" >/tmp/$USER/fox-profile
        source /tmp/$USER/fox-profile
        profile=$Default
        rm /tmp/$USER/fox-profile
        gr.debug "$FUNCNAME profile:'$profile'"
        [[ $profile ]] || return 113

        # get cookies database
        fox_cookie_db=$HOME/.mozilla/firefox/$profile/cookies.sqlite
        gr.debug "$FUNCNAME cookie_db:'$fox_cookie_db'"
        [[ -f $cookie_db ]] || return 114

        cp $fox_cookie_db $cookie_db
    }

    [[ -f $cookie_db ]] || get_database
    python3 "$GRBL_BIN/audio/get_cookie.py" youtube.com $cookie_db >$youtube_data/youtube_cookie.txt
    rm $cookie_db
}


youtube.search_n_play () {
# search input and play it from youtube. use long arguments --video or --audio to select optimization

    local base_url="https://www.youtube.com"
    local _error=

    # to fulfill global variables: save_to_file save_location mpv_options youtube_options
    youtube.options $@

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
        #tag.main add $new_name "grbl youtube.sh $title"
        return $?
    fi

    # make now playing info available for audio module
    echo "youtube $title" >$GRBL_AUDIO_NOW_PLAYING

    # start stream and play
    yt-dlp $youtube_options $media_address -o - 2>$youtube_error \
        | mpv $mpv_options - >$mpv_error

    # in some cases there is word fuck or exposed tits in video, therefore:
    if grep 'Sign in to' $youtube_error; then
        [[ -f $mpv_error ]] && rm $mpv_error
        [[ -f $youtube_error ]] && rm $youtube_error

        # if user willing to save password in configs (who would?) serve him/her anyway
        [[ $GRBL_YOUTUBE_PASSWORD ]] \
            && sing_in="-u $GRBL_YOUTUBE_USER -p $GRBL_YOUTUBE_PASSWORD --cookies-from-browser" \
            || sing_in="-u $GRBL_YOUTUBE_USER --cookies-from-browser"

            gr.msg -v2 "signing in as $GRBL_YOUTUBE_USER"

            # then perform re-try
            yt-dlp -v $youtube_options $sing_in $media_address -o - 2>$youtube_error \
                | mpv $mpv_options - >$mpv_error
    fi

    # lacy error printout
    if [[ -f $mpv_error ]]; then
        _error=$(grep 'ERROR:' $youtube_error)
        [[ $_error ]] && gr.msg -v2 -c red $_error
        rm "$mpv_error"
    fi

    if [[ -f $youtube_error ]]; then
        _error=$(grep 'Failed' $mpv_error)
        [[ $_error ]] && gr.msg -v2 -c yellow $_error
        rm "$youtube_error"
    fi
    # remove now playing and error data
    [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && rm $GRBL_AUDIO_NOW_PLAYING

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
        echo "youtube $_url" >$GRBL_AUDIO_NOW_PLAYING

        # start stream and play
        yt-dlp $youtube_options "$_url" -o - 2>/dev/null| mpv $mpv_options --no-video - >$mpv_error

        #remove now playing data
        [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && rm $GRBL_AUDIO_NOW_PLAYING

        if flag.get audio_stop ; then
            flag.rm audio_stop
            break
        fi
    done
    return 0
}


youtube.get_media () {
# download videos from tube by youtube id or url
# print list of formats and let user select proper one
# can be used to download audio only, select '0' or 'a' in video list

    local input=$1
    local url_base="https://www.youtube.com/watch?v"
    local url=
    local filename=
    local save_location=$(pwd)
    local resolution=
    local quality=
    local color=gray
    local audio=
    local selected=
    local audio_only=
    local base_name=

    # check is installed
    yt-dlp --version >/dev/null || youtube.install

    # url or id selector
    if [[ $input == "https:"* ]]; then
        # input is url
        url="$input"
    else
        # input is video id
        url="$url_base=$input"
    fi

    # get data from youtube
    ifs=$IFS
    IFS=$'\n'
    list=( $(yt-dlp -F $url 2>/dev/null | grep "|" ) )

    # make separated lists for video and audio
    for (( i = 0; i < ${#list[@]}; i++ )); do
        if echo ${list[$i]} | grep -q "video only"; then
            video_list+=( "${list[$i]}" )

        elif echo ${list[$i]} | grep -q "audio only" ; then
            audio_list+=( "${list[$i]}" )

        fi
    done
    IFS=$ifs

    ## video select loop
    gr.msg -h "#   ${list[0]}"
    for (( i = 1; i < ${#video_list[@]}; i++ )); do
        color=list
        gr.msg -n -h -w 4 "$i:"

        # get file size
        size="$(echo ${video_list[$i]} | cut -d " " -f6 | cut -d "x" -f1)"

        # clean up file size
        [[ $size == '~' ]] && size="$(echo ${video_list[$i]} | cut -d " " -f7 | cut -d "x" -f1)"
        size=${size//'~'/}
        size=${size/'iB'/}

        # printout video selection menu, colorize by file size
        case $size in
            *K)
                size=${size/'K'/}
                size=${size%%.*}
                color=black
                ;;
            *M)
                size=${size/'M'/}
                size=${size%%.*}
                if [[ $size -lt 5 ]] ; then  color=dark_gray
                elif [[ $size -ge 5 ]] && [[ $size -lt 10 ]] ; then color=gray
                elif [[ $size -ge 10  ]] && [[ $size -lt 30 ]] ; then color=list
                elif [[ $size -ge 30  ]] && [[ $size -lt 50 ]] ; then color=white
                elif [[ $size -ge 50  ]] && [[ $size -lt 100 ]] ; then color=lime
                elif [[ $size -ge 100  ]] && [[ $size -lt 300 ]] ; then color=yellow
                elif [[ $size -ge 300  ]] && [[ $size -lt 500 ]] ; then color=orange
                elif [[ $size -ge 500  ]] && [[ $size -lt 999 ]] ; then color=red
                fi
                ;;
            *G)
                size=${size/'G'/}
                size=${size%%.*}
                color=deep_pink
                ;;
        esac
        gr.msg -c $color "${video_list[$i]}"
    done

    # clear keyboard buffer
    # while read -e -t 0.1; do : ; done

    # ask to select video (0 or a is audio only)
    while true; do
        read -p "select video: " ans

        if [[ $ans == "q" ]]; then
            echo
            return 12

        # audio only
        elif [[ $ans == "0" ]] || [[ $ans == "a" ]]; then
            audio_only=true
            quality=
            break

        # select worst quality
        elif [[ $ans == "w" ]] || [[ $ans == "" ]]; then
            quality="-f $(echo ${video_list[0]} | cut -d " " -f1)"
            resolution="$(echo ${video_list[0]} | cut -d " " -f3)"
            v_size="$(echo ${video_list[0]} | cut -d " " -f6 | cut -d "x" -f1)"
            [[ $v_size == '~' ]] && v_size="$(echo ${video_list[0]} | cut -d " " -f7 | cut -d "x" -f1)"
            v_size=${v_size//'~'/}

        # select best quality
        elif [[ $ans == "b" ]] || [[ $ans == "" ]]; then
            quality="-f $(echo ${video_list[${#video_list[@]}]} | cut -d " " -f1)"
            resolution="$(echo ${video_list[${#video_list[@]}]} | cut -d " " -f3)"
            v_size="$(echo ${video_list[${#video_list[@]}]} | cut -d " " -f6 | cut -d "x" -f1)"
            [[ $v_size == '~' ]] && v_size="$(echo ${video_list[${#video_list[@]}]} | cut -d " " -f7 | cut -d "x" -f1)"
            v_size=${v_size//'~'/}
            break

        # check answer is number
        elif ! [[ $ans =~ ^[0-9]+$ ]] || [[ $ans -lt 1 ]] || [[ $ans -gt ${#video_list[@]} ]]; then
            gr.msg -N "please select 1..${#video_list[@]} 'b' for best, 'w' for worst, or 'q' to exit"
            continue

        # go here if all fine
        else
            quality="-f $(echo ${video_list[$ans]} | cut -d " " -f1)"
            resolution="$(echo ${video_list[$ans]} | cut -d " " -f3)"
            v_size="$(echo ${video_list[$ans]} | cut -d " " -f6 | cut -d "x" -f1)"
            [[ $v_size == '~' ]] && v_size="$(echo ${video_list[$i]} | cut -d " " -f7 | cut -d "x" -f1)"
            v_size=${v_size//'~'/}
            break
        fi
    done

    # get filename
    local raw_filename=$(yt-dlp $quality --print filename $url 2>/dev/null)

    # clean up filename
    base_name=${raw_filename%%.*}
    file_ending=${raw_filename##*.}
    base_name=${base_name/\＂/-}
    base_name=${base_name//\＂/}
    base_name=${base_name//\ /_}
    base_name=${base_name//'!'/}
    base_name=${base_name//'['/}
    base_name=${base_name//']'/}
    base_name=${base_name//']'/}
    base_name=${base_name//'('/}
    base_name=${base_name//')'/}
    base_name=${base_name//'?'/}
    base_name=${base_name//'？'/} # that was not normal mot*fucker
    base_name=${base_name//','/}
    filename="${base_name}-${resolution}.${file_ending}"

    # clear keyboard buffer
    # while read -e -t 0.1; do : ; done

    ## Audio select loop
    while true; do

        # printout header
        gr.msg -h "#   ${list[0]}"

        # printout audio selection menu, red are non compatible formats
        for (( i = 1; i < ${#audio_list[@]}; i++ )); do
            number_color="-h"

            if echo ${audio_list[$i]} | grep -q "unknown" ; then
                continue
            elif echo ${audio_list[$i]} | grep -q '\[en' ; then
                color=lime
            elif echo ${audio_list[$i]} | grep -q '\[fi' ; then
                color=aqua
            elif echo ${audio_list[$i]} | grep -q '\[de' ; then
                color=white
            else
                color=gray
                number_color="-c gray"
            fi

            # skip non supported audio type
            if [[ $file_ending == "mp4" ]] && echo ${audio_list[$i]} | grep -q "webm"; then
                color=red
                [[ $list_all ]] || continue
            elif [[ $file_ending == "webm" ]] && echo ${audio_list[$i]} | grep -q "m4a"; then
                color=red
                [[ $list_all ]] || continue
            fi

            gr.msg -n $number_color -w 4 "$i:"
            gr.msg -c $color "${audio_list[$i]}"
        done

        # process audio selection
        read -p "select audio: " ans

        # quit
        if [[ $ans == "q" ]]; then
            echo
            return 12
        # toggle all items view (default is off)
        elif [[ $ans == "a" ]]; then
            [[ $list_all ]] && list_all= || list_all=true
            continue
        # select best audio (last on list)
        elif [[ $ans == "b" ]] || [[ $ans == "" ]]; then
            audio="$(cut -d " " -f1 <<<${audio_list[${#audio_list[@]}]})"
            a_size="$(echo ${audio_list[${#audio_list[@]}]} | cut -d " " -f6 | cut -d "x" -f1)"
            break
        # select worst audio (first on list)
        elif [[ $ans == "w" ]]; then
            audio="$(cut -d " " -f1 <<<${audio_list[0]})"
            a_size="$(echo ${audio_list[0]} | cut -d " " -f6 | cut -d "x" -f1)"
            break
        # check answer is number
        elif ! [[ $ans =~ ^[0-9]+$ ]] || [[ $ans -lt 1 ]] || [[ $ans -gt ${#audio_list[@]} ]]; then
            gr.msg -N "please select 1..${#audio_list[@]} 'a' for all audio files, or 'q' to exit"
            continue
        # all fine
        else
            audio=$(cut -d " " -f1 <<<${audio_list[$ans]})
            a_size="$(echo ${audio_list[$ans]} | cut -d " " -f7 | cut -d "x" -f1)"
            break
        fi
    done


    ### audio download
    if [[ $audio_only ]];then

        # check existence
        if [[ -f "${save_location}/$base_name.mp3" ]]; then
            if gr.ask "file already downloaded, overwrite?"; then
                rm "${save_location}/$base_name.mp3"
            else
                return 0
            fi
        fi

        # download audio and convert it to mp3
        if yt-dlp -q --progress -x --audio-format mp3 --ignore-errors --continue --no-overwrites \
               --output "${save_location}/$base_name.mp3" \
               -f $audio "$url" 2>/tmp/$USER/youtube.error
        then
            # check file is created
            if [[ -f ${save_location}/${base_name}.mp3 ]]; then
                gr.msg -n -c green "saved to "
                gr.msg -c white "${save_location}/${base_name}.mp3"
                echo "${save_location}/${base_name}.mp3" | xclip -i -selection clipboard
                return 0
            else # file not created
                gr.msg -e2 "error during download"
                [[ $GRBL_VERBOSE -gt 0 ]] && cat /tmp/$USER/youtube.error
                return 128
            fi
        else
            # yt-dlp error
            gr.msg -e1 "failed get data from youtube"
            [[ $GRBL_VERBOSE -gt 0 ]] && cat /tmp/$USER/youtube.error
            return 129
        fi
    fi


    ### video download
    if [[ -f "${save_location}/$filename" ]]; then
        if gr.ask "file already downloaded, overwrite?"; then
            rm "${save_location}/$filename"
        else
            return 0
        fi
    fi

    # information to user
    gr.msg -v2 -c dark_gray "selected: $quality+$audio resolution: $resolution, video: ${v_size} audio: ${a_size}"
    gr.msg -n -v2 -c white "downloading "
    gr.msg -v1 -c white "${url}"

    # combine video and audio selections
    selected="$quality+$audio"

    # make download
    if yt-dlp -q --progress --ignore-errors --continue --no-overwrites \
           --output "${save_location}/${filename}" \
            $selected "$url" 2>/tmp/$USER/youtube.error
    then
        # check file is created
        if [[ -f ${save_location}/${filename} ]]; then
            gr.msg -n -c green "saved to "
            gr.msg -c white "${save_location}/${filename}"
            echo ${save_location}/${filename} | xclip -i -selection clipboard
            return 0
        else
            # file not created
            gr.msg -e2 "error during download"
            [[ $GRBL_VERBOSE -gt 0 ]] && cat /tmp/$USER/youtube.error
            return 128
        fi
    else
        # yt-dlp error
        gr.msg -e1 "failed get data from youtube"
        [[ $GRBL_VERBOSE -gt 0 ]] && cat /tmp/$USER/youtube.error
        return 129
    fi
}


youtube.get_audio () {
# download audio from tube by youtube id

    local id=$1
    local url_base="https://www.youtube.com/watch?v"

    # source mount module and mount audio file forlder in cloud
    source mount.sh
    mount.main audio

    [[ -d $GRBL_MOUNT_AUDIO/new ]] || mkdir -p $GRBL_MOUNT_AUDIO/new

    # check is installed
    yt-dlp --version || youtube.install

    # inform user
    gr.msg -c white "downloading $url_base=$id to $GRBL_MOUNT_AUDIO.. "

    # download and convert to mp3 format, then save to audio base location named by title
    yt-dlp -x --audio-format mp3 --ignore-errors --continue --no-overwrites \
           --output "$GRBL_MOUNT_AUDIO/%(title)s.%(ext)s" \
           "$url_base=$id"
    return $?
}


youtube.play () {
# play input file

    # check is user input url or id
    echo "$@" | grep -q "https://" && base_url="" || base_url="https://www.youtube.com/watch?v="

     # debug stuff (TBD remove later)
    gr.debug "$FUNCNAME save_to_file" "$save_to_file"
    gr.debug "$FUNCNAME youtube_options" "$youtube_options"
    gr.debug "$FUNCNAME module_command" "${module_command[@]}"
    gr.debug "$FUNCNAME mpv_options" "$mpv_options"
    gr.debug "$FUNCNAME save_location" "$save_location"

    # set playing and saving options and generate url
    local media_address="$base_url$1"

    # indicate playing
    gr.msg -c dark_grey "$media_address" -k $GRBL_AUDIO_INDICATOR_KEY

    # get steam and play
    gr.debug "$FUNCNAME yt-dlp $youtube_options $media_address -o - | mpv $mpv_options -"

    yt-dlp $youtube_options $sing_in_option $media_address -o - 2>$youtube_error | mpv $mpv_options -
    local _error=$?
    gr.debug "$FUNCNAME _error:$_error"

    # if ! grep 'Sign in to' $youtube_error; then
    #     [[ -f $mpv_error ]] && rm $mpv_error
    #     [[ -f $youtube_error ]] && rm $youtube_error



    # remove playing indications
    gr.msg -c reset -k $GRBL_AUDIO_INDICATOR_KEY

    (( $_error > 0 )) && gr.msg -c yellow "${FUNCNAME[0]} returned $_error"
    return $_error
}


youtube.upgrade() {
# upgrade needed tools, youtube do changes often and shit causing weird errors

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

youtube.option () {
# core says error cause of changes, quick fix
    true
}

# get configs and set variables
youtube.rc

# fix missing user configuration
[[ $GRBL_YOUTUBE_RESULT_LIMIT ]] || GRBL_YOUTUBE_RESULT_LIMIT=20
[[ $GRBL_YOUTUBE_THUMBNAIL_SIZE ]] || GRBL_YOUTUBE_THUMBNAIL_SIZE=60
[[ $GRBL_AUDIO_NOW_PLAYING ]] || GRBL_AUDIO_NOW_PLAYING=/tmp/$USER/now_playing
[[ $GRBL_AUDIO_MPV_SOCKET ]] || GRBL_AUDIO_MPV_SOCKET=/tmp/$USER/youtube
[[ $GRBL_AUDIO_INDICATOR_KEY ]] || GRBL_AUDIO_INDICATOR_KEY=f5
 # $GRBL_MOUNT_AUDIO
 # $GRBL_MOUNT_VIDEO

source $GRBL_BIN/audio.sh
declare -g module_command=()
declare -g save_location=$GRBL_MOUNT_DOWNLOADS
declare -g mpv_options="--input-ipc-server=$GRBL_AUDIO_MPV_SOCKET-youtube"
[[ $GRBL_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"
declare -g youtube_options= #"-f worst"
declare -g save_to_file=

# run main only if run, not sourced
if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    youtube.main $@
fi
