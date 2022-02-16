#!/bin/bash
# guru-client single file place template casa@ujo.guru 2022
##
## instructions for using this template
## 4) try it './place.sh help'
## 5) read lines with double hashtags
## 6) cleanup by removing all double hashtags
## 7) add place to 'modules_to_install' list in ../install.sh
## 8) contribute by pull requests at github.com/ugcasa/guru-client =)

## include needed libraries
source $GURU_BIN/common.sh

## declare run wide global variables
declare -g temp_file="/tmp/guru-place.tmp"
declare -g place_indicator_key="f$(daemon.poll_order place)"


## functions, keeping help at first position it might be even updated
place.help () {
    # user help
    gmsg -v1 -c white "place help "
    gmsg -v2
    gmsg -v1 "few clause description"
    gmsg -v2
    gmsg -v0 "usage:  $GURU_CALL place command variables "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v2 " ls           list something "
    gmsg -v2 " help         printout this help "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "   $GURU_CALL place <command>"
    gmsg -v2
}


## when place is sourced by another script this function is acting as an interface
## source place.sh and then call
## core temp to call functions by 'place.main poll variables'
## rather than 'place.poll variables' both work dough
place.main () {
    # main command parser

    local function="$1" ; shift
    ## declare one shot variables here only if really needed
    ## declare -g bubble_gum=̈́true

    case "$function" in
            ## add functions called from outside on this list
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


## example function
place.ls () {
    # list something
    gmsg "nothing to list"
    # test and return result
    return 0
}


## following function should be able to call without passing trough place.main
place.status () {
    # output place status

    gmsg -n -t -v1 "${FUNCNAME[0]}: "

    # other tests with output, return errors

    }


## following function is used as daemon polling interface
## to include 'place' to poll list in user.cfg in
## section '[daemon]''
## variable 'poll_order'
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


## if place requires tools or libraries to work installation is done here
place.install () {

    # sudo apt update || gmsg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gmsg "nothing to install"
    return 0
}

## instructions to remove installed tools.
## DO NOT remove any tools that might be considered as basic hacker tools even place did those install those install
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

