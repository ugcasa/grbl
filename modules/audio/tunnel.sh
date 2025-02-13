#!/bin/bash
# audio tunneling adapter for grbl audio module 2019 casa@ujo.guru
# uses voip,sh and fast_voip.sh in installation folder


audio.tunnel.help () {

    gr.msg -v1 -c white "grbl audio tunnel help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL audio tunnel open|close|toggle|fast|install|remove|help"
    gr.msg -v2
    gr.msg -v1 "commands " -c white
    gr.msg -v1 "  tunnel open <host>            open audio tunnel (ssh) to host audio device "
    gr.msg -v1 "  tunnel close                  close current audio tunnel "
    gr.msg -v1 "  tunnel install                install tools to voip over ssh"
    gr.msg -v1 "  tunnel toggle <host>          build tunnel or close active tunnel "
    gr.msg -v1 "  tunnel fast [command] <host>  fast (and brutal) way to open tunnel"
    gr.msg -v2
}


audio.tunnel.main () {
# tunnel secure audio link to another computer

    local _cmd=$1
    shift
    case $_cmd in
            status|open|close|toggle|install|help)
                audio.tunnel.$_cmd $@
                ;;
            fast) # for speed testing
                $GRBL_BIN/audio/fast_voipt.sh $1 \
                    -h $GRBL_ACCESS_DOMAIN \
                    -p $GRBL_ACCESS_PORT \
                    -u $GRBL_ACCESS_USERNAME
                    return $?
                ;;
            *)
                tunnel_toggle $@
                ;;
        esac
    return 0
}


audio.tunnel.status () {
# status function is required by core

    if ps auxf | grep "ssh -L 10000:127.0.0.1:10001 " | grep -v grep >/dev/null ; then
            gr.msg -c green "audio tunnel is active"
            return 0
        else
            gr.msg -c dark_grey "no audio tunnels"
            return 1
        fi
}


audio.tunnel.open () {
# open audio ssh tunnel

    # fill defaults to point to home server
    local _host=$GRBL_ACCESS_DOMAIN
    local _port=$GRBL_ACCESS_PORT
    local _user=$GRBL_ACCESS_USERNAME

    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gr.msg -v1 "tunneling mic to $_user@$_host:$_port"
    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c aqua
    if $GRBL_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c green
        else
            gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c red
            return 233
        fi
}


audio.tunnel.close () {
# close audio tunnel

    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c aqua

    if ! $GRBL_BIN/audio/voipt.sh close -h $GRBL_ACCESS_DOMAIN -p $GRBL_ACCESS_PORT -u $GRBL_ACCESS_USERNAME ; then
            gr.msg -c yellow "voip tunnel exited with code $?"
            gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c red
        fi

    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c reset
    return $?
}


audio.tunnel.toggle () {
# audio toggle for keyboard shortcut usage

    # source $GRBL_BIN/corsair.sh
    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c aqua
    if audio.status ; then

            if $GRBL_BIN/audio/fast_voipt.sh close -h $GRBL_ACCESS_DOMAIN -p $GRBL_ACCESS_PORT ; then
                    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c reset
                    return 0
                else
                    gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c red
                    return 1
            fi
    fi

    if $GRBL_BIN/audio/fast_voipt.sh open -h $GRBL_ACCESS_DOMAIN -p $GRBL_ACCESS_PORT -u $GRBL_ACCESS_USERNAME ; then
            gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c green
            return 0
        else
            gr.msg -k $GRBL_AUDIO_INDICATOR_KEY -c red
            return 1
        fi
}


audio.tunnel.install () {
# install function is required by core

    $GRBL_BIN/audio/voipt.sh install
}

