#!/bin/bash
# guru client mqtt functions
# casa@ujo.guru 2020

source $GURU_BIN/common.sh
mqtt_indicator_key="f$(daemon.poll_order mqtt)"


mqtt.help () {
    gmsg -v1 -c white "guru-client mqtt help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mqtt start|end|status|help|install|remove|single|sub|pub "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " sub <topic>              subscribe to topic on local mqtt server "
    gmsg -v1 " single <topic>           subscribe to topic and wait for message, then exit "
    gmsg -v1 " pub <topic> <message>    printout mqtt service status "
    gmsg -v1 " log <topic> <log_file>   subscribe to topic and log it to file "
    gmsg -v1 " install                  install client requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "         $GURU_CALL mqtt status "
    gmsg -v2
}


mqtt.debug () {
    export GURU_VERBOSE=1
    export GURU_FLAG_COLOR=
    mqtt.status $@
    return $?
}


mqtt.enabled () {
    if [[ $GURU_MQTT_ENABLED ]] ; then
        gmsg -v3 -c green "mqtt enabled"
        return 0
    else
        gmsg -v2 -c black "mqtt disabled in user config"
        gmsg -v3 "type '$GURU_CALL config user' to change configurations"
        return 1
    fi
}


mqtt.main () {
    # command parser
    mqtt_indicator_key="f$(daemon.poll_order mqtt)"

    local _cmd="$1" ; shift
    case "$_cmd" in
               status|help|install|remove|enabled|debug)
                            mqtt.$_cmd "$@"
                            return $?
                            ;;

               single|sub|pub|poll)
                            mqtt.enabled || return 1
                            mqtt.$_cmd "$@"
                            ;;

               *)           echo "${FUNCNAME[0]}: unknown command: $_cmd"
        esac

    return 0
}



mqtt.online () {
    # check mqtt is functional, no printout
    mqtt.online_send () {
        # if mqtt message takes more than 2 seconds to return from closest mqtt server there is something wrong
        sleep 2
        timeout 2 mosquitto_pub -u $GURU_MQTT_USER -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT \
          -t "$GURU_HOSTNAME/online" -m "$(date +$GURU_FORMAT_TIME)" >/dev/null 2>&1 \
          || gmsg -v2 -c yellow "mqtt publish issue: $?"
    }

    # delayed publish
    mqtt.online_send &

    # subscribe to channel
    if timeout 3 mosquitto_sub -C 1 -u $GURU_MQTT_USER -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$GURU_HOSTNAME/online" $_options >/dev/null; then
            return 0
        else
            gmsg -v2 -c yellow "mqtt subscribe issue: $?" -k $mqtt_indicator_key
            return 1
    fi
}


mqtt.status () {
    # check mqtt broker is reachable.
    # printout and signal by corsair keyboard indicator led - if available
    mqtt_indicator_key="f$(daemon.poll_order mqtt)"

    gmsg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_MQTT_ENABLED ]] ; then
            gmsg -v1 -n -c green "mqtt enabled, "
        else
            gmsg -v1 -c black "mqtt disabled " -k $mqtt_indicator_key
            return 1
        fi

    if mqtt.online ; then
            gmsg -v1 -c green "mqtt broker available " -k $mqtt_indicator_key
            return 0
        else
            gmsg -v1 -c red "mqtt broker unreachable " -k $mqtt_indicator_key
            return 1
        fi
}


mqtt.sub () {
    # subscribe to channel, stay listening
    local _topic="$1" ; shift
    [[ $1 ]] && local _options="-$@"
    mosquitto_sub -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_topic" $_options
    #-u $GURU_MQTT_USER
    return $?
}


mqtt.single () {
    # subscribe to channel, stay listening
    local _topic="$1" ; shift
    [[ $1 ]] && local _options="-$@"
    mosquitto_sub -C 1 -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_topic" $_options
    # -u $GURU_MQTT_USER
    return $?
}


mqtt.pub () {
    # publish to mqtt server
    local _topic="$1" ; shift
    local _message="$@"
    local _error=

    [[ $_topic ]] || gmsg -v1 -x 127 "no topic specified"

    local _i=
    for _i in {1..5} ; do
          # -I $GURU_MQTT_CLIENT
          mosquitto_pub -u $GURU_MQTT_USER -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT \
          -t "$_topic" -m "$_message" >/dev/null 2>&1
          _error=$?

          if (( $_error )) ; then
                  gmsg -v2 -c red "mqtt connection $_i error $_error" -k $mqtt_indicator_key
              else
                  gmsg -n -c green -k $mqtt_indicator_key
                  break
              fi
        done

    return $_error
}


mqtt.log () {
    local _topic="$1" ; shift
    local _log_file=$GURU_LOG ; [[ $1 ]] && _log_file="$1"
    mosquitto_sub -u $GURU_MQTT_USER -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_topic" >> $_log_file
    return $?
}


mqtt.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: mqtt status polling started" -k $mqtt_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: mqtt status polling ended" -k $mqtt_indicator_key
            ;;
        status )
            mqtt.status
            ;;
        *)  mqtt.help
            ;;
        esac

}


mqtt.install () {
    sudo apt update
    sudo apt install mosquitto-clients \
        && gmsg -c green "guru is now ready to mqtt"  \
        || gmsg -c yellow "error $? during install mosquitto-clients"
    return 0
    #sudo add-apt-repository ppa:certbot/certbot || return $?
    #sudo apt-get install certbot || return $?
}


mqtt.remove () {
    sudo apt remove mosquitto-clients
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    #source common.sh
    mqtt.main "$@"
    exit "$?"
fi

