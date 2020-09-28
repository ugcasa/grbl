#!/bin/bash
# guru client corsair led notification functions
# casa@ujo.guru 2020


mqtt.main () {
    # corsair command parser
    #mqtt.check                   # check than ckb-next-darmon, ckb-next and pipes are started and start is not
    local _cmd="$1" ; shift

    case "$_cmd" in

               start|end|status|help|install|remove)
                            mqtt.$_cmd ; return $? ;;

               check|write)
                            mqtt.$_cmd ; return $? ;;

               *)           echo "mqtt: unknown command"
        esac

    return 0
}


mqtt.write () {
    gmsg -v 2 TBD
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
    gmsg -v 2 TBD
     return 1
}


mqtt.online () {
    gmsg -v 2 TBD
    return 1
}


mqtt.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "starting message bus status poller"
    corsair.write f3 off
}


mqtt.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "ending message bus status polling"
    corsair.write f3 white
}


mqtt.status () {

    source $GURU_BIN/corsair.sh

    # check mqtt is reachable
    if mqtt.online "$GURU_LOCAL_SERVER" "$GURU_MQTT_LOCAL_PORT" ; then
            gmsg -v 1 -t -c green "message server online"
            corsair.write f3 green
        elif mqtt.online "$GURU_REMOTE_SERVER" "$GURU_MQTT_REMOTE_PORT" ; then
            gmsg -v 1 -t -c yellow "remote message server online "
            corsair.write f3 yellow
        else
            gmsg -v 1 -t -c red "message server offline"
            corsair.write f3 red
        fi
}


mqtt.install () {
    return 0
}


mqtt.remove () {
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc2"
    export GURU_VERBOSE=2
    source "$GURU_BIN/lib/deco.sh"
    mqtt.main "$@"
    exit "$?"
fi

