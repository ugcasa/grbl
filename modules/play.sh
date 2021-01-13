#!/bin/bash
# guru-client player wrap
# casa@ujo.guru 2019-2020
source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh


play.help () {
    gmsg -v1 -c white "guru-client play help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL play youtube|video|music|radio|song|karaoke|stop|status|install|remove <what-to-play> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  youtube <url|id>     play youtube ID or full url "
    gmsg -v1 "  video <title>        search match in $GURU_MOUNT_VIDEO "
    gmsg -v1 "  music <song/artist>  search match in $GURU_MOUNT_MUSIC "
    gmsg -v1 "  radio <station>      radio station"
    gmsg -v1 "  song <by/name>       search and pay song or artis "
    gmsg -v1 "  karaoke <song>       try to find songs with lyrics "
    gmsg -v1 "  stop                 kill all players "
    gmsg -v2 "  install              install requirements "
    gmsg -v2 "  remove               remove requirements "
    gmsg -v2 "  api_key <key>        set youtube api key "
    gmsg -v2
}


play.main () {
    # main command parser
    local _command="$1" ; shift
    case "$_command" in

            youtube|video|music|radio|song|karaoke)
                            play.$_command $@
                            return 0 ;;

            stop|install|remove|help)
                            play.$_command $@
                            return $? ;;

            api_key)        play.set_api_key $@
                            return $? ;;

            rollfm)         firefox --new_window stream.rollfm.fi
                            return $? ;;

            "")             echo empty
                            return 0 ;;

            *)              gmsg -c red "unknown command"
                            return 1 ;;
        esac
}


play.youtube () {
    # play youtube video by default video player
    ## config radio_station.list
    gmsg -c dark_grey "$FUNCNAME todo"

}


play.radio () {
    # play web radio station input name
    ## config radio_station.list
    gmsg -c dark_grey "$FUNCNAME todo"
}


play.song () {
    # play web radio station input name
    ## config radio_station.list
    gmsg -c dark_grey "$FUNCNAME todo"

}


play.music () {
    # search from music folder and play
    [[ $GURU_MOUNT_MUSIC ]] || gmsg -v2 -c yellow "empty global variable music"
    gmsg -c dark_grey "$FUNCNAME todo"
}


play.video () {
    # search from video folder and play
    [[ $GURU_MOUNT_VIDEO ]] || gmsg -v2 -c yellow "empty global variable video"
    gmsg -c dark_grey "$FUNCNAME todo"
}


play.set_api_key() {
    # Set youtube api key - somehow to somewhere
    # remove cache file
    local _api_key=""
    [[ -f /.config/mps-youtube/cache_py_* ]] && rm -f -v "~/.config/mps-youtube/cache_py_*"
    [[ "$1" ]] && _api_key="$1" || _api_key="$GURU_YOUTUBE_API_KEY"
    [[ "$GURU_YOUTUBE_API_KEY" ]] || read -p "input api key: " _api_key
    if (( ${#_api_key}<20 )); then echo "too short api key" ; return 100 ; fi

    gmsg -v1 "set api_key $_api_key - somehow to somewhere"
    return 0
}


play.stop () {
    exec 3>&2
    exec 2> /dev/null
        pkill mplayer
        pkill mpsyt
    exec 2>&3
    return 0
}


play.requirements () {
    # install and remove requirements
    local _action=$1

    # general requirements, do not uninstall
    pip3 --version || sudo apt-get -y install python3-pip

    # own requirements
    sudo apt-get -y "$_action" mplayer pulseaudio

    # ytmusic requirements
    sudo apt-get -y "$_action" mpv ffmpeg AtomicParsley
    sudo pip3 "$_action" youtube-dl argparse prettytable colorama
    return $error
}

# install function is required by core
play.install () {
    # clean remove
    play.requirements install
    play.set_api_key $@
}

# remove function is required by core
play.remove () {
    # clean remove
    play.requirements remove
}

# status function is required by core
play.status () {
    # report status
    gmsg -c dark_grey "$FUNCNAME todo"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    play.main "$@"
    exit $?
fi

