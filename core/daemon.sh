#!/bin/bash
# guru client background servicer
# casa@ujo.guru 2020

source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh

daemon.main () {
    argument="$1" ; shift
    case "$argument" in
            start|stop|status|help|kill|poll)
                daemon.$argument                ; return $? ;;
            *)  gmsg "unknown daemon command"   ; return 1  ;;
        esac
    return 0
}


daemon.help ( ) {
    gmsg -v 1 -c white "guru daemon help "
    gmsg -v 2
    gmsg -v 0 "usage:    $GURU_CALL daemon [start|stop|status|kill|poll]"
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " start        start daemon (same as $GURU_CALL start)"
    gmsg -v 1 " stop         stop daemon (same as $GURU_CALL stSop)"
    gmsg -v 1 " status       printout status"
    gmsg -v 1 " kill         kill jammed daemon"
    gmsg -v 2 " poll         start polling process"
    gmsg -v 2
    gmsg -v 1 -c white "example:"
    gmsg -v 1 "      $GURU_CALL daemon status"
    gmsg -v 2
}


daemon.status () {

    local _err=0

    if [[ -f "$GURU_SYSTEM_MOUNT/.daemon-pid" ]] ; then
            local _pid="$(cat $GURU_SYSTEM_MOUNT/.daemon-pid)"
            gmsg -v 1 -c green "${FUNCNAME[0]}: $_pid"
        else
            gmsg -v 1 -c black "${FUNCNAME[0]}: no pid reserved"
            _err=$((_err+10))
        fi

    if ps auxf | grep "guru start" | grep -v "grep"  | grep -v "status" >/dev/null ; then
            gmsg -v 1 -c green "${FUNCNAME[0]}: running"
        else
            gmsg -v 1 -c red "${FUNCNAME[0]}: not running"
            _err=$((_err+10))
        fi

    return $_err

}


daemon.start () {

    if [[ -f "$GURU_SYSTEM_MOUNT/.daemon-pid" ]] ; then
            local _pid=$(cat "$GURU_SYSTEM_MOUNT/.daemon-pid")
            gmsg -v 1 "${FUNCNAME[0]}:  killing $_pid"
            kill -9 $_pid
        fi

    # call start method of module
    for module in ${GURU_DAEMON_POLL_LIST[@]} ; do

        if [[ -f "$GURU_BIN/$module.sh" ]] ; then
                source "$GURU_BIN/$module.sh"               # ; echo "module: $GURU_BIN/$GURU_BIN/$module.sh"
                $module.main start                          # ; echo "command: $module.main start"
            else
                gmsg -v1 -c yellow "${FUNCNAME[0]}: module $module not installed"
            fi

        done

    daemon.poll &
}


daemon.stop () {
    [[ -f "$HOME/.guru-stop" ]] && rm "$HOME/.guru-stop"     # remove action

    if ! [[ -f "$GURU_SYSTEM_MOUNT/.daemon-pid" ]] ; then   # if pid file is not exist
            gmsg "${FUNCNAME[0]}: daemon not running"
            gmsg -v1 "start daemon by typing 'guru start'"
            return 0
        fi

    local _pid=$(cat $GURU_SYSTEM_MOUNT/.daemon-pid)

    gmsg -v1 "stopping modules.. "
    for module in ${GURU_DAEMON_POLL_LIST[@]} ; do

        if [[ -f "$GURU_BIN/$module.sh" ]] ; then
                source "$GURU_BIN/$module.sh"               # ; echo "module: $GURU_BIN/$GURU_BIN/$module.sh"
                $module.main end                            # ; echo "command: $module.main end"
            else
                gmsg -v 1 "${FUNCNAME[0]}: module '$module' not installed"
            fi

        done

    gmsg -v1 "stopping guru-daemon.. "
    [[ -f $GURU_SYSTEM_MOUNT/.daemon-pid ]] && rm -f $GURU_SYSTEM_MOUNT/.daemon-pid
    kill -9 "$_pid" || gmsg -v 1 "$ERROR guru-daemon pid $_pid cannot be killed, try to 'guru kill $_pid'"

}



daemon.kill () {
    if pkill guru ; then
            gmsg -v1 "${FUNCNAME[0]}: guru-daemon killed.."
        else
            gmsg -v1 "${FUNCNAME[0]}: guru-daemon not running"
        fi

    if ps auxf | grep "$GURU_BIN/guru" | grep "start" | grep -v "grep" >/dev/null ; then
            gmsg -v1 -c yellow "${FUNCNAME[0]}: daemon still running, try to 'sudo guru kill'"
            return 100
        else
            gmsg -v1 -c white "${FUNCNAME[0]}: kill verified"
            [[ -f $GURU_SYSTEM_MOUNT/.daemon-pid ]] && rm -f $GURU_SYSTEM_MOUNT/.daemon-pid
            return 0
        fi
}


daemon.poll () {
    source ~/.gururc2
    [[ -f "$HOME/.guru-stop" ]] && rm -f "$HOME/.guru-stop"
    echo "$(sh -c 'echo "$PPID"')" > "$GURU_SYSTEM_MOUNT/.daemon-pid"

    # DAEMON POLL LOOP
    while true ; do
        source ~/.gururc2                                           # to update configurations is user changes them
        corsair.main write esc magenta
        for module in ${GURU_DAEMON_POLL_LIST[@]} ; do
                if [[ -f "$GURU_BIN/$module.sh" ]] ; then
                        source "$GURU_BIN/$module.sh"
                        $module.main status
                        gmsg -v2 -t "${FUNCNAME[0]}: $module status $?"
                    else
                        gmsg -v1 -c yellow "${FUNCNAME[0]}: module $module not installed"
                        gmsg -v2 "${FUNCNAME[0]}: $GURU_BIN/${_poll_list[$_i]}.sh"
                    fi
                done
        corsair.main reset esc
        sleep $GURU_DAEMON_INTERVAL
        [[ -f "$HOME/.guru-stop" ]] && break                        # check is stop command given, exit if so
    done
    daemon.stop
}


daemon.process_opts () {                                            # argument parser

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


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then                        # user and platform settings (implement here, always up to date)
        source ~/.gururc2
        daemon.process_opts $@
        daemon.main $ARGUMENTS
        exit $?
    fi
