#!/bin/bash
# keyboard.sh

# Known devices
## USB connected open source barcode reader 
barcode="Newland Auto-ID NLS IOTC PRDs HID KBW"
barcode_dev='/dev/input/by-id/usb-Newland_Auto-ID_NLS_IOTC_PRDs_HID_KBW_EY016945-event-kbd'

## USB based Nokia 3110 like interface 
phone_kb="Yealink usb-p1k" 
phone_kb_dev='/dev/input/by-id/usb-Yealink_Network_Technology_Ltd._VOIP_USB_Phone-event-if03'

## numpad interface 
# hmm.. there is two devices named save way, but dif. id, how to compile id is not static in any level
numpab="USB Compliant Keypad"
numpab_dev="/dev/input/by-id/usb-05a4_USB_Compliant_Keypad-event-kbd"

history=""
history_file="$HOME/tmp/kb.log"


keyboard_main() {

    command="$1"; shift

    case "$command" in

        ls) # List devices
            xinput --list
            ;;

        mask|enable)
           case "$1" in 
                numpad|-nb)  $command "$numpad" ;;
                phone|-pb)   $command "$phone_kb" ;;
                barcode|-br) $command "$barcode" ;;
                all) 
                    $command "$numpab" 
                    $command "$phone_kb"
                    $command "$barcode"
                    ;;
                *) echo "please input keyboard alias"
            esac
            ;;
        
        barcode)  
            mask "$barcode"      
            poll_kb "$barcode_dev"         
            enable "$barcode"          
            ;;

        phone|phone_kb)  
            mask "$phone_kb" 
            poll_kb "$phone_kb_dev"
            enable "$phone_kb"
            ;;

        numpad|pad|num)  
            mask "$numpab" 
            poll_kb "$numpab_dev"
            enable "$numpab"
            ;;

        install|remove)
            sudo apt "$command" xinput
            ;;
        
        last|history)
            [ "$1" ] && lines="$1" || lines="1"
            tail $history_file -n$lines
            ;;

        help)
            printf "usage: $GURU_CALL input [command] argument \ncommands: \n"
            printf "mask            remove target device from core import feed\n"
            printf "enable          connect target device to core import feed\n"
            printf "barcode         record barcode reader \n"
            printf "phone           record Nokia 3110 type interface \n"
            printf "last|history    last <n> lines og history \n"
            printf "install|remove  install/remove needed tools \n"
            ;;
        *)
            # Reset to default 
            enable "$phone_kb"
            enable "$barcode"      
        
    esac
}


get_input_device_id() {
# Get given device name ID
    tab=$(printf "\t")
    temp_id=$(xinput --list|grep "$@")      # places line of list where input is mentioned
                                            # Format '∼ Yealink usb-p1k                           id=13   [floating slave]'
    temp_id=${temp_id#*=}                   # removes all before "=" character
    temp_id=${temp_id%%$tab*}               # removes all from tab character
    echo "$temp_id"
}


check_kb () {
# check that its connected return 0 if is and 1 if not
    xinput --list|grep "$@" >/dev/null; error="$?"
    if [ $error -gt 0 ]; then 
        echo "device $@ not connected" # >$GURU_ERROR_MSG
        exit 127
    else        
        return 0 
    fi
}


mask() {
# remove connection between hardware and core virtual master iNput stream
    check_kb "$@" 
    temp_id=$(get_input_device_id "$@")
    echo "id:$temp_id"
    xinput float $temp_id
}


enable(){
# returns connection between hardware and core virtual master iNput stream
# input: device name
    check_kb "$@" || return 123 
    core_id=$(get_input_device_id "Virtual core keyboard")   #;echo "core: $core_id" 
    temp_id=$(get_input_device_id "$@")                      #;echo "target: $temp_id"
    echo "id:$temp_id"
    xinput reattach $temp_id $core_id
}


parse_kb () {
# Parses key values from xinput output and parses key commands (for now)
# Event: time 1572541863.140094, type 1 (EV_KEY), code 2 (KEY_1), value 1
    
    key=$(echo "$@" | grep "code " | grep "EV_KEY" | grep -v "value 0") 
    key=${key#*code }             #;echo "$key"      # remove all before "code "
    key=${key#*"("}               #;echo "$key"      # remove all to first "("
    key=${key#*"("}               #;echo "$key"      # remove all to second from "(
    key=${key%%")"*}              #;echo "$key"      # remove ")" 
    key=${key#*KEY_}              #;echo "$key"      # remove "KEY_" prefix
    key=${key#*KP}                #;echo "$key"      # remove "PK" prefix 
    key_non_num=${key//[[:digit:]]/}

    case "$key_non_num" in      # To remove nueric variable names, dont know why do not worki
        LEFTALT)     history="$history'='"; printf "="; return 0 ;;
        LEFTSHIFT)   history="$history'#'"; printf "#"; return 0 ;;  # TODO remove "3" somehow without using string pointing to name.. do not work. 
        # TODO: bug: prints out leftover numbers of key string, dont know where those comes!
    esac

    case "$key" in
    # TODO: How to break out here?? we are in sub case function called by sub routine while loop, cannot exit mothers 
    # Numpad keys: 

    # ignored characters
        HOME)       printf "" ;;
        PAGEUP)     printf "" ;;
        END)        printf "" ;;
        PAGEDOWN)   printf "" ;;
        INSERT)     printf "" ;;

    # prited characters (added to history)
        SLASH)      history="$history'/'"; printf "/" ;;
        MINUS)      history="$history'-'"; printf "-" ;;
        PLUS)       history="$history'+'"; printf "+" ;;
        DOT)        history="$history','"; printf "," ;;
        LEFT)       history="$history'<'"; printf "←" ;;
        DOWN)       history="$history'_'"; printf "↓" ;;
        RIGHT)      history="$history'>'"; printf "→" ;;                       
        UP)         history="$history'^'"; printf "↑" ;; 
        ASTERISK)   history="$history'*'"; printf "*" ;;

    # Special function key

        BACKSPACE|DELETE)                      
            printf "\b \b" 
            [ $history ] && history=${history::-1}
            ;;

        ESC)                            # Cancel line
            for ((i=$character_count; i>=1; i--)); do
                printf "\b \b"
            done
            history=""
            ;;

        ENTER)                          # Confirm line
            printf "\n" 
            [ "$history" ] && printf "$history\n" >>"$history_file"
            history=""
            ;;             
        
    # Numerals

        *)
            key=${key//NUMLOCK/}    # NUMLOCK7NUMLOCK -> 7

            ((character_count++))               
            if [ "$key" ]; then
                printf "$key" 
                history="$history$key"
            fi
        esac
}


poll_kb() {
# Poll for given keyboard device
# TODO add long press function, doable, both states are reported in xinput put-put
# Event: time 1572541863.140094, type 1 (EV_KEY), code 2 (KEY_1), value 1
    sudo evtest "$1" | while read line; do parse_kb "$line"; done 
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    keyboard_main "$@"
    exit $?
fi


