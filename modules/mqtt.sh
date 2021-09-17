#!/bin/bash
# guru client mqtt functions
# casa@ujo.guru 2020 - 2021

source $GURU_BIN/common.sh
mqtt_indicator_key="f$(daemon.poll_order mqtt)"

mqtt.main () {
    # mqtt main command parser

    local _cmd="$1" ; shift
    mqtt_indicator_key="f$(daemon.poll_order mqtt)"

    case "$_cmd" in
               status|help|install|remove|enabled)
                    mqtt.$_cmd "$@"
                    return $?
                    ;;

               single|sub|pub|poll)
                    mqtt.enabled || return 1
                    mqtt.$_cmd "$@"
                    ;;
               *)   gmsg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 2
        esac
    return 0
}


mqtt.help () {
    # general help

    gmsg -v1 -c white "guru-client mqtt help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mqtt status|sub|pub|start|end|single|help|install|remove "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " status                   show status of default mqtt server "
    gmsg -v1 " sub <topic>              subscribe to topic on local mqtt server "
    gmsg -v1 " pub <topic> <message>    printout mqtt service status "
    gmsg -v1 " log <topic> <log_file>   subscribe to topic and log it to file "
    gmsg -v1 " single <topic>           subscribe to topic and wait for message, then exit "
    gmsg -v1 " install                  install client requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2 " help                     printout this help "
    gmsg -v2
    gmsg -v1 -c white "examples: "
    gmsg -v2 "         $GURU_CALL mqtt status "
    gmsg -v1 "         $GURU_CALL mqtt sub '#' "
    gmsg -v1 "         $GURU_CALL mqtt pub '/msg Hello!' "
    gmsg -v2
    return 0
}

# TBD enabled, online and status should combine to one function?

mqtt.enabled () {
    # check is function activated and output instructions to enable function on user configuration

    if [[ $GURU_MQTT_ENABLED ]] ; then
        # gmsg -v2 -c green "mqtt enabled"
        return 0
    else
        gmsg -v2 -c black "mqtt disabled in user config"
        gmsg -v3 "type '$GURU_CALL config user' to change configurations"
        return 1
    fi
}


mqtt.online () {
    # check mqtt is functional, no printout

    mqtt.online_send () {
        # if mqtt message takes more than 2 seconds to return from closest mqtt server there is something wrong

        sleep 2
        timeout 1 mosquitto_pub \
            -u "$GURU_MQTT_USER" \
            -h "$GURU_MQTT_BROKER" \
            -p "$GURU_MQTT_PORT" \
            -t "$GURU_HOSTNAME/online" \
            -m "$(date +$GURU_FORMAT_DATE) $(date +$GURU_FORMAT_TIME)" \
             >/dev/null 2>&1 \
        || gmsg -v2 -c yellow "timeout or mqtt publish issue: $?"
    }

    # delayed publish
    mqtt.online_send &

    # subscribe to channel no output
    if timeout 3 mosquitto_sub -C 1 \
                    -u "$GURU_MQTT_USER" \
                    -h "$GURU_MQTT_BROKER" \
                    -p "$GURU_MQTT_PORT" \
                    -t "$GURU_HOSTNAME/online" \
                    $_options >/dev/null
        then
            return 0
        else
            gmsg -v2 -c yellow \
                -k $mqtt_indicator_key \
                "mqtt subscribe issue: $?"
            return 1
    fi
}


mqtt.sub () {
    # subscribe to channel, stay listening

    local _topic="$1" ; shift
    # lazy way to deliver arguments
    [[ $1 ]] && local _options="-$@"
    # susbsribe
    mosquitto_sub \
        -h $GURU_MQTT_BROKER \
        -p $GURU_MQTT_PORT \
        -t "$_topic" $_options
        # TBD why -u $GURU_MQTT_USER was removed?
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
          mosquitto_pub \
            -u $GURU_MQTT_USER \
            -h $GURU_MQTT_BROKER \
            -p $GURU_MQTT_PORT \
            -t "$_topic" \
            -m "$_message" >/dev/null 2>&1
          _error=$?

          if (( $_error )) ; then
                  gmsg -v2 -c red \
                    -k $mqtt_indicator_key \
                    "mqtt connection $_i error $_error"
              else
                  gmsg -n -c green -k $mqtt_indicator_key
                  break
              fi
        done
    return $_error
}


mqtt.single () {
    # subscribe to channel, stay listening until one message received

    local _topic="$1" ; shift
    # lazy ass variable transport. TBD -- for this use
    [[ $1 ]] && local _options="-$@"
    mosquitto_sub -C 1 \
        -h "$GURU_MQTT_BROKER" \
        -p "$GURU_MQTT_PORT" \
        -t "$_topic" \
        $_options
        # -u $GURU_MQTT_USER
    return $?
}


mqtt.log () {
    # start topic log to file

    local _topic="$1" ; shift
    local _log_file=$GURU_LOG ; [[ $1 ]] && _log_file="$1"
    mosquitto_sub \
        -u "$GURU_MQTT_USER" \
        -h "$GURU_MQTT_BROKER" \
        -p "$GURU_MQTT_PORT" \
        -t "$_topic" >> $_log_file
    return $?
}


# ################# daemon functions #######################


mqtt.status () {
    # check mqtt broker is reachable.

    mqtt_indicator_key="f$(daemon.poll_order mqtt)"

    gmsg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_MQTT_ENABLED ]] ; then
            gmsg -v1 -n -c green "enabled, "
        else
            gmsg -v1 -c black "disabled " \
                 -k $mqtt_indicator_key
            return 1
        fi

    # printout and signal by corsair keyboard indicator led
    if mqtt.online ; then
            gmsg -v1 -c green "broker available " \
                 -k $mqtt_indicator_key
            return 0
        else
            gmsg -v1 -c red "broker unreachable " \
                 -k $mqtt_indicator_key
            return 1
        fi
    #try to keep possible error messages in module segment by waiting mqtt.sub reply after timeout
    sleep 3
}


mqtt.poll () {
    # daemon required polling functions

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black \
                -k $mqtt_indicator_key \
                "${FUNCNAME[0]}: mqtt status polling started"
            ;;
        end )
            gmsg -v1 -t -c reset \
                -k $mqtt_indicator_key \
                "${FUNCNAME[0]}: mqtt status polling ended"
            ;;
        status )
            mqtt.status
            ;;
        *)  mqtt.help
            ;;
        esac
}


mqtt.install () {
    # install mosquitto mqtt clients

    sudo apt update
    sudo apt install mosquitto-clients \
        && gmsg -c green "guru is now ready to mqtt" \
        || gmsg -c yellow "error $? during install mosquitto-clients"
    return 0

    # TBD cartification requirements
    # sudo add-apt-repository ppa:certbot/certbot || return $?
    # sudo apt-get install certbot || return $?
}


mqtt.remove () {
    # remove mosquitto mqtt clients

    sudo apt remove mosquitto-clients && return 0
    return 1
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    #source common.sh
    mqtt.main "$@"
    exit "$?"
fi

