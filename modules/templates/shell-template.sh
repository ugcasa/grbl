#!/bin/bash
# grbl single file mudule template casa@ujo.guru 2022

### Instructions to use template if created by make_single_module.sh
### 1) skim and then remove lines with triple hashtags
###
### Instructions to use template manually
###
### 1) copy shell-template.sh to ../<your_module_name>.sh remember to chmod +x
### 2) find all 'module' words in this file and replace with your module name
### 3) do the same to 'MODULE' by replacing with your module name written in UPCASE
### 4) rename "mudule" words to module
### 4) try it './module.sh help'
### 5) read lines with double hashtags
### 6) cleanup by removing all double hashtags
### 7) add module to 'modules_to_install' list in ../install.sh
### 8) contribute by setting pull requests at github.com/ugcasa/grbl =)
### 9) remove triple comments


# include other modules/libraries that are needed
### grbl modules are set to path, name is enough therefore you should  name
### module way that is not conflict in run environment
# source nnnn.sh

# declare global variables for module
declare -g module_temp_file="$GRBL_TEMP/module.tmp"
declare -g module_rc="/tmp/$USER/grbl_module.rc"
declare -g module_data_folder=$GRBL_SYSTEM_MOUNT/module

### functions, keeping help at first position it might be even updated

module.help () {
# user help
    gr.msg -v1 "grbl module help " -c white
### few clause description what module is doing
    gr.msg -v2
    gr.msg -v2 ""
    gr.msg -v2
### explain how to use
    gr.msg -v0 "usage: " -c white
    gr.msg -v0 "          $GRBL_CALL module command variables"
    gr.msg -v0 "          $GRBL_CALL --option --optin_with_value <value>"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
### add callable commands below
    gr.msg -v1 " ls         list something "
    gr.msg -v1 " install    install requirements "
    gr.msg -v1 " remove     remove installed requirements "
    gr.msg -v1 " help       printout this help "
    gr.msg -v2
### module options are separated from core variables by double lines
    gr.msg -v1 "options: " -c white
    gr.msg -v1 " --option   option "
    gr.msg -v1 " --value    option with value "
### add few examples callable commands below
    gr.msg -v1 "example: " -c white
    gr.msg -v1 "          $GRBL_CALL module <command>"
    gr.msg -v2
}

### when module is sourced by another script this function is acting as an interface
### source module.sh and then call
### core temp to call functions by 'module.main poll variables'
### rather than 'module.poll variables' both work dough

module.main () {
# main command parser

    local function="$1" ; shift

    case "$function" in
            ## add functions called from outside on this list
            ls|status|poll|install|remove|help)
                module.$function $@
                return $?
                ;;
            *)
                module.help
                return 0
                ;;
        esac
}

### example function

module.ls () {
# list something
    gr.msg "nothing to list"
    # test and return result
    return 0
}

### following function should be able to call without passing trough module.main

module.status () {
# output module status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # check module is installed
    if [[ -f $GRBL_BIN/module.sh ]]; then
        gr.msg -n -v1 -c green "installed, "
    else
        gr.msg -v1 -k $module_indicator_key -c reset "not installed "
        return 1
    fi

    # check module is enabled
    if [[ $GRBL_MODULE_ENABLED ]] ; then
        gr.msg -n -v1 \
        -c green "enabled, "
    else
        gr.msg -v1 \
        -c black "disabled" \
        -k $module_indicator_key
        return 1
    fi

    # check that module works
    if module.check ; then
        gr.msg -v1 \
        -k $module_indicator_key \
        -c green "available "
    else
        gr.msg -v1 \
        -c red "non functional" \
        -k $module_indicator_key
        return 1
    fi

    return 0
}

### following function is used as daemon polling interface
### to include 'module' to poll list in user.cfg in
### section '[daemon]''
### variable 'poll_order'

module.poll () {
# daemon interface

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: module status polling started" -k $module_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: module status polling ended" -k $module_indicator_key
            ;;
        status)
            module.status $@
            ;;
        *)  module.help
            ;;
        esac
}

### if mudule requires tools or libraries to work installation is done here

module.install () {
# install requirements
    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gr.msg "nothing to install"
    return 0
}

### instructions to remove installed tools.
### DO NOT remove any tools that might be considered as basic tools even module did those install

module.remove () {
# remove requirements
    # sudo apt remove -y ...
    # pip3 remove --user ...
    gr.msg "nothing to remove"
    return 0
}


module.rc () {
# source configurations

    local mudule_config="$GRBL_CFG/$GRBL_USER/module.cfg"
    # check is mudule configuration changed lately, update rc if so
    if [[ ! -f $module_rc ]] \
        || [[ $(( $(stat -c %Y $mudule_config) - $(stat -c %Y $module_rc) )) -gt 0 ]] ## \
        # || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/other_module.cfg) - $(stat -c %Y $module_rc) )) -gt 0 ]]
        then
            module.make_rc && gr.msg -v1 -c dark_gray "$module_rc updated"
        fi

    [[ ! -d $module_data_folder ]] && [[ -f $GRBL_SYSTEM_MOUNT/.online ]] && mkdir -p $module_data_folder
    if [[ -f $module_rc ]] ; then
        source $module_rc
    else
        gr.msg -v2 -c dark_gray "no configuration"
    fi

    ## check is any mudule or linked mudule configuration changed lately, update rc if so
    # if [[ ! -f $module_rc ]] \
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/module.cfg) - $(stat -c %Y $0000000module_rc) )) -gt 0 ]] \
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/module2.cfg) - $(stat -c %Y $module_rc) )) -gt 0 ]]
    #     then ...
}


module.make_rc () {
# construct module configuration rc

    source config.sh
    local mudule_config="$GRBL_CFG/$GRBL_USER/module.cfg"

    # try to find user configuration
    if ! [[ -f $mudule_config ]] ; then
        gr.debug "$mudule_config does not exist"
        mudule_config="$GRBL_CFG/module.cfg"

        # try to find default configuration
        if ! [[ -f $mudule_config ]] ; then
            gr.debug "$mudule_config not exist, skipping"
            return 1
        fi
    fi

    # remove existing rc file
    if [[ -f $module_rc ]] ; then
            rm -f $module_rc
        fi

    config.make_rc $mudule_config $module_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/another_module.cfg" $module_rc append
    chmod +x $module_rc
}

# run these functions every time module is called
module.rc

# global variables that need values from module configuration
# declare global that need configuration values from rc
declare -g module_indicator_key="esc"
[[ $GRBL_MODULE_INDICATOR_KEY ]] && module_indicator_key=$GRBL_MODULE_INDICATOR_KEY

# check is module.sh run alone, if sourced by core.sh this
### general grbl configuration is sourced, then main module.main called
if [[ ${BASH_SOURCE[0]} == ${0} ]]; then

    # run without grbl installation
    if [[ -z $GRBL_RC ]] ; then
        ### Add environmental variables below your module need to run without installation
        export GRBL_CALL="grbl"
        export GRBL_RC="$HOME/.grblrc"
        export GRBL_BIN="$HOME/bin"
        export GRBL_CFG="$HOME/.config/grbl"
        export GRBL_TEMP="/tmp/$USER/grbl"
    fi
    source $GRBL_RC
    module.main $@
    exit $?
fi

