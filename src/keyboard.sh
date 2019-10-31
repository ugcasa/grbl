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

        test)
            mask_kb "$phone_kb"
            mask_kb "$barcode"
            read -p "disabled: " foo
            [ "$foo" ] && echo "failed" || echo "passed"
            enable_kb "$phone_kb"
            enable_kb "$barcode"
            read -p "enabled: " foo
            [ "$foo" ] && echo "passed" || echo "failed"
            ;;

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
    
        *)
        echo "duud!"
    esac
}


get_input_device_id() {
    # Get given device name ID
    tab=$(printf "\t")6415600549813
    temp_id=$(xinput --list|grep "$@")
    temp_id=${temp_id#*=}   
    temp_id=${temp_id%%$tab*}
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
    # input device name
    echo "$0: device not connected" >$GURU_ERROR_MSG
    check_kb "$@" && rm $GURU_ERROR_MSG || return 123 
    temp_id=$(get_input_device_id "$@")                      #;echo "targed: $temp_id"
    core_id=$(get_input_device_id "Virtual core keyboard")   #;echo "core: $core_id" 
    xinput reattach $temp_id $core_id
}


parse_kb () {
    line=$(echo "$@" | grep "code " | grep "EV_KEY" | grep -v "value 0") 
    line=${line#*code }             #;echo "$line"
    line=${line#*"("}               #;echo "$line"
    line=${line#*"("}               #;echo "$line"
    line=${line%%")"*}              #;echo "$line"
    line=${line#*KEY_}              #;echo "$line"
    case $line in
        ENTER)
            printf "\n"
            ;;
        BACKSPACE)
            printf "\b \b"                
            ;;
        LEFTSHIFT*)
            printf "#"
            ;;                
        KPASTERISK)
            printf "*"
            ;;
        LEFT)
            printf "←"
            ;;
        UP)
            printf "↑"
            ;;
        DOWN)
            printf "↓"
            ;;
        RIGHT)
            printf "→"
            ;;               
        ESC)
            for ((i=$counter; i>=1; i--)); do
                printf "\b \b"
            done
            ;;
        *)
            ((counter++))
            [ "$line" ] && printf "$line" 
        esac
}


poll_kb() {
    # Event: time 1572541863.140094, type 1 (EV_KEY), code 2 (KEY_1), value 1
    # TODO long press
    sudo evtest "$1" | while read line; do parse_kb "$line"; done 
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    keyboard_main "$@"
    exit $?
fi


