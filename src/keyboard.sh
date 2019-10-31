#!/bin/bash
# keyboard.sh

# Known devices
## USB connected open source barcode reader 
barcode="Newland Auto-ID NLS IOTC PRDs HID KBW"
barcode_dev='/dev/input/by-id/usb-Newland_Auto-ID_NLS_IOTC_PRDs_HID_KBW_EY016945-event-kbd'

## USB based Nokia 3110 like interface 
phone_kb="Yealink usb-p1k" 
phone_kb_dev='/dev/input/by-id/usb-Yealink_Network_Technology_Ltd._VOIP_USB_Phone-event-if03'


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
    
        test1|t1)
            mask_kb "$phone_kb"
            output=$(poll_kb "$barcode") 
            echo "got: $output" 
            enable_kb "$phone_kb"           
            ;;

        test2|t2)
            mask_kb "$phone_kb"
            mask_kb "$barcode"
            read -p "disabled: " foo
            [ "$foo" ] && echo "failed" || echo "passed"
            enable_kb "$phone_kb"
            enable_kb "$barcode"
            read -p "enabled: " foo
            [ "$foo" ] && echo "passed" || echo "failed"
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
    # remove connection between hardware and core virtual master imput stream
    check_kb "$@" 
    temp_id=$(get_input_device_id "$@")
    xinput float $temp_id
}


enable_kb(){
    # returns connection between hardware and core virtual master imput stream
    # input: device name
    echo "$0: device not connected" >$GURU_ERROR_MSG
    check_kb "$@" && rm $GURU_ERROR_MSG || return 123 
    temp_id=$(get_input_device_id "$@")                      #;echo "targed: $temp_id"
    core_id=$(get_input_device_id "Virtual core keyboard")   #;echo "core: $core_id" 
    xinput reattach $temp_id $core_id
}


parse_kb () {
    # Parses key values from xinput output and parses key commands (for now)
    # Event: time 1572541863.140094, type 1 (EV_KEY), code 2 (KEY_1), value 1
    data_array=()
    line=$(echo "$@" | grep "code " | grep "EV_KEY" | grep -v "value 0") 
    line=${line#*code }             #;echo "$line"      # remove all before "code "
    line=${line#*"("}               #;echo "$line"      # remove all to first "("
    line=${line#*"("}               #;echo "$line"      # remove all to second from "(
    line=${line%%")"*}              #;echo "$line"      # remove ")" 
    line=${line#*KEY_}              #;echo "$line"      # remove "KEY_" form value
    
    case "$line" in
        ENTER)          
                    #printf "\n" 
                        ;; # TODO: How to break out here?? we are in sub case function called by sub routine while loop, cannot exit mothers 
        BACKSPACE)  printf "\b \b" ;;
        LEFTSHIFT*) printf "#" ;;  
        KPASTERISK) printf "*" ;;
        LEFT)       printf "←" ;;
        UP)         
            #printf "↑" 
            >"$HOME/tmp/file.rm"
            ;;

        DOWN)       printf "↓" ;;
        RIGHT)      printf "→" ;;                       
        ESC)
            for ((i=$counter; i>=1; i--)); do
                printf "\b \b"
            done
            ;;
        *)
            ((counter++))
            if [ "$line" ]; then
                printf "$line"             
                data_array+=("$line")
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


