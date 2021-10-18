#!/bin/bash 
# corsair indicator raw methods library for non systemd releases.


corsair.raw.help () {
    # general help

    gmsg -v1 -c white "guru-client help for corsair raw method"
    gmsg -v2
    gmsg -v0 "usage:           $GURU_CALL corsair raw help|status|restart|start|set|clear|stop|disable| <key/profile> <color>"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " status                   printout status "
    gmsg -v1 " start                    start ckb-next-daemon "
    gmsg -v1 " stop                     stop ckb-next-daemon"
    gmsg -v1 " set <key> <color>        write key color <color> to keyboard key <key> "
    gmsg -v1 " help                     get more detailed help by adding verbosity flag"
    gmsg -v2 " disable                  disable service (some systemd) "
    gmsg -v2

    return 0
}


corsair.raw.status () {
    # get status information

    gmsg -V1 "$(ps auxf | grep ckb-next | grep -v grep)"

    gmsg -N -v2 -c white "application status:"
    gmsg -v1 "$(systemctl --user status corsair.service)"
    gmsg -v3 "$(systemctl --user list-dependencies corsair.service)"

    gmsg -N -v2 -c white "daemon status:"
    gmsg -v2 "$(systemctl status ckb-next-daemon.service)"
    gmsg -v3 "$(systemctl --user list-dependencies ckb-next-daemon.service)"

}


corsair.raw.restart () {
    # start full stack, daemon and application

    if ! [[ $GURU_VERBOSE ]] ; then
            ckb-next -b 2>/dev/null &
        else
            ckb-next -b &
        fi

    sleep 2
    corsair.init
    corsair.check
    return $?
}


corsair.raw.start () {
    # check and start part by part based on check result

    if [[ $1 ]] ; then
            local _status="$1"
        else
            corsair.check
            local _status="$?"
        fi

    [[ $GURU_FORCE ]] && _status="7"

    gmsg -v3 "status/given: $_status"
    case $_status in
        1 )     gmsg -v1 -c black "corsair disabled by user configuration" ;;
        2 )     gmsg -v1 -c black "no corsair devices connected" ;;
        3 )     gmsg -v1 -n "corsair daemon not running, starting.. "
                if systemctl restart ckb-next-daemon ; then
                        corsair.restart
                    else
                        gmsg -c red "failed"
                        return 112
                    fi
                ;;
        4 )     gmsg -v1 "starting corsair application.. "
                corsair.restart
                return $?
                ;;
        5 )     gmsg -v1 "no pipe support in current profile..  "
                corsair.init
                return $?
                ;;
        6 )     gmsg -v1 "re-starting corsair application.. "
                ckb-next -c
                sleep 1
                system.suspend rm_flag
                corsair.restart
                ;;
        7 )     gmsg -v1 "force re-start full corsair stack.. "
                ckb-next -c
                systemctl restart ckb-next-daemon
                sleep 3
                corsair.restart
                ;;
        * )     gmsg -v1 -t -c green "corsair on service"
                return 0
    esac
}


corsair.raw.set () {
    # write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>

    local _button=$1 ; shift
    local _color=$1 ; shift
    local _bright="FF" ; [[ $1 ]] && _bright="$1" ; shift
    # write color code to button pipe file
    echo "rgb $_color$_bright" > "$_button"
    # let device to receive and process command (surprisingly slow)
    sleep 0.1
    return 0
}


corsair.raw.clear () {
    # set key to black, input <pipe_file_list> default is F1 to F12

    local _pipelist=($key_pipe_list)
    gmsg -n -v1 "writing to pipe file(s) "
    [[ "$1" ]] && _pipelist=(${@})
    for _key_pipe in $_pipelist ; do
            gmsg -n -v1 "."
            gmsg -n -V1 -v2 "$_key_pipe "
            corsair.raw.set $_key_pipe $rgb_black
        done
    gmsg -v1 -c green " done"
}


corsair.raw.stop () {
    # stop application

    if ps auxf | grep "ckb-next" |  grep -v "ckb-next-" | grep -v grep >/dev/null || [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping ckb-next application.. "
            ckb-next -c || kill $(pidof ckb-next)
            sleep 2
        fi

    if ps auxf | grep "ckb-next" | grep -v grep >/dev/null ; then
        gmsg -c yellow "ckb-next stop failed"
     else
        gmsg -v2 -c green "ckb-next stopped"
     fi
}


corsair.raw.disable () {
    # stop corsair daemon

    # stop daemon first
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null || [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping ckb-next-daemon.. "
            systemctl stop ckb-next-daemon
        fi

    # stop application
    if ps auxf | grep "ckb-next" |  grep -v "ckb-next-" | grep -v grep >/dev/null || [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping ckb-next application.. "
            ckb-next -c || kill $(pidof ckb-next)
            sleep 2
        fi

    # verify kills
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -c red "ckb-next-daemon kill failed"
         else
            gmsg -v2 -c green "ckb-next-daemon stopped"
         fi

    if ps auxf | grep "ckb-next" | grep -v grep >/dev/null ; then
            gmsg -c red "ckb-next kill failed"
         else
            gmsg -v2 -c green "ckb-next stopped"
         fi
    }
