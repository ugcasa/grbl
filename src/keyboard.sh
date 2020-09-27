#!/bin/bash
# guru client keyboard shortcut functions
# casa@ujo.guru 2020

keyboard_main() {

    source "$(dirname "$0")/lib/common.sh"
    distro="$(check_distro)"    # lazy

    command="$1"
    shift

    case "$command" in

        add-shortcut)
                if [ "$1" == "all" ]; then
                     [ "$distro" == "linuxmint" ] && add_cinnamon_guru_shortcuts
                     [ "$distro" == "ubuntu" ] && add_ubuntu_guru_shortcuts
                else
                    [ "$distro" == "linuxmint" ] && echo "TBD set_cinnamon_keyboard_shortcut"
                    [ "$distro" == "ubuntu" ] && set_ubuntu_keyboard_shortcut "$@"
                fi
                ;;

        release-shortcut)
                if [ "$1" == "all" ]; then
                    reset_ubuntu_keyboard_shortcuts
                    [ "$distro" == "linuxmint" ] && echo "TBD reset_cinnamon_keyboard_shortcuts"
                    [ "$distro" == "ubuntu" ] && reset_ubuntu_keyboard_shortcuts
                else
                    [ "$distro" == "linuxmint" ] && echo "TBD release_cinnamon_guru_shortcut" "$@"
                    [ "$distro" == "ubuntu" ] && echo "TBD release_ubuntu_keyboard_shortcut"
                fi
                ;;

            *)
                printf "\nUsage:\n\t %s keyboard [command] [variables]\n" "$GURU_CALL"
                printf "\nCommands:\n\n"
                printf " add-shortcut [all]             add shortcut\n"
                printf "                                [all] add shortcuts set in '~/.config/guru/$GURU_USER/userrc'\n"
                printf " release-shortcut [all]         releases shortcut [name]\n"
                printf "                                [all] release all custom shortcuts\n"
                printf "\nExample:\n\t %s keyboard add-shortcut terminal %s F1\n\n" "$GURU_CALL" "$GURU_TERMINAL"
                ;;
    esac
}


# Functions
set_ubuntu_keyboard_shortcut () {
    # usage: set_ubuntu_keyboard_shortcut [name] [command] [binding]
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


reset_ubuntu_keyboard_shortcuts(){
    # resets all custom shortcuts
        compatible_with "ubuntu" || return 1
        gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings
}


release_ubuntu_keyboard_shortcut(){
    # usage: release_ubuntu_keyboard_shortcuts [key_binding] {directory}
        echo "TBD"
}


add_ubuntu_guru_shortcuts(){
    # set guru defaults

        compatible_with "ubuntu" || return 1

        reset_ubuntu_keyboard_shortcuts

        [ "$GURU_KEYBIND_TERMINAL" ]    && set_ubuntu_keyboard_shortcut terminal      "$GURU_TERMINAL"            "$GURU_KEYBIND_TERMINAL"    ; error=$((error+$?))
        [ "$GURU_KEYBIND_NOTE" ]        && set_ubuntu_keyboard_shortcut notes         "guru note"                 "$GURU_KEYBIND_NOTE"        ; error=$((error+$?))
        [ "$GURU_KEYBIND_TIMESTAMP" ]   && set_ubuntu_keyboard_shortcut timestamp     "guru stamp time"           "$GURU_KEYBIND_TIMESTAMP"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_DATESTAMP" ]   && set_ubuntu_keyboard_shortcut datestamp     "guru stamp date"           "$GURU_KEYBIND_DATESTAMP"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_SIGNATURE" ]   && set_ubuntu_keyboard_shortcut signature     "guru stamp signature"      "$GURU_KEYBIND_SIGNATURE"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_PICTURE_MD" ]  && set_ubuntu_keyboard_shortcut picture_link  "guru stamp picture_md"     "$GURU_KEYBIND_PICTURE_MD"  ; error=$((error+$?))

        # sum errors
        if [[ "$error" -gt "0" ]]; then
            echo "warning: $error in ${BASH_SOURCE[0]}, non defined shortcut keys in config file"
            return "$error"
        fi
        return 0
}


add_cinnamon_guru_shortcuts() {

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
        keyboard_main "$@"
        exit "$?"
fi




