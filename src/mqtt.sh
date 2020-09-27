#!/bin/bash
# guru tool-kit corsair led notification functions
# casa@ujo.guru 2020


mqtt.main () {
    # corsair command parser
    mqtt.check                   # check than ckb-next-darmon, ckb-next and pipes are started and start is not
    local _cmd="$1" ; shift
    case "$_cmd" in
               start|end|status)  mqtt.$_cmd ; return $? ;;
            help|install|remove)  mqtt.$_cmd ; return $? ;;
                              *)  echo "mqtt.sh: unknown command"
        esac
    return 0
}


mqtt.write () {
    return 0
}


mqtt.help () {
    echo "-- guru tool-kit corsair help -----------------------------------------------"
    printf "usage:\t\t %s corsair [command] \n\n" "$GURU_CALL"
    printf "commands:\n"
    printf " install         install requirements \n"
    printf " status          launch keyboard status view \n"
    printf " help            this help \n\n"
    printf "\nexample:"
    printf "\t %s corsair status \n" "$GURU_CALL"
}


mqtt.check () {
     # Check mqtt client tools are ok
     return 1
}


mqtt.online () {
    return 1
}


mqtt.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "F3 ${WHT}WHITE${NC}"
    corsair.write $F3 $_WHITE
}


mqtt.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "F3 OFF"
    corsair.write $F3 $_OFF
}


mqtt.status () {

    source $GURU_BIN/corsair.sh

    # check mqtt is reachable
    if mqtt.online "$GURU_LOCAL_SERVER" "$GURU_MQTT_LOCAL_PORT" ; then
            gmsg -v 1 -t "F3 ${GRN}GREEN${NC}"
            corsair.write $F3 $_GREEN
        elif mqtt.online "$GURU_REMOTE_SERVER" "$GURU_MQTT_REMOTE_PORT" ; then
            gmsg -v 1 -t "F3 ${YEL}YELLOW${NC}"
            corsair.write $F3 $_YELLOW
        else
            gmsg -v 1 -t "F3 ${RED}RED${NC}"
            corsair.write $F3 $_RED
        fi
}


mqtt.install () {
    return 0
}


mqtt.remove () {
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        mqtt.main "$@"
        exit "$?"
fi

