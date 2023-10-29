#!/bin/bash
# guru-client volume control functions. casa@ujo.guru 2020
declare -g volume=

vol.main () {
    # set volume
    command="$1"
    shift

    [ $(awk -F"[][]" '/dB/ { print $6 }' <(amixer sget Master)) == "off" ] && vol.mute      # input anything removes mute if it is on

    case "$command" in

            mute|fadeup|fadedown|get|set|status)
                vol.$command "$@"
                ;;

            up|+)
                vol.up "$@"
                ;;

            down|-)
                vol.down "$@"
                ;;

            help)
                echo "usage:    $GURU_CALL vol [get|mute|unmute|up|down|fadeup|fadedown|help]"
                ;;
            *)
                vol.status
                ;;
    esac
}


vol.status () {
    gr.msg -v2 -n "volume level is: "
    echo $(vol.get)
}


vol.set() {

    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        gr.msg -c error "volume must be number"
        return 10
    fi

    amixer -D pulse sset Master "$1"% >/dev/null;       # weird, without ; syntax error near unexpected token ` {'
}


vol.up() {
    [ "$1" ] && step="$1" || step=10
    amixer -D pulse sset Master "$step"%+ >/dev/null
}


vol.down() {
    [ "$1" ] && step="$1" || step=10
    amixer -D pulse sset Master "$step"%- >/dev/null
}


vol.get() {
    volume=$(awk -F"[][]" '/%/ { print $2 }' <(amixer -D pulse sget Master | grep "Front Left"))
    echo $volume | sed 's/%//g'
}


vol.mute() {
    amixer -D pulse set Master toggle >/dev/null
}


vol.fadedown () {
    volume=$(vol.get)
    volume=$((volume/5))
    for (( i=0; i<=$volume; i++ )); do
        vol.down
        sleep 0.05
    done
}


vol.fadeup () {
    volume=$(vol.get)
    [ "$1" ] && set_to="$1" || set_to=50
    volume=$(($set_to-volume))
    volume=$((volume/5))
    for (( i=0; i<=$volume; i++ )); do
        vol.up
        sleep 0.05
    done
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    vol.main "$@"
    exit "$?"
fi


