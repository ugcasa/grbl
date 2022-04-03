#!/bin/bash
# guru-client single file place template casa@ujo.guru 2022

source $GURU_BIN/common.sh

declare -g temp_file="/tmp/guru-place.tmp"
declare -g place_indicator_key="f$(gr.poll place)"


place.help () {
    # user help
    gr.msg -n -v2 -c white "guru-cli place help "
    gr.msg -v1 "fuzzy logic to place files to right locations."
    gr.msg -v2
    gr.msg -c white -n -v0 "usage:    "
    gr.msg -v0 "$GURU_CALL place "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v2 " ls       list of places "
    gr.msg -v2 " help     printout this help "
    gr.msg -v2
    gr.msg -n -v1 -c white "example:  "
    gr.msg -v1 "$GURU_CALL place ls"
    gr.msg -v2
}


place.main () {
    # main command parser

    local function="$1" ; shift

    case "$function" in
            ls|help|poll)
                place.$function $@
                return $?
                ;;
            *)
                place.help
                return 0
                ;;
        esac
}


place.ls () {
    # list something
    GURU_VERBOSE=2
    if [[ $GURU_MOUNT_ENABLED ]] ; then
            source mount.sh
            [[ $GURU_VERBOSE -lt 2 ]] \
                && mount.main ls \
                || mount.main info
        fi

    # test and return result
    return 0
}


place.status () {
    # output place status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # other tests with output, return errors

    }


place.poll () {
    # daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $place_indicator_key ]] || \
        place_indicator_key="f$(gr.poll place)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: place status polling started" -k $place_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: place status polling ended" -k $place_indicator_key
            ;;
        status)
            place.status $@
            ;;
        *)  place.help
            ;;
        esac
}


place.install () {

    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gr.msg "nothing to install"
    return 0
}

place.remove () {

    # sudo apt remove -y ...
    # pip3 remove --user ...
    gr.msg "nothing to remove"
    return 0
}

# if called place.sh file configuration is sourced and main place.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    place.main "$@"
    exit "$?"
fi

