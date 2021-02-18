#!/bin/bash
# guru-client corsair led notification functions casa@ujo.guru 2020-2021
source $GURU_BIN/common.sh
source $GURU_BIN/system.sh

# active key list
key_pipe_list=$(file /tmp/ckbpipe0* | grep fifo | cut -f1 -d ":")
# modes with status bar function set
status_modes=(status, test, red, olive, dark, orange)
# bubble cum temporary fix TODO is this needed?
corsair_last_mode="/tmp/corsair.mode"
# service configurations for ckb-next application
corsair_service="$HOME/.config/systemd/user/corsair.service"
corsair_daemon_service="/usr/lib/systemd/system/ckb-next-daemon.service"
# poll order is read from  environment list ${GURU_DAEMON_POLL_LIST[@]}
# origin is $GURU_CFG/$GURU_USER/user.cfg chapter '[daemon]' variable 'poll_list'
corsair_indicator_key="f$(poll_order corsair)"

# import colors
[[ -f "$GURU_CFG/rgb-color.cfg" ]] && source "$GURU_CFG/rgb-color.cfg"
# key pipe files (these need to correlate with cbk-next animation settings)
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


corsair.help () {
    gmsg -v 1 -c white "guru-client corsair help"
    gmsg -v 2
    gmsg -v 0 "usage:    $GURU_CALL corsair [start|init|set|reset|end|status|help|install|patch|compile|remove|raw_start|raw_status|raw_stop|set-suspend] <key> <color>"
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " status                      printout status "
    gmsg -v 1 " start                       start ckb-next-daemon "
    gmsg -v 1 " stop                        stop ckb-next-daemon"
    gmsg -v 1 " init <mode>                 initialize keyboard mode "
    gmsg -v 2 "                             [status|red|olive|dark] able to set keys "
    gmsg -v 2 "                             [trippy|yes-no|rainbow] active animations "
    gmsg -v 1 " set <key> <color>           write key color to keyboard key  "
    gmsg -v 1 " reset <key>                 reset one key or if empty, all pipes "
    gmsg -v 1 " end                         end playing with keyboard, set to normal "
    gmsg -v 1 " install                     install requirements "
    gmsg -v 2 " compile                     only compile, do not clone or patch"
    gmsg -v 2 " patch <device>              edit source devices: K68, IRONCLAW"
    gmsg -v 2 " set-suspend                 active suspend control to avoid suspend issues"
    gmsg -v 1 " remove                      remove corsair driver "
    gmsg -v 1 " help -v|-V                  get more detailed help by adding verbosity flag"
    gmsg -v 2 -c white -N "raw functions for non systemd linux:"
    gmsg -v 2 " raw_start <1..7>            start ckb-next, number is deepness "
    gmsg -v 2 " raw_status                  rad status (without systemd)"
    gmsg -v 2 " raw_stop                    stop by killing app"
    gmsg -v 2 " raw_disable                 disable service (some systemd) "
    gmsg -v 2
    gmsg -v 1 -c white "examples:"
    gmsg -v 1 "          $GURU_CALL corsair status -v   "
    gmsg -v 1 "          $GURU_CALL corsair init trippy "
    gmsg -v 1 "          $GURU_CALL corsair end         "
    gmsg -v 2
    return 0
}


corsair.help-profile () {
    # inform user to set profile manually (should never need)
    gmsg -c white "set ckb-next profile manually"
    gmsg -v1 -n "open ckb-next and click profile bar and select " ; gmsg -v1 -n -c white "Manage profiles "
    gmsg -v1 -n "then click " ; gmsg -v1 -n -c white "Import "
    gmsg -v1 -n "and navigate to " ; gmsg -v1 -n -c white "$GURU_CFG "
    gmsg -v1 -n "select " ; gmsg -v1 -n -c white "corsair-profile.ckb "
    gmsg -v1 -n "then click " ; gmsg -v1 -n -c white "open "
    gmsg -v1 "and close ckb-next"
}


corsair.main () {
    # command parser
    # ckb-next current mode data

    # is this really needed? (tmw)
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    local cmd="$1" ; shift

    case "$cmd" in

            # indicator functions
            init|set|reset|clear|end)
                    corsair.$cmd $@
                    return $?
                    ;;

            # non systemd control aka. raw_method (not well tested)
            raw_start|raw_status|raw_stop|raw_disable)
                    corsair.$cmd $@
                    return $?
                    ;;

            # systemd method in use after v0.6.4.5

            status|enable|start|restart|stop|disable)
                    if ! system.init_system_check systemd ; then
                            gmsg -c yellow -x 133 "systemd not in use, try raw_start or raw_stop"
                        fi
                    corsair.systemd_$cmd $@
                    return $?
                    ;;

            # guru.client daemon required functions
            check|install|patch|compile|remove|poll|help)
                    corsair.$cmd $@
                    return $?
                    ;;

            *)      gmsg -c yellow "corsair: unknown command: $cmd"
                    GURU_VERBOSE=2
                    corsair.help
                    ;;
        esac

    return 0
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v1 "checking corsair is enabled.. "
    if [[ $GURU_CORSAIR_ENABLE ]] ; then
            gmsg -v1 -c green "enabled"
        else
            gmsg  -c dark_grey "disabled"
            return 1
        fi

    gmsg -n -v1 "checking device is connected.. "
    if lsusb | grep "Corsair" >/dev/null ; then
            gmsg -v1 -c green "connected"
        else
            gmsg -c dark_grey "disconnected"
            return 2
        fi

    gmsg -n -v1 "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "running"
        else
            gmsg -c dark_grey "ckb-next-daemon not running"
            [[ $GURU_FORCE ]] || gmsg -v1 -c white "start by '$GURU_CALL corsair start'"
            return 3
        fi

    gmsg -n -v1 "checking ckb-next.. "
    if ps auxf | grep "ckb-next" | grep -v "daemon" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "running"

        else
            gmsg -c yellow "ckb-next application not running"
            [[ $GURU_FORCE ]] || gmsg -v1 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    if system.suspend flag ; then
            #gmsg -c yellow "computer suspended, ckb-next restart requested"
            #gmsg -v2 -c white "command: $GURU_CALL corsair start"
            return 6
        fi

    gmsg -n -v1 "checking mode supports piping.. "
    if [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
            gmsg -v1 -c green "ok"
        else
            gmsg -c white "writing not available in '$corsair_mode' mode"
            return 5
        fi

    gmsg -n -v1 "checking pipes.. "
    if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
            gmsg -v1 -c green "ok"
        else
            gmsg -c red "failed"
            corsair.help-profile
            return 6
        fi

    # all fine
    return 0
}


corsair.status () {
    # get status and print it out to kb leds
    if corsair.check >/dev/null ; then
            gmsg -v1 -t -c green "${FUNCNAME[0]}: corsair on service" -k $corsair_indicator_key
            return 0
        else
            local status=$?
            gmsg -t -c red "${FUNCNAME[0]}: corsair is not available" -k $corsair_indicator_key
            gmsg -v3 -c light_blue "$(corsair.raw_status)"
        fi
}


corsair.init () {
    # load default profile and set wanted mode, default is set in user configuration
    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > $corsair_last_mode
        else
            local _error=$?
            gmsg -c yellow "corsair init failure"
            return $_error
        fi

    return 0
}


corsair.set () {
    # write color to key: input <key> <color>
    corsair.check | return $?
    local _button=${1^^}
    local _color='rgb_'"$2"
    local _bright="FF" ; [[ $3 ]] && _bright="$3"

    gmsg -n -v3 "${FUNCNAME[0]}: $_button color to "
    gmsg -v3 -c $2 "$2"

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
    #gmsg -v2 "${FUNCNAME[0]}: $_button <- $_color"

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
    # application level function, not restarting daemon or application
    # return normal, if no input reset all
    # gmsg -n -v2 "resetting key"

    if [[ "$1" ]] ; then
            # gmsg -v2 " $1"
            corsair.set $1 $corsair_mode 10 && return 0 || return 100
        else
            gmsg -n -v2 "s"
            for _key_pipe in $key_pipe_list ; do
                gmsg -n -v2 "."
                corsair.raw_set $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10 || return 100
            done
           gmsg -v2 -c green " done"
           return 0
        fi
}


corsair.clear () {
    # set key to black, input <known_key> default is F1 to F12
    local _keylist=($key_pipe_list)
    gmsg -n -v1 "setting keys "
    [[ "$1" ]] && _keylist=(${@})
    for _key in $_keylist ; do
            gmsg -n -v1 "."
            gmsg -n -V1 -v2 "$_key "
            corsair.set $_key black
        done
    gmsg -v1 -c green " done"
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now
    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE && return 0 || return 100
}

## raw method

corsair.raw_status () {
    gmsg -V1 "$(ps auxf | grep ckb-next | grep -v grep)"

    gmsg -N -v2 -c white "application stuff"
    gmsg -v1 "$(systemctl --user status corsair.service)"
    gmsg -v3 "$(systemctl --user list-dependencies corsair.service)"

    gmsg -N -v2 -c white "daemon stuff"
    gmsg -v2 "$(systemctl status ckb-next-daemon.service)"
    gmsg -v3 "$(systemctl --user list-dependencies ckb-next-daemon.service)"

}


corsair.raw_start () {
    # check and start part by part based on check result

    function start_stack () {
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
                        start_stack
                    else
                        gmsg -c red "failed"
                        return 112
                    fi
                ;;
        4 )     gmsg -v1 "starting corsair application.. "
                start_stack
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
                start_stack
                ;;
        7 )     gmsg -v1 "force re-start full corsair stack.. "
                ckb-next -c
                systemctl restart ckb-next-daemon
                sleep 3
                start_stack
                ;;
        * )     gmsg -v1 -t -c green "corsair on service"
                return 0
    esac
}



corsair.raw_set () {
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


corsair.raw_clear () {
    # set key to black, input <pipe_file_list> default is F1 to F12
    local _pipelist=($key_pipe_list)
    gmsg -n -v1 "writing to pipe file(s) "
    [[ "$1" ]] && _pipelist=(${@})
    for _key_pipe in $_pipelist ; do
            gmsg -n -v1 "."
            gmsg -n -V1 -v2 "$_key_pipe "
            corsair.raw_set $_key_pipe $rgb_black
        done
    gmsg -v1 -c green " done"
}


corsair.raw_stop () {
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


corsair.raw_disable () {
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


## systemd method

corsair.systemd_enable () {

    temp="/tmp/suspend.temp"
    gmsg -v1 "generating corsair service file.. "

    if ! [[ -d  ${corsair_service%/*} ]] ; then
        mkdir -p ${corsair_service%/*} \
        || gmsg -x 100 "no permission to create folder ${corsair_service%/*}"
    fi

    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
[Unit]
Description=ckb-next application

[Service]
ExecStart=bash -c '/home/$USER/bin/core.sh corsair start'
ExecStop=bash -c '/home/$USER/bin/core.sh corsair stop'
Type=simple
Restart=always
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
EOL

    if ! cp -f $temp $corsair_service ; then
            gmsg -c red "script copy failed"
            return 101
        fi

    # copy file to from backup to avoid reinstall need after disable
    [[ -f $corsair_daemon_service ]] || cp -f $GURU_CFG/${corsair_daemon_service##*/} $corsair_daemon_service

    chmod +x $corsair_service
    systemctl --user daemon-reload || gmsg -c yellow "reload failed"
    systemctl --user enable corsair.service || gmsg -c yellow "enable failed"
    systemctl --user start corsair.service || gmsg -c yellow "start failed"

    # setup suspend script
    system.main suspend rm_flag
    system.main suspend install

    # load default profile
    corsair.check
    corsair.systemd_start

    rm -f $temp
    gmsg -v1 -c green "ok"
    return 0
}


corsair.systemd_status () {
    systemctl --user status corsair.service
}


corsair.systemd_start () {
    # check and start part by part based on check result

    function corsair.systemd_start_application () {
        systemctl --user start corsair.service || systemctl --user restart corsair.service || corsair.systemd_enable
        sleep 1
        corsair.init
        return $?
    }

    if [[ $1 ]] ; then
            local _status="$1"
        else
            corsair.check
            local _status="$?"
            gmsg -v3 -c deep_pink "corsair.check: $_status"
        fi

    [[ $GURU_FORCE ]] && _status="7"

    gmsg -v3 "status/given: $_status"
    case $_status in
        1 )     gmsg -v1 -c black "corsair disabled by user configuration" ;;
        2 )     gmsg -v1 -c black "no corsair devices connected" ;;

        3 )     gmsg -v1 "corsair daemon not running, starting.. "
                if ! sudo systemctl start ckb-next-daemon ; then
                        gmsg -c yellow "start failed, trying to restart.."
                        sudo systemctl restart ckb-next-daemon
                        return 112
                    fi
                    corsair.systemd_start_application
                ;;
        4 )     gmsg -v1 "starting corsair application.. "
                corsair.systemd_start_application
                return $?
                ;;
        5 )     gmsg -v1 "no pipe support in current profile..  "
                corsair.init
                return $?
                ;;
        6 )     gmsg -v1 "re-starting corsair application.. "
                systemctl --user stop corsair.service
                system.suspend rm_flag
                corsair.systemd_start_application
                ;;
        7 )     gmsg -v1 "force re-start full corsair stack.. "
                sudo systemctl restart ckb-next-daemon
                systemctl --user restart corsair.service

                corsair.systemd_start_application
                ;;
        * )     gmsg -v1 -t -c green "corsair on service"
                return 0
    esac
}


corsair.systemd_restart () {
    gmsg -v1 "restarting corsair service.. "
    systemctl --user restart corsair.service

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "restarting daemon service.. "
            sudo systemctl restart ckb-next-daemon
        fi
}


corsair.systemd_stop () {
    gmsg -v1 "stopping corsair service.. "
    systemctl --user stop corsair.service || gmsg -c yellow "stop failed"

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping corsair daemon service.. "
            sudo systemctl stop ckb-next-daemon
        fi
}


corsair.systemd_disable () {

    cp -f $corsair_daemon_service $GURU_CFG

    systemctl --user stop corsair.service || gmsg -c yellow "stop failed"
    systemctl --user disable corsair.service || gmsg -c yellow "disable failed"
    rm $corsair_service || gmsg -c yellow "rm failed"
    systemctl --user daemon-reload || gmsg -c yellow "reload failed"
    systemctl --user reset-failed || gmsg -c yellow "reset failed"

    sudo systemctl stop ckb-next-daemon || gmsg -c yellow "daemon stop failed"
    sudo systemctl disable ckb-next-daemon || gmsg -c yellow "daemon disable failed"

    system.main suspend remove
    rm -f $corsair_service

}

## guru.client required functions

corsair.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: corsair status polling started" -k $corsair_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: corsair status polling ended" -k $corsair_indicator_key
            ;;
        status )
            corsair.status $@
            ;;
        *)  corsair.help
            ;;
        esac

}


corsair.check_pipe () {
    # check that piping is activated. input timeout in seconds.
    declare -i timeout=10
    let timeout=$1 loops=timeout*2

    for (( i = 0; i < $loops; i++ )); do
        if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
                continue
            fi
        sleep 0.5
    done
    return 127
}


corsiar.suspend_recovery () {
    # check is system suspended during run and restart ckb-next application to re-connect led pipe files

    system.flag rm fast

    [[ $GURU_CORSAIR_ENABLE ]] || return 0

    # restart ckb-next
    corsair.systemd_restart

    # wait corsair to start
    corsair.check_pipe 4
    return $?
}


corsair.clone () {
    cd /tmp
    git clone https://github.com/ckb-next/ckb-next.git \
        && gmsg -c green "ok" \
        || gmsg -x 101 -c yellow "cloning error"
}


corsair.patch () {
    # patch corsair k68 to avoid long daemon stop time
    cd /tmp/ckb-next

    case $1 in
            K68|k68|keyboard)
                gmsg -c pink "1) find 'define NEEDS_UNCLEAN_EXIT(kb)' somewhere near line ~195"
                gmsg -c pink "2) add '|| (kb)->product == P_K68_NRGB' to end of line before ')'"
                subl src/daemon/usb.h
                ;;
            IRONCLAW|ironclaw|mouse)
                gmsg "no patches yet needed for ironclaw mice"
                ;;
            *)  gmsg -c yellow "unknown patch"
        esac

    read -p "press any key to continue"
    return 0
}


corsair.compile () {
    # compile ckb-next and ckb-next-daemon
    [[ -d /tmp/ckb-next ]] || corsair.clone
    cd /tmp/ckb-next
    gmsg -c white "running installer.."
    ./quickinstall && gmsg -c green "ok" || gmsg -x 103 -c yellow "quick installer error"
    return 0
}


usb.install-uhubctl () {
    # install usb hub control tool https://github.com/mvp/uhubctl
    # DID NOT WORK -failed
    # other https://github.com/hevz/hubpower/blob/master/hubpower.c
    cd /tmp
    git clone https://github.com/mvp/uhubctl
    cd uhubctl
    make
    sudo make install

    # test installation
    sudo uhubctl \
        || gmsg -x 101 -c yellow "usb hub control tool install error $?" \
        && gmsg -c green "ok"


}

corsair.requirements () {
    # install required libs and apps
    gmsg -c white "installing needed software "
    usb.install-uhubctl
    sudo apt-get install -y git cmake build-essential \
        pavucontrol \
        libudev-dev \
        qt5-default \
        zlib1g-dev \
        libappindicator-dev \
        libpulse-dev \
        libquazip5-dev \
        libqt5x11extras5-dev \
        libxcb-screensaver0-dev \
        libxcb-ewmh-dev \
        libxcb1-dev qttools5-dev \
        libdbusmenu-qt5-2 \
        libdbusmenu-qt5-dev \
        || gmsg -x 101 -c yellow "apt-get error $?" \
        && gmdg -c green "ok"
        return 0

}

corsair.install () {
    # install essentials, driver and application

    if ! [[ $GURU_FORCE ]] && corsair.check ; then
            gmsg -v1 "corsair seems to be working. use force flag '-f' to re-install"
            return 0
        fi

    if ! lsusb | grep "Corsair" ; then
            echo "no corsair devices connected, exiting.."
            return 100
        fi

    corsair.requirements && \
    corsair.clone && \
    corsair.patch K68 && \
    corsair.compile && \

    corsair.systemd_enable
    corsar.enable
    corsar.start

    # TBD system.suspend_control

    # TBD debian suspend control

    # make backup of .service file
    cp -f $corsair_daemon_service $GURU_CFG

    return 0
}


corsair.remove () {
    # get rid of driver and shit
    gask "really remove corsair" || return 100

    if [[ /tmp/ckb-next ]] ; then
        cd /tmp/ckb-next
        sudo cmake --build build --target uninstall
    else
        # if source is not available anymore re clone it to build uninstall method
        cd /tmp
        git clone https://github.com/ckb-next/ckb-next.git
        cd ckb-next
        cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release -DSAFE_INSTALL=ON -DSAFE_UNINSTALL=ON -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBEXECDIR=lib
        cmake --build build --target all -- -j 4
        sudo cmake --build build --target install       # The compilation and installation steps are required because install target generates an install manifest that later allows to determine which files to remove and what is their location.
        sudo cmake --build build --target uninstall
    fi

    rm -f $suspend_script

    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$GURU_RC"
        corsair.main "$@"
        exit "$?"
fi

