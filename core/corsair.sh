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
status_modes=(status, test, red, olive, dark)
# bubblecum tempreary fix
corsair_last_mode="/tmp/guru/corsair.mode"


corsair.main () {
    # ckb-next current mode data
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    # command parser
    local _cmd="$1" ; shift         # get command
    case "$_cmd" in start|init|set|end|kill|reset|status|help|install|remove)
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
    gmsg -v 1 " init <mode>                 init keyboard mode listed below "
    gmsg -v 2 "                             [status|red|olive|dark] able to set keys "
    gmsg -v 2 "                             [trippy|yes-no|rainbow] active animations "
    gmsg -v 1 " set <key> <color>           write key color to keyboard key  "
    gmsg -v 1 " reset <key>                 reset one key or if empty, all pipes "
    gmsg -v 1 "  end                         end playing with keyboard, set to normal "
    gmsg -v 1 " kill                        stop ckb-next-daemon"
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
}


corsair.kill () {
    gmsg -c white "killing ckb-next-daemon.."
    sudo -v

    sudo pkill ckb-next-daemon || gmsg -c yellow "kill error"
    sleep 2
    if ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -x 100 -c tomato "kill failed"
         else
            gmsg -x 0 -c green "kill verified"
         fi
    }


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v2 -t "checking ckb-next-daemon.. "

    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c black "disabled"
            return 1
        fi

    if ! ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 "ckb-next-daemon not running"
            gmsg -v2 "start by '$GURU_CALL corsair start'"
        else
            gmsg -v2 -c green "OK"
            return 0
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
            corsair.set esc red
            gmsg -v1 -t -c red "corsair not on service"
            return 1
        fi

}


corsair.init () {
    # load default profile and set wanted mode
    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > $corsair_last_mode
        else
            local _error=$?
            gmsg -v -c yellow "corsair init failure"
            return $_error
        fi
    return 0
}


corsair.start () {
    # reserve some keys for future purposes by coloring them now
    # todo: I think this can be removed, used to be test interface before daemon
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "already running"
            return 0
        fi

    gmsg -v1 -c white "starting ckb-next-daemon"

    gmsg -c white "starting kb-next-daemon.."
    sudo -v

    # start daemon to background
    sudo /usr/local/bin/ckb-next-daemon >/dev/null &
    sleep 3

    # check lauch
    gmsg -n -v1 -t "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
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
    if ! ps auxf |grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null; then
            gmsg -c white "set pipes in cbk-next gui: K68 > Lighting > select a key(s) > New animation > Pipe > ... and try again"
                # Check is keyboard setup interface, start if not
                # if ! ps auxf |grep "ckb-next " | grep -v grep >/dev/null 2>&1 ; then
                #         gmsg -v1 -t "starting ckb-next.."
                #         ckb-next -b >/dev/null 2>&1 &
                #         sleep 3
                #     else gmsg -v1 -t "ckb-next $(OK)" ; fi
            return 100
        else
            gmsg -v1 -c green "OK"
        fi

    # Cleaning the table
    gmsg -n -v1 -t "setting keys keys"
    for _key_pipe in $key_pipe_list ; do
            gmsg -n -v2 "."
            corsair.raw_write $_key_pipe $rgb_black
        done
    gmsg -v1 -c green " done"
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now
    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE
}


corsair.reset () {
    # return normal, if no input reset all
    gmsg -n -v2 -t "resetting key"

    if [[ "$1" ]] ; then
            gmsg -v2 " $1"
            corsair.set $1 $corsair_mode 10
        else
            gmsg -n -v2 "s"
            for _key_pipe in $key_pipe_list ; do
                gmsg -n -v2 "."
                corsair.raw_write $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10
            done
        gmsg -v2 -c green " done"
        fi
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
    if ! [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
            gmsg  -v2 "writing not available in '$corsair_mode' mode"
            return 1
        fi

    local _button=${1^^}
    local _color='rgb_'"$2"
    local _bright="FF" ; [[ $3 ]] && _bright="$3"
    gmsg -n -v1 -t "set $_button color to "
    gmsg -v1 -c $2 "$2"
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
    gmsg -v2 -t "$_button <- $_color"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $_button |grep fifo >/dev/null ; then
            echo "rgb $_color" > "$_button"
            sleep 0.05
        else
            gmsg -c yellow "io error, pipe file $_button is not set in cbk-next"
            return 103
        fi
    # pass
    return 0
}


corsair.install () {
    # install essentials, driver and application
    sudo apt-get install -y build-essential cmake libudev-dev qt5-default zlib1g-dev libappindicator-dev libpulse-dev libquazip5-dev libqt5x11extras5-dev libxcb-screensaver0-dev libxcb-ewmh-dev libxcb1-dev qttools5-dev git pavucontrol
    cd /tmp
    git clone https://github.com/ckb-next/ckb-next.git
    cd ckb-next
    ./quickinstall

    if ! lsusb |grep "Corsair" ; then
        echo "no corsair devices connected, exiting.."
        return 100
    fi
}


corsair.remove () {
    # get rid of driver and shit
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
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$HOME/.gururc2"
        corsair.main "$@"
        exit "$?"
fi

