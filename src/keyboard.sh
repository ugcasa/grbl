#!/bin/bash
# guru tool-kit keyboard shortcut functions 
# casa@ujo.guru 2020

# Inclides
. $GURU_BIN/lib/common.sh

keyboard_main() {

    command="$1"
    shift

    case $command in

        add-shortcut)
                if [ "$1" == "all" ]; then  
                    add_guru_defaults 
                else
                    set_ubuntu_keyboard_shortcut "$@"
                fi
                ;;
        
        release-shortcut)
                if [ "$1" == "all" ]; then  
                    reset_ubuntu_keyboard_shortcuts
                else
                    release_ubuntu_keyboard_shortcut "$@"
                fi
                ;;

            *)
                printf "\nUsage:\n\t $0 [command] [arguments]\n\t $0 mount [source] [target]\n"
                printf "\nCommands:\n\n"
                prinff "[name] [command] [binding]"
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

        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_keys"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ name "$1" 
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ command "'$2'"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_base$key_number/ binding "$3"
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


add_ubuntu_guru_defaults(){
    # test for older guru toolkits where these variables are not set    
        # guru variablesfor test, not implemented to userrc yet
        
        echo "Testing keyboard shortcuts in $PRETTY_NAME"

        # Test
        reset_ubuntu_keyboard_shortcuts

        [ "$GURU_KEYBIND_TERMINAL" ]    && set_ubuntu_keyboard_shortcut terminal      "$GURU_TERMINAL"            "$GURU_KEYBIND_TERMINAL"    ; error=$((error+$?))
        [ "$GURU_KEYBIND_NOTE" ]        && set_ubuntu_keyboard_shortcut notes         "guru note"                 "$GURU_KEYBIND_NOTE"        ; error=$((error+$?))
        [ "$GURU_KEYBIND_TIMESTAMP" ]   && set_ubuntu_keyboard_shortcut timestamp     "guru stamp time"           "$GURU_KEYBIND_TIMESTAMP"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_DATESTAMP" ]   && set_ubuntu_keyboard_shortcut datestamp     "guru stamp date"           "$GURU_KEYBIND_DATESTAMP"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_SIGNATURE" ]   && set_ubuntu_keyboard_shortcut signature     "guru stamp signature"      "$GURU_KEYBIND_SIGNATURE"   ; error=$((error+$?))
        [ "$GURU_KEYBIND_PICTURE_MD" ]  && set_ubuntu_keyboard_shortcut picture_link  "guru stamp picture_md"     "$GURU_KEYBIND_PICTURE_MD"  ; error=$((error+$?))

        # sum errors
        if [[ "$error" -gt "0" ]]; then 
            echo "Error: $error, Something went wrong." 
            return "$error"
        fi
        return 0
}


# check is called by user of includet in scrip. 
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        keyboard_main "$@"
        exit "$?"
fi




