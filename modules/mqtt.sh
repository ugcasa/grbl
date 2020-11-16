#!/bin/bash
# guru client mqtt functions
# casa@ujo.guru 2020
source $GURU_BIN/common.sh

mqtt.help () {
    gmsg -v1 -c white "guru-client mqtt help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mqtt start|end|status|help|install|remove|sub|pub "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " sub <topic>              subsribe to topic on local mqt server "
    gmsg -v1 " pub <topic> <message>    printout mqtt service status "
    gmsg -v1 " install                  install requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v3 " start                    start status polling "
    gmsg -v3 " end                      end status polling "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "         $GURU_CALL mqtt status"
    gmsg -v2
}


mqtt.main () {
    # corsair command parser
    indicator_key='F'"$(poll_order mqtt)"

    local _cmd="$1" ; shift
    case "$_cmd" in
               start|end|status|help|install|remove|sub|pub)
                            mqtt.$_cmd "$@" ; return $? ;;
               *)           echo "${FUNCNAME[0]}: unknown command"
        esac

    return 0
}


mqtt.status () {
    gmsg -v2 -c black "${FUNCNAME[0]} TBD"
    return 1
}


mqtt.sub () {
    # subsribe to channel, stay listening
    local _mqtt_topic="$1" ; shift
    gmsg -v2 "h:$GURU_MQTT_REMOTE_SERVER p:$GURU_MQTT_REMOTE_PORT t:$_mqtt_topic"
    mosquitto_sub -v -h $GURU_MQTT_REMOTE_SERVER -p $GURU_MQTT_REMOTE_PORT -t "$_mqtt_topic"
    return $?
}


mqtt.pub () {
    local _mqtt_topic="$1" ; shift
    local _mqtt_message="$@"
    gmsg -v2 "h:$GURU_MQTT_REMOTE_SERVER p:$GURU_MQTT_REMOTE_PORT t:$_mqtt_topic:$_mqtt_message"
    mosquitto_pub -h $GURU_MQTT_REMOTE_SERVER -p $GURU_MQTT_REMOTE_PORT -t "$_mqtt_topic" -m "$_mqtt_message"
    return $?
}


mqtt.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "${FUNCNAME[0]}: starting message bus status poller"
    corsair.main set $indicator_key off
}


mqtt.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "${FUNCNAME[0]}: ending message bus status polling"
    corsair.main set $indicator_key white
}


mqtt.status () {
    # sub mqtt is reachable
    if mqtt.status "$GURU_REMOTE_SERVER" "$GURU_MQTT_REMOTE_PORT" ; then
            gmsg -v 1 -t -c green "${FUNCNAME[0]}: local available" -q "/status"
            corsair.main set $indicator_key green
            return 0
        elif mqtt.status "$GURU_REMOTE_SERVER" "$GURU_MQTT_REMOTE_PORT" ; then
            gmsg -v 1 -t -c yellow "${FUNCNAME[0]}: remote available " -q "/status"
            corsair.main set $indicator_key yellow
            return 0
        else
            gmsg -v 1 -t -c red "${FUNCNAME[0]}: mqtt offline"
            corsair.main set $indicator_key red
            return 101
        fi
}


mqtt.install () {
    sudo apt update && \
    sudo apt install mosquitto_clients
    return 0
}


mqtt.remove () {
    sudo apt remove mosquitto_clients
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    mqtt.main "$@"
    exit "$?"
fi

