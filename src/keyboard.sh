#!/bin/bash
# keyboard.sh

# Known devices
## USB connected open source barcode reader 
barcode="Newland Auto-ID NLS IOTC PRDs HID KBW"
barcode_dev='/dev/input/by-id/usb-Newland_Auto-ID_NLS_IOTC_PRDs_HID_KBW_EY016945-event-kbd'

## USB based Nokia 3110 like interface 
phone_kb="Yealink usb-p1k" 
phone_kb_dev='/dev/input/by-id/usb-Yealink_Network_Technology_Ltd._VOIP_USB_Phone-event-if03'

history=""
history_file="$HOME/tmp/kb.log"


keyboard_main() {

    command="$1"; shift

    case "$command" in

        disable|ds)
            mask_kb "$phone_kb"
            mask_kb "$barcode"
            ;;
        
        enable|en)  
            enable_kb "$phone_kb"
            enable_kb "$barcode"        
            ;;

        barcode|poll_barcode)  
            mask_kb "$barcode"      
            poll_kb "$barcode_dev"         
            enable_kb "$barcode"          
            ;;

        phone|phone_kb|poll-phone-kb)  
            mask_kb "$phone_kb" 
            poll_kb "$phone_kb_dev"
            enable_kb "$phone_kb"
            ;;

        install|remove)
            sudo apt "$command" xinput
            ;;
        *)
        echo "duud!"
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


mask_kb() {
    # remove connection between hardware and core virtual master iNput stream
    check_kb "$@" 
    temp_id=$(get_input_device_id "$@")
    xinput float $temp_id
}


enable_kb(){
    # returns connection between hardware and core virtual master iNput stream
    # input: device name
    check_kb "$@" || return 123 
    temp_id=$(get_input_device_id "$@")                      #;echo "target: $temp_id"
    core_id=$(get_input_device_id "Virtual core keyboard")   #;echo "core: $core_id" 
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
    key=${key#*KEY_}              #;echo "$key"      # remove "KEY_" form value
    
    case "$key" in
        # TODO: How to break out here?? we are in sub case function called by sub routine while loop, cannot exit mothers 
        LEFTSHIFT*) printf "#" ;;  
        LEFT)       printf "←" ;;
        DOWN)       printf "↓" ;;
        RIGHT)      printf "→" ;;                       
        UP)         printf "↑" ;; 

        KPASTERISK) 
                history="$history "
                printf " " 
                ;;

        BACKSPACE)  
            printf "\b \b" 
            [ $history ] && history=${history::-1}
            ;;


        ESC)
            for ((i=$counter; i>=1; i--)); do
                printf "\b \b"
            done
            history=""
            ;;

        ENTER)      
            printf "\n" 
            [ "$history" ] && printf "$history\n" >>"$history_file"
            history=""
            ;;                     
        *)
            ((counter++))
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


