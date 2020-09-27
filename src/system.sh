#!/bin/bash
# system tools for guru-client

source $GURU_BIN/lib/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/corsair.sh

system.main() {             # system command parser
    local tool="$1"; shift
    case "$tool" in
       status|start|end)                    system.$tool   ; return $? ;;
       core-dump|get|set|upgrade|rollback)  system.$tool   ; return $? ;;
                                        *)  system.help    ;;
    esac
    return 0
}

system.help () {            # system help printout

    echo "$GURU_CALL system upgrade|rollback|set"
}


system.status () {
    if mount.online "$GURU_SYSTEM_MOUNT" ; then
        gmsg -v 1 -t "F1 ${GRN}GREEN${NC}"
        corsair.write $F1 $_GREEN
    else
        gmsg -v 1 -t "F1 ${RED}RED${NC}"
        corsair.write $F1 $_RED
    fi
}


system.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "F1 OFF"
    corsair.write $F1 $_OFF
}

system.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "F1 ${WHT}WHITE${NC}"
    corsair.write $F1 $_WHITE
}



system.upgrade() {          # upgrade guru-client

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-shell.git"
    local _banch="master" ;
    [[ "$GURU_USE_VERSION" ]] && _branch="$GURU_USE_VERSION"
    [[ "$1" ]] && _branch="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "$_branch" "$source" || return 100
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-shell"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    #[ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}

system.rollback() {         # rollback to version

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-shell.git"
    local _roll_to="1"
    [ "$1" ] && _roll_to="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "rollback$_roll_to" "$source" || return 100
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-shell"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    [ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$HOME/.gururc"
    system.main "$@"
    exit $?
fi

