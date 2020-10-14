#!/bin/bash
# system tools for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/corsair.sh

system.main () {
    # system command parser
    indicator_key='F'"$(poll_order system)"
    local tool="$1"; shift
    case "$tool" in
       status|start|end)                    system.$tool   ; return $? ;;
       core-dump|get|set|upgrade|rollback)  system.$tool   ; return $? ;;
                                     help)  system.help    ;;
                                        *)  system.help    ;;
    esac
    return 0
}


system.help () {
    # system help printout
    gmsg -v0 "usage:    $GURU_CALL system [core-dump|get|set|upgrade|rollback|status|start|end]"
}


system.status () {
    if mount.online "$GURU_SYSTEM_MOUNT" ; then
        gmsg -v 1 -t -c green "${FUNCNAME[0]}: guru on service"
        corsair.main set $indicator_key green
        return 0
    else
        gmsg -v 1 -t -c red "${FUNCNAME[0]}: .data is unmounted"
        corsair.main set $indicator_key red
        return 101
    fi
}


system.start () {
    # set leds  F1 -> F4 off
    gmsg -v 1 -t "${FUNCNAME[0]}: system status polling started"
    corsair.main set $indicator_key off || return 101
}


system.end () {
    # return normal, assuming that while is normal
    gmsg -v 1 -t "${FUNCNAME[0]}: system status polling ended"
    corsair.main set $indicator_key white || return 101
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

