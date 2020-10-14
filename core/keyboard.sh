#!/bin/bash
# guru-client keyboard shortcut functions
# casa@ujo.guru 2020
source $GURU_BIN/common.sh


keyboard.main() {
    # keyboard command parser
    distro="$(check_distro)" # ; gmsg -v2 "|$distro|"
    command="$1" ; shift
    case "$command" in
        add)  if [[ "$1" == "all" ]] ; then
                    keyboard.set_guru_linuxmint && return 0 || return 100
                else
                    keyboard.set_shortcut_$distro "$@"  && return 0 || return 100
                fi ;;
         rm)  [[ "$1" == "all" ]] && "keyboard.reset_""${distro}" || keyboard.release_$distro "$@" ;;
     status) keyboard.status ; return 0 ;;
     *|help) keyboard.help ; return 0 ;;
    esac
}

keyboard.status () {
    gmsg "nothing to report"
    return 0
}

keyboard.help () {
    gmsg -v1 -c white "guru-client keyboard help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL keyboard [add|rm] {all}"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 "  add <key> <cmd>   add shortcut"
    gmsg -v1 "  rm <key>          releases shortcut"
    gmsg -v2
    gmsg -v1 "'all' will add shortcuts set in '~/.config/guru/$GURU_USER/userrc'"
    gmsg -v2
    gmsg -v1 -c white  "example:"
    gmsg -v1 "      $GURU_CALL keyboard add terminal $GURU_TERMINAL F1"
    gmsg -v1 "      $GURU_CALL keyboard add all"
    gmsg -v1 "      $GURU_CALL keyboard rm all"
    gmsg -v2

}


keyboard.set_shortcut_ubuntu () {           # set ubuntu keyboard shorcuts
    # usage: keyboard.set_ubuntu_shortcut [name] [command] [binding]
    compatible_with "ubuntu" || return 1

    current_keys=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    key_base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom"
    key_number=$(echo $current_keys|grep -o "custom-keybindings/custom" | wc -l)

    if (($key_number > 0)); then
        current_keys=${current_keys//]}
        new_keys="$current_keys, '$key_base$key_number/']"
    else
        new_keys="['$key_base$key_number/']"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_keys" ||return 100
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ name "$1"  ||return 101
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ command "'$2'"  ||return 102
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ binding "$3"  ||return 103
    return 0
}


keyboard.reset_ubuntu () {        # resets all custom shortcuts to default
    compatible_with "ubuntu" || return 1
    gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings || return 100
    return 0
}


keyboard.release_ubuntu(){        # release single shortcut
    # usage: keyboard.release_ubuntu_shortcutss [key_binding] {directory}
    gmsg -v1 -x 101 "TBD ${FUNCNAME[0]}"
    return 9
}

keyboard.set_guru_ubuntu(){       # set guru defaults

    compatible_with "ubuntu" || return 1
    keyboard.reset_ubuntu

    [ "$GURU_KEYBIND_TERMINAL" ]    && keyboard.set_ubuntu_shortcut terminal      "$GURU_TERMINAL"            "$GURU_KEYBIND_TERMINAL"    ; error=$((error+$?))
    [ "$GURU_KEYBIND_NOTE" ]        && keyboard.set_ubuntu_shortcut notes         "guru note"                 "$GURU_KEYBIND_NOTE"        ; error=$((error+$?))
    [ "$GURU_KEYBIND_TIMESTAMP" ]   && keyboard.set_ubuntu_shortcut timestamp     "guru stamp time"           "$GURU_KEYBIND_TIMESTAMP"   ; error=$((error+$?))
    [ "$GURU_KEYBIND_DATESTAMP" ]   && keyboard.set_ubuntu_shortcut datestamp     "guru stamp date"           "$GURU_KEYBIND_DATESTAMP"   ; error=$((error+$?))
    [ "$GURU_KEYBIND_SIGNATURE" ]   && keyboard.set_ubuntu_shortcut signature     "guru stamp signature"      "$GURU_KEYBIND_SIGNATURE"   ; error=$((error+$?))
    [ "$GURU_KEYBIND_PICTURE_MD" ]  && keyboard.set_ubuntu_shortcut picture_link  "guru stamp picture_md"     "$GURU_KEYBIND_PICTURE_MD"  ; error=$((error+$?))

    if [[ "$error" -gt "0" ]]; then     # sum errors
        echo "warning: $error in ${BASH_SOURCE[0]}, non defined shortcut keys in config file"
        return "$error"
    fi
    return 0
}


keyboard.set_guru_linuxmint () {

local _new=$GURU_CFG/kbbind.guruio.cfg
local _backup=$GURU_CFG/kbbind.backup.cfg

if [[ ! -f "$_backup" ]] ; then

        gmsg -n -v2 -c gray "backup $_backup "

        if dconf dump /org/cinnamon/desktop/keybindings/ > "$_backup" ; then
                gmsg -v1 -c green "done"
            else
                gmsg -c yellow "error saving shortcut backup to $_backup"
            fi
    fi

gmsg -n -v2 -c gray "$_new "

if dconf load /org/cinnamon/desktop/keybindings/ < "$_new" ; then
        gmsg -v1 -c green "done"
        return 0
    else
        gmsg -c yellow "error setting keyboard shortcuts $_new"
        return 1
    fi

return 0
}


keyboard.set_shortcut_linuxmint () {
    gmsg -v1 -x 101 "TBD ${FUNCNAME[0]}"
    return 9
}


keyboard.reset_linuxmint() {
    # ser cinnamon chortcut
    compatible_with "linuxmint" || return 1

    backup=$GURU_CFG/kbbind.backup.cfg

    if [ -f "$backup" ]; then
        dconf load /org/cinnamon/desktop/keybindings/ < "$backup" || return 101
    else
        gmsg -c yellow "no backup found"
        return 2
    fi
}


keyboard.release_linuxmint () {
    gmsg -v1 -x 101 "TBD ${FUNCNAME[0]}"
    return 9
}

keyboard.install () {
     dconf help >/dev/null || sudo apt install dconf-cli
}

# check is called by user of includet in scrip.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        keyboard.main "$@"
        exit "$?"
fi




