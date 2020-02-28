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
            
            fadeup|fadedown|silence)
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

    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer -D pulse sset Master 5%- >>/dev/null
        sleep 0.2
    done
}


fadeup () {

    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer -D pulse sset Master 5%+ >>/dev/null
        sleep 0.2
    done
    return 0
}


silence () {	# alias
	$GURU_CALL mute
	$GURU_CALL play stop
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    volume_main "$@"     
    exit "$?"      
fi


