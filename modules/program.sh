#!/bin/bash
# guru client program functions
# casa@ujo.guru 2020-2021

source $GURU_BIN/common.sh

program.help () {
    gmsg -v1 -c white "guru-client program help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL program start|end|status|help|install|remove|single|sub|pub "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "         $GURU_CALL program status "
    gmsg -v2
}

# program.debug () {
#     export GURU_VERBOSE=1
#     export GURU_FLAG_COLOR=
#     program.status $@
#     return $?
# }

program.main () {
    # command parser
    program_indicator_key="f$(daemon.poll_order program)"
    last_programmer_file="$GURU_SYSTEM_MOUNT/program/program.last"
    #gmsg -c pink $last_programmer_file

    if ! [[ -d $GURU_SYSTEM_MOUNT/program ]] ; then
        source mount.sh
        mount.main mount system
        [[ $GURU_SYSTEM_MOUNT./online ]] && mkdir $GURU_SYSTEM_MOUNT/program
    fi

    # last programmer
    if [[ -f $last_programmer_file ]] ; then
            programmer="$(cat $last_programmer_file)"
        else
            programmer="pk2" # default programmer
            echo "$programmer" > $last_programmer_file
        fi

    local _cmd="$1" ; shift

    # programmer selection
    case "$_cmd" in
            pk2|pic)
                programmer="pk2"
                echo $programmer > $last_programmer_file
                shift ; _cmd="$@"
                ;;

            st-link|stlink|st)
                programmer="stlink"
                echo $programmer > $last_programmer_file
                shift ; _cmd="$@"
                ;;

            select|set)
                shift
                [[ "$1" ]] && programmer=$1
                shift ; _cmd="$@"
                ;;
        esac

    # check selection

    local _runnable="$GURU_BIN/program/$programmer.sh"
    # gmsg -c pink $_runnable

    if [[ -f "$_runnable" ]] ; then
            source "$_runnable"
        else
            gmsg -x 100 -c yellow "non valid programmer selected" -k $program_indicator_key
        fi

    gmsg -v2 "$programmer programmer selected"

    case "$_cmd" in

            status|help|install|remove|poll)
                $programmer.$_cmd "$@" ; return $? ;;
            *)
                gmsg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
        esac

    return 0
}


program.status () {
    # check program broker is reachable.
    # printout and signal by corsair keyboard indicator led - if available
    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    if program.online ; then
            gmsg -v1 -c green "broker available " -k $program_indicator_key
            return 0
        else
            gmsg -v1 -c red "broker unreachable " -k $program_indicator_key
            return 1
        fi

    gmsg "current programmer is $(cat $last_programmer_file)"


}


program.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: program status polling started" -k $program_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: program status polling ended" -k $program_indicator_key
            ;;
        status )
            $programmer.status
            ;;
        # *)
        #     ;;
        esac

}


program.install () {
    $programmer.install "$@" ; return $?
}


program.remove () {
    $programmer.remove "$@" ; return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    #source common.sh
    program.main "$@"
    exit "$?"
fi

