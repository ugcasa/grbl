#!/bin/bash
# guru-client corsair led notification functions casa@ujo.guru 2020-2021
# WARNING: this module can fuck up system suspend, # if taht happends just
# weit until login window activates, it should take less than 2 minutes (cinnamon)
# and remove file '/lib/systemd/system-sleep/guru-client-suspend.sh'

source $GURU_BIN/common.sh
source $GURU_BIN/system.sh

# active key list
key_pipe_list=$(file /tmp/ckbpipe0* | grep fifo | cut -f1 -d ":")
# modes with status bar function set
status_modes=(status, test, red, olive, dark, orange, eq)
corsair_last_mode="/tmp/corsair.mode"
# service configurations for ckb-next application
corsair_service="$HOME/.config/systemd/user/corsair.service"
corsair_daemon_service="/usr/lib/systemd/system/ckb-next-daemon.service"
# jsut know what to delete shen disable option/lib/systemd/system-sleep/guru-client-suspend.sh
suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh"
# poll order is read from  environment list ${GURU_DAEMON_POLL_ORDER[@]} set in user.cfg
corsair_indicator_key="f$(daemon.poll_order corsair)"
pipelist_file="$GURU_CFG/corsair-pipelist.cfg"

# import colors
[[ -f "$GURU_CFG/rgb-color.cfg" ]] && source "$GURU_CFG/rgb-color.cfg"

# load key pipe file list
if [[ -f $pipelist_file ]] ; then
        source $pipelist_file
    else
        gmsg -c red "pipelist file $pipelist_file missing"
    fi


corsair.main () {
    # command parser

    # ckb-next last mode data
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    local cmd="$1" ; shift

    case "$cmd" in
            # indicator functions
            status|init|set|reset|clear|end)
                    corsair.$cmd $@
                    return $?
                    ;;
            # systemd method is used after v0.6.4.5
            enable|start|restart|stop|disable)
                    if ! system.init_system_check systemd ; then
                            gmsg -c yellow -x 133 "systemd not in use, try raw_start or raw_stop"
                        fi
                    corsair.systemd_$cmd $@
                    return $?
                    ;;
            # guru.client daemon functions
            check|install|patch|compile|remove|poll)
                    corsair.$cmd $@
                    return $?
                    ;;
            # non systemd control aka. raw_method for non systemd releases like devuan
            raw)
                    if [[ -f $GURU_BIN/corsair-raw.sh ]] ; then
                            source $GURU_BIN/corsair-raw.sh
                            corsair.raw.$1 $@
                        else
                            gmsg -c yellow "install dev modules first by 'install.sh -df' "
                        fi
                    return $?
                    ;;
            # hmm..
            '--')
                    return 12
                    ;;
            #
            help)   case $1 in  profile) corsair.help-profile ;;
                                      *) corsair.help
                        esac
                    ;;
            *)  gmsg -c yellow "corsair: unknown command: $cmd"
        esac

    return 0
}


corsair.help () {
    # general help

    gmsg -v1 -c white "guru-client corsair keyboard indicator help"
    gmsg -v2
    gmsg -v0 "usage:           $GURU_CALL corsair start|init|reset|end|status|help|set <key/profile> <color>"
    gmsg -v1 "setup:           install|compile|patch|remove"
    gmsg -v2 "without systemd: raw start|raw status|raw stop "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " status                      printout status "
    gmsg -v1 " start                       start ckb-next-daemon "
    gmsg -v1 " stop                        stop ckb-next-daemon"
    gmsg -v1 " init <mode>                 initialize keyboard mode "
    gmsg -v2 "                             [status|red|olive|dark|orange|eq] able to set keys "
    gmsg -v2 "                             [trippy|yes-no|rainbow] animations only "
    gmsg -v1 " set <key> <color>           write key color <color> to keyboard key <key> "
    gmsg -v1 " reset <key>                 reset one key or if empty, all pipes "
    gmsg -v1 " end                         end playing with keyboard, set to normal "
    gmsg -v1 " install                     install requirements "
    gmsg -v2 " compile                     only compile, do not clone or patch"
    gmsg -v2 " patch <device>              edit source devices: K68, IRONCLAW"
    gmsg -v2 " set-suspend                 active suspend control to avoid suspend issues"
    gmsg -v1 " remove                      remove corsair driver "
    gmsg -v1 " help -v|-V                  get more detailed help by adding verbosity flag"
    gmsg -v2
    gmsg -v1 -c white "examples:"
    gmsg -v1 " $GURU_CALL corsair status        printout status report "
    gmsg -v1 " $GURU_CALL corsair init trippy   initialize trippu color profile"
    gmsg -v1 " $GURU_CALL corsair end           stop playing with colors, return to normal"
    gmsg -v2
    gmsg -v1 -c white "setting up corsair keyboard and mice indication functions "
    gmsg -v1 -c white "1) to show how configure profile run: "
    gmsg -v1 "              $GURU_CALL corsair help profile "
    gmsg -v1 -c white "2) to enable service run: "
    gmsg -v1 "              $GURU_CALL corsair enable "
    gmsg -v1 -c white "3) to set suspend support run: "
    gmsg -v1 "              $GURU_CALL system suspend install "

    return 0
}


corsair.help-profile () {
    # inform user to set profile manually (should never need)

    gmsg -c white "set ckb-next profile manually"
    gmsg -v1 -n "1) open ckb-next and click profile bar and select "
    gmsg -v1 -c white "Manage profiles "
    gmsg -v1 -n "2) then click " ; gmsg -v1 -n -c white "Import "
    gmsg -v1 -n "and navigate to " ; gmsg -v1 -n -c white "$GURU_CFG "
    gmsg -v1 -n "select " ; gmsg -v1 -c white "corsair-profile.ckb "
    gmsg -v1 -n "3) then click " ; gmsg -v1 -n -c white "open "
    gmsg -v1 "and close ckb-next"
}


corsair.enabled () {
    # check is corsair enables in user.cfg

    gmsg -n -v2 "checking corsair is enabled.. "
        if [[ $GURU_CORSAIR_ENABLED ]] ; then
                gmsg -v2 -c green "enabled"
            else
                gmsg -v2 -c dark_grey "disabled"
                gmsg -v1 -V2 -c dark_grey "corsair disabled"
                return 1
            fi
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v2 "checking corsair is enabled.. "
    if [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c green "enabled"
        else
            gmsg  -c dark_grey "disabled"
            return 1
        fi

    gmsg -n -v2 "checking device is connected.. "
    if lsusb | grep "Corsair" >/dev/null ; then
            gmsg -v2 -c green "connected"
        else
            gmsg -c dark_grey "disconnected"
            return 2
        fi

    gmsg -n -v2 "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"
        else
            gmsg -c dark_grey "ckb-next-daemon not running"
            [[ $GURU_FORCE ]] || gmsg -v2 -c white "start by '$GURU_CALL corsair start -f'"
            return 3
        fi

    gmsg -n -v2 "checking ckb-next.. "
    if ps auxf | grep "ckb-next" | grep -v "daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"

        else
            gmsg -c yellow "ckb-next application not running"
            [[ $GURU_FORCE ]] || gmsg -v2 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    if system.suspend flag ; then
            gmsg -v2 -c yellow "computer suspended, ckb-next restart requested"
            #gmsg -v2 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    gmsg -n -v2 "checking mode supports piping.. "
    if [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c white "writing not available in '$corsair_mode' mode"
            return 5
        fi

    gmsg -n -v2 "checking pipes.. "
    if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c red "pipe failed"
            corsair.help-profile
            return 6
        fi

    # all fine
    return 0
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

    gmsg -v4 -n "${FUNCNAME[0]}: $_button color to "
    gmsg -v4 -c $2 "$2"

    # get input key pipe file location
    _button=$(eval echo '$'$_button)
    if ! [[ $_button ]] ; then
            gmsg -v3 -c yellow "no such button"
            return 101
        fi

    # get input color code
    _color=$(eval echo '$'$_color)
    if ! [[ $_color ]] ; then
            gmsg -v3 -c yellow "no such color"
            return 102
        fi

    # corsailize RGB code with brightness value
    _color="$_color""$_bright"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $_button | grep fifo >/dev/null ; then
            echo "rgb $_color" > "$_button"
            sleep 0.05
            return 0
        else
            gmsg -c yellow "io error, pipe file $_button is not set in cbk-next"
            return 103
        fi
}


corsair.pipe () {
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


corsair.reset () {
    # application level function, not restarting daemon or application, return normal, if no input reset all

    gmsg -n -v3 "resetting key"

    if [[ "$1" ]] ; then
            # gmsg -v2 " $1"
            corsair.set $1 $corsair_mode 10 && return 0 || return 100
        else
            gmsg -n -v3 "s"
            for _key_pipe in $key_pipe_list ; do
                gmsg -n -v3 "."
                corsair.pipe $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10 || return 100
            done
           gmsg -v3 -c green " done"
           return 0
        fi
}


corsair.clear () {
    # set key to black, input <known_key> default is F1 to F12

    local _keylist=($key_pipe_list)
    gmsg -n -v3 "setting keys "
    [[ "$1" ]] && _keylist=(${@})
    for _key in $_keylist ; do
            gmsg -n -v3 "."
            gmsg -n -V3 -v2 "$_key "
            corsair.set $_key black
        done
    gmsg -v3 -c green " done"
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now

    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE && return 0 || return 100
}


corsair.check_pipe () {
    # check that piping is activated. input timeout in seconds

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


############################ systemd method ###############################


corsair.systemd_status () {
    # printout systemd service status

    systemctl --user status corsair.service
}


corsair.systemd_start_application () {
    #s try to start, if fails, restart and it that failes to run setup again

    systemctl --user start corsair.service \
         || systemctl --user restart corsair.service\
         #|| corsair.systemd_enable

    sleep 2
    corsair.init
    return $?
}


corsair.systemd_start () {
    # check and start stack based on corsair.check return code

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
    # systemd method restart function

    gmsg -v1 "restarting corsair service.. "
    systemctl --user restart corsair.service

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "restarting daemon service.. "
            sudo systemctl restart ckb-next-daemon
        fi
}


corsair.systemd_stop () {
    # systemd method stop service function

    gmsg -v1 "stopping corsair service.. "
    systemctl --user stop corsair.service || gmsg -c yellow "stop failed"

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping corsair daemon service.. "
            sudo systemctl stop ckb-next-daemon
        fi
}


corsair.make_daemon_service () {
    ## ckb-next-daemon service

     local temp="/tmp/suspend.temp"

    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
# Copyright 2017-2018 ckb-next Development Team <ckb-next@googlegroups.com>
# Distributed under the terms of the GNU General Public License v2

[Unit]
Description=Corsair Keyboards and Mice Daemon

[Service]
ExecStart=/usr/local/bin/ckb-next-daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

    # copy file to from backup to avoid reinstall need after disable
    [[ -f $corsair_daemon_service ]] || cp -f $corsair_daemon_service $GURU_CFG/${corsair_daemon_service##*/}
    if ! sudo cp -f $temp $corsair_daemon_service ; then
            gmsg -c yellow "ckb-next-daemon service update failed"
            return 101
        fi

    return $?
}


corsair.make_app_service () {
    # ckb-next application service

    local temp="/tmp/suspend.temp"

    if ! [[ -d  ${corsair_service%/*} ]] ; then
        mkdir -p ${corsair_service%/*} \
            || gmsg -c yellow "no permission to create folder ${corsair_service%/*}"
    fi


    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
[Unit]
Description=run ckb-next application as user
DefaultDependencies=no
After=network.target

[Service]
Type=simple
# User=$USER
# Group=$USER
ExecStart=/usr/local/bin/ckb-next -b -p guru
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=default.target

EOL

    [[ -f $corsair_service ]] || cp -f $corsair_service $GURU_CFG/${corsair_service##*/}

    if ! cp -f $temp $corsair_service ; then
            gmsg -c yellow "ckb-next service update failed"
            return 102
        fi

    return $?
}


corsair.systemd_enable () {
    # set and enable corsair service based on systemd, enable suspend script, load profile and start

    # make ckb-next-daemon service
    gmsg -v1 "generating ckb-next-daemon service file.. "

    corsair.make_daemon_service
    sudo systemctl daemon-reload                         || gmsg -c yellow "daemon daemon-reload failed"
    sudo systemctl enable ${corsair_daemon_service##*/}  || gmsg -c yellow "daemon enable failed"
    sudo systemctl start ${corsair_daemon_service##*/}   || gmsg -c yellow "deamon start failed"

    ## ckb-next application service
    gmsg -v1 "generating ckb-next application service file.. "
    corsair.make_app_service
    systemctl --user daemon-reload                  || gmsg -c yellow "user daemon-reload failed"
    systemctl --user enable ${corsair_service##*/}  || gmsg -c yellow "enable failed"
    systemctl --user start ${corsair_service##*/}   || gmsg -c yellow "start failed"

    # setup suspend script
    system.main suspend rm_flag
    system.main suspend install

    # load default profile
    # corsair.check
    corsair.init status

    rm -f $temp
    #gmsg -v1 -c green "ok"
    return 0
}


corsair.systemd_disable () {
    # systemd method disable service function

    cp -f $corsair_daemon_service $GURU_CFG

    systemctl --user stop corsair.service       || gmsg -c yellow "stop failed"
    systemctl --user disable corsair.service    || gmsg -c yellow "disable failed"
    rm $corsair_service                         || gmsg -c yellow "rm failed"
    systemctl --user daemon-reload              || gmsg -c yellow "reload failed"
    systemctl --user reset-failed               || gmsg -c yellow "reset failed"

    sudo systemctl stop ckb-next-daemon         || gmsg -c yellow "daemon stop failed"
    sudo systemctl disable ckb-next-daemon      || gmsg -c yellow "daemon disable failed"

    system.main suspend remove
    rm -f $corsair_service
}


corsair.suspend_recovery () {
    # check is system suspended during run and restart ckb-next application to re-connect led pipe files

    system.flag rm fast

    [[ $GURU_CORSAIR_ENABLED ]] || return 0

    # restart ckb-next
    corsair.systemd_restart

    # wait corsair to start
    corsair.check_pipe 4
    return $?
}


################# get, patching, compile, install and setup functions ######################

corsair.clone () {
    # get ckb-next source

    cd /tmp
    [[ -d ckb-next ]] && rm -rf ckb-next
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


corsair.requirements () {
    # install required libs and apps

    gmsg -c white "installing needed software "

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
            && gmsg -c green "ok"

    return 0

}


######################### guru.client required functions ###########################

corsair.poll () {
    # guru daemon api functions

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


corsair.status () {
    # get status for daemon (or user)

    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    if corsair.check ; then
            gmsg -v1 -c green "corsair on service" -k $corsair_indicator_key
            return 0
        else
            local status=$?
            gmsg -v1 -c red "corsair is not in service" # -k $corsair_indicator_key
            return $status
        fi
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
    corsair.patch K68 && \
    corsair.compile && \

    corsair.systemd_enable
    corsair.systemd_start

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

