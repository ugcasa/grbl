#!/bin/bash
# guru client mqtt functions
# casa@ujo.guru 2020
source $GURU_BIN/common.sh

mqtt.help () {
    gmsg -v1 -c white "guru-client mqtt help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mqtt start|end|status|help|install|remove|single|sub|pub "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " sub <topic>              subsribe to topic on local mqt server "
    gmsg -v1 " single <topic>           subsribe to topic and wait for message and exit "
    gmsg -v1 " pub <topic> <message>    printout mqtt service status "
    gmsg -v1 " log <topic> <log_file>   subsribe to topic and log it to file "
    gmsg -v1 " install                  install client requirements "
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
               start|end|status|help|install|remove|single|sub|pub)
                            mqtt.$_cmd "$@" ; return $? ;;
               *)           echo "${FUNCNAME[0]}: unknown command"
        esac

    return 0
}

mqtt.online () {

    _send () {
        touch /tmp/guru-socket
        while [[ -f /tmp/guru-socket ]]; do
            mqtt.pub "$GURU_HOSTNAME/test" "online"
            sleep 1
        done
    }

    _send &

    if mqtt.single "$GURU_HOSTNAME/test" >/dev/null ; then
            rm /tmp/guru-socket
            return 0
        else
            rm /tmp/guru-socket
            return 1
    fi
}


mqtt.sub () {
    # subsribe to channel, stay listening
    local _mqtt_topic="$1" ; shift
    mosquitto_sub -v -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic"
    return $?
}


mqtt.single () {
    # subsribe to channel, stay listening
    local _mqtt_topic="$1" ; shift
    mosquitto_sub -C 1 -v -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic"
    return $?
}


mqtt.pub () {
    local _mqtt_topic="$1" ; shift
    local _mqtt_message="$@"
    mosquitto_pub -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic" -m "$_mqtt_message"
    return $?
}


mqtt.log () {
    local _mqtt_topic="$1" ; shift
    local _log_file=$GURU_LOG ; [[ $1 ]] && _log_file="$1"
    mosquitto_sub -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic" >> $_log_file
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
    source corsair.sh
    if mqtt.online "$GURU_MQTT_BROKER" "$GURU_MQTT_PORT" ; then
            gmsg -v1 -t -k $indicator_key -c green "${FUNCNAME[0]}: broker available"
            return 0
        else
            gmsg -v1 -t -k $indicator_key -c red "${FUNCNAME[0]}: broker offline"
            return 1
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

