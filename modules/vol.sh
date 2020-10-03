#!/bin/bash
# guru-client volume control functions. casa@ujo.guru 2020

volume_main () {
    # set volume
    get_volume

    command="$1"
    shift

    [ $(awk -F"[][]" '/dB/ { print $6 }' <(amixer sget Master)) == "off" ] && mute      # input anything removes mute if it is on

    case "$command" in

            get|status)
                get_volume
                echo "$volume"
                ;;

            unmute|umute|silence)
                return 0
                ;;

            mute)
                mute
                ;;

            up|+)
                volume_up "$@"
                ;;

            down|-)
                volume_down "$@"
                ;;

            fadeup|fadedown)
                $command "$@"
                ;;
            help)
                echo "usage:    $GURU_CALL vol [get|mute|unmute|up|down|fadeup|fadedown|help]"
                ;;
            *)
                if [[ "$command" =~ ^[0-9]+$ ]]; then
                    set_volume "$command"
                    return 0
                else
                    echo "volume needs to be numeral" >$GURU_ERROR_MSG
                    return 100
                fi
                ;;
    esac
}

set_volume() {
    amixer -D pulse sset Master "$1"% >/dev/null;       # weird, without ; syntax error near unexpected token ` {'
}


volume_up() {
    [ "$1" ] && step="$1" || step=10
    amixer -D pulse sset Master "$step"%+ >/dev/null
}


volume_down() {
    [ "$1" ] && step="$1" || step=10
    amixer -D pulse sset Master "$step"%- >/dev/null
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
        volume_down
        sleep 0.02
    done
}


fadeup () {
    get_volume;                                     # weird, without ;
    [ "$1" ] && set_to="$1" || set_to=50
    volume=$(($set_to-volume))
    volume=$((volume/5))
    for (( i=0; i<=$volume; i++ )); do
        volume_up
        sleep 0.02
    done
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    volume_main "$@"
    exit "$?"
fi


