#!/bin/bash
# system tools for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh


system.main () {
    # system command parser
    indicator_key='F'"$(poll_order system)"
    local tool="$1" ; shift
    case "$tool" in
        status|start|end)
            system.$tool
            return $? ;;
        core-dump|get|set|upgrade|rollback)
            system.$tool
            return $? ;;
        env)
            re='^[0-9]+$'
            if [[ $1 =~ $re ]] ; then
                    system.get_env $@
                else
                    system.get_env_by_name $@
                fi ;;
        help)
            system.help ;;
        *)  system.help ;;
    esac
    return 0
}


system.help () {
    # system help printout
    gmsg -v0 "usage:    $GURU_CALL system [core-dump|get|set|upgrade|rollback|status|start|end]"
}


system.status () {
    # system status
    if mount.online "$GURU_SYSTEM_MOUNT" ; then
        gmsg -v 1 -t -c green "${FUNCNAME[0]}: guru on service" -k $indicator_key
        return 0
    else
        gmsg -v 1 -t -c red "${FUNCNAME[0]}: .data is unmounted" -k $indicator_key
        return 101
    fi
}


system.get_env () {
    # get running process variable values by pid

    local _pid=$1
    [[ $_pid ]] || gmsg -x 127 -c yellow  "pid name required "
    local _pattern=$2
    local _variable_to_find=$3

    # find variables pattern
    if [[ $_pattern ]] ; then
            local _variables=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep $_pattern || gmsg -c yellow "no variables")
        else
            local _variables=$(cat /proc/$_pid/environ | tr '\0' '\n' || gmsg -c yellow "no variables")
        fi

    if ! [[ $_variable_to_find ]] ; then
            gmsg -c light_blue "$_variables"
            return 0
        fi

    local _variables_found=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep "$_pattern*" | grep $_variable_to_find | awk '{ print length(), $0 | "sort -n" }' | cut -f2 -d " " || gmsg -c yellow "variable not found")

    # single variable
    local _variable_found=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep "$_pattern*" | grep $_variable_to_find | awk '{ print length(), $0 | "sort -n" }' | cut -f2 -d " " | head -1 || gmsg -c yellow "variable not found")
    local _variable=$(echo  $_variable_found | cut -f1 -d "=")
    # single value
    local _value=$(echo  $_variable_found | cut -f2 -d "=")

    # printout
    gmsg -v1 -c white "found variables:"
    gmsg -v1 -c light_blue "$_variables_found"
    if [[ $_variable_found ]] ; then
            gmsg -v1 -c white "$_variable value is:"
            gmsg "$_value"
            return 0
        else
            gmsg -v1 -c yellow "no variable found"
            return 1
        fi
}


system.get_pid_by_name () {
    # get process pid by name

    local _process="$1"
    [[ $_process ]] || read -p "process name: " _process

    # find process
    local _found_processes=$(ps auxf | grep "$_process" | grep -v grep | grep -v "system" )

    # pid where environment ir read
    local _pid=$(echo $_found_processes | head -1 | xargs | cut -f2 -d " ")

    if ! [[ $_pid ]] ; then
            gmsg -c yellow "no process '$_process'"
            return 101
        fi

    # check is number
    local re='^[0-9]+$'
    if ! [[ $_pid =~ $re ]] ; then
            gmsg -c yellow "no process '$_process' or found got bad PID '$_pid'"
            return 102
        fi

    echo $_pid
    return 0
}


system.get_env_by_name () {
    # get running process variable values by process name

    local _process=$1
    local _pattern=$2
    local _variable_to_find=$3

    # get PID
    local _pid=$(system.get_pid_by_name $_process)
    gmsg -v1 -c deep_pink -n "$_pid"

    # check putput (bash return annoying is hrr)
    local re='^[0-9]+$' ; if ! [[ $_pid =~ $re ]] ; then return 102 ; fi
    local found_process="$(ps auxf | grep $_pid | grep -v grep | head -1 | xargs | rev | cut -d " " -f1-4 | rev)"
    [[ $_pid ]] || gmsg -x 111 -c red "no pid found" && gmsg -v1 " $found_process"

    # pattern in variable name
    system.get_env $_pid $_pattern $_variable_to_find
}


system.start () {
    # set leds  F1 -> F4 off
    gmsg -v1 -t -c black "${FUNCNAME[0]}: system status polling started" -k $indicator_key
}


system.end () {
    # return normal, assuming that while is normal
    gmsg -v1 -t -c reset "${FUNCNAME[0]}: system status polling ended" -k $indicator_key
}


system.upgrade () {
    # upgrade guru-client
    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-client.git"
    local _banch="master" ;
    [[ "$GURU_USE_VERSION" ]] && _branch="$GURU_USE_VERSION"
    [[ "$1" ]] && _branch="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "$_branch" "$source" || return 100
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-client"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    #[ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


system.rollback () {
    # rollback to version

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-client.git"
    local _roll_to="1"
    [ "$1" ] && _roll_to="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "rollback$_roll_to" "$source" || return 100
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-client"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    [ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$GURU_RC"
    system.main "$@"
    exit $?
fi

