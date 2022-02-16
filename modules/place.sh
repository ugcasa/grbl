#!/bin/bash
# guru-client single file place template casa@ujo.guru 2022

source $GURU_BIN/common.sh

declare -g temp_file="/tmp/guru-place.tmp"
declare -g place_indicator_key="f$(daemon.poll_order place)"


place.help () {
    # user help
    gmsg -n -v2 -c white "guru-cli place help "
    gmsg -v1 "fuzzy logic to place files to right locations."
    gmsg -v2
    gmsg -c white -n -v0 "usage:    "
    gmsg -v0 "$GURU_CALL place "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v2 " ls       list of places "
    gmsg -v2 " help     printout this help "
    gmsg -v2
    gmsg -n -v1 -c white "example:  "
    gmsg -v1 "$GURU_CALL place ls"
    gmsg -v2
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

    gmsg -n -t -v1 "${FUNCNAME[0]}: "

    # other tests with output, return errors

    }


place.poll () {
    # daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $place_indicator_key ]] || \
        place_indicator_key="f$(daemon.poll_order place)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gmsg -v1 -t -c black "${FUNCNAME[0]}: place status polling started" -k $place_indicator_key
            ;;
        end)
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: place status polling ended" -k $place_indicator_key
            ;;
        status)
            place.status $@
            ;;
        *)  place.help
            ;;
        esac
}


place.install () {

    # sudo apt update || gmsg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gmsg "nothing to install"
    return 0
}

place.remove () {

    # sudo apt remove -y ...
    # pip3 remove --user ...
    gmsg "nothing to remove"
    return 0
}

# if called place.sh file configuration is sourced and main place.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    place.main "$@"
    exit "$?"
fi

