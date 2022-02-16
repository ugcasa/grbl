#!/bin/bash
# guru-client single file module template casa@ujo.guru 2022
##
## instructions for using this template
## 1) copy shell-template.sh to ../<your_module_name>.sh remember to chmod +x
## 2) find all 'module' words in this file and replace with your module name
## 3) do the same to 'MODULE' by replacing with your module name written in UPCASE
## 4) try it './module.sh help'
## 5) read lines with double hashtags
## 6) cleanup by removing all double hashtags
## 7) add module to 'modules_to_install' list in ../install.sh
## 8) contribute by pull requests at github.com/ugcasa/guru-client =)

## include needed libraries
source $GURU_BIN/common.sh

## declare run wide global variables
declare -g temp_file="/tmp/guru-module.tmp"
declare -g module_indicator_key="f$(daemon.poll_order module)"


## functions, keeping help at first position it might be even updated
module.help () {
    # user help
    gmsg -v1 -c white "module help "
    gmsg -v2
    gmsg -v1 "few clause description"
    gmsg -v2
    gmsg -v0 "usage:  $GURU_CALL module command variables "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v2 " ls           list something "
    gmsg -v2 " help         printout this help "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "   $GURU_CALL module <command>"
    gmsg -v2
}


## when module is sourced by another script this function is acting as an interface
## source module.sh and then call
## core temp to call functions by 'module.main poll variables'
## rather than 'module.poll variables' both work dough
module.main () {
    # main command parser

    local function="$1" ; shift
    ## declare one shot variables here only if really needed
    ## declare -g bubble_gum=̈́true

    case "$function" in
            ## add functions called from outside on this list
            ls|help|poll)
                module.$function $@
                return $?
                ;;
            *)
                module.help
                return 0
                ;;
        esac
}


## example function
module.ls () {
    # list something
    gmsg "nothing to list"
    # test and return result
    return 0
}


## following function should be able to call without passing trough module.main
module.status () {
    # output module status

    gmsg -n -t -v1 "${FUNCNAME[0]}: "

    # check module is enabled
    if [[ $GURU_MODULE_ENABLED ]] ; then
            gmsg -n -v1 -c green "enabled, " -k $module_indicator_key
        else
            gmsg -v1 -c reset "disabled" -k $module_indicator_key
            return 1
        fi

    # other tests with output, return errors

    }


## following function is used as daemon polling interface
## to include 'module' to poll list in user.cfg in
## section '[daemon]''
## variable 'poll_order'
module.poll () {
    # daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $module_indicator_key ]] || \
        module_indicator_key="f$(daemon.poll_order module)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gmsg -v1 -t -c black "${FUNCNAME[0]}: module status polling started" -k $module_indicator_key
            ;;
        end)
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: module status polling ended" -k $module_indicator_key
            ;;
        status)
            module.status $@
            ;;
        *)  module.help
            ;;
        esac
}


## if module requires tools or libraries to work installation is done here
module.install () {

    # sudo apt update || gmsg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gmsg "nothing to install"
    return 0
}

## instructions to remove installed tools.
## DO NOT remove any tools that might be considered as basic hacker tools even module did those install those install
module.remove () {

    # sudo apt remove -y ...
    # pip3 remove --user ...
    gmsg "nothing to remove"
    return 0
}

# if called module.sh file configuration is sourced and main module.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    module.main "$@"
    exit "$?"
fi

