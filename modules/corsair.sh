#!/bin/bash
# guru-client corsair led notification functions
# casa@ujo.guru 2020

# todo
#   - automated keyboard shortcut and pipe configurations for ckb-next
#   - able keys to go blink in background
#   - more colors and key > pipe file bindings
#   - shortcuts behind indicator key presses

# keys pipe files
# NOTE: these need to correlate with cbk-next animation settings!
source $GURU_BIN/common.sh

    ESC="/tmp/ckbpipe000"
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
   CPLC="/tmp/ckbpipe059"

# rgb color codes [R|G|B|Brightness]
   _RED="ff0000ff"
 _GREEN="00ff00ff"
  _BLUE="0000ffff"
_YELLOW="ffff00ff"
 _WHITE="ffffffff"
   _OFF="000000ff"

# active key list
key_list=$(file /tmp/ckbpipe0* |grep fifo |cut -f1 -d ":")


corsair.main () {
    # command parser
    local _cmd="$1" ; shift         # get command
    case "$_cmd" in init|start|end|status|help|install|remove|write)
            corsair.$_cmd $@ ; return $? ;;
        *)  echo "unknown command"
    esac
    return 0
}


corsair.help () {
    gmsg -v 1 -c white "guru-client corsair driver help"
    gmsg -v 2
    gmsg -v 0 "usage:    $GURU_CALL corsair [start|end|status|help|install|remove|write <key> <color>]"
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " install         install requirements "
    gmsg -v 1 " remove          remove corsair driver "
    gmsg -v 2 " help            this help "
    gmsg -v 1 " write           write key color (described below)  "
    gmsg -v 1 "    <KEY>        up-case key name like 'F1'  "
    gmsg -v 1 " _<COLOR>        up-case color with '_' on front of it "     # todo: go better
    gmsg -v 1 " start           starting procedure"
    gmsg -v 1 " end             ending procedure"
    #        start_blink     make key to blink (details below)
    #           <freq>       frequency in milliseconds
    #           <ratio>      10 = 10 of freq/100
    #        status          launch keyboard status view for testing
    gmsg -v 2
    gmsg -v 1 -c white "example:"
    gmsg -v 1 "          $GURU_CALL corsair status "
    gmsg -v 2
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c black "${FUNCNAME[0]}: disabled"
            return 1
        fi

    if ! ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v0 "starting ckb-next-daemon.. sudo needed"
            sudo ckb-next-daemon >/dev/null &
            sleep 3
        else
            gmsg -n -v2 -t "ckb-next-daemon " ; gmsg -v2 -c green "OK"
        fi

    return 0

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
            corsair.write f4 green
            gmsg -v1 -c green "corsair on service"
            return 0
        else
            corsair.write f4 red
            gmsg -v1 -c black "corsair not on service"
            return 1
        fi
}


corsair.init () {
    # load default profile and set wanted mode
    local _mode="status" ; [[ $1 ]] && _mode=$1
    if ! ckb-next -p guru -m $_mode 2>/dev/null ; then
            gmsg -v -x $? -c yellow "corsair init failure"
        fi
    return 0
}


corsair.start () {
    # reserve some keys for future purposes by coloring them now
    # todo: I think this can be removed, used to be test interface before daemon
    gmsg -v1 -t "starting corsair"

    for _key_pipe in $key_list ; do
        gmsg -v2 -t "$_key_pipe off"
        corsair.raw_write $_key_pipe $_OFF
        sleep 0.1
    done
}


corsair.end () {
    # return normal, assuming that normal really exits
    gmsg -v1 "resetting keyboard indicators"
    for _key_pipe in $key_list ; do
        gmsg -v2 -t "$_key_pipe white"
        corsair.raw_write $_key_pipe $_WHITE
        sleep 0.1
    done
}


corsair.raw_write () {
    if ! corsair.check ; then return 0 ; fi
    # write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>
    #corsair.check || return 100         # check is corsair up ünd running
    local _button=$1 ; shift            # get input key pipe file
    local _color=$1 ; shift             # get input color code
    echo "rgb $_color" > "$_button"     # write color code to button pipe file
    sleep 0.1                           # let device to receive and process command (surprisingly slow)
    return 0
}


corsair.write () {
    # write color to key: input <key> <color>
    if ! corsair.check ; then return 0 ; fi
    local _button=${1^^}
    local _color='_'"${2^^}"

    gmsg -n -v1 -t "set $_button color to "
    gmsg -v1 -c $2 "$2"

    # get input key pipe file location
    _button=$(eval echo '$'$_button)
    [[ $_button ]] || gmsg -c yellow -x 101 "no such button"
    # get input color code
    _color=$(eval echo '$'$_color)
    [[ $_color ]] || gmsg  -c yellow -x 102 "no such color"
    gmsg -v2 -t "$_button <- $_color"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $_button |grep fifo >/dev/null ; then
            echo "rgb $_color" > "$_button"
            sleep 0.05
        else
            gmsg -c yellow "io error, pipe file $_button is not set in cbk-next"
            return 103
        fi

    return 0
}


corsair.start_blink () {
    # ask daemon to blink a key
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
}


corsair.stop_blink () {
    # ask daemon to stop to blink a key
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
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

