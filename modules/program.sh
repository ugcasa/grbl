#!/bin/bash
# grbl client program functions
# casa@ujo.guru 2020-2021
# TODO: https://www.instructables.com/How-to-Setup-AVR-Programming-Environment-on-Linux/
# TODO: https://developerhelp.microchip.com/xwiki/bin/view/software-tools/ides/x/archive/linux/

source $GRBL_BIN/common.sh
program_indicator_key="f8"

program.help () {
    gr.msg -v1 -c white "grbl program help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL program start|end|status|help|install|remove|single|sub|pub "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " remove                   remove installed requirements "
    gr.msg -v1 " remove                   remove installed requirements "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 "         $GRBL_CALL program status "
    gr.msg -v2
}

# program.debug () {
#     export GRBL_VERBOSE=1
#     export GRBL_FLAG_COLOR=
#     program.status $@
#     return $?
# }

program.main () {
    # command parser

    last_programmer_file="$GRBL_SYSTEM_MOUNT/program/program.last"
    #gr.msg -c pink $last_programmer_file

    if ! [[ -d $GRBL_SYSTEM_MOUNT/program ]] ; then
        source mount.sh
        mount.main mount system
        [[ $GRBL_SYSTEM_MOUNT./online ]] && mkdir $GRBL_SYSTEM_MOUNT/program
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

    local _runnable="$GRBL_BIN/program/$programmer.sh"
    # gr.msg -c pink $_runnable

    if [[ -f "$_runnable" ]] ; then
            source "$_runnable"
        else
            gr.msg -x 100 -c yellow "non valid programmer selected" -k $program_indicator_key
        fi

    gr.msg -v2 "$programmer programmer selected"

    case "$_cmd" in

            status|help|install|remove|poll)
                $programmer.$_cmd "$@" ; return $? ;;
            *)
                gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
        esac

    return 0
}


program.status () {
    # check program broker is reachable.
    # printout and signal by corsair keyboard indicator led - if available
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    if program.online ; then
            gr.msg -v1 -c green "broker available " -k $program_indicator_key
            return 0
        else
            gr.msg -v1 -c red "broker unreachable " -k $program_indicator_key
            return 1
        fi

    gr.msg "current programmer is $(cat $last_programmer_file)"


}


program.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: program status polling started" -k $program_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: program status polling ended" -k $program_indicator_key
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
    #source "$GRBL_RC"
    program.main "$@"
    exit "$?"
else
    gr.msg -v4 -c $__corsair_color "$__corsair [$LINENO] sourced " >&2
fi



