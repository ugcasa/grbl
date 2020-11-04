#!/bin/bash
# guru-client audio adapter
# casa@ujo.guru 2020
source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh

# back compatibly
[[ $GURU_CORSAIR_CONNECTED_COLOR ]] || GURU_CORSAIR_CONNECTED_COLOR=deep_pink

audio.help () {
    gmsg -v1 -c white "guru-client audio help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL audio status|close|install|remove|toggle|fast help|tunnel <host|ip> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  tunnel <host>           open tunnel to host "
    gmsg -v2 "  toggle <host>           check is tunnel on them stop it, else open tunnel "
    gmsg -v1 "  close                   close tunnel "
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
            status|tunnel|close|install|remove|help)
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
    corsair.main set F8 $GURU_CORSAIR_EFECT_COLOR
    $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME || corsair.main set F8 red
    corsair.main reset F8
    return $?
}


audio.tunnel () {
    # open tunnel adapter for voipt. input host, port, user (all optional)

    # # toggler
    # if audio.status ; then
    #         audio.close
    #         return 0
    #     fi

    # fill default
    local _host=$GURU_ACCESS_DOMAIN
    local _port=$GURU_ACCESS_PORT
    local _user=$GURU_ACCESS_USERNAME
    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gmsg -v1 "tunneling mic to $_user@$_host:$_port"
    corsair.main set F8 $GURU_CORSAIR_EFECT_COLOR
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            corsair.main set F8 $GURU_CORSAIR_CONNECTED_COLOR
        else
            corsair.main set F8 red
        fi

    return 0
}


audio.tunnel_toggle () {
    # # toggler
    if audio.status ; then
            audio.close
            return 0
        fi
    audio.tunnel $@
    return $?
}

    # # info user enter pressing
    # gmsg -V1 "press enter to close"
    # gmsg -v1 -c light_blue \
    #     "press $(printf $C_WHITE)enter $(printf $C_LIGHT_BLUE)to close of"\
    #     "$(printf $C_WHITE)ctrl+c $(printf $C_LIGHT_BLUE)to leave on then close by typing"\
    #     "$(printf $C_WHITE)$GURU_CALL audio close"
    # read _ans

    # # close tunnel
    # gmsg -v2 "$(audio.close)"

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
            corsair.main set F8 $GURU_CORSAIR_CONNECTED_COLOR
            gmsg -c green "audio tunnel is active"
            return 0
        else
            corsair.main reset F8
            gmsg -c dark_grey "no audio tunnels"
            return 1
        fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    audio.main "$@"
    exit $?
fi

