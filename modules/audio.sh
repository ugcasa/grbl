#!/bin/bash
# guru-client audio adapter
# casa@ujo.guru 2020
source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh


audio.help () {
    gmsg -v1 -c white "guru-client audio help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL audio status|close|install|remove|toggle|fast help|tunnel <host|ip> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  tunnel <host>           open tunnel to host "
    gmsg -v2 "  toggle <host>           check is tunnel on them stop it, else open tunnel "
    gmsg -v1 "  close                   close tunnel "
    gmsg -v1 "  ls                      list of local audio devices "
    gmsg -v1 "  ls_remote               list of local remote audio devices "
    gmsg -v1 "  install                 install requirements "
    gmsg -v1 "  remove                  remove requirements "
    gmsg -v2 "  fast [command] <host>   quick open tunnel, does not check stuff, just brute force"
    gmsg -v1 "  fast help               check fast tool help for more detailed instructions"
    gmsg -v2
}


audio.main () {
    # main command parser
    local _command="$1" ; shift
    case "$_command" in
            status|ls|tunnel|close|install|remove|help)
                            audio.$_command $@
                            return $? ;;
            fast)
                            $GURU_BIN/audio/fast_voipt.sh $1 -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME
                            return $? ;;

            toggle)
                            audio.tunnel_toggle $@
                            return $? ;;
            *)
                            gmsg -c red "unknown command"
                            return 1 ;;
        esac
}


audio.close () {
    # close audio tunnel
    corsair.main set F8 aqua
    $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME || corsair.main set F8 red
    corsair.main reset F8
    return $?
}


audio.ls () {
    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gmsg -v -c "audio device list (alsa card)"
    gmsg -c light_blue "$_device_list"
}


audio.ls_remote () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gmsg -c light_blue "$_device_list"
}


audio.tunnel () {
    # open tunnel adapter for voipt. input host, port, user (all optional)

    # fill default
    local _host=$GURU_ACCESS_DOMAIN
    local _port=$GURU_ACCESS_PORT
    local _user=$GURU_ACCESS_USERNAME

    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gmsg -v1 "tunneling mic to $_user@$_host:$_port"
    corsair.main set F8 aqua
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            corsair.main set F8 green
        else
            corsair.main set F8 red
        fi

    return 0
}


audio.tunnel_toggle () {
    # audio toggle for keyboard shortcut usage
    corsair.main set F8 aqua
    if audio.status ; then
            if $GURU_BIN/audio/fast_voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT ; then
                    corsair.main reset F8
                    return 0
                else
                    corsair.main set F8 red
                    return 1
                fi
        fi

    if $GURU_BIN/audio/fast_voipt.sh open -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            corsair.main set F8 green
            return 0
        else
            corsair.main set F8 red
            return 1
        fi
}

# install function is required by core
audio.install () {
    $GURU_BIN/audio/voipt.sh install
}

# remove function is required by core
audio.remove () {
    $GURU_BIN/audio/voipt.sh remove
}

# status function is required by core
audio.status () {
    # report status
    if ps auxf | grep "ssh -L 10000:127.0.0.1:10001 " | grep -v grep >/dev/null ; then
            gmsg -c green "audio tunnel is active"
            return 0
        else
            gmsg -c dark_grey "no audio tunnels"
            return 1
        fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    audio.main "$@"
    exit $?
fi

