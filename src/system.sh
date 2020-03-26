#!/bin/bash
# system tools for guru tool-kit
#source $GURU_BIN/functions.sh
source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh


system.main() {
    local tool="$1"; shift
    case "$tool" in
       get|set|upgrade|rollback)  system.$tool   ; return $? ;;
                              *)  system.help    ;;
    esac
    return 0
}


system.help () {
    echo "$GURU_CALL system upgrade|rollback|set"
}


system.upgrade() {

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-ui.git"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone "$source" || return 666
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-ui"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    [ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


system.rollback() {

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-ui.git"
    local _roll_to="1"
    [ "$1" ] && _roll_to="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "rollback$_roll_to" "$source" || exit 666
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-ui"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    [ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


system.get (){

    [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
    set |grep "GURU_${_setting^^}"
    #set |grep "GURU_${_setting^^}" |cut -c13-
    return $?
}


system.set () {
    # set guru environmental funtions
    [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
    [ "$2" ] && _value="$2" || read -r -p "$_setting value: " _value

    [ -f "$GURU_USER_RC" ] && target_rc="$GURU_USER_RC" || target_rc="$HOME/.gururc"
    sed -i -e "/$_setting=/s/=.*/=$_value/" "$target_rc"                               # Ähh..
    msg "setting GURU_${_setting^^} to $_value\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    system.main "$@"
    exit $?
fi

