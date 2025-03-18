#!/bin/bash
# grbl keyboard shortcut functions
# casa@ujo.guru 2020
source $GRBL_BIN/common.sh
source $GRBL_BIN/os.sh



keyboard.main() {
    # keyboard command parser
    distro="$(os.check_distro)" # ; gr.msg -v2 "|$distro|"
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] && return 0

    command="$1" ; shift
    case "$command" in
        add)  if [[ "$1" == "all" ]] ; then
                    keyboard.set_GRBL_linuxmint && return 0 || return 100
                else
                    keyboard.set_shortcut_$distro "$@"  && return 0 || return 100
                fi ;;
         rm)  [[ "$1" == "all" ]] && "keyboard.reset_""${distro}" || keyboard.release_$distro "$@" ;;
     status) keyboard.status ; return 0 ;;
     *|help) keyboard.help ; return 0 ;;
    esac
}


keyboard.status () {
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    gr.msg "nothing to report"
    return 0
}


keyboard.help () {
    gr.msg -v1 -c white "grbl keyboard help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL keyboard [add|rm] {all}"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 "  add <key> <cmd>   add shortcut"
    gr.msg -v1 "  rm <key>          releases shortcut"
    gr.msg -v2
    gr.msg -v1 "'all' will add shortcuts set in '~/.config/grbl/$GRBL_USER/userrc'"
    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "      $GRBL_CALL keyboard add terminal $GRBL_TERMINAL F1"
    gr.msg -v1 "      $GRBL_CALL keyboard add all"
    gr.msg -v1 "      $GRBL_CALL keyboard rm all"
    gr.msg -v2

}


keyboard.set_shortcut_ubuntu () {           # set ubuntu keyboard shorcuts
    # usage: keyboard.set_ubuntu_shortcut [name] [command] [binding]
    os.compatible_with "ubuntu" || return 1
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] || return 0

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
    os.compatible_with "ubuntu" || return 1
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] || return 0
    gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings || return 100
    return 0
}


keyboard.release_ubuntu(){        # release single shortcut
    # usage: keyboard.release_ubuntu_shortcutss [key_binding] {directory}
    gr.msg -v1 -x 101 "TBD ${FUNCNAME[0]}"
    return 9
}

keyboard.set_GRBL_ubuntu(){       # set grbl defaults

    os.compatible_with "ubuntu" || return 1
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] || return 0

    keyboard.reset_ubuntu
    [ "$GRBL_KEYBIND_TERMINAL" ]    && keyboard.set_ubuntu_shortcut terminal      "$GRBL_TERMINAL"            "$GRBL_KEYBIND_TERMINAL"    ; error=$((error+$?))
    [ "$GRBL_KEYBIND_NOTE" ]        && keyboard.set_ubuntu_shortcut notes         "grbl note"                 "$GRBL_KEYBIND_NOTE"        ; error=$((error+$?))
    [ "$GRBL_KEYBIND_TIMESTAMP" ]   && keyboard.set_ubuntu_shortcut timestamp     "grbl stamp time"           "$GRBL_KEYBIND_TIMESTAMP"   ; error=$((error+$?))
    [ "$GRBL_KEYBIND_DATESTAMP" ]   && keyboard.set_ubuntu_shortcut datestamp     "grbl stamp date"           "$GRBL_KEYBIND_DATESTAMP"   ; error=$((error+$?))
    [ "$GRBL_KEYBIND_SIGNATURE" ]   && keyboard.set_ubuntu_shortcut signature     "grbl stamp signature"      "$GRBL_KEYBIND_SIGNATURE"   ; error=$((error+$?))
    [ "$GRBL_KEYBIND_PICTURE_MD" ]  && keyboard.set_ubuntu_shortcut picture_link  "grbl stamp picture_md"     "$GRBL_KEYBIND_PICTURE_MD"  ; error=$((error+$?))

    if [[ "$error" -gt "0" ]]; then     # sum errors
        echo "warning: $error in ${BASH_SOURCE[0]}, non defined shortcut keys in config file"
        return "$error"
    fi
    return 0
}


keyboard.set_GRBL_linuxmint () {

    local _new=$GRBL_CFG/keyboard.binding-mint.cfg
    local _backup=$GRBL_CFG/keyboard.backup-mint.cfg

    if [[ ! -f "$_backup" ]] ; then

            gr.msg -n -v2 -c gray "backup $_backup "

            if dconf dump /org/cinnamon/desktop/keybindings/ > "$_backup" ; then
                    gr.msg -v1 -c green "done"
                else
                    gr.msg -c yellow "error saving shortcut backup to $_backup"
                fi
        fi

    gr.msg -n -v2 -c gray "$_new "

    if dconf load /org/cinnamon/desktop/keybindings/ < "$_new" ; then
            gr.msg -v1 -c green "done"
            return 0
        else
            gr.msg -c yellow "error setting keyboard shortcuts $_new"
            return 1
        fi

    return 0
}


keyboard.set_shortcut_linuxmint () {
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] || return 0
    gr.msg -v1 -x 101 "TBD ${FUNCNAME[0]}"
    return 9
}


keyboard.reset_linuxmint() {
    # ser cinnamon chortcut
    os.compatible_with "linuxmint" || return 1
    [[ "$GRBL_INSTALL_TYPE" == "server" ]] || return 0

    backup=$GRBL_CFG/keyboard.backup-mint.cfg

    if [ -f "$backup" ]; then
        dconf load /org/cinnamon/desktop/keybindings/ < "$backup" || return 101
    else
        gr.msg -c yellow "no backup found"
        return 2
    fi
}


keyboard.release_linuxmint () {
    gr.msg -v1 -x 101 "TBD ${FUNCNAME[0]}"
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




