#!/bin/bash
# guru tool-kit volume control functions. casa@ujo.guru 2020

volume_main () {
    # set volume
    get_volume

    command="$1"
    shift

    [ $(awk -F"[][]" '/dB/ { print $6 }' <(amixer sget Master)) == "off" ] && mute      # input anything removes mute if it is on

    case "$command" in 

            get)
                get_volume
                echo "$volume"
                ;;

            unmute|umute)
                return 0
                ;; 

            mute)   
                mute
                ;;

            up|+)   
                amixer -D pulse sset Master 5%+ >/dev/null   
                ;;

            down|-) 
                
                amixer -D pulse sset Master 5%- >/dev/null
                ;;
            
            fadeup|fadedown)
                $command "$@"
                ;;

            *)
                if [[ "$command" =~ ^[0-9]+$ ]]; then
                    amixer -D pulse sset Master "$command"% >/dev/null
                else
                    echo "volume needs to be numeral" >$GURU_ERROR_MSG
                    return 100
                fi                
    esac
}


get_volume() {
        volume=$(awk -F"[][]" '/%/ { print $2 }' <(amixer -D pulse sget Master|grep "Front Left"))
        volume=${volume//%}
}


mute() {
    amixer -D pulse set Master toggle >/dev/null        
}


fadedown () {
    get_volume
    volume=$((volume/5))
    for (( i=0; i<=$volume; i++ )); do         
        amixer -D pulse sset Master 5%- >/dev/null
        sleep 0.02
    done
}


fadeup () {
    get_volume
    [ "$1" ] && local to=$1 || local to=50
    volume=$(($to-volume))
    volume=$((volume/5))
    for (( i=0; i<=$volume; i++ )); do 
        amixer -D pulse sset Master 5%+ >/dev/null
        sleep 0.02
    done
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    volume_main "$@"     
    exit "$?"      
fi


