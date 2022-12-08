#!/bin/bash
# guru client background servicer
# casa@ujo.guru 2020

declare -xg daemon_service_script="$HOME/.config/systemd/user/guru.service"
declare -xg daemon_pid_file="/tmp/guru.daemon-pid"
declare -axg GURU_DAEMON_PID=

# use same key than system.sh
daemon_indicator_key="esc"

source $GURU_BIN/system.sh

daemon.main () {
# daemon main command parser

    local argument="$1" ; shift
    case "$argument" in
            start|stop|status|help|kill|poll)
                daemon.$argument
                return $?
                ;;
            install|remove)
                daemon.systemd $argument
                return $?
                ;;

            *)  gr.msg "unknown daemon command"   ; return 1  ;;
        esac
    return 0
}


daemon.help () {
# general help

    gr.msg -v 1 -c white "guru daemon help "
    gr.msg -v 2
    gr.msg -v 0 "usage:    $GURU_CALL daemon [start|stop|status|kill|poll]"
    gr.msg -v 2
    gr.msg -v 1 -c white "commands:"
    gr.msg -v 1 " start        start daemon (same as $GURU_CALL start)"
    gr.msg -v 1 " stop         stop daemon (same as $GURU_CALL stSop)"
    gr.msg -v 1 " status       printout status"
    gr.msg -v 1 " kill         kill jammed daemon"
    gr.msg -v 2 " poll         start polling process"
    gr.msg -v 2
    gr.msg -v 1 -c white "example:"
    gr.msg -v 1 "      $GURU_CALL daemon status"
    gr.msg -v 2
}


daemon.status () {
# printout status of daemon

    gr.msg -n -v1 "${FUNCNAME[0]}: "

    if [[ -f "$daemon_pid_file" ]]; then
            local last_pid="$(cat $daemon_pid_file)"
            gr.msg -n -v2 "(prev. PID: $last_pid) "
        fi

    local _ifs=$IFS; IFS=$'\n'
    process_list=($(ps auxf | grep -v grep | grep -e "$GURU_BIN/guru start" -e "daemon.sh start" | grep -e "$USER"))
    IFS=$_ifs

    GURU_DAEMON_PID=()

    for (( i = 0; i < ${#process_list[@]}; i++ )); do
            GURU_DAEMON_PID=(${GURU_DAEMON_PID[@]} $(echo ${process_list[$i]} | xargs | cut -f2 -d' '))
            gr.msg -n -c light_blue "${GURU_DAEMON_PID[$i]} "
            #statements
        done

    # GURU_DAEMON_PID=($(ps auxf | grep -v grep | grep -e "$GURU_BIN/guru start" -e "daemon.sh start" | grep -e "$USER" | xargs | cut -d' ' -f2))
    #${GURU_DAEMON_PID[1]}

    if ! [[ $GURU_DAEMON_PID ]]; then
            gr.msg -v1 -c red "not running" -k $daemon_indicator_key
            [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file && gr.msg -n -v2 "previous PID removed "
            return 127
        fi

    if [[ ${#GURU_DAEMON_PID[@]} -gt 1 ]]; then
            gr.msg -v1 -c yellow "multiple daemons detected, get a shotgun.." -k $daemon_indicator_key
            gr.msg -v2 "kill daemons by '$GURU_CALL daemon kill' command and then start new one by '$GURU_CALL start'"
            # gr.msg -c -v2 light_blue "${GURU_DAEMON_PID[@]} "
            return 0
        fi

    if ! [[ $GURU_DAEMON_PID -eq $last_pid ]]; then
            gr.msg -n -v2 -c yellow "previous PID mismatch " -k $daemon_indicator_key
            echo $GURU_DAEMON_PID >$daemon_pid_file
            # retest
            last_pid="$(cat $daemon_pid_file)"
            [[ $GURU_DAEMON_PID -eq $last_pid ]] \
                && gr.msg -n -v2 -c white "fixed "\
                || gr.msg -n -v2 -c red "failed to update previous PID " -k $daemon_indicator_key
        fi

    #export $GURU_DAEMON_PID
    gr.msg -v0 -V1 "$GURU_DAEMON_PID"
    gr.msg -v1 -c green "running"
    gr.ind done $daemon_indicator_key
    return 0
}


daemon.start () {
# start daemon

    # if daemon.status && ! [[ $GURU_FORCE ]]; then
    #         gr.msg -v1 -c green "already running"
    #         gr.msg -v2  "use force to restart"
    #         return 0
    #     fi

    # daemon.status fixes previous PID file, so we can trust that $daemon_pid_file includes current pid of running daemon
    # EDIT: $GURU_DAEMON_PID declared globally and is exported
    if [[ -f "$daemon_pid_file" ]]; then
            local last_pid=$(cat "$daemon_pid_file")
            gr.msg -v2 "${FUNCNAME[0]}: killing $last_pid"
            kill -9 $last_pid || kill -9 $GURU_DAEMON_PID
            sleep 2
        fi

    if system.suspend flag ; then
            [[ $GURU_CORSAIR_ENABLED ]] && source $GURU_BIN/corsair.sh
            system.suspend rm_flag
            corsair.systemd_restart
        fi

    gr.ind doing $daemon_indicator_key

    #for module in ${GURU_DAEMON_POLL_ORDER[@]} ; do
    for ((i=1 ; i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GURU_DAEMON_POLL_ORDER[i-1]}
        case $module in
            null|empty )
                ;;
            *)
                gr.msg -v2 -c dark_golden_rod "$i:$module: "
                if [[ -f "$GURU_BIN/$module.sh" ]]; then
                        source "$GURU_BIN/$module.sh"
                        # gr.msg -v3 ": $GURU_BIN/$GURU_BIN/$module.sh"
                        $module.main poll start
                    else
                        gr.msg -v1 -c yellow "${FUNCNAME[0]}: module $module not installed" \
                            -k "f$(gr.poll $module)"
                    fi
                ;;
            esac
        done

    gr.end $daemon_indicator_key
    gr.msg "start polling" -c reset -k $daemon_indicator_key
    daemon.poll &
}


daemon.stop () {
# stop daemon

    system.flag rm stop
    gr.msg -N -n -V1 -c white "stopping daemon.. "
    # if pid file is not exist
    if ! [[ -f "$daemon_pid_file" ]]; then
            gr.msg "${FUNCNAME[0]}: daemon not running"
            gr.msg -v1 "start daemon by typing 'guru start'"
            return 0
        fi

    local _pid=$(cat $daemon_pid_file)

    gr.msg -t -v1 "stopping modules.. "
    #for module in ${GURU_DAEMON_POLL_ORDER[@]} ; do

    for ((i=1 ; i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GURU_DAEMON_POLL_ORDER[i-1]}
        #gr.msg -v3 -c dark_golden_rod "$i $module"
        case $module in
            null|empty )
                #gr.msg -v3 -c dark_grey "skipping $module"
                ;;
            * )
                gr.msg -v2 -c dark_golden_rod "$i:$module: "
                if [[ -f "$GURU_BIN/$module.sh" ]]; then
                        source "$GURU_BIN/$module.sh"
                        $module.main poll end
                        # gr.msg -v3 "module: $GURU_BIN/$GURU_BIN/$module.sh"
                        # gr.msg -v2 "command: $module.main poll end"
                    else
                        gr.msg -v1 "${FUNCNAME[0]}: module '$module' not installed"
                    fi
                ;;
            esac
        done

    gr.msg -t -v1 "stopping guru-daemon.. "


    [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file

    system.flag rm running

    if ! kill -15 "$_pid" ; then
        gr.msg -V1 -c yellow "error $?, retry" -k $daemon_indicator_key

        if kill -9 "$_pid" ; then
             gr.end $daemon_indicator_key
             gr.msg -V1 -c green "ok" -k $daemon_indicator_key
        else
             gr.msg -V1 -c red "failed to kill daemon pid: $_pid"
             gr.ind failed $daemon_indicator_key
            return 124
        fi
    else
        gr.end $daemon_indicator_key
        gr.msg -V1 -c green "ok" -k $daemon_indicator_key
    fi


}


daemon.kill () {
# force stop daemon

    if ! daemon.status ; then
            return 0
        fi

    for (( i = 0; i < ${#GURU_DAEMON_PID[@]}; i++ )); do
            gr.msg -v1 -n "killing ${GURU_DAEMON_PID[$i]}.. "
            kill -9 ${GURU_DAEMON_PID[$i]} \
                && gr.msg -v1 -c green "ok" -k $daemon_indicator_key \
                || gr.msg -v1 -c red "failed" -k $daemon_indicator_key
        done

    if daemon.status ; then
            gr.msg -c red "failed to kill daemons" -k $daemon_indicator_key
        else
            gr.msg -v1 -c green "done" -k $daemon_indicator_key
        fi


    #daemon.status && gr.msg -c red "failed to stop daemons"

    # if ps auxf | grep "$GURU_BIN/guru" | grep "start" | grep -v "grep" >/dev/null ; then
    #         gr.msg -v1 -c yellow "daemon still running, try to 'sudo guru kill' again"
    #         gr.ind failed $daemon_indicator_key
    #         return 100
    #     else
    #         gr.msg -v3 -c white "kill verified"
    #         [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file
    #         gr.end $daemon_indicator_key
    #         return 0
    #     fi

    #IFS=$_ifs
}


daemon.day_change () {
# check is date changed and update pid file datestamp

    [[ -f /tmp/guru.daemon-pid ]] || return 1
    local now="d$(date +%Y-%m-%d)"
    local was="d$(stat -c '%x' /tmp/guru.daemon-pid | cut -d' ' -f1)"
    [[ "$now" == "$was" ]] && return 0
    gr.msg -t -c white "${FUNCNAME[0]}: $(date +%-d.%-m.%Y)"
    touch /tmp/guru.daemon-pid
    return 0
}


daemon.poll () {
# poller for modules

    source $GURU_RC
    source net.sh
    [[ $GURU_CORSAIR_ENABLED ]] && source $GURU_BIN/corsair.sh
    #[[ -f "/tmp/guru-stop.flag" ]] && rm -f "/tmp/guru-stop.flag"
    echo "$(sh -c 'echo "$PPID"')" > "$daemon_pid_file"
    system.flag rm fast
    system.flag rm stop
    GURU_FORCE=

    gr.end $daemon_indicator_key

    # DAEMON POLL LOOP
    while true ; do
        gr.msg -N -t -v3 -c aqua "daemon active" -k $daemon_indicator_key
        system.flag set running
        # to update configurations is user changes them
        source $GURU_RC

        # check is system suspended and perform needed actions
        if system.flag suspend ; then
                # restart ckb-next application to reconnect led pipe files
                gr.msg -N -t -v1 "daemon recovering from suspend.. "
                [[ $GURU_CORSAIR_ENABLED ]] && corsair.suspend_recovery
                system.flag rm suspend
                #gr.msg -c red -v4 "issue 20221120.1, daemon stalls here"
                sleep 15
                #gr.msg -c green -v4 "issue 20221120.1, it did continue"
            fi

        # if paused
        if system.flag pause ; then
                gr.end $daemon_indicator_key
                gr.msg -N -t -v1 -c yellow "daemon paused "
                gr.ind pause $daemon_indicator_key
                for (( i = 0; i < 150; i++ )); do
                    system.flag pause || break
                    system.flag stop && break
                    system.flag suspend && break
                    sleep 2
                done
                system.flag rm pause
                gr.end $daemon_indicator_key
                gr.msg -v1 -t -c aqua "daemon continued" #-k $daemon_indicator_key

            fi

        if system.flag stop ; then
                gr.end $daemon_indicator_key
                gr.msg -N -t -v1 "daemon got requested to stop "
                gr.ind cancel $daemon_indicator_key
                daemon.stop
                return $?
            fi

        gr.ind doing -k $daemon_indicator_key
        # go trough poll list
        for ((i=1 ; i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; i++)) ; do
                module=${GURU_DAEMON_POLL_ORDER[i-1]}
                case $module in
                    null|empty|na|NA|'-')
                        gr.msg -v3 -c dark_grey "$i:$module skipping "
                        ;;
                    *)
                        gr.msg -v2 -c dark_golden_rod "$i:$module: "

                        if [[ -f "$GURU_BIN/$module.sh" ]]; then
                                source "$GURU_BIN/$module.sh"
                                $module.main poll status
                            else
                                gr.msg -v1 -c yellow "${FUNCNAME[0]}: module '$module' not installed"
                            fi
                        ;;
                    esac
            done


        gr.end $daemon_indicator_key
        gr.ind done $daemon_indicator_key
        gr.msg -n -v2 "sleep ${GURU_DAEMON_INTERVAL}s: "

        local _seconds=
        for (( _seconds = 0; _seconds < $GURU_DAEMON_INTERVAL; _seconds++ )) ; do
                system.flag stop && break
                system.flag suspend && continue
                system.flag pause && continue
                system.flag fast && continue || sleep 1
                gr.msg -v2 -n -c reset "."
                daemon.day_change
            done
        gr.msg -v2 ""
    done

    gr.msg -N -t -v1 "daemon got tired, dropped out and died"
    gr.ind cancel $daemon_indicator_key
    daemon.stop
}


daemon.process_opts () {
# argument parser

    TEMP=`getopt --long -o "vVflu:h:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -v ) export GURU_VERBOSE=1      ; shift     ;;
            -V ) export GURU_VERBOSE=2      ; shift     ;;
            -f ) export GURU_FORCE=true     ; shift     ;;
            -l ) export GURU_LOGGING=true   ; shift     ;;
            -u ) export GURU_USER_NAME=$2   ; shift 2   ;;
            -h ) export GURU_HOSTNAME=$2    ; shift 2   ;;

             * ) break                  ;;
        esac
    done;
    _arg="$@"
    [[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"
}


daemon.systemd () {
# systemd method

    local cmd=$1 ; shift
    case $cmd in
            install|remove|enable|disable)
                        daemon.systemd_$cmd $@
                        return $?
                    ;;
              * ) gr.msg -c yellow "unknown command '$cmd'"
                  return 127
        esac
}


daemon.systemd_install () {
# setup systemd service

    temp="/tmp/starter.temp"
    gr.msg -v1 -V2 -n "setting starter script.. "
    gr.msg -v2 -n "setting starter script $daemon_service_script.. "

    if ! [[ -d  ${daemon_service_script%/*} ]]; then
        mkdir -p ${daemon_service_script%/*} \
        || gr.msg -x 100 "no permission to create folder ${daemon_service_script%/*}"
    fi

    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
[Unit]
Description=guru daemon process manager

[Service]
ExecStart=bash -c '/home/$USER/bin/core.sh start'
ExecStop=bash -c '/home/$USER/bin/core.sh stop'
Type=simple
Restart=always
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
EOL

    if ! cp -f $temp $daemon_service_script ; then
            gr.msg -c red "script copy failed"
            return 101
        fi

    chmod +x $daemon_service_script
    systemctl --user enable guru.service
    systemctl --user daemon-reload
    systemctl --user restart guru.service

    # clean
    rm -f $temp
    gr.msg -v1 -c green "ok"
    return 0

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        daemon.process_opts $@
        daemon.main $ARGUMENTS
        exit $?
    fi
