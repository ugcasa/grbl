############################ systemd functions for corsair ###############################
# relies on corsair variables, source only from corsair module

corsair.systemd_status () {
# printout systemd service status
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    systemctl --user status corsair.service
}

corsair.systemd_fix () {
# check and start stack based on corsair.check return code
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    source system.sh
    if [[ $1 ]] ; then
        local _status="$1"
    else
        corsair.check
        local _status="$?"
        gr.debug "corsair.check: $_status"
    fi

    [[ $GRBL_FORCE ]] && _status="7"

    gr.msg -v1 "trying to fix.. $_status"
    case $_status in

        1)
            gr.msg -v1 -c black "corsair disabled by user configuration"
            source config.sh
            config.save $corsair_config enabled "true" && gr.msg -v1 -c green "enabled"
            ;;

        2)
            gr.msg -v1 -c black "no corsair devices connected"
            ;;

        3)
            gr.msg -v1 "corsair daemon not running, starting.. "
            if ! sudo systemctl start ckb-next-daemon ; then
                gr.msg -c yellow "start failed, trying to restart.."
                sudo systemctl restart ckb-next-daemon
                return 112
            fi
            corsair.systemd_app start
            ;;

        4)
            gr.msg -v1 "starting corsair application.. "
            corsair.systemd_app start
            return $?
            ;;

        5)
            gr.msg -v1 "no pipe support in current profile..  "
            corsair.init
            return $?
            ;;

        6)
            gr.msg -v1 "re-starting corsair application.. "
            corsair.systemd_app restart
            ;;

        7)
            gr.msg -v1 "force re-start full corsair stack.. "
            sudo systemctl restart ckb-next-daemon
            systemctl --user restart corsair.service
            # corsair.systemd_app start
            ;;

        * )     gr.msg -v1 -t -c green "corsair on service"
    esac
    return 0
}

corsair.systemd_start () {
# full stack
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    corsair.systemd_daemon start
    corsair.systemd_app start
}

corsair.systemd_stop () {
# full stack
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    corsair.systemd_app stop
    corsair.systemd_daemon stop
}

corsair.systemd_restart () {
# full stack
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    corsair.systemd_app stop
    corsair.systemd_daemon restart
    corsair.systemd_app start
}

corsair.systemd_daemon () {
# systemd method restart function
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -v1 -n "$1 daemon service.. "
    if sudo systemctl $1 ckb-next-daemon; then
        gr.msg -c green "done"
    else
        gr.msg -e2 "failed"
        return 101
    fi
}

corsair.systemd_app () {
# try to start, if fails, restart and it that failes to run setup again
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -v1 -n "$1 corsair app service.. "

    case $1 in
        stop)

            if ! sudo pkill ckb-next 2>/dev/null; then
                gr.msg -c dark_grey "not running"
                return $?
            fi
            ;;
        restart)
            if sudo pkill ckb-next 2>/dev/null; then
                gr.msg -n -c white "killed.. "
            else
                gr.msg -n -c dark_grey "not running.. "
            fi

            ckb-next 1>/dev/null 2>/dev/null &
            ;;
        start|*)
            ckb-next 1>/dev/null 2>/dev/null &
            ;;
    esac
    gr.msg -c green "done"

}


corsair.systemd_make_daemon_service () {
# ckb-next-daemon service
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

     local temp="/tmp/$USER/suspend.temp"

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
    [[ -f $corsair_daemon_service ]] || cp -f $corsair_daemon_service $GRBL_CFG/${corsair_daemon_service##*/}
    if ! sudo cp -f $temp $corsair_daemon_service ; then
        gr.msg -c yellow "ckb-next-daemon service update failed"
        return 101
    fi

    return $?
}

corsair.systemd_make_app_service () {
# ckb-next application service
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local temp="/tmp/$USER/suspend.temp"

    if ! [[ -d  ${corsair_service%/*} ]] ; then
        mkdir -p ${corsair_service%/*} \
            || gr.msg -e1 "no permission to create folder ${corsair_service%/*}"
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
ExecStart=/usr/local/bin/ckb-next -b -p grbl
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=default.target

EOL

    [[ -f $corsair_service ]] || cp -f $corsair_service $GRBL_CFG/${corsair_service##*/}

    if ! cp -f $temp $corsair_service ; then
        gr.msg -c yellow "ckb-next service update failed"
        return 102
    fi

    return $?
}

corsair.systemd_setup () {
# set and enable corsair service based on systemd, enable suspend script, load profile and start
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    source system.sh

    # make ckb-next-daemon service
    gr.msg -v1 "generating ckb-next-daemon service file.. "

    corsair.systemd_make_daemon_service
    sudo systemctl daemon-reload                         || gr.msg -c yellow "daemon daemon-reload failed"
    sudo systemctl enable ${corsair_daemon_service##*/}  || gr.msg -c yellow "daemon enable failed"
    sudo systemctl start ${corsair_daemon_service##*/}   || gr.msg -c yellow "daemon start failed"

    ## ckb-next application service
    gr.msg -v1 "generating ckb-next application service file.. "
    corsair.systemd_make_app_service
    systemctl --user daemon-reload                  || gr.msg -c yellow "user daemon-reload failed"
    systemctl --user enable ${corsair_service##*/}  || gr.msg -c yellow "enable failed"
    systemctl --user start ${corsair_service##*/}   || gr.msg -c yellow "start failed"

    # setup suspend script
    system.main suspend rm_flag
    system.main suspend install

    # load default profile
    # corsair.check
    corsair.init status

    rm -f $temp
}

corsair.systemd_disable () {
# systemd method disable service function
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    source system.sh

    cp -f $corsair_daemon_service $GRBL_CFG

    systemctl --user stop corsair.service       || gr.msg -c yellow "stop failed"
    systemctl --user disable corsair.service    || gr.msg -c yellow "disable failed"
    rm $corsair_service                         || gr.msg -c yellow "rm failed"
    systemctl --user daemon-reload              || gr.msg -c yellow "reload failed"
    systemctl --user reset-failed               || gr.msg -c yellow "reset failed"

    sudo systemctl stop ckb-next-daemon         || gr.msg -c yellow "daemon stop failed"
    sudo systemctl disable ckb-next-daemon      || gr.msg -c yellow "daemon disable failed"

    system.main suspend remove
    rm -f $corsair_service
}

corsair.suspend_recovery () {
# check is system suspended during run and restart ckb-next application to re-connect led pipe files
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    source system.sh
    system.flag rm fast

    [[ $GRBL_CORSAIR_ENABLED ]] || return 0

    # restart ckb-next
    corsair.systemd_app restart

    # wait corsair to start
    corsair.check_pipe 4
    return $?
}