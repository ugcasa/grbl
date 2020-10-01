#!/bin/bash
# guru client corsair led notification functions
# casa@ujo.guru 2020


mqtt.main () {
    # corsair command parser
    indicator_key='F'"$(poll_order mqtt)"

    local _cmd="$1" ; shift
    case "$_cmd" in

               start|end|status|help|install|remove)
                            mqtt.$_cmd ; return $? ;;

               check|write)
                            mqtt.$_cmd ; return $? ;;

               *)           echo "${FUNCNAME[0]}: unknown command"
        esac

    return 0
}


mqtt.write () {
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 0
}


mqtt.help () {
    gmsg -v 1 -c white "guru-client mqtt help -----------------------------------------------"
    gmsg -v 2
    gmsg -v 0 "usage:   $GURU_CALL mqtt [start|end|status|help|install|remove|check|write] "
    gmsg -v 2
    gmsg -v 1 -c white "commands:"
    gmsg -v 1 " status          printout mqtt service status "
    gmsg -v 1 " start           start status polling "
    gmsg -v 1 " end             end status polling "
    gmsg -v 1 " install         install requirements "
    gmsg -v 1 " remove          remove installed requirements "
    gmsg -v 2 " help            printout this help "
    gmsg -v 2
    gmsg -v 1 -c white "example:"
    gmsg -v 1 "         $GURU_CALL mqtt status"
    gmsg -v 2
}


mqtt.check () {
    # Check mqtt client tools are ok
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 1
}


mqtt.online () {
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 1
}


mqtt.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "${FUNCNAME[0]}: starting message bus status poller"
    corsair.write $indicator_key off
}


mqtt.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "${FUNCNAME[0]}: ending message bus status polling"
    corsair.write $indicator_key white
}


mqtt.status () {

    source $GURU_BIN/corsair.sh

    # check mqtt is reachable
    if mqtt.online "$GURU_LOCAL_SERVER" "$GURU_MQTT_LOCAL_PORT" ; then
            gmsg -v 1 -t -c green "${FUNCNAME[0]}: message server online"
            corsair.write $indicator_key green
            return 0 
        elif mqtt.online "$GURU_REMOTE_SERVER" "$GURU_MQTT_REMOTE_PORT" ; then
            gmsg -v 1 -t -c yellow "${FUNCNAME[0]}: remote message server online "
            corsair.write $indicator_key yellow
            return 0 
        else
            gmsg -v 1 -t -c red "${FUNCNAME[0]}: message server offline"
            corsair.write $indicator_key red
            return 101 
        fi
}


mqtt.install () {
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 0
}


mqtt.remove () {
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc2"
    export GURU_VERBOSE=2
    source "$GURU_BIN/deco.sh"
    mqtt.main "$@"
    exit "$?"
fi

