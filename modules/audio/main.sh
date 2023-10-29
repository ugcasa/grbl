#!/bin/bash
# guru-cli audio module 2020 - 2023 casa@ujo.guru

source corsair.sh
source mount.sh
source $GURU_BIN/audio/mpv.sh


declare -g audio_rc="/tmp/guru-cli_audio.rc"
declare -g audio_data_folder="$GURU_SYSTEM_MOUNT/audio"
declare -g audio_playlist_folder="$audio_data_folder/playlists"
declare -g audio_temp_file="/tmp/guru-cli_audio.playlist"
declare -g audio_playing_pid=$(ps x | grep mpv | grep -v grep | cut -f1 -d" ")
# more global variables downstairs (after sourcing rc file)

audio.help () {

    gr.msg -v1 -c white "guru-cli audio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL audio play|ls|list|listen|radio|pause|resume|mute|stop|tunnel|toggle|install|remove|help"
    gr.msg -v2
    #gr.msg -v1 "options:"
    #gr.msg -v1 "  --loop                      loop forever (not fully implemented)"
    #gr.msg -v1 "  --save                      save output (TBD)"
    #gr.msg -v2
    gr.msg -v1 "  play <song|album|artist>    play files in $GURU_MOUNT_AUDIO"
    gr.msg -v1 "  play list <playlist_name>   play a playlist set in user.cfg"
    gr.msg -v1 "  play list ls                list of available playlists "
    gr.msg -v1 "  mute                        mute (or un-mute) main audio device"
    gr.msg -v1 "  stop                        try to stop audio sources (TBD)"
    gr.msg -v1 "  pause                       pause all audio and video"
    gr.msg -v2 "  toggle                      toggle last/default audio (for keyboard launch)"
    gr.msg -v2 "  ls                          list of local audio devices "
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
    local _command=$1
    shift

    case "$_command" in

        continue)
            if [[ -f $audio_temp_file ]] ; then
                [[ $audio_playing_pid ]] && kill $audio_playing_pid
                mpv $mpv_options --playlist=$audio_temp_file --save-position-on-quit
            else
                gr.msg -c error "no saved position"
                return 0
            fi
            ;;

        tunnel)
            source $GURU_BIN/audio/tunnel.sh
            tunnel.main $@
            ;;

        radio|playlist)
			source $GURU_BIN/audio/$_command.sh
			$_command.main $@
			;;

        play|ls|pause|mute|stop|tunnel|toggle|install|update|remove|help|poll|status)
            audio.$_command $@
            return $?
            ;;

        mpvstat)
            mpv.stat
            return $?
            ;;

        playlist)
            audio.playlist_main $@
            return $?
            ;;

        *)
            gr.msg -c error "audio module: unknown command '$_command'"
            return 1
            ;;
    esac
   # rm $audio_rc
}


audio.play () {
# play playlist and song/album/artist name given as parameter
    local _error=

    corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

    case $1 in
            find)
                shift
                audio.find_and_play $1
                _error=$?
                ;;
            "")
                radio.listen yle kajaani
                _error=$?
                ;;
            *)
                audio.find_and_play $@
                _error=$?
                ;;
        esac

    gr.end $GURU_AUDIO_INDICATOR_KEY
    return $_error
}


audio.stop () {
# send stop or brutal kill audio source

    pkill mpv
    pkill mpv
    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] && audio.pause

    gr.end $GURU_AUDIO_INDICATOR_KEY
    # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY

}


audio.pause () {
# pause all audio and video system wide

    [[ -d "/tmp/guru" ]] || mkdir "/tmp/guru"

    if ! [[ -f $GURU_AUDIO_PAUSE_FLAG ]] ; then
        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/amixer -q -D pulse sset Master mute; /usr/bin/killall -q -STOP 'pulseaudio'"
        touch $GURU_AUDIO_PAUSE_FLAG
        corsair.indicate pause $GURU_AUDIO_INDICATOR_KEY
    else
        # resume
        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/killall -q -CONT 'pulseaudio'; /usr/bin/amixer -q -D pulse sset Master unmute"
        rm $GURU_AUDIO_PAUSE_FLAG
        audio.status
    fi
}


audio.mute () {
# mute master audio device

    amixer -q -D pulse sset Master toggle
    return $?
}


audio.ls () {
# list audio devices TBD rename audio.device_list()

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -c light_blue "$_device_list"
}


audio.is_paused () {
# check is module set to pause

    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] && return 0 || return 1
}


audio.is_playing () {
# check is something playing

    mpv.stat || return 1
    [[ -f $GURU_AUDIO_NOW_PLAYING ]] || return 1
    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] || return 1
    return 0
}


audio.toggle () {
# start or stop to play last listened or default audio source

    local default_radio='yle puhe'

    if [[ -f $GURU_AUDIO_PAUSE_FLAG ]] ; then
            gr.debug "paused, calling pause: $@"
            audio.pause
            return 0
        fi

    if ps auxf | grep "mpv " | grep -v grep ; then
    # if [[ -f $GURU_AUDIO_NOW_PLAYING ]] ; then
            gr.debug "running, calling pause: $@"
            audio.pause
            return 0
        fi

    # check is there something
    if [[ -f $audio_temp_file ]] ; then
        to_play="--playlist=$audio_temp_file"

        # continue from last played if not playing
        elif [[ -f $GURU_AUDIO_LAST_PLAYED ]] ; then
            to_play=$(< $GURU_AUDIO_LAST_PLAYED)

        # play default if no last played file
        else
            # why audio.main listen "$default_radio"
            radio.listen "$default_radio"
            return $?
        fi

    [[ $audio_playing_pid ]] && kill $audio_playing_pid

    corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
    mpv $to_play $mpv_options

    echo "$to_play" > $GURU_AUDIO_LAST_PLAYED
    gr.end $GURU_AUDIO_INDICATOR_KEY

    return 0
}


audio.find_and_play () {
gr.msg "$FUNCNAME BROKEN, exiting.."
return 128
# find from known audio locations and play
    local to_play
    # TBD review needed
        if [[ -f $1 ]] ; then
                to_play=$1
            fi

        # if part of name, look from folders
        if [[ $1 ]] ; then
            local to_find=$1
            to_find=${to_find//'ä'/'a'}
            to_find=${to_find//'å'/'a'}
            to_find=${to_find//'ö'/'o'}

            source mount.sh
            mount.main audio
            mount.main audiobooks
            mount.main music
            mount.main tv

            ifs=$IFS
            IFS=" "
            # luoja mitä kuraa.. TBD review!
            _got="$(find $GURU_DOC -maxdepth 5 -iname *mp3)"

            while [[ $1 ]] ; do
                got=$(echo -e $_got | grep -i $to_find | grep -v 'Trash-1000')
                shift
            done
            #gr.msg -c light_blue "${got[@]}"

            IFS=$ifs

            # printout artist and song name
            songs=${got//"$GURU_MOUNT_MUSIC/"/""}
            songs=${songs//'/'/'@'}                 # to remove word before '/' later
            songs=${songs//'_'/' '}
            songs=${songs//'-'/': '}
            songs=${songs//'.mp3'/''}

            if [[ $got ]] ; then
                return $?
            fi
            gr.msg -v1 -c light_blue "${songs}" | sed 's/.*@//'
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            audio.stop

            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            gr.msg -h "$got"
            mpv $(echo -e $got) $mpv_options --no-resume-playback --no-video #>/dev/null

            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        fi

        gr.msg -c error "nothing found"
        return 1
}


audio.update() {
# update needed tools

    # sudo pip install -U youtube-dl
    sudo -H pip install --upgrade youtube-dl
}


audio.install () {
# install function is required by core

    sudo apt-get install espeak mpv vlc -y
}


audio.remove () {
# remove function is required by core

    $GURU_BIN/audio/voipt.sh remove
    gr.msg "remove manually: 'sudo apt-get remove espeak mpv vlc'"
}


audio.status () {
# printout module status

    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    # for playing files
    local now_playing=$(mpv.stat)

    # add string from now playing file (adds station number)
    if [[ -f $GURU_AUDIO_NOW_PLAYING ]] ; then
            local station=$(cat $GURU_AUDIO_NOW_PLAYING)
            now_playing="$station $now_playing"
        fi

    if [[ $GURU_AUDIO_ENABLED ]] ; then
            gr.msg -n -v1 -c green "enabled "

        else
            gr.end $GURU_AUDIO_INDICATOR_KEY
            gr.msg -c black "disabled" -k $GURU_AUDIO_INDICATOR_KEY
            return 0
        fi

    if [[ $now_playing ]] ; then

            gr.msg -v1 -n -c aqua "playing: $now_playing"

            if audio.is_paused ; then
                gr.msg -v1 -h " [paused]"
                corsair.indicate pause $GURU_AUDIO_INDICATOR_KEY
            else
                gr.msg -v1
                corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            fi
        else
            gr.end $GURU_AUDIO_INDICATOR_KEY
            gr.msg -v1 -c dark_grey "stopped"

        fi
}


audio.poll () {
# daemon poll can access functions start, stop and status trough this

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: polling started" -k $GURU_AUDIO_INDICATOR_KEY
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: polling ended" -k $GURU_AUDIO_INDICATOR_KEY
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

    if [[ ! -f $audio_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mount.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]]
        then
            audio.make_rc && \
                gr.msg -v1 -c dark_gray "$audio_rc updated"
        fi

    [[ ! -d $audio_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder

    source $audio_rc
}


audio.make_rc () {
# configure audio module

    source config.sh

    # make rc out of config file and run it

    if [[ -f $audio_rc ]] ; then
            rm -f $audio_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $audio_rc
    config.make_rc "$GURU_CFG/$GURU_USER/audio.cfg" $audio_rc append
    chmod +x $audio_rc
    source $audio_rc
}

# located here cause rc needs to see some of functions above
audio.rc
# variables that needs values that audio.rc provides
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_MPV_SOCKET"
[[ $GURU_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
# to avoid sourcing loops caused by sub module sourcing
    source $GURU_BIN/audio/tunnel.sh
    source $GURU_BIN/audio/radio.sh

    gr.debug "$(pwd) remember that module folder is not set to path and installed version of module is used"
    audio.main $@ # $(audio.parse_options $@)
    exit $?
fi

