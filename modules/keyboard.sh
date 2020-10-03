#!/bin/bash
# guru-client keyboard shortcut functions
# casa@ujo.guru 2020

keyboard.main() {                           # keyboard command parser

    source "$GURU_BIN/common.sh"
    distro="$(check_distro)"    # lazy

    command="$1"
    shift

    case "$command" in

        add-shortcut)
                if [ "$1" == "all" ]; then
                     [ "$distro" == "linuxmint" ] && keyboard.set_cinnamon_guru_shortcuts
                     [ "$distro" == "ubuntu" ] && keyboard.set_ubuntu_guru_shortcuts
                else
                    [ "$distro" == "linuxmint" ] && echo "TBD set_cinnamon_keyboard_shortcut"
                    [ "$distro" == "ubuntu" ] && keyboard.set_ubuntu_shortcut "$@"
                fi
                ;;

        release-shortcut)
                if [ "$1" == "all" ]; then
                    keyboard.reset_ubuntu_shortcuts
                    [ "$distro" == "linuxmint" ] && echo "TBD reset_cinnamon_keyboard_shortcuts"
                    [ "$distro" == "ubuntu" ] && keyboard.reset_ubuntu_shortcuts
                else
                    [ "$distro" == "linuxmint" ] && echo "TBD release_cinnamon_guru_shortcut" "$@"
                    [ "$distro" == "ubuntu" ] && echo "TBD keyboard.release_ubuntu_shortcuts"
                fi
                ;;

            *|help)
                gmsg -v1 -c white "guru-client keyboard help "
                gmsg -v2
                gmsg -v0 "usage:    $GURU_CALL keyboard [command] [variables]"
                gmsg -v2
                gmsg -v1 -c white "commands:"
                gmsg -v1 " add-shortcut [all]             add shortcut"
                gmsg -v1 "                                [all] add shortcuts set in '~/.config/guru/$GURU_USER/userrc'"
                gmsg -v1 " release-shortcut [all]         releases shortcut [name]"
                gmsg -v1 "                                [all] release all custom shortcuts"
                gmsg -v1 -c white  "example:"
                gmsg -v1 "      $GURU_CALL keyboard add-shortcut terminal $GURU_TERMINAL F1"
                gmsg -v2
                ;;
    esac
}

keyboard.set_ubuntu_shortcut () {           # set ubuntu keyboard shorcuts
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

keyboard.reset_ubuntu_shortcuts () {        # resets all custom shortcuts to default
        compatible_with "ubuntu" || return 1
        gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings
}

keyboard.release_ubuntu_shortcuts(){        # release single shortcut
    # usage: keyboard.release_ubuntu_shortcutss [key_binding] {directory}
        echo "TBD"
}

keyboard.set_ubuntu_guru_shortcuts(){       # set guru defaults

        compatible_with "ubuntu" || return 1
        keyboard.reset_ubuntu_shortcuts

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

keyboard.set_cinnamon_guru_shortcuts() {    # ser cinnamon chortcut

        compatible_with "linuxmint" || return 1

        dconf help >/dev/null || sudo apt install dconf-cli

        new=$GURU_CFG/$GURU_USER/kbbind.guruio.cfg
        backup=$GURU_CFG/kbbind.backup.cfg

        if [ ! -f "$backup" ]; then
            dconf dump /org/cinnamon/desktop/keybindings/ > "$backup" # && cat "$backup" | grep binding=

        fi

        dconf load /org/cinnamon/desktop/keybindings/ < "$new"
}


# check is called by user of includet in scrip.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        keyboard.main "$@"
        exit "$?"
fi




