#!/bin/bash
# guru client background servicer
# casa@ujo.guru 2020

source $GURU_BIN/lib/common.sh

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
    gmsg -v 1 -c white "guru daemon help -----------------------------------------------"
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
            local _pid="$GURU_SYSTEM_MOUNT/.daemon-pid"
            gmsg -v 1 "$_pid"
        else
            gmsg -v 1 "no pid reserved"
            _err=$((_err+10))
        fi

    if ps auxf | grep "guru-daemon" | grep -v "grep"  | grep -v "status" >/dev/null ; then
            gmsg -v 1 "running"
        else
            gmsg -v 1 "not running"
            _err=$((_err+10))
        fi

    return $_err

}


daemon.start () {

    if [[ -f "$GURU_SYSTEM_MOUNT/.daemon-pid" ]] ; then
            local _pid=$(cat "$GURU_SYSTEM_MOUNT/.daemon-pid")
            gmsg -v 1 "killing $_pid"
            kill -9 $_pid
        fi

    # call start method of module
    for module in ${GURU_DAEMON_POLL_LIST[@]} ; do

        if [[ -f "$GURU_BIN/$module.sh" ]] ; then
                source "$GURU_BIN/$module.sh"               # ; echo "module: $GURU_BIN/$GURU_BIN/$module.sh"
                $module.main start                          # ; echo "command: $module.main start"
            else
                gmsg -v1 "module $module not installed"
            fi

        done

    daemon.poll &
}


daemon.stop () {
    [[ -f "$HOME/.guru-stop" ]] && rm "$HOME/.guru-stop"     # remove action

    if ! [[ -f "$GURU_SYSTEM_MOUNT/.daemon-pid" ]] ; then   # if pid file is not exist
            gmsg "daemon not running"
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
                gmsg -v 1 "module '$module' not installed"
            fi

        done

    gmsg -v1 "stopping guru-daemon.. "
    [[ -f $GURU_SYSTEM_MOUNT/.daemon-pid ]] && rm -f $GURU_SYSTEM_MOUNT/.daemon-pid
    kill -9 "$_pid" || gmsg -v 1 "$ERROR guru-daemon pid $_pid cannot be killed, try to 'guru kill $_pid'"

}



daemon.kill () {
    if pkill guru-daemon ; then
            gmsg -v1 "guru-daemon killed.."
        else
            gmsg -v1 "guru-daemon not running"
        fi

    if ps auxf | grep "guru-daemon" | grep -v "grep" >/dev/null ; then
            gmsg -v1 "$ERROR guru-daemon cannot be killed, try to 'sudo guru kill'"
            return 100
        else
            gmsg -v1 "kill verified"
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
        for module in ${GURU_DAEMON_POLL_LIST[@]} ; do
                if [[ -f "$GURU_BIN/$module.sh" ]] ; then
                        source "$GURU_BIN/$module.sh"
                        $module.main status                         # ; echo "command: $module.main status"
                    else
                        gmsg -v 1 "module $module not installed"    # ; echo "mobule: $GURU_BIN/${_poll_list[$_i]}.sh"
                    fi
            done
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
