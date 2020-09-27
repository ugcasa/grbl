#!/bin/bash
# guru-client corsair led notification functions
# casa@ujo.guru 2020

# todo
#   - automated keyboard shortcut and pipe configurations for ckb-next
#   - able keys to go blink in background
#   - more colors and key > pipe file bindings
#   - shortcuts behind indicator key presses

# key to pipe file
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
   CPLC="/tmp/ckbpipe015"

# color codes R|G|B|Brightness
   _RED="ff0000ff"
 _GREEN="00ff00ff"
  _BLUE="0000ffff"
_YELLOW="ffff00ff"
 _WHITE="ffffffff"
   _OFF="000000ff"


corsair.main () {
    # command parser
    corsair.check                   # check than ckb-next-darmon, ckb-next and pipes are started and start is not
    local _cmd="$1" ; shift         # get command
    case "$_cmd" in start|end|status|help|install|write|remove)
            corsair.$_cmd ; return $? ;;
        *)  echo "unknown command"
    esac
    return 0
}


corsair.help () {
    echo "-- guru guru-client corsair help -----------------------------------------------"
    printf "usage:\t\t %s corsair [command] \n\n" "$GURU_CALL"
    printf "commands:\n"
    printf " install         install requirements \n"
    printf " remove          remove corsair driver "
    printf " help            this help \n"
    printf " write           write key color (described below) \n "
    printf "      <KEY>      up-case key name like 'F1' \n "
    printf "   _<COLOR>      up-case color with '_' on front of it \n"     # todo: go better
    #        start           starting procedure
    #        end             ending procedure
    #        start_blink     make key to blink (details below)
    #           <freq>       frequency in milliseconds
    #           <ratio>      10 = 10 of freq/100
    #        status          launch keyboard status view for testing
    printf "\n\n example:"
    printf "\t %s corsair status \n" "$GURU_CALL"
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed
    if ! ps auxf |grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 -t "starting ckb-next-daemon.."
            ckb-next-daemon --nonroot >/dev/null
            sleep 2
        else gmsg -v1 -t "ckb-next-daemon $(OK)" ; fi

    # Check is keyboard setup interface, start if not
    if ! ps auxf |grep "ckb-next " | grep -v grep >/dev/null 2>&1 ; then
            gmsg -v1 -t "starting ckb-next.."
            ckb-next >/dev/null 2>&1 &
            sleep 2
        else gmsg -v1 -t "ckb-next $(OK)" ; fi

    # Check are pipes started, start if not
    if ! ps auxf |grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep>/dev/null ; then
            gmsg "set pipes in cbk-next gui: K68 > Lighting > select a key(s) > New animation > Pipe > ... and try again"
            ckb-next -p guru >/dev/null
            return 100
        else gmsg -v1 -t "ckb-next pipes $(OK)" ; fi

    return 0
}


corsair.status () {
    # writes its in status to keyboard LED, no really other purpose then testing
    if corsair.check ; then
            gmsg -v1 -t "F4 $(OK)"
            corsair.write $F4 $_GREEN
            return 0
        else
            gmsg -v1 -t "F4 $(ERROR)"
            corsair.write $F4 $_YELLOW
            return 1
        fi
}


corsair.start () {
    # reserve some keys for future purposes by coloring them now
    # todo: I think this can be removed, used to be test interface before daemon
    gmsg -v1 -t "starting corsair"
    corsair.write $CPLC $_OFF           # reserved for future use as an guru super key
}


corsair.end () {
    # return normal, assuming that normal really exits
    gmsg -v1 -t "ending corsair"
    corsair.write $F4 $_WHITE
    corsair.write $CPLC $_WHITE
}


corsair.write () {
    # write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>
    #corsair.check || return 100         # check is corsair up ünd running
    local _button=$1 ; shift            # get input key pipe file
    local _color=$1 ; shift             # get input color code
    echo "rgb $_color" > "$_button"     # write color code to button pipe file
    sleep 0.1                           # let device to receive and process command (surprisingly slow)
    return 0
}


corsair.start_blink () {
    # ask daemon to blink a key
    echo "TBD"
}


corsair.stop_blink () {
    # ask daemon to stop to blink a key
    echo "TBD"
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
        source "$GURU_BIN/lib/deco.sh"
        corsair.main "$@"
        exit "$?"
fi

