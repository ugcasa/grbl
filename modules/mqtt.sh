#!/bin/bash
# guru client mqtt functions casa@ujo.guru 2020 - 2021

declare -g mqtt_rc="/tmp/guru-cli_mqtt.rc"

mqtt.main () {
# mqtt main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in
               status|help|install|remove|enabled|poll)
                    mqtt.$_cmd "$@"
                    return $?
                    ;;

               single|sub|pub)
                    mqtt.enabled || return 1
                    mqtt.$_cmd "$@"
                    ;;
               *)   gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 2
        esac
    return 0
}


mqtt.help () {
# general help

    gr.msg -v1 -c white "guru-client mqtt help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL mqtt status|sub|pub|start|end|single|help|install|remove "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " status                   show status of default mqtt server "
    gr.msg -v1 " sub <topic>              subscribe to topic on local mqtt server "
    gr.msg -v1 " pub <topic> <message>    printout mqtt service status "
    gr.msg -v1 " log <topic> <log_file>   subscribe to topic and log it to file "
    gr.msg -v1 " single <topic>           subscribe to topic and wait for message, then exit "
    gr.msg -v1 " install                  install client requirements "
    gr.msg -v1 " remove                   remove installed requirements "
    gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "examples: "
    gr.msg -v2 "         $GURU_CALL mqtt status "
    gr.msg -v1 "         $GURU_CALL mqtt sub '#' "
    gr.msg -v1 "         $GURU_CALL mqtt pub '/msg Hello!' "
    gr.msg -v2
    return 0
}



mqtt.rc () {
# source configurations

    if  [[ ! -f $mqtt_rc ]] || \
        [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mqtt.cfg) - $(stat -c %Y $mqtt_rc) )) -gt 0 ]]
        then
            mqtt.make_rc && \
                gr.msg -v1 -c dark_gray "$mqtt_rc updated"
        fi

    source $mqtt_rc
}


mqtt.make_rc () {
# make core module rc file out of configuration file

    if ! source config.sh ; then
            gr.msg -c yellow "unable to load configuration module"
            return 100
        fi

    if [[ -f $mqtt_rc ]] ; then
            rm -f $mqtt_rc
        fi

    if ! config.make_rc "$GURU_CFG/$GURU_USER/mqtt.cfg" $mqtt_rc ; then
            gr.msg -c yellow "configuration failed"
            return 101
        fi

    chmod +x $mqtt_rc

    if ! source $mqtt_rc ; then
            gr.msg -c red "unable to source configuration"
            return 202
        fi
}


mqtt.enabled () {
# check is function activated and output instructions to enable function on user configuration

    if [[ $GURU_MQTT_ENABLED ]] ; then
        # gr.msg -v2 -c green "mqtt enabled"
        return 0
    else
        gr.msg -v2 -c black "mqtt disabled in user config"
        gr.msg -v3 "type '$GURU_CALL config user' to change configurations"
        return 1
    fi
}


mqtt.online () {
# check mqtt is functional, no printout

    mqtt.online_send () {
        # if mqtt message takes more than 2 seconds to return from closest mqtt server there is something wrong

        sleep 2
        gr.msg -v4 -c aqua -k $GURU_MQTT_INDICATOR_KEY
        timeout 1 mosquitto_pub \
            -u "$GURU_MQTT_USER" \
            -h "$GURU_MQTT_BROKER" \
            -p "$GURU_MQTT_PORT" \
            -t "$GURU_HOSTNAME/online" \
            -m "$(date +$GURU_FORMAT_DATE) $(date +$GURU_FORMAT_TIME)" \
             >/dev/null 2>&1 \
        || gr.msg -v2 -c yellow "timeout or mqtt publish issue: $?" -k $GURU_MQTT_INDICATOR_KEY
    }

    # delayed publish
    mqtt.online_send &

    # subscribe to channel no output
    gr.msg -v4 -c aqua_marine -k $GURU_MQTT_INDICATOR_KEY
    if timeout 3 mosquitto_sub -C 1 \
                    -u "$GURU_MQTT_USER" \
                    -h "$GURU_MQTT_BROKER" \
                    -p "$GURU_MQTT_PORT" \
                    -t "$GURU_HOSTNAME/online" \
                    $_options >/dev/null
        then
            gr.msg -v4 -c green -k $GURU_MQTT_INDICATOR_KEY
            return 0
        else
            gr.msg -v2 -c yellow \
                -k $GURU_MQTT_INDICATOR_KEY \
                "mqtt subscribe issue: $?"
            return 1
    fi
}


mqtt.sub () {
# subscribe to channel, stay listening

    local _topic="$1" ; shift

    gr.msg -v4 -c white -k $GURU_MQTT_INDICATOR_KEY

    # lazy way to deliver arguments
    [[ $1 ]] && local _options="-$@"

    # susbsribe
    if mosquitto_sub \
            -h $GURU_MQTT_BROKER \
            -p $GURU_MQTT_PORT \
            -t "$_topic" $_options ; then
            gr.msg -v4 -c green -k $GURU_MQTT_INDICATOR_KEY
        else
            gr.msg -v4 -c red -k $GURU_MQTT_INDICATOR_KEY
        fi

    return $?
}


mqtt.pub () {
# publish to mqtt server

    local _topic="$1" ; shift
    local _message="$@"
    local _error=

    if ! [[ $_topic ]] ; then
            gr.msg -v1  "no topic specified"
            return 127
        fi

    if ! [[ $_message ]] ; then
        gr.msg -v1  "no mesage specified"
            return 128
        fi

    gr.msg -v4 -c aqua -k $GURU_MQTT_INDICATOR_KEY

    local _i=
    for _i in {1..5} ; do

            mosquitto_pub \
                -u $GURU_MQTT_USER \
                -h $GURU_MQTT_BROKER \
                -p $GURU_MQTT_PORT \
                -t "$_topic" \
                -m "$_message" >/dev/null 2>&1
                _error=$?

            if (( $_error )) ; then
                  gr.msg -v2 -c red \
                    -k $GURU_MQTT_INDICATOR_KEY \
                    "mqtt connection $_i error $_error"
              else
                  gr.msg -v4 -c green -k $GURU_MQTT_INDICATOR_KEY
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
    gr.msg -v4 -c white -k $GURU_MQTT_INDICATOR_KEY

    mosquitto_sub -C 1 \
        -h "$GURU_MQTT_BROKER" \
        -p "$GURU_MQTT_PORT" \
        -t "$_topic" \
        $_options
        # -u $GURU_MQTT_USER
    gr.msg -v4 -c green -k $GURU_MQTT_INDICATOR_KEY
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

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_MQTT_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled, " -k $GURU_MQTT_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled " -k $GURU_MQTT_INDICATOR_KEY
            return 1
        fi

    # printout and signal by corsair keyboard indicator led
    if mqtt.online ; then
            gr.msg -v1 -c green "broker available " \
                 -k $GURU_MQTT_INDICATOR_KEY
            return 0
        else
            gr.msg -v1 -c red "broker unreachable " \
                 -k $GURU_MQTT_INDICATOR_KEY
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
            gr.msg -v1 -t -c black \
                -k $GURU_MQTT_INDICATOR_KEY \
                "${FUNCNAME[0]}: mqtt status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GURU_MQTT_INDICATOR_KEY \
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
        && gr.msg -c green "guru is now ready to mqtt" \
        || gr.msg -c yellow "error $? during install mosquitto-clients"
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

mqtt.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    mqtt.main "$@"
    exit "$?"
fi

