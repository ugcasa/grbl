#!/bin/bash
# grbl audio module 2020 - 2023 casa@ujo.guru

source corsair.sh
source flag.sh
source $GRBL_BIN/audio/mpv.sh

__audio_color="firebrick"
__audio=$(readlink --canonicalize --no-newline $BASH_SOURCE)

declare -g audio_rc="/tmp/$USER/grbl_audio.rc"
declare -g audio_data_folder="$GRBL_SYSTEM_MOUNT/audio"
declare -g audio_playlist_folder="$audio_data_folder/playlists"
declare -g audio_temp_file="/tmp/$USER/grbl_audio.playlist"
declare -g audio_playing_pid=$(ps x | grep mpv | grep -v grep | cut -f1 -d" ")
declare -g audio_modules=(yle youtube audio uutiset)
declare -g audio_available_sockets=(audio radio uutiset yle youtube)
# more global variables downstairs (after sourcing rc file)

audio.help () {
# audio help
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    gr.msg -v1 -c white "grbl audio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL audio play|ls|list|mount|unmount|listen|radio|pause|resume|mute|stop|tunnel|toggle|install|remove|help"
    gr.msg -v2
    #gr.msg -v1 "options:"
    #gr.msg -v1 "  --loop                      loop forever (not fully implemented)"
    #gr.msg -v2
    gr.msg -v1 "  play <song|album|artist>    play files in $GRBL_MOUNT_AUDIO"
    gr.msg -v1 "  play list <playlist_name>   play a playlist set in user.cfg"
    gr.msg -v1 "  play list ls                list of available playlists "
    gr.msg -v1 "  mute                        mute (or un-mute) main audio device"
    gr.msg -v1 "  stop                        try to stop audio sources (TBD)"
    gr.msg -v1 "  pause                       pause all audio and video"
    gr.msg -v1 "  reload                      reload fallen audio system "
    gr.msg -v2 "  mount                       mount audio media file locations"
    gr.msg -v2 "  unmount                     unmount audio media file locations"
    gr.msg -v2 "  ls                          list of local audio devices "
    gr.msg -v1 "  title                       get song title "
    gr.msg -v1 "  install                     install requirements "
    gr.msg -v1 "  remove                      remove requirements "
    gr.msg -v1 "  help                        printout this help "
    gr.msg -v2
    gr.msg -v1 "other function: " -c white
    gr.msg -v1 "  radio help                  radio/stream player help"
    gr.msg -v1 "  tunnel help                 secure audio tunnel tools"
    gr.msg -v2
}

# CLEAN hmm.. this should work, why not implemented?
# audio.parse_options () {

#     gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
#     local got_args=($@)
#     for (( i = 0; i < ${#got_args[@]}; i++ )); do
#         case ${got_args[$i]} in

#             --repeat|--l|--loop)
#                 mpv_options="$mpv_options --loop"
#                 ;;
#             *)
#                 pass_forward+=("${got_args[$i]}")
#                 ;;
#             esac
#         done
#     echo ${pass_forward[@]}
# }

audio.main () {
# main command parser
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    local _command=$1
    shift

    case "$_command" in

        continue)
            if [[ -f $audio_temp_file ]] ; then
                [[ $audio_playing_pid ]] && kill $audio_playing_pid
                echo "audio $audio_temp_file" >$GRBL_AUDIO_NOW_PLAYING
                mpv $mpv_options --playlist=$audio_temp_file --save-position-on-quit
                [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && rm $GRBL_AUDIO_NOW_PLAYING
            else
                gr.msg -c error "no saved position"
                return 0
            fi
            ;;

        paused)
            audio.paused && gr.msg -x0 -c green "true" || gr.msg -x1 -c dark_gray "false"
            ;;

        tunnel)
            source $GRBL_BIN/audio/tunnel.sh
            tunnel.main $@
            return $?
            ;;

        radio|playlist)
			source $GRBL_BIN/audio/$_command.sh
			$_command.main $@
            return $?
			;;

        pause|mpv|play|ls|hold|release|mount|unmount|mute|stop|tunnel|toggle|install|update|remove|help|poll|status|help|np|playing|reload)
            audio.$_command $@
            return $?
            ;;
        next|prev)
            audio.np
            audio.$command
            ;;
        mpvstat)
            mpv.stat
            return $?
            ;;
        title)
            audio.song_title --no_separator
            return $?
            ;;

        *)
            gr.msg -c error "audio module: unknown command '$_command'"
            return 1
            ;;
    esac
}


audio.default () {
# may remove this shit
    gr.debug "$FUNCNAME starting play default shit "
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    source $GRBL_BIN/audio/radio.sh
    radio.main
}


audio.mpv () {
# adapter for mpv
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    local command=$1
    shift

    case $command in
        pause)
            mpv.set pause $1
            ;;
        list|get|set|stat)
            mpv.$command $@
    esac
}


audio.hold () {
# setting hold flag ans stop audio
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    flag.set audio_hold
    audio.stop
}


audio.release () {
# removing hold flag
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    flag.rm audio_hold
}


audio.reload () {
# rebuild fallen audio tree
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    gr.msg -v2 "reloading audio.. "
    if pulseaudio -k ; then
        if sudo alsa force-reload ; then
            gr.msg -v2 -c green "audio stack reloaded"
        else
            gr.msg -e2 "failed to reload alsa stack"
            return 112
        fi
    else
        gr.msg -e1 "failed to kill audio stack"
        return 111
    fi
}


audio.next () {
# jump to next item depending what ever is playing
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    gr.debug "$FUNCNAME np:$GRBL_AUDIO_NOW_PLAYING"

    if [[ -f $GRBL_AUDIO_NOW_PLAYING ]] ; then

        contains="$(cat $GRBL_AUDIO_NOW_PLAYING)"

        gr.debug "$FUNCNAME np-contains:$contains"

        # skip yle news item
        if [[ ${contains,,} == uutiset* ]]; then
            source $GRBL_BIN/yle.sh
            yle.main next
        fi

        # skip yle item
        if [[ ${contains,,} == yle* ]]; then
            source $GRBL_BIN/yle.sh
            yle.main next
        fi

        # next radio station
        if [[ ${contains,,} == radio* ]]; then
            source $GRBL_BIN/audio/radio.sh
            radio.next
        fi

        # next tube item
        if [[ ${contains,,} == youtube* ]]; then
            flag.set next
            audio.stop
        fi
    else
        gr.debug "$FUNCNAME nothing playing "
        audio.default
    fi

}


audio.prev () {
# jump to previous item depending what ever is playing
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    gr.debug "$FUNCNAME np:$GRBL_AUDIO_NOW_PLAYING"

    if [[ -f $GRBL_AUDIO_NOW_PLAYING ]] ; then

        contains="$(cat $GRBL_AUDIO_NOW_PLAYING)"
        gr.debug "$FUNCNAME np-contains:$contains"

        # next radio station
        if [[ ${contains,,} == radio* ]]; then
            source $GRBL_BIN/audio/radio.sh
            radio.main prev
        fi

        # skip yle item
        if [[ ${contains,,} == yle* ]]; then
            source $GRBL_BIN/yle.sh
            yle.main prev
        fi

         # prev tube item
        if [[ ${contains,,} == youtube* ]]; then
            flag.set prev
            audio.stop
        fi
    else
        gr.debug "$FUNCNAME nothing playing "
        audio.default
    fi
}


audio.now_playing () {
# now playing string
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    local now_playing=

    # cols=$(($(echo "cols"|tput -S) -10 ))
    if [[ -f $GRBL_AUDIO_NOW_PLAYING ]] ; then
        now_playing="$(cat $GRBL_AUDIO_NOW_PLAYING) $(audio.song_title)"
        if audio.paused ; then
            gr.msg -v1 -n -c white "[paused] "
        else
            gr.msg -v1 -n -c lime "[playing] "
        fi
        gr.msg -v1 -c aqua_marine "$now_playing"
    else
        gr.msg -v1 -c dark_grey "[stopped] "
        #gr.msg -v1 -c dark_gray "$now_playing"
    fi
}


audio.song_title () {
# get song title from mpv daemon, to remove separator give argument
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    local separator="| "

    [[ $1 ]] && separator=

    for socket in ${audio_available_sockets[@]}; do
        song_title=$(audio.mpv get media-title $socket)
        [[ $song_title ]] && break
    done

    # cleanup and add separator
    case $song_title in
        -|*icecast*|*stream*|*mp3|listen|*.pls|""*.aac)
            song_title=
            ;;
        *)
            song_title="$separator$song_title"
    esac

    echo $song_title
}


audio.playing () {
# now playing loop
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    local now_playing=
    local length
    local cols
    clear
    while true ; do
        cols=$(($(echo "cols"|tput -S) -10 ))
        if [[ -f $GRBL_AUDIO_NOW_PLAYING ]] ; then

            # collecting output string
            now_playing="$(cat $GRBL_AUDIO_NOW_PLAYING) $(audio.song_title)"

            if audio.paused ; then
                gr.msg -w10 -v1 -n -c white "[paused] "
            else
                gr.msg -w10 -v1 -n -c lime "[playing] "
            fi
             gr.msg -w$cols -v1 -n -r -c aqua_marine "$now_playing"
        else
            if audio.paused ; then
                gr.msg -w10 -v1 -n -c white "[paused] "
            else
                gr.msg -w10 -v1 -n -c grey "[stopped] "
            fi
            gr.msg -w$cols -v1 -n -r -c dark_gray "$now_playing"
        fi
        gr.msg -n -r
        read -sr -n1 -t1 ans && break
    done
    echo
}


audio.np () {
# open now playing window
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    # Issue: NoScrollbar profile https://github.com/Gogh-Co/Gogh/issues/203

    local window_name="now playing"

    if wmctrl -l | grep -q "$window_name" ; then
        wmctrl -R "$window_name"
        wmctrl -r "$window_name" -e 0,1000,1114,-1,-1
        # wmctrl -r "$window_name" -e 0,1,1500,-1,-1
    else
        gnome-terminal --hide-menubar --window-with-profile="NoScrollbar" --geometry 100x1 --zoom 1 --title "$window_name"  -- $GRBL_BIN/grbl audio playing
        wmctrl -r "$window_name" -e 0,1000,1114,-1,-1
    fi
    # 0x05016a46  1 530  382  904  46   electra now playing
    # wmctrl -r "now playing" -e 0,1,1,-1,-1
}


audio.unmount () {
# when mount.cfg does not know mount configuration, module should u-mount own mount points
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    source unmount.sh
    unmount.main music
    unmount.main audio
}


audio.mount () {
# when mount.cfg does not know mount configuration, module should be able to mount own mount points
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    source mount.sh
    mount.mounted audio || mount.main audio
    mount.mounted music || mount.main music
}


audio.play () {
# play playlist and song/album/artist name given as parameter
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    local _error=
    flag.rm audio_stop
    corsair.indicate playing $GRBL_AUDIO_INDICATOR_KEY

    case $1 in
            find)
                shift
                audio.find_and_play $@
                _error=$?
                ;;
            "")
                source $GRBL_BIN/audio/radio.sh
                radio.play $GRBL_RADIO_WAKEUP_STATION
                _error=$?
                ;;
            *)
                audio.find_and_play $@
                _error=$?
                ;;
        esac

    gr.end $GRBL_AUDIO_INDICATOR_KEY
    return $_error
}


audio.stop () {
# send stop or brutal kill audio source
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    pkill mpv
    pkill mpv
    [[ -f $GRBL_AUDIO_PAUSE_FLAG ]] && audio.pause
    gr.end $GRBL_AUDIO_INDICATOR_KEY

}


audio.pause () {
# pause all audio and video system wide
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    local input=$1
    local me=
    shift

    # pause mpv based things
    case $input in

        # TODO test can this be variable
        radio|audio|yle|uutiset|youtube)
            if [[ $(mpv.get pause $input) == "false" ]]; then
                mpv.set pause true $input 2>/dev/null >/dev/null
            else
                mpv.set pause false $input 2>/dev/null >/dev/null
            fi
            return 0
            ;;

        others|other)

            if [[ $1 ]]; then
                me=$1
            else
                if [[ -f $GRBL_AUDIO_NOW_PLAYING ]]; then
                    me="$(cat $GRBL_AUDIO_NOW_PLAYING)"
                    me=${me%% *}
                else
                    gr.msg "not playing"
                    return 0
                fi
            fi

            gr.debug "$FUNCNAME me:$me, modules:${audio_modules[@]}"

            for module in ${audio_modules[@]} ; do
                gr.msg -v2 "pausing $module.."
                if [[ $module == $me ]] ; then continue ; fi
                mpv.set pause true $module 2>/dev/null >/dev/null
            done

            return 0

            ;;

        all|soft)
            for module in ${audio_modules[@]} ; do
                gr.msg -v2 "pausing $module.."
                mpv.set pause true $module 2>/dev/null >/dev/null
            done
            return 0
            ;;
    esac

    # 'superpause' pause all, even browser based stuff
    [[ -d "/tmp/$USER/grbl" ]] || mkdir -p "/tmp/$USER/grbl"

    if ! [[ -f $GRBL_AUDIO_PAUSE_FLAG ]] || [[ "$input" == "set" ]] ; then
        gr.end $GRBL_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/amixer -q -D pulse sset Master mute; /usr/bin/killall -q -STOP 'pulseaudio'"
        touch $GRBL_AUDIO_PAUSE_FLAG
        corsair.indicate pause $GRBL_AUDIO_INDICATOR_KEY
        gr.debug "$FUNCNAME: paused"

    elif [[ -f $GRBL_AUDIO_PAUSE_FLAG ]] || [[ "$input" == "rm" ]] ; then
        gr.end $GRBL_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/killall -q -CONT 'pulseaudio'; /usr/bin/amixer -q -D pulse sset Master unmute"
        rm $GRBL_AUDIO_PAUSE_FLAG

        [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && corsair.indicate playing $GRBL_AUDIO_INDICATOR_KEY

        gr.debug "$FUNCNAME: pause released"
        #audio.now_playing
    fi
}


audio.mute () {
# mute master audio device
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    amixer -q -D pulse sset Master toggle
    return $?
}


audio.ls () {
# list audio devices TBD rename audio.device_list()
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -c light_blue "$_device_list"
}


audio.paused () {
# check is module set to pause
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    # check master pause status
    if [[ -f $GRBL_AUDIO_PAUSE_FLAG ]] ; then
        return 0
    fi

    # check mpv status
    players=(youtube yle uutiset audio)
    for player in ${players[@]} ; do
        if [[ $(mpv.get pause $player 2>/dev/null) == "true" ]]; then
            return 0
        fi
    done

    # did not found anything paused
    return 1

}


audio.is_playing () {
# check is something playing
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    mpv.stat || return 1
    [[ -f $GRBL_AUDIO_NOW_PLAYING ]] || return 1
    [[ -f $GRBL_AUDIO_PAUSE_FLAG ]] || return 1
    return 0
}


audio.sort_yle_list () {
# sort filenames based on yle.areena timestamp in filename
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
# do this to folder before: shopt -s globstar ; rename 's/_/-/g' * ; rename 's/ /-/g' *

    local items_to_sort=$(echo $@ | tr " " "\n")

    while read line; do
        date_stamp=$(echo $line | rev | cut -d'.' -f 2- | cut -d '-' -f-4 | rev)
        echo "$(date -d ${date_stamp//-/} +%-s) $line"
    done <<<$items_to_sort | sort | cut -d' ' -f2-
}


audio.find_and_play () {
# find from known audio locations and play
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
# BROKEN
    update_list=true
    timeout=

    print_list () {

        gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
        [[ ${#_got[@]} -lt 10 ]] && width=3
        [[ ${#_got[@]} -gt 9 ]] && width=4
        [[ ${#_got[@]} -gt 99 ]] && width=5

        for (( i = 0; i < ${#_got[@]}; i++ )); do
            gr.msg -h -n -w$width "$i)"
            gr.msg -c list "${_got[$i]##*/}"
        done
        update_list=
        gr.msg -v1 -c dark_gray "(n)ext, (p)revious, (c)acontinue, (s)ort, (l)ist, (q)uit or (0..$((${#_got[@]} -1 )))"
    }

    play () {

        gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
        # indication
        corsair.indicate playing $GRBL_AUDIO_INDICATOR_KEY

        # now playing
        local now_playing="${_got[$_item_nr]##*/} [$_item_nr/$(( ${#_got[@]} -1 ))]"
        gr.msg -h "$now_playing"
        echo "audio $now_playing" >$GRBL_AUDIO_NOW_PLAYING

        # play
        mpv $1 $mpv_options --no-resume-playback --no-video
        local _error=$?
        gr.debug "$FUNCNAME _error:$_error"

        [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && rm $GRBL_AUDIO_NOW_PLAYING
        return $_error
    }


    local to_find='*'$1'*'
    local pre_item=$2
    local _item_nr=0

    # if part of name, look from folders
    if ! [[ $to_find ]] ; then
        gr.msg -c error "please specify what to find '$to_find' "
        return 100
    fi

    to_find=${to_find//'ä'/'a'}
    to_find=${to_find//'å'/'a'}
    to_find=${to_find//'ö'/'o'}

    gr.msg -v2 -c white "searching $to_find.."q

    # mount possible audio material
    audio.mount

    ifs=$IFS
    IFS=$'\n'
    local _got=()
    [[ -f $GRBL_MOUNT_MUUSIC/.online ]] && _got=($(find "$GRBL_MOUNT_MUSIC/" -iname $to_find 2>/dev/null | grep -v 'Trash-1000' | grep -e mp3 -e wav -e m4a))
    [[ -f $GRBL_MOUNT_AUDIO/.online ]] && _got+=($(find "$GRBL_MOUNT_AUDIO/" -iname $to_find 2>/dev/null | grep -v 'Trash-1000' | grep -e mp3 -e wav -e m4a))
    [[ -f $GRBL_MOUNT_AUDIOBOOKS/.online ]] && _got+=($(find "$GRBL_MOUNT_AUDIOBOOKS/" -iname $to_find 2>/dev/null | grep -v 'Trash-1000' | grep -e mp3 -e wav -e m4a))
    IFS=$ifs

    gr.debug "got: $_got"

    if [[ ${#_got[@]} -lt 1 ]] ; then
        gr.msg -c error "sorry, not able to find anything"
        return 0
    fi

    update_list=true
    while true ; do

        gr.end $GRBL_AUDIO_INDICATOR_KEY # corsair.blink_stop $GRBL_AUDIO_INDICATOR_KEY

        # print list if more than one item found or no pre item is given
        if [[ ${#_got[@]} -gt 1 ]] && ! [[ $pre_item ]] ; then

            [[ $update_list ]] && print_list

            gr.msg -n -c yellow_green "audio.sh [$_item_nr/$((${#_got[@]} -1 ))] "
            # gr.msg -n "[$_item_nr/$((${#_got[@]} -1 ))] "
            if [[ $timeout ]] ; then
                read -t 5 -p "select ($timeout s): " user_input
                user_input=${user_input:-n}
            else
                read -p "select: " user_input
            fi

            # user input parser
            case $user_input in
                q*|Q*|e*|x*) break ;;
                n*) _item_nr=$(( $_item_nr +1 )) ;;
                l*) update_list=true ; continue ;;
                p) _item_nr=$(( $_item_nr -1 )) ;;
                c*) [[ $timeout ]] && timeout= || timeout=5 ; continue ;;
                s*) _got=($(audio.sort_yle_list ${_got[@]})) ; update_list=true ; _item_nr=0 ; continue ;;
                "") true ;;
                *) _item_nr=$user_input
            esac

        else
        # use pre item only once
            [[ $pre_item ]] && _item_nr=$pre_item
            pre_item=
        fi

        # check is user input valid
        if [[ $_item_nr -lt 0 ]] || [[ $_item_nr -ge ${#_got[@]} ]] ; then
            _item_nr=0
            continue
        fi

        if ! [[ $stopped ]] ; then
            local stopped=true
            audio.stop
        fi

        play ${_got[$_item_nr]}
        _error=$?
        gr.debug "$FUNCNAME _error:$_error"
        if [[ $_error -eq 143 ]]; then

            if flag.get audio_hold ; then
                while flag.get audio_hold >/dev/null; do
                    sleep 2
                done
            fi
            gr.msg "timeout removed"
            timeout=
        fi
    done

    gr.end $GRBL_AUDIO_INDICATOR_KEY # corsair.blink_stop $GRBL_AUDIO_INDICATOR_KEY
    [[ -f $GRBL_AUDIO_NOW_PLAYING ]] && rm $GRBL_AUDIO_NOW_PLAYING
}


audio.update() {
# update needed tools
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    # sudo pip install -U youtube-dl
    sudo -H pip install --upgrade youtube-dl
}

audio.install() {
# Install needed tools
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    gr.msg -v4 -c blue "$__note [$LINENO] $FUNCNAME '$1'"
    local require=(mpv vlc pulseaudio socat)
    for install in ${require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "going to install $install" || continue
        sudo apt-get -y install $install
    done

    source tag.sh
    tag.main install
}

audio.uninstall() {
# Install needed tools
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
    gr.msg -v4 -c blue "$__note [$LINENO] $FUNCNAME '$1'"
    local require=(mpv vlc pulseaudio socat)
    for install in ${require[@]} ; do
        hash $install 2>/dev/null || continue
        gr.ask -h "going to remove $install" || continue
        sudo apt-get -y purge $install
    done
    # $GRBL_BIN/audio/voipt.sh remove
    # gr.msg "remove manually: 'sudo apt-get remove espeak mpv vlc pulseaudio'"
}


audio.status () {
# printout module status
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    if [[ $GRBL_AUDIO_ENABLED ]] ; then
        gr.msg -n -v1 -c green "enabled "
    else
        gr.end $GRBL_AUDIO_INDICATOR_KEY
        gr.msg -c black "disabled" -k $GRBL_AUDIO_INDICATOR_KEY
        return 0
    fi

    # for playing files
    audio.now_playing
}


audio.poll () {
# daemon poll can access functions start, stop and status trough this
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: polling started" -k $GRBL_AUDIO_INDICATOR_KEY
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: polling ended" -k $GRBL_AUDIO_INDICATOR_KEY
            ;;
        status )
           audio.status $@
            ;;
        *) audio.help
            ;;
        esac
}


audio.rc () {
# source configurations (to be faster)
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2
#|| [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mpv.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]] \

    if [[ ! -f $audio_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/radio.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/audio.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]]
        then
            audio.make_rc && \
                gr.msg -v1 -c dark_gray "$audio_rc updated"
        fi

    [[ ! -d $audio_data_folder ]] && [[ -f $GRBL_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder

    source $audio_rc
}


audio.make_rc () {
# configure audio module
    gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME '$1'" >&2

    source config.sh

    # make rc out of config file and run it

    if [[ -f $audio_rc ]] ; then
            rm -f $audio_rc
        fi

    config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $audio_rc
    config.make_rc "$GRBL_CFG/$GRBL_USER/audio.cfg" $audio_rc append
    config.make_rc "$GRBL_CFG/$GRBL_USER/radio.cfg" $audio_rc append
    #config.make_rc "$GRBL_CFG/$GRBL_USER/mpv.cfg" $audio_rc append

    chmod +x $audio_rc
    source $audio_rc
}

gr.msg -v4 -c $__audio_color "$__audio [$LINENO] $FUNCNAME" >&2

# located here cause rc needs to see some of functions above
audio.rc
# variables that needs values that audio.rc provides
declare -g mpv_options="--input-ipc-server=$GRBL_AUDIO_MPV_SOCKET-audio"
[[ $GRBL_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
# to avoid sourcing loops caused by sub module sourcing
    source $GRBL_BIN/audio/tunnel.sh
    source $GRBL_BIN/audio/radio.sh

    gr.debug "$(pwd) remember that module folder is not set to path and installed version of module is used"
    audio.main $@ # $(audio.parse_options $@)
    exit $?
fi

