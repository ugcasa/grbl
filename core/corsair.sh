#!/bin/bash
# guru-client corsair led notification functions
# casa@ujo.guru 2020

# todo
#   - more colors and key > pipe file bindings - DONE
#   - more key pipes
#   - automated keyboard shortcut and pipe configurations for ckb-next
#   - able keys to go blink in background
#   - shortcuts behind indicator key presses

# keys pipe files
# NOTE: these need to correlate with cbk-next animation settings!
source $GURU_BIN/common.sh

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
status_modes=(status, test, red, olive, dark)

corsair.main () {

    # ckb-next current mode data
    if [[ -f /tmp/guru/corsair.mode ]] ; then
            corsair_mode="$(head -1 /tmp/guru/corsair.mode)"
            #corsair_bg_color="$(head -2 /tmp/guru/corsair.mode |tail -1)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
            #corsair_bg_color=$GURU_CORSAIR_BG_COLOR
        fi


    # command parser
    local _cmd="$1" ; shift         # get command
    case "$_cmd" in init|start|reset|status|help|install|remove|set|yes-no|end)
            corsair.$_cmd $@ ; return $? ;;
        *)  echo "unknown command"
    esac
    return 0
}


corsair.help () {
    gmsg -v 1 -c white "guru-client corsair driver help"
    gmsg -v 2
    gmsg -v 0 "usage:    $GURU_CALL corsair [start|end|status|help|install|remove|write|yes-no|end <key> <color>]"
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " install         install requirements "
    gmsg -v 1 " remove          remove corsair driver "
    gmsg -v 2 " help            this help "
    gmsg -v 1 " write           write key color (described below)  "
    gmsg -v 1 "    <KEY>        up-case key name like 'F1'  "
    gmsg -v 1 " _<COLOR>        up-case color with '_' on front of it "     # todo: go better
    gmsg -v 1 " start           init guru base layout"
    gmsg -v 1 " end             end animation"
    gmsg -v 1 " reset           reset without init"
    gmsg -v 1 " init <mode>     init keyboard mode"
    gmsg -v 2 "                 status|trippy|yes-no|rainbow"
    gmsg -v 2 "                 default is status "
    gmsg -v 1 -c white "examples:"
    gmsg -v 1 "          $GURU_CALL corsair status "
    gmsg -v 1 "          $GURU_CALL corsair init trippy "
    gmsg -v 1 "          $GURU_CALL corsair end "
    gmsg -v 2
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v2 -t "checking ckb-next-daemon.. "

    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c black "disabled"
            return 1
        fi

    if ! ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -c white "starting ckb-next-daemon.. sudo needed"
            sudo ckb-next-daemon >/dev/null &

            gmsg -n -v2 -t "checking is is stated up.. "
            sleep 3
            if ! ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
                    gmsg -x 123 -c red "ckb-next-daemon stating error"
                fi
        else
            gmsg -v2 -c green "OK"
            return 0
        fi

    # Check is keyboard setup interface, start if not
    # if ! ps auxf |grep "ckb-next " | grep -v grep >/dev/null 2>&1 ; then
    #         gmsg -v1 -t "starting ckb-next.."
    #         ckb-next -b >/dev/null 2>&1 &
    #         sleep 3
    #     else gmsg -v1 -t "ckb-next $(OK)" ; fi

    # Check are pipes started, start if not
    # corsair.init status
    # if ! ps auxf |grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null; then
    #         gmsg -x 100 -c white "set pipes in cbk-next gui: K68 > Lighting > select a key(s) > New animation > Pipe > ... and try again"
    #     else gmsg -v1 -t "ckb-next pipes $(OK)" ; fi

}


corsair.status () {
    # get status and print it out to kb leds
    if corsair.check ; then
            corsair.set f4 green
            gmsg -v1 -c green "corsair on service"
            return 0
        else
            corsair.set f4 red
            gmsg -v1 -c black "corsair not on service"
            return 1
        fi
}


corsair.init () {
    # load default profile and set wanted mode
    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > /tmp/guru/corsair.mode
        else
            gmsg -v -x $? -c yellow "corsair init failure"
        fi
    return 0
}


corsair.start () {
    # reserve some keys for future purposes by coloring them now
    # todo: I think this can be removed, used to be test interface before daemon
    local _mode=$corsair_mode ; [[ $1 ]] && _mode="$1"

    gmsg -v1 -t "starting corsair"
    corsair.init $_mode
    sleep 1
    for _key_pipe in $key_pipe_list ; do
        gmsg -v2 -t "$_key_pipe off"
        corsair.raw_write $_key_pipe $rgb_black
    done
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now
    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE
}


corsair.reset () {
    # return normal, if no input reset all
    # TODO: unable to return mode backround color, it is not known FIX: use mode name as color name
    corsair.check || return  1
    gmsg -v1 "resetting keyboard indicators"
    if [[ "$1" ]] ; then
        corsair.set $1 $corsair_mode 10
    else
        for _key_pipe in $key_pipe_list ; do
            corsair.raw_write $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10
        done
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
    if ! [[ $1 ]] ; then corsair.start ; return 0 ; fi

    [[ "${status_modes[@]}" =~ "$corsair_mode" ]] || gmsg -x 1 -v2 "writing not available in '$corsair_mode' mode"
    corsair.check || gmsg -x 1 "corsair not available"

    local _button=${1^^}
    local _color='rgb_'"$2"
    local _bright="FF" ; [[ $3 ]] && _bright="$3"
    gmsg -n -v1 -t "set $_button color to "
    gmsg -v1 -c $2 "$2"

    # get input key pipe file location
    _button=$(eval echo '$'$_button)
    [[ $_button ]] || gmsg -c yellow -x 101 "no such button"

    # get input color code
    _color=$(eval echo '$'$_color)
    [[ $_color ]] || gmsg  -c yellow -x 102 "no such color"

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

