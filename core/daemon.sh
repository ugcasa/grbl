#!/bin/bash
# guru client background servicer casa@ujo.guru 2020

declare -xg daemon_service_script="$HOME/.config/systemd/user/guru.service"
declare -xg daemon_pid_file="/tmp/guru.daemon-pid"
declare -axg GURU_DAEMON_PID=
declare -xg daemon_arguments=

# source $GURU_BIN/system.sh
source $GURU_BIN/flag.sh

daemon.main () {
# daemon main command parser

    daemon.process_opts $@
    gr.debug "$FUNCNAME: $daemon_arguments"
    case ${daemon_arguments[0]} in
            start|stop|status|help|kill|poll|pid)
                daemon.${daemon_arguments[0]}
                return $?
                ;;
            install|remove)
                daemon.systemd ${daemon_arguments[0]}
                return $?
                ;;

            *)  gr.msg "unknown daemon command"   ; return 1  ;;
        esac
    return 0
}


daemon.help () {
# general help

    gr.msg -v1 -c white "guru daemon help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL daemon [start|stop|status|kill|poll]"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " start        start daemon (same as $GURU_CALL start)"
    gr.msg -v1 " stop         stop daemon (same as $GURU_CALL stSop)"
    gr.msg -v1 " status       printout status"
    gr.msg -v1 " pid          get daemon pid(s)"
    gr.msg -v1 " kill         kill jammed daemon"
    gr.msg -v2 " poll         start polling process"
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GURU_CALL daemon status"
    gr.msg -v2
}


daemon.pid () {
# fetch pid for running daemon preocess(es)
# this cannot find preocess of sourced and then called daemon.start function

    local _ifs=$IFS; IFS=$'\n'
    process_list=($(ps auxf | \
        grep -v grep | \
        grep -e "$GURU_BIN/$GURU_CALL start" \
             -e "$GURU_BIN/$GURU_CALL daemon start" \
             -e "$GURU_BIN/$GURU_CALL active" \
             -e "$GURU_BIN/daemon.sh start" | \
        grep -e "$USER"))

    IFS=$_ifs

    GURU_DAEMON_PID=()
    descriptions=("guru-cli daemon" "corsair animation" "sub process" "sub process")
    for (( i = 0; i < ${#process_list[@]}; i++ )); do
            GURU_DAEMON_PID=(${GURU_DAEMON_PID[@]} $(echo ${process_list[$i]} | xargs | cut -f2 -d' '))
            gr.msg -n -c light_blue "${GURU_DAEMON_PID[$i]} "
            gr.msg "${descriptions[$i]}"
    done
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
            gr.msg -v1 -c red "not running" -k $GURU_DAEMON_INDICATOR_KEY
            [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file && gr.msg -n -v2 "previous PID removed "
            return 127
        fi

    if [[ ${#GURU_DAEMON_PID[@]} -gt 2 ]]; then
            gr.msg -v1 -c yellow "multiple daemons detected, get a shotgun.." -k $GURU_DAEMON_INDICATOR_KEY
            gr.msg -v2 "kill daemons by '$GURU_CALL daemon kill' command and then start new one by '$GURU_CALL start'"
            # gr.msg -c -v2 light_blue "${GURU_DAEMON_PID[@]} "
            return 0
        fi

    if ! [[ $GURU_DAEMON_PID -eq $last_pid ]]; then
            gr.msg -n -v2 -c yellow "previous PID mismatch " -k $GURU_DAEMON_INDICATOR_KEY
            echo $GURU_DAEMON_PID >$daemon_pid_file
            # retest
            last_pid="$(cat $daemon_pid_file)"
            [[ $GURU_DAEMON_PID -eq $last_pid ]] \
                && gr.msg -n -v2 -c white "fixed "\
                || gr.msg -n -v2 -c red "failed to update previous PID " -k $GURU_DAEMON_INDICATOR_KEY
        fi

    #export $GURU_DAEMON_PID
    gr.msg -v0 -V1 "$GURU_DAEMON_PID"
    gr.msg -v1 -c green "running"
    gr.ind done $GURU_DAEMON_INDICATOR_KEY
    return 0
}


daemon.start () {
# start daemon

    if [[ -f "$daemon_pid_file" ]]; then
            local last_pid=$(cat "$daemon_pid_file")
            gr.msg -v2 "${FUNCNAME[0]}: killing $last_pid"
            kill -9 $last_pid || kill -9 $GURU_DAEMON_PID
            sleep 2
        fi

    if flag.check suspend ; then
            [[ $GURU_CORSAIR_ENABLED ]] && source $GURU_BIN/corsair.sh
            flag.rm suspend
            corsair.systemd_restart
        fi

    gr.ind doing $GURU_DAEMON_INDICATOR_KEY

    #for module in ${GURU_DAEMON_POLL_ORDER[@]} ; do
    for ((i=1 ; i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GURU_DAEMON_POLL_ORDER[i-1]}
        case $module in
            null|empty )
                ;;
            *)
                gr.debug "$i:$module: "
                if [[ -f "$GURU_BIN/$module.sh" ]]; then
                        source "$GURU_BIN/$module.sh"
                        # gr.msg -v3 ": $GURU_BIN/$GURU_BIN/$module.sh"
                        $module.poll start
                    else
                        gr.msg -v1 -c yellow "${FUNCNAME[0]}: module $module not installed" \
                            -k "f$(gr.poll $module)"
                    fi
                ;;
            esac
        done

    gr.end $GURU_DAEMON_INDICATOR_KEY
    gr.msg -v1 "start polling" -c reset -k $GURU_DAEMON_INDICATOR_KEY
    daemon.poll &
}


daemon.stop () {
# stop daemon

    flag.rm stop
    gr.msg -N -n -V1 -c white "stopping guru-cli.. "
    # if pid file is not exist
    if ! [[ -f "$daemon_pid_file" ]]; then
            gr.msg "${FUNCNAME[0]}: daemon not running"
            gr.msg -v1 "start daemon by typing 'guru start'"
            return 0
        fi

    local _pid=$(cat $daemon_pid_file)

    gr.msg -t -v1 "stopping modules.. "

    for ((i=1 ; i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GURU_DAEMON_POLL_ORDER[i-1]}
        #gr.msg -v3 -c dark_golden_rod "$i $module"
        case $module in
            null|empty)
                #gr.msg -v3 -c dark_grey "skipping $module"
                ;;
            * )
                gr.debug "$FUNCNAME $i:$module"

                if ! grep -q -e $module.poll end | $GURU_BIN/$module.sh ; then
                    gr.msg -v1 "$FUNCNAME: $module has no poll function"
                    return 12
                fi

                if [[ -f "$GURU_BIN/$module.sh" ]]; then
                        source "$GURU_BIN/$module.sh"
                        $module.poll end
                    else
                        gr.msg -v1 "${FUNCNAME[0]}: module '$module' not installed"
                    fi
                ;;
            esac
        done

    gr.msg -t -v1 "stopping guru-daemon.. "

    [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file

    flag.rm running

    if ! kill -15 "$_pid" ; then
        gr.msg -V1 -c yellow "error $?, retry" -k $GURU_DAEMON_INDICATOR_KEY

        if kill -9 "$_pid" ; then
             gr.end $GURU_DAEMON_INDICATOR_KEY
             gr.msg -V1 -c green "ok" -k $GURU_DAEMON_INDICATOR_KEY
        else
             gr.msg -V1 -c red "failed to kill daemon pid: $_pid"
             gr.ind failed $GURU_DAEMON_INDICATOR_KEY
            return 124
        fi
    else
        gr.end $GURU_DAEMON_INDICATOR_KEY
        gr.msg -V1 -c green "ok" -k $GURU_DAEMON_INDICATOR_KEY
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
                && gr.msg -v1 -c green "ok" -k $GURU_DAEMON_INDICATOR_KEY \
                || gr.msg -v1 -c red "failed" -k $GURU_DAEMON_INDICATOR_KEY
        done

    if daemon.status ; then
            gr.msg -c red "failed to kill daemons" -k $GURU_DAEMON_INDICATOR_KEY
        else
            gr.msg -v1 -c green "done" -k $GURU_DAEMON_INDICATOR_KEY
        fi
}


daemon.day_change () {
# check is date changed and update pid file datestamp

    [[ -f /tmp/guru.daemon-pid ]] || return 1
    local now="d$(date +%Y-%m-%d)"
    local was="d$(stat -c '%x' /tmp/guru.daemon-pid | cut -d' ' -f1)"
    [[ "$now" == "$was" ]] && return 0
    gr.msg -v1 -t -c white "${FUNCNAME[0]}: $(date +%-d.%-m.%Y)"
    touch /tmp/guru.daemon-pid
    return 0
}


daemon.poll () {
# poller for modules

    local _seconds=
    source $GURU_RC
    source net.sh
    source os.sh
    [[ $GURU_CORSAIR_ENABLED ]] && source $GURU_BIN/corsair.sh
    #[[ -f "/tmp/guru-stop.flag" ]] && rm -f "/tmp/guru-stop.flag"
    echo "$(sh -c 'echo "$PPID"')" > "$daemon_pid_file"
    flag.rm fast
    flag.rm stop
    GURU_FORCE=
    deamon_sum=$(sum $GURU_BIN/daemon.sh | cut -d" " -f1)

    #source_timestamp=$(stat -c %Y $GURU_BIN/daemon.sh)

    gr.end $GURU_DAEMON_INDICATOR_KEY

    # DAEMON POLL LOOP
    while true ; do
        gr.msg -N -t -v3 -c aqua "daemon active" -k $GURU_DAEMON_INDICATOR_KEY
        flag.set running

        # check is system suspended and perform needed actions
        if flag.check suspend ; then
                # restart ckb-next application to reconnect led pipe files
                gr.msg -N -t -v1 "daemon recovering from suspend.. "
                [[ $GURU_CORSAIR_ENABLED ]] && corsair.suspend_recovery
                flag.rm suspend
                #gr.msg -c red -v4 "issue 20221120.1, daemon stalls here"
                sleep 15
                #gr.msg -c green -v4 "issue 20221120.1, it did continue"
            fi

        # if paused
        if flag.check pause ; then
                gr.end $GURU_DAEMON_INDICATOR_KEY
                gr.msg -N -t -v1 -c yellow "daemon paused "
                gr.ind pause $GURU_DAEMON_INDICATOR_KEY
                for (( i = 0; i < 150; i++ )); do
                    flag.check pause || break
                    flag.check stop && break
                    flag.check suspend && break
                    sleep 2
                done
                flag.rm pause
                sleep 1
                gr.end $GURU_DAEMON_INDICATOR_KEY
                gr.msg -v1 -t -c aqua "daemon continued" #-k $GURU_DAEMON_INDICATOR_KEY
            fi

        if flag.check stop ; then
                gr.end $GURU_DAEMON_INDICATOR_KEY
                gr.msg -N -t -v1 "daemon got requested to stop "
                gr.ind cancel $GURU_DAEMON_INDICATOR_KEY
                daemon.stop
                return $?
            fi

        gr.ind doing -k $GURU_DAEMON_INDICATOR_KEY
        # to update configurations is user changes them
        source $GURU_RC
        # unset caps lock.
        # some way caps lock seems to active even the button is set to do other shit =bubblecum
        os.capslock state >/dev/null && os.capslock off

        if [[ $deamon_sum != $(sum $GURU_BIN/daemon.sh | cut -d" " -f1) ]]; then
                gr.msg -c deep_pink -t "daemon restart requested"
            fi

        # go trough poll list
        for ((daemon_i=1 ; daemon_i <= ${#GURU_DAEMON_POLL_ORDER[@]} ; daemon_i++)) ; do
                module=${GURU_DAEMON_POLL_ORDER[daemon_i-1]}
                flag.check pause && break
                case $module in
                    null|empty|na|NA|'-')
                        gr.msg -v3 -c dark_grey "$daemon_i:$module skipping "
                        ;;
                    *)
                        gr.debug "$daemon_i: ${module}.sh function ${module}.status "

                        if [[ -f "$GURU_BIN/$module.sh" ]]; then
                                source "$GURU_BIN/$module.sh"
                                $module.main poll status 2>/tmp/daemon.error
                            else
                                gr.msg -v1 -c dark_gray "${FUNCNAME[0]}: module '$module' not installed"
                            fi
                        ;;
                    esac
            done

        gr.end $GURU_DAEMON_INDICATOR_KEY
        gr.ind done $GURU_DAEMON_INDICATOR_KEY
        touch $daemon_pid_file
        gr.msg -n -v2 "sleep : "

        for (( _seconds = 0; _seconds < $GURU_DAEMON_INTERVAL; _seconds++ )) ; do
                flag.check stop && break
                flag.check suspend && continue
                flag.check pause && continue
                flag.check fast && continue || sleep 1
                # gr.msg -v2 -n -c reset "."
                [[ $GURU_VERBOSE -gt 1 ]] && printf '%s %s %s\r' "sleep for" "$(( $GURU_DAEMON_INTERVAL - $_seconds ))" "seconds"
                daemon.day_change
            done
        gr.msg -v2 ""
    done

    gr.msg -N -t -v1 "daemon got tired, dropped out and died"
    gr.ind cancel $GURU_DAEMON_INDICATOR_KEY
    daemo-v1 n.stop
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
    [[ "$_arg" != "--" ]] && export daemon_arguments="${_arg#* }"
    gr.debug "$FUNCNAME: $daemon_arguments"
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
    daemon.main $@
    exit $?
fi
