#!/bin/bash
# guru-client corsair led notification functions casa@ujo.guru 2020
# todo
#   - automated keyboard shortcut and pipe configurations for ckb-next
#   - more colors and key > pipe file bindings - DONE
#   - able keys to go blinky in background "new message"
#   - more key pipes
source $GURU_BIN/common.sh

# key pipe files
# NOTE: these need to correlate with cbk-next animation settings
    ESC="/tmp/ckbpipe000"
   CPLC="/tmp/ckbpipe059"
     F1="/tmp/ckbpipe001"
     F2="/tmp/ckbpipe002"
     F3="/tmp/ckbpipe003"
     F4="/tmp/ckbpipe004"
     F5="/tmp/ckbpipe005"
     F6="/tmp/ckbpipe006"
     F7="/tmp/ckbpipe007"
     F8="/tmp/ckbpipe008"
     F9="/tmp/ckbpipe009"
    F10="/tmp/ckbpipe010"
    F11="/tmp/ckbpipe011"
    F12="/tmp/ckbpipe012"

# extended color list
[[ "$GURU_CFG/rgb-color.cfg" ]] && source "$GURU_CFG/rgb-color.cfg"
# active key list
key_pipe_list=$(file /tmp/ckbpipe0* |grep fifo |cut -f1 -d ":")
# modes with status bar function set
# NOTE: these need to correlate with cbk-next animation settings
status_modes=(status, test, red, olive, dark, orange)
# bubblecum tempreary fix
corsair_last_mode="/tmp/corsair.mode"


corsair.main () {
    # command parser
    # ckb-next current mode data

    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    local _cmd="$1" ; shift
    case "$_cmd" in check|ps|start|init|set|reset|clear|end|stop|kill|status|help|install|remove)
            corsair.$_cmd $@ ; return $? ;;
        *)  echo "corsair: unknown command: $_cmd"
    esac
    return 0
}


corsair.help () {
    gmsg -v 1 -c white "guru-client corsair help"
    gmsg -v 2
    gmsg -v 0 "usage:    $GURU_CALL corsair [start|init|set|reset|end|kill|status|help|install|remove] <key> <color>"
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " start                       start ckb-next-daemon "
    gmsg -v 1 " init <mode>                 init keyboard mode "
    gmsg -v 2 "                             [status|red|olive|dark] able to set keys "
    gmsg -v 2 "                             [trippy|yes-no|rainbow] active animations "
    gmsg -v 1 " set <key> <color>           write key color to keyboard key  "
    gmsg -v 1 " reset <key>                 reset one key or if empty, all pipes "
    gmsg -v 1 " end                         end playing with keyboard, set to normal "
    gmsg -v 1 " stop (kill)                 stop ckb-next-daemon"
    gmsg -v 1 " status                      blink esc, print status and return "
    gmsg -v 1 " install                     install requirements "
    gmsg -v 1 " remove                      remove corsair driver "
    gmsg -v 2 " help                        this help "
    gmsg -v 2
    gmsg -v 1 -c white "examples:"
    gmsg -v 1 "          $GURU_CALL corsair status -v   "
    gmsg -v 1 "          $GURU_CALL corsair init trippy "
    gmsg -v 1 "          $GURU_CALL corsair end         "
    gmsg -v 2
    return 0
}


corsair.ps () {
    ps auxf | grep ckb-next | grep -v grep
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v2 -t "checking corsair is enabled.. "
    if [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c green "enabled"
        else
            gmsg -v1 -c dark_grey "disabled"
            return 1
        fi

    gmsg -n -v2 -t "checking device is connected.. "

    if lsusb |grep "Corsair" >/dev/null ; then
            gmsg -v2 -c green "connected"
        else
            gmsg -v1 -c dark_grey "disconnected"
            return 2
        fi

    gmsg -n -v2 -t "checking ckb-next-daemon.. "
    if ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"
        else
            gmsg -v1 -c dark_grey "ckb-next-daemon not running"
            gmsg -v2 -c white "start by '$GURU_CALL corsair start'"
            return 3
        fi

    # todo: check is hardware communicating with daemon
    gmsg -n -v2 -t "checking ckb-next.. "
    if ps auxf |grep "ckb-next" | grep -v "daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"
        else
            gmsg -v1 -c yellow "ckb-next application not running"
            gmsg -v2 -c white "start by '$GURU_CALL corsair start'"
            return 4
        fi

    gmsg -n -v2 -t "checking mode supports piping.. "
    if [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -v1 -c white "writing not available in '$corsair_mode' mode"
            return 5
        fi

   gmsg -n -v2 -t "checking pipes.. "
    if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "ready"
            return 0
        else
            gmsg -n -c yellow "error, trying to initilize profile.. "
            corsair.init
            sleep 1
            if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
                gmsg -c green "ok"
                return 0
            else
                gmsg
                gmsg -c red "non imported ckb-next profile "
                gmsg -v1 -n "open ckb-next and click profile bar and select "
                gmsg -v1 -n -c white "Manage profiles "
                gmsg -v1 -n "then click "
                gmsg -v1 -n -c white "Import "
                gmsg -v1 -n "and navigate to "
                gmsg -v1 -n -c white "$GURU_CFG "
                gmsg -v1 -n "select "
                gmsg -v1 -n -c white "corsair-profile.ckb "

                gmsg -v1 -n "then click "
                gmsg -v1 -n -c white "open "
                gmsg -v1 "and close ckb-next"
                gmsg -V1
            fi
            return 6
        fi


}


corsair.status () {
    # get status and print it out to kb leds
    if corsair.check ; then
            gmsg -v1 -t -c green "corsair on service"
            corsair.set esc green
            sleep 0.5
            corsair.reset esc

            return 0
        else
            #corsair.set esc red
            gmsg -v1 -t -c red "corsair not on service"
            return 1
        fi

}


corsair.start () {
    # reserve keys esc, F1 to 12
    if ! [[ $GURU_FORCE ]] && ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -c green "already running"
            gmsg -v1 "use -f to force restart"
            return 0
        fi

    if [[ $GURU_FORCE ]] ; then
            gmsg -n "restarting ckb-next-daemon.. "

            if systemctl restart ckb-next-daemon ; then
                    gmsg -c green "ok"
                else
                    gmsg -c red "failed"
                fi
        else
            # ask sudo password forehand cause next step stdout is rerouted to null
            gmsg -v1 -c white "starting ckb-next-daemon.. "

            # start daemon to background
            systemctl start ckb-next-daemon
        fi

    # check lauch
    gmsg -n -v1 -t "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "OK"
        else
            gmsg -c red "ckb-next-daemon starting failed"
            return 123
        fi

    gmsg -v1 -c white "starting ckb-next application "
    ckb-next -b &

    if ps auxf | grep "ckb-next" |  grep -v "ckb-next-" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "OK"
        else
            gmsg -c red "ckb-next-daemon starting failed"
            return 123
        fi


    # initialize profile and mode
    gmsg -n -v1 -t "setting profile and mode.. "
    local _mode=$GURU_CORSAIR_MODE ; [[ "$1" ]] && _mode="$1"
    corsair.init $_mode && gmsg -v1 -c green "OK"
    sleep 1

    # Check are pipes started, start if not
    gmsg -n -v1 -t "checking pipes.. "
    if ps auxf |grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null; then
            gmsg -v1 -c green "OK"
        else
            gmsg -c red "wrong or not imported ckb-next profile "
            return 100
        fi
    return 0
}


corsair.init () {
    # load default profile and set wanted mode
    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > $corsair_last_mode
        else
            local _error=$?
            gmsg -v0 -c yellow "corsair init failure"
            return $_error
        fi
    return 0
}


corsair.raw_write () {
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


corsair.set () {
    # write color to key: input <key> <color>
    corsair.check | return $?
    local _button=${1^^}
    local _color='rgb_'"$2"
    local _bright="FF" ; [[ $3 ]] && _bright="$3"
    gmsg -n -v2 -t "${FUNCNAME[0]}: $_button color to "
    gmsg -v2 -c $2 "$2"
    # get input key pipe file location
    _button=$(eval echo '$'$_button)
    if ! [[ $_button ]] ; then
            gmsg -c yellow "no such button"
            return 101
        fi
    # get input color code
    _color=$(eval echo '$'$_color)
    if ! [[ $_color ]] ; then
            gmsg  -c yellow "no such color"
            return 102
        fi
    #corsailize RGB code with brightness value
    _color="$_color""$_bright"

    # wrtite to pipe
    gmsg -v2 -t "${FUNCNAME[0]}: $_button <- $_color"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $_button |grep fifo >/dev/null ; then
            echo "rgb $_color" > "$_button"
            sleep 0.05
            return 0
        else
            gmsg -c yellow "io error, pipe file $_button is not set in cbk-next"
            return 103
        fi
}


corsair.reset () {
    # return normal, if no input reset all
    gmsg -n -v2 -t "resetting key"

    if [[ "$1" ]] ; then
            gmsg -v2 " $1"
            corsair.set $1 $corsair_mode 10 && return 0 || return 100
        else
            gmsg -n -v2 "s"
            for _key_pipe in $key_pipe_list ; do
                gmsg -n -v2 "."
                corsair.raw_write $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10 || return 100
            done
           gmsg -v2 -c green " done"
           return 0
        fi
}


corsair.clear () {
    # Cleaning the table
    gmsg -n -v1 -t "setting keys "
    for _key_pipe in $key_pipe_list ; do
            gmsg -n -v1 "."
            gmsg -n -V1 -v2 "$_key_pipe "
            corsair.raw_write $_key_pipe $rgb_black
        done
    gmsg -v1 -c green " done"
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now
    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE && return 0 || return 100
}


corsair.stop () {
    # stop corsair daemon

    gmsg "stopping ckb-next-daemon.. "

    systemctl stop ckb-next-daemon

    if ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -c tomato "kill failed"
            return 100
         else
            gmsg -c green "kill verified"
            return 0
         fi


    }


corsair.kill () {
    # compatibility
    corsair.stop $@
}


corsair.install () {
    # install essentials, driver and application

    if ! [[ $GURU_FORCE ]] && corsair.check ; then
            gmsg -x 100 "corsair seems to be working. use '-f' to re-install"
        fi

    sudo apt-get install -y build-essential cmake libudev-dev qt5-default zlib1g-dev libappindicator-dev libpulse-dev libquazip5-dev libqt5x11extras5-dev libxcb-screensaver0-dev libxcb-ewmh-dev libxcb1-dev qttools5-dev git pavucontrol libdbusmenu-qt5-2 libdbusmenu-qt5-dev
    cd /tmp
    git clone https://github.com/ckb-next/ckb-next.git
    cd ckb-next
    ./quickinstall

    if ! lsusb |grep "Corsair" ; then
        echo "no corsair devices connected, exiting.."
        return 100
    fi
    return 0
}


corsair.remove () {
    # get rid of driver and shit
    gask "surely remove corsair" || return 100

    if [[ /tmp/ckb-next ]] ; then
        cd /tmp/ckb-next
        sudo cmake --build build --target uninstall
    else
        cd /tmp
        git clone https://github.com/ckb-next/ckb-next.git
        cd ckb-next
        cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release -DSAFE_INSTALL=ON -DSAFE_UNINSTALL=ON -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBEXECDIR=lib
        cmake --build build --target all -- -j 4
        sudo cmake --build build --target install       # The compilation and installation steps are required because install target generates an install manifest that later allows to determine which files to remove and what is their location.
        sudo cmake --build build --target uninstall
    fi
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$GURU_RC"
        corsair.main "$@"
        exit "$?"
fi

