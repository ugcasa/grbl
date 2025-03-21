#!/bin/bash
# grbl client MQTT functions casa@ujo.guru 2020

declare -g mqtt_rc="/tmp/$USER/grbl_mqtt.rc"
[[ $GRBL_DEBUG ]] && mqtt_client_options='-d '
__mqtt_color="light_blue"
__mqtt=$(readlink --canonicalize --no-newline $BASH_SOURCE)

mqtt.main () {
# MQTT main command parser
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

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
           *)   gr.msg -e1 "unknown command: $_cmd"
                return 2
    esac
}


mqtt.help () {

    gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    gr.msg -v1 "grbl MQTT help " -c white
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL MQTT status|sub|pub|start|end|single|help|install|remove "
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v1 " status                   show status of default MQTT server "
    gr.msg -v1 " sub <topic>              subscribe to topic on local MQTT server "
    gr.msg -v1 " pub <topic> <message>    printout MQTT service status "
    gr.msg -v1 " log <topic> <log_file>   subscribe to topic and log it to file "
    gr.msg -v1 " single <topic>           subscribe to topic and wait for message, then exit "
    gr.msg -v1 " install                  install client requirements "
    gr.msg -v1 " remove                   remove installed requirements "
    gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 "examples: " -c white
    gr.msg -v2 "  $GRBL_CALL mqtt status "
    gr.msg -v1 "  $GRBL_CALL mqtt sub '#' "
    gr.msg -v1 "  $GRBL_CALL mqtt pub '/msg Hello!' "
    gr.msg -v2
}


mqtt.rc () {
# source configurations
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    if  [[ ! -f $mqtt_rc ]] || \
        [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mqtt.cfg) - $(stat -c %Y $mqtt_rc) )) -gt 0 ]]
    then
        mqtt.make_rc && \
            gr.msg -v1 -c dark_gray "$mqtt_rc updated"
    fi

    source $mqtt_rc
}


mqtt.make_rc () {
# make core module rc file out of configuration file
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    if ! source config.sh ; then
        gr.msg -e1 "unable to load configuration module"
        return 100
    fi

    if [[ -f $mqtt_rc ]] ; then
        rm -f $mqtt_rc
    fi

    if ! config.make_rc "$GRBL_CFG/$GRBL_USER/mqtt.cfg" $mqtt_rc ; then
        gr.msg -e1 "configuration failed"
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
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    if [[ $GRBL_MQTT_ENABLED ]] ; then
        # gr.msg -v2 -c green "MQTT enabled"
        return 0
    else
        gr.msg -v2 -c black "disabled in user config"
        gr.msg -v3 "type '$GRBL_CALL config user' to change configurations"
        return 1
    fi
}


mqtt.online () {
# check MQTT is functional, no printout
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    mqtt.online_send () {
        # if MQTT message takes more than 2 seconds to return from closest MQTT server there is something wrong
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

        sleep 2
        gr.msg -v4 -c aqua -k $GRBL_MQTT_INDICATOR_KEY
        timeout 1 mosquitto_pub $mqtt_client_options \
            -u "$GRBL_MQTT_USER" \
            -h "$GRBL_MQTT_BROKER" \
            -p "$GRBL_MQTT_PORT" \
            -t "$GRBL_HOSTNAME/online" \
            -m "$(date +$GRBL_FORMAT_DATE) $(date +$GRBL_FORMAT_TIME)" \
             >/dev/null 2>&1 \
                || gr.msg -v2 -e1 "timeout or publish issue: $?" -k $GRBL_MQTT_INDICATOR_KEY
    }

    # delayed publish
    (mqtt.online_send &)

    # subscribe to channel no output
    gr.msg -v4 -c aqua_marine -k $GRBL_MQTT_INDICATOR_KEY
    if timeout 3 mosquitto_sub -C 1 $mqtt_client_options \
                    -u "$GRBL_MQTT_USER" \
                    -h "$GRBL_MQTT_BROKER" \
                    -p "$GRBL_MQTT_PORT" \
                    -t "$GRBL_HOSTNAME/online" \
                    $_options >/dev/null
        then
            gr.msg -v4 -c green -k $GRBL_MQTT_INDICATOR_KEY
            return 0
        else
            gr.msg -v2 -e1 "subscribe issue: $?" -k $GRBL_MQTT_INDICATOR_KEY
            return 1
    fi
}


mqtt.sub () {
# subscribe to channel, stay listening
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _topic="$1" ; shift
    case $_topic in *#*|root|all) mqtt_client_options="$mqtt_client_options -v " ; _topic='#';; esac

    gr.msg -v4 -c white -k $GRBL_MQTT_INDICATOR_KEY

    # lazy way to deliver arguments
    [[ $1 ]] && local _options="-$@"

    # subscribe
    if mosquitto_sub $mqtt_client_options -R --quiet \
            -h $GRBL_MQTT_BROKER \
            -p $GRBL_MQTT_PORT \
            -t "$_topic" $_options ; then
            gr.msg -v4 -c green -k $GRBL_MQTT_INDICATOR_KEY
        else
            gr.msg -v4 -c red -k $GRBL_MQTT_INDICATOR_KEY
        fi

    return $?
}


mqtt.pub () {
# publish to MQTT server
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _topic="$1" ; shift
    local _message="$@"
    local _error=

    if ! [[ $_topic ]] ; then
            gr.msg -v1  "no topic specified"
            return 127
        fi

    if ! [[ $_message ]] ; then
        gr.msg -v1  "no message specified"
            return 128
        fi

    gr.msg -v4 -c aqua -k $GRBL_MQTT_INDICATOR_KEY

    local _i=

    for _i in {1..5} ; do

        mosquitto_pub $mqtt_client_options \
            -u $GRBL_MQTT_USER \
            -h $GRBL_MQTT_BROKER \
            -p $GRBL_MQTT_PORT \
            -t "$_topic" \
            -m "$_message" >/dev/null 2>&1
            _error=$?

        if (( $_error )) ; then
              gr.msg -v2 -c red \
                -k $GRBL_MQTT_INDICATOR_KEY \
                "connection $_i error $_error"
          else
              gr.msg -v4 -c green -k $GRBL_MQTT_INDICATOR_KEY
              break
          fi
    done

    return $_error
}


mqtt.single () {
# Subscribe to channel, stay listening until one message received. Timeout is minute.
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
#
# ## Best variables to just get message it self and mayby find way to get some VALID exit code
#
# -E : Exit once all subscriptions have been acknowledged by the broker.
# -C : disconnect and exit after receiving the 'msg_count' messages.
# -F : output format. ## Da fuck is this?
# -R : do not print stale messages (those with retain set).
# -v : print published messages verbosely.
# -W : Specifies a timeout in seconds how long to process incoming MQTT messages.
# --quiet : don't print error messages.
# --remove-retained : send a message to the server to clear any received retained messages
#                 Use -T to filter out messages you do not want to be cleared.
# ## Test string
#
# source mqtt.sh
# mosquitto_sub -C 1 -R -W 60 --quiet --remove-retained -h "$GRBL_MQTT_BROKER" -p "$GRBL_MQTT_PORT" -t "check"
#

    local _topic="$1" ; shift
    local _timeout=5

    gr.blink $GRBL_MQTT_INDICATOR_KEY "active"

    local answer=$(mosquitto_sub -C 1 -R -W $_timeout --quiet --remove-retained \
        -h "$GRBL_MQTT_BROKER" \
        -p "$GRBL_MQTT_PORT" \
        -t "$_topic" )
        # -u $GRBL_MQTT_USER

    if ! [[ $answer ]]; then
        gr.msg -e1 "timeout no message to '$_topic' on $GRBL_MQTT_BROKER:$GRBL_MQTT_PORT "
        gr.blink $GRBL_MQTT_INDICATOR_KEY "error"
        return 100
    fi

    #gr.msg -v4 -c green -k $GRBL_MQTT_INDICATOR_KEY
    gr.blink $GRBL_MQTT_INDICATOR_KEY "ok"
    echo "$answer"
    return 0
}


mqtt.log () {
# start topic log to file
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _topic="$1" ; shift
    local _log_file=$GRBL_LOG ; [[ $1 ]] && _log_file="$1"
    mosquitto_sub $mqtt_client_options \
        -u "$GRBL_MQTT_USER" \
        -h "$GRBL_MQTT_BROKER" \
        -p "$GRBL_MQTT_PORT" \
        -t "$_topic" >> $_log_file
    return $?
}


# ################# daemon functions #######################


mqtt.status () {
# check MQTT broker is reachable
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    gr.msg -n -v1 -t ""

    if [[ $GRBL_MQTT_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled, " -k $GRBL_MQTT_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled " -k $GRBL_MQTT_INDICATOR_KEY
            return 1
        fi

    # printout and signal by corsair keyboard indicator led
    if mqtt.online ; then
            gr.msg -v1 -c aqua "on service " \
                 -k $GRBL_MQTT_INDICATOR_KEY
            return 0
        else
            gr.msg -v1 -c red "unreachable " \
                 -k $GRBL_MQTT_INDICATOR_KEY
            return 1
        fi
    #try to keep possible error messages in module segment by waiting mqtt.sub reply after timeout
    sleep 3
}


mqtt.poll () {
# daemon required polling functions
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_MQTT_INDICATOR_KEY \
                "mqtt status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_MQTT_INDICATOR_KEY \
                "mqtt status polling ended"
            ;;
        status )
            mqtt.status
            ;;
        *)  mqtt.help
            ;;
        esac
}


mqtt.install_svr () {
# install MQTT server 'local', over ssh to 'remote' or in 'docker' container
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2


    local command="$1"
    shift

    uname -a |grep "Ubuntu" -q || gr.msg -c error -x 13 "installer expects that it is run on Ubuntu based system "

    case $command in

        local|remote|docker)
            mqtt.install_svr_$command "$@"
            return $?
            ;;
        server)
            local platform="$1"
            shift
            mqtt.install_svr_$platform "$@"
            return $?
            ;;
        *)
            mqtt.install_svr_$command local "$command" "$@"

    esac

}


mqtt.install_svr_local () {
# install MQTT server on local computer
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
# any install tool expects to run Ubuntu based distribution
    gr.debug "$FUNCNAME: TBD"


}


mqtt.install_svr_remote () {
# install MQTT server on remote computer
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
# any install tool expects to run Ubuntu based distribution
    gr.debug "$FUNCNAME: TBD"


}


mqtt.install_svr_docker () {
# install MQTT server on in docker container
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
# any install tool expects to run Ubuntu based distribution
    gr.debug "$FUNCNAME: TBD"


}


mqtt.install () {
# install Mosquitto MQTT clients
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _cmd="$1" ; shift

    case "$_cmd" in
            server|local|docker|remote)
                mqtt.install_svr $_cmd $@ || gr.msg -x 14 "error during install $_cmd"
                gr.ask -t 10 -d no "install also Mosquitto client locally?" || return 0
                ;;
    esac

    sudo apt update
    sudo apt install mosquitto-clients \
        && gr.msg -c green "grbl is now ready to MQTT" \
        || gr.msg -e1 "error $? during install mosquitto-clients"
    return 0

    # TBD certification requirements
    # sudo add-apt-repository ppa:certbot/certbot || return $?
    # sudo apt-get install certbot || return $?
}


mqtt.remove () {
# remove Mosquitto MQTT clients
gr.msg -v4 -n -c $__mqtt_color "$__mqtt [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    sudo apt remove mosquitto-clients && return 0
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # module settings to environment
    mqtt.rc
    mqtt.main "$@"
    exit "$?"
else
    gr.msg -v4 -c $__mqtt_color "$__mqtt [$LINENO] sourced " >&2
    mqtt.rc
fi












