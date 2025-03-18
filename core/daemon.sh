#!/bin/bash
# grbl client background servicer casa@ujo.guru 2020

__daemon=$(readlink --canonicalize --no-newline $BASH_SOURCE)
source $GRBL_BIN/flag.sh

declare -xg daemon_service_script="$HOME/.config/systemd/user/grbl.service"
declare -xg daemon_pid_file="/tmp/$USER/grbl.daemon-pid"
declare -axg GRBL_DAEMON_PID=
declare -xg daemon_arguments=

daemon.main () {
# daemon main command parser
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    local command=$1
    shift

    case $command in
            start|stop|status|help|kill|poll|ps|caps|pause|fast|end)
                daemon.$command $@
                return $?
                ;;
            install|remove)
                daemon.systemd $@
                return $?
                ;;

            *)  gr.msg -e1 "unknown daemon command"  ; return 1  ;;
        esac
    return 0
}


daemon.help () {
# general help
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    gr.msg -v1 -c white "grbl daemon help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL daemon [start|stop|status|end|kill|poll|pause]"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " status       printout status"
    gr.msg -v1 " start        start daemon (same as $GRBL_CALL start)"
    gr.msg -v1 " pause        pause and release daemon polling process"
    gr.msg -v1 " stop         stop daemon (same as $GRBL_CALL stSop)"
    gr.msg -v1 " stop         stop daemon (same as $GRBL_CALL stSop)"
    gr.msg -v1 " kill         kill jammed daemon"
    gr.msg -v1 " pid          get daemon pid(s)"
    gr.msg -v2 " poll         start polling process"
    gr.msg -v1 " fast         daemon poll interval to minimal (toggle)"
    gr.msg -v3 " caps         let module handle caps lock presses"
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GRBL_CALL daemon status"
    gr.msg -v2
}


daemon.ps () {
# get daemon process list (not solid, more like guessing ;)
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"# this function can be used to fill global GRBL_DAEMON_PID, use verbose 0

    local color=aqua
    local verbosity=1

    # get lines from process list and select valuable lines
    local _ifs=$IFS; IFS=$'\n'
    local process_list=($(ps -ax -o pid,user,args --sort=pid --no-headers | \
                            grep -v grep | \
                            grep -e "$GRBL_USER" | \
                            grep -e "sleep" \
                                 -e "$GRBL_BIN/$GRBL_CALL start" \
                                 -e "$GRBL_BIN/$GRBL_CALL active" \
                                 -e "$GRBL_BIN/daemon.sh" \
                                 -e "daemon.main" \
                                 -e "$GRBL_BIN/$GRBL_CALL daemon" ))
    IFS=$_ifs

    # go through list of lines collected from ps
    GRBL_DAEMON_PID=()
    for (( i = 0; i < ${#process_list[@]}; i++ )); do
            GRBL_DAEMON_PID+=( $(echo ${process_list[$i]} | xargs | cut -f1 -d" ") )

            # find patterns of different kind of daemon sessions (yes, messy clean later and like it matters)
            case $(echo ${process_list[$i]} | xargs | cut -f3- -d' ') in
                *active)
                    description="active daemon "
                    # [[ ${GRBL_DAEMON_PID[$i]} -lt 10000 ]] && description="$description (initial)"
                    color=aqua_marine
                    verbosity=1
                    ;;
                *daemon.sh*)
                    description="direct start"
                    color=white
                    verbosity=1
                    ;;
                *start)
                    description="manual start"
                    color=aqua
                    verbosity=1
                    ;;
                sleep*)
                    description="sleeper loop"
                    color=dark_grey
                    verbosity=1
                    ;;
                *daemon*ps*)
                    description="this process"
                    color=black
                    verbosity=2
                    ;;
                *)
                    description="unknown"
                    color=black
                    verbosity=2
            esac

            # printout if verbose level is more than one
            gr.msg -v $verbosity -h -n "[$i] "
            gr.msg -v $verbosity -w8 -n -c light_blue "${GRBL_DAEMON_PID[$i]} "
            gr.msg -v $verbosity -w15 -n -c $color "$description "
            gr.msg -v $verbosity -n -v2 "$(echo ${process_list[$i]} | xargs | cut -f3- -d' ') "
            gr.msg -v $verbosity
    done
}


daemon.status () {
# printout status of daemon
# this function can be used to fill global GRBL_DAEMON_PID, use verbose 0 (conflict with pid function)
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"

    if [[ -f "$daemon_pid_file" ]]; then
            local last_pid="$(cat $daemon_pid_file)"
            gr.msg -n -v2 "(prev. PID: $last_pid) "
        fi

    # get current list of grbl processes
    daemon.ps >/dev/null

    if ! [[ $GRBL_DAEMON_PID ]]; then
            gr.msg -v1 -c red "not running" -k $GRBL_DAEMON_INDICATOR_KEY
            [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file && gr.msg -n -v2 "previous PID removed "
            return 127
        fi

    # if [[ ${#GRBL_DAEMON_PID[@]} -gt 2 ]]; then
    #         gr.msg -v1 -c yellow "multiple daemons detected, get a shotgun.." -k $GRBL_DAEMON_INDICATOR_KEY
    #         gr.msg -v2 "kill daemons by '$GRBL_CALL daemon kill' command and then start new one by '$GRBL_CALL start'"
    #         # gr.msg -c -v2 light_blue "${GRBL_DAEMON_PID[@]} "
    #         return 0
    #     fi

    if ! [[ $GRBL_DAEMON_PID -eq $last_pid ]]; then
            gr.msg -n -v2 -c yellow "previous PID mismatch " -k $GRBL_DAEMON_INDICATOR_KEY
            echo $GRBL_DAEMON_PID >$daemon_pid_file
            # retest
            last_pid="$(cat $daemon_pid_file)"
            [[ $GRBL_DAEMON_PID -eq $last_pid ]] \
                && gr.msg -n -v2 -c white "fixed "\
                || gr.msg -n -v2 -c red "failed to update previous PID " -k $GRBL_DAEMON_INDICATOR_KEY
        fi

    gr.msg -n -t "$FUNCNAME: "
    gr.msg -v0 -V1 "$GRBL_DAEMON_PID"
    gr.msg -v1 -c green "running"
    return 0
}


daemon.start () {
# start daemon
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    if [[ -f "$daemon_pid_file" ]]; then
            local last_pid=$(cat "$daemon_pid_file")
            gr.msg -v2 "${FUNCNAME[0]}: killing $last_pid"
            kill -9 $last_pid || kill -9 $GRBL_DAEMON_PID
            sleep 2
        fi

    if flag.check suspend ; then
            [[ $GRBL_CORSAIR_ENABLED ]] && source $GRBL_BIN/corsair.sh
            flag.rm suspend
            corsair.systemd_restart
        fi

    gr.ind doing $GRBL_DAEMON_INDICATOR_KEY

    #for module in ${GRBL_DAEMON_POLL_ORDER[@]} ; do
    for ((i=1 ; i <= ${#GRBL_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GRBL_DAEMON_POLL_ORDER[i-1]}
        case $module in
            null|empty )
                ;;
            *)
                gr.debug "$i:$module: "
                if [[ -f "$GRBL_BIN/$module.sh" ]]; then
                        source "$GRBL_BIN/$module.sh"
                        # gr.msg -v3 ": $GRBL_BIN/$GRBL_BIN/$module.sh"
                        $module.poll start
                    else
                        gr.msg -v1 -c yellow "${FUNCNAME[0]}: module $module not installed" \
                            -k "f$(gr.poll $module)"
                    fi
                ;;
            esac
        done

    gr.end $GRBL_DAEMON_INDICATOR_KEY
    gr.msg -v1 "start polling" -c reset -k $GRBL_DAEMON_INDICATOR_KEY
    daemon.poll &
}


daemon.stop () {
# stop daemon
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    flag.rm stop
    gr.msg -N -n -V1 -c white "stopping grbl.. "
    # if pid file is not exist
    if ! [[ -f "$daemon_pid_file" ]]; then
            gr.msg "${FUNCNAME[0]}: daemon not running"
            gr.msg -v1 "start daemon by typing 'grbl start'"
            return 0
        fi

    local _pid=$(cat $daemon_pid_file)

    gr.msg -t -v1 "stopping modules.. "

    for ((i=1 ; i <= ${#GRBL_DAEMON_POLL_ORDER[@]} ; i++)) ; do

        module=${GRBL_DAEMON_POLL_ORDER[i-1]}
        #gr.msg -v3 -c dark_golden_rod "$i $module"
        case $module in
            null|empty)
                #gr.msg -v3 -c dark_grey "skipping $module"
                ;;
            * )
                gr.debug "$FUNCNAME $i:$module"

                if ! grep -q -e $module.poll end | $GRBL_BIN/$module.sh ; then
                    gr.msg -v1 "$FUNCNAME: $module has no poll function"
                    return 12
                fi

                if [[ -f "$GRBL_BIN/$module.sh" ]]; then
                        source "$GRBL_BIN/$module.sh"
                        $module.poll end
                    else
                        gr.msg -v1 "${FUNCNAME[0]}: module '$module' not installed"
                    fi
                ;;
            esac
        done

    gr.msg -t -v1 "stopping grbl-daemon.. "

    [[ -f $daemon_pid_file ]] && rm -f $daemon_pid_file

    flag.rm running

    if ! kill -15 "$_pid" ; then
        gr.msg -V1 -c yellow "error $?, retry" -k $GRBL_DAEMON_INDICATOR_KEY

        if kill -9 "$_pid" ; then
            gr.end $GRBL_DAEMON_INDICATOR_KEY
            gr.msg -V1 -c green "ok" -k $GRBL_DAEMON_INDICATOR_KEY
        else
            gr.msg -V1 -c red "failed to kill daemon pid: $_pid"
            gr.ind failed $GRBL_DAEMON_INDICATOR_KEY
            return 124
        fi
    else
        gr.end $GRBL_DAEMON_INDICATOR_KEY
        gr.msg -V1 -c green "ok" -k $GRBL_DAEMON_INDICATOR_KEY
    fi


}


daemon.pause () {
# pause daemon polling process
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"    source flag.sh
    flag.toggle pause
}


daemon.fast () {
# set daemon poll interval to minimal
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"    source flag.sh
    flag.toggle fast
}


daemon.end () {
# ask daemon to stop polling
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"    source flag.sh
    flag.toggle stop
}


daemon.kill () {
# force stop daemon
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"    daemon.ps
    local gpid=$1

    [[ $gpid ]] || read -p "select process: " gpid
    [[ $gpid ]] || return 0
    case $gpid in *[!0-9]*) gr.msg -e0 "'$gpid' geh" ; return 1 ; esac

    if [[ $gpid -ge ${#GRBL_DAEMON_PID[@]} ]] || [[ $gpid -lt 0 ]] ; then
        gr.msg -e0 "$gpid/$(( ${#GRBL_DAEMON_PID[@]} -1 )) geh"
        return 1
    fi

    if ! [[ -d /proc/${GRBL_DAEMON_PID[$gpid]} ]]; then
        gr.msg -v1 "gone already"
        return 0
    fi

    if kill -15 ${GRBL_DAEMON_PID[$gpid]} ; then
        gr.msg -c green -v1 "killed"
        return 0
    else
        gr.msg -e1 "failed"
        return 100
    fi
}


daemon.day_change () {
# check is date changed and update pid file datestamp
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    [[ -f /tmp/$USER/grbl.daemon-pid ]] || return 1
    local now="d$(date +%Y-%m-%d)"
    local was="d$(stat -c '%x' /tmp/$USER/grbl.daemon-pid | cut -d' ' -f1)"
    [[ "$now" == "$was" ]] && return 0
    gr.msg -v1 -t -c white "${FUNCNAME[0]}: $(date +%-d.%-m.%Y)"
    touch /tmp/$USER/grbl.daemon-pid
    return 0
}


# # TBD interesting idea, pretty sure this is not in use anywhere, disabled
# daemon.caps () {
# # what to do if user presses caps lock when caps channel is connected to module
#    gr.msg -v4 -c bluedaemon$__os [$LINENO] $FUNCNAME '$@'"#     gr.debug "$FUNCNAME caps channel actived"
#     gnome-terminal --hide-menubar --geometry 50x10 --zoom 0.7 --hide-menubar --title "mqtt server feed"  -- $GRBL_BIN/grbl stop
#     sleep 3
#     true
# }


daemon.poll () {
# runs module poll function to printout module status
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    local _seconds=
    source $GRBL_RC
    source net.sh
    source os.sh
    [[ $GRBL_CORSAIR_ENABLED ]] && source $GRBL_BIN/corsair.sh
    #[[ -f "/tmp/$USER/grbl-stop.flag" ]] && rm -f "/tmp/$USER/grbl-stop.flag"
    echo "$(sh -c 'echo "$PPID"')" > "$daemon_pid_file"
    flag.rm fast
    flag.rm stop
    GRBL_FORCE=
    deamon_sum=$(sum $GRBL_BIN/daemon.sh | cut -d" " -f1)

    #source_timestamp=$(stat -c %Y $GRBL_BIN/daemon.sh)

    gr.end $GRBL_DAEMON_INDICATOR_KEY
    #gr.msg -v2 -c aqua "$module" -k $GRBL_DAEMON_INDICATOR_KEY

    # DAEMON POLL LOOP
    while true ; do
        gr.msg -N -t -v3 -c aqua "daemon active" -k $GRBL_DAEMON_INDICATOR_KEY

        flag.set running

        # check is system suspended and perform needed actions
        if flag.check suspend ; then
                # restart ckb-next application to reconnect led pipe files
                gr.msg -N -t -v1 "daemon recovering from suspend.. "
                [[ $GRBL_CORSAIR_ENABLED ]] && corsair.suspend_recovery
                flag.rm suspend
                #gr.msg -c red -v4 "issue 20221120.1, daemon stalls here"
                sleep 15
                #gr.msg -c green -v4 "issue 20221120.1, it did continue"
            fi

        # if paused
        if flag.check pause ; then
                gr.end $GRBL_DAEMON_INDICATOR_KEY
                gr.msg -N -t -v1 -c yellow "daemon paused "
                gr.ind pause $GRBL_DAEMON_INDICATOR_KEY
                for (( i = 0; i < 150; i++ )); do
                    flag.check pause || break
                    flag.check stop && break
                    flag.check suspend && break
                    sleep 2
                done
                flag.rm pause
                sleep 1
                gr.end $GRBL_DAEMON_INDICATOR_KEY
                gr.msg -v1 -t -c aqua "daemon continued" #-k $GRBL_DAEMON_INDICATOR_KEY
            fi

        if flag.check stop ; then
                gr.end $GRBL_DAEMON_INDICATOR_KEY
                gr.msg -N -t -v1 "daemon got requested to stop "
                gr.ind cancel $GRBL_DAEMON_INDICATOR_KEY
                daemon.stop
                return $?
            fi

        #gr.ind doing -k $GRBL_DAEMON_INDICATOR_KEY
        # to update configurations is user changes them
        source $GRBL_RC
        # unset caps lock.
        # some way caps lock seems to active even the button is set to do other shit =bubblecum
        os.capslock state >/dev/null && os.capslock off

        if [[ $deamon_sum != $(sum $GRBL_BIN/daemon.sh | cut -d" " -f1) ]]; then
                gr.msg -c deep_pink -t "daemon restart requested"
            fi

        # go trough poll list
        for ((daemon_i=1 ; daemon_i <= ${#GRBL_DAEMON_POLL_ORDER[@]} ; daemon_i++)) ; do
            module=${GRBL_DAEMON_POLL_ORDER[daemon_i-1]}
            flag.check pause && break

            gr.msg -v2 -c aqua_marine "$module" -k $GRBL_DAEMON_INDICATOR_KEY

            case $module in
                null|empty|na|NA|'-')
                    gr.msg -v3 -c dark_grey "$daemon_i:$module skipping "
                    ;;
                *)
                    gr.debug "$daemon_i: ${module}.sh function ${module}.status "

                    if [[ -f "$GRBL_BIN/$module.sh" ]]; then
                            source "$GRBL_BIN/$module.sh"
                            $module.main poll status 2>/tmp/$USER/daemon.error
                        else
                            gr.msg -v1 -c dark_gray "${FUNCNAME[0]}: module '$module' not installed"
                        fi
                    ;;
            esac
            gr.msg -n -c aqua -k $GRBL_DAEMON_INDICATOR_KEY
        done

        #gr.end $GRBL_DAEMON_INDICATOR_KEY
        gr.ind done $GRBL_DAEMON_INDICATOR_KEY

        touch $daemon_pid_file
        gr.msg -n -v2 "sleep : "

        for (( _seconds = 0; _seconds < $GRBL_DAEMON_INTERVAL; _seconds++ )) ; do
            flag.check stop && break
            flag.check suspend && continue
            flag.check pause && continue
            flag.check fast && continue || sleep 1
            # gr.msg -v2 -n -c reset "."
            [[ $GRBL_VERBOSE -gt 1 ]] && printf '%s %s %s\r' "sleep for" "$(( $GRBL_DAEMON_INTERVAL - $_seconds ))" "seconds"
            daemon.day_change
        done
        gr.msg -v2 ""
    done

    gr.msg -N -t -v1 "daemon got tired, dropped out and died"
    gr.ind cancel $GRBL_DAEMON_INDICATOR_KEY
}


daemon.systemd () {
# command parser for systemd methods
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
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
    gr.msg -v4 -c blue "$__daemon [$LINENO] $FUNCNAME '$@'"
    local temp="/tmp/$USER/starter.temp"
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
Description=grbl daemon process manager

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
    systemctl --user enable grbl.service
    systemctl --user daemon-reload
    systemctl --user restart grbl.service

    # clean
    rm -f $temp
    gr.msg -v1 -c green "ok"
    return 0

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    daemon.main $@
    exit $?
fi
