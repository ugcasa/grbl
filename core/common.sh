# guru-client common functions
# TODO remove common.sh, not practical way cause of namespacing

system.core-dump () {
    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}


daemon.poll_order () {
    local _to_find="$1"
    local i=0

    source "$HOME/.gururc"

    for val in ${GURU_DAEMON_POLL_ORDER[@]} ; do
        ((i++))
        #echo "$i: $val"
        if [[ "$val" == "$_to_find" ]] ; then break ; fi
    done

    if [[ "$i" -lt "${#GURU_DAEMON_POLL_ORDER[@]}" ]] ; then
            echo $i
            return 0
        else
            echo "NA"
            return 1
        fi
}


daemon.poll_order_old () {
    local i=0
    local _to_find=$1
    # while [[ "$i" -lt "${#GURU_DAEMON_POLL_LIST[@]}" ]] && [[ "${GURU_DAEMON_POLL_LIST[$i]}" != "$_to_find" ]] ; do
    while [[ "$i" -lt "${#GURU_DAEMON_POLL_LIST[@]}" ]] ; do
             if [[ "${GURU_DAEMON_POLL_LIST[$i]}" == "$_to_find" ]] ; then break; fi
            ((i++))
        done
    ((i=i+1))
    echo $i
    #return $i
}


gmsg () {
    # function for ouput messages and make log notifications

    # default values
    local _verbose_trigger=0                        # prinout if verbose trigger is not set in options
    local _verbose_limiter=4                        # maximum + 1 verbose level
    local _newline="\n"                             # newline is on by default
    local _pre_newline=                             # newline before text disable by default
    local _timestamp=                               # timestamp is disabled by default
    local _message=                                 # message container
    local _logging=                                 # logging is disabled by default
    local _color=
    local _color_code=                              # default color if none
    local _exit=                                    # exit with code (exit not return!)
    local _mqtt_topic=
    local _indicator_key=
    # parse flags
    TEMP=`getopt --long -o "tlnhNx:V:v:c:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
            case "$1" in
                -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
                -l ) _logging=true                              ; shift ;;
                -h ) _color_code="$C_HEADER"                    ; shift ;;
                -n ) _newline=                                  ; shift ;;
                -N ) _pre_newline="\n"                          ; shift ;;
                -x ) _exit=$2                                   ; shift 2 ;;
                -V ) _verbose_limiter=$2                        ; shift 2 ;;
                -v ) _verbose_trigger=$2                        ; shift 2 ;;
                -m ) _mqtt_topic="$2"                           ; shift 2 ;;
                -q ) _mqtt_topic="$GURU_HOSTNAME/$2"            ; shift 2 ;;
                -k ) _indicator_key=$2                          ; shift 2 ;;
                -c ) _color=$2
                     _c_var="C_${_color^^}"
                     _color_code=${!_c_var}                     ; shift 2 ;;
                 * ) break
            esac
        done

    # check message for long parameters (don't remember why like this)
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    # add exit code to message
    [[ $_exit -gt 0 ]] && _message="$_exit: $_message"


    # set corsair key is '-k <key>' used
    if [[ $_indicator_key ]] && [[ $GURU_CORSAIR_ENABLED ]]; then
        # TBD: check corsair (or other kb led) module installed
        #      now in corsair is part of core what it should not to be
        source corsair.sh
        if [[ "$_color" == "reset" ]] ; then
                corsair.main reset "$_indicator_key"
            else
                corsair.main set "$_indicator_key" "$_color"
            fi
       fi

    # publish to mqtt if '-q|-m <topic>' used
    if [[ $_mqtt_topic ]] && [[ $GURU_MQTT_ENABLED ]]; then
            source mqtt.sh
            # mqtt.enabled || return 0
            mqtt.pub "$_mqtt_topic" "$_message"
        fi

    # uncomment if vanted to see how verbose changes during run
    # echo "$_verbose_trigger:$GURU_VERBOSE"

    # printout message if verbose level is more than verbose trigger
    if [[ $GURU_VERBOSE -ge $_verbose_trigger ]] ; then

            if [[ $GURU_VERBOSE -ge $_verbose_limiter ]] ; then return 0 ; fi

            if [[ $_color_code ]] && [[ $GURU_FLAG_COLOR ]] ; then
                    printf "$_pre_newline$_color_code%s%s$_newline$C_NORMAL" "$_timestamp" "$_message"
                else
                    printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
                fi
        fi

    # # print to log if '-l' set
    # if [[ "$LOGGING" ]] || [[ "$_logging" ]] ; then
    #         # check that system mount is online before logging
    #         [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] || return 0
    #         # log only is log exist
    #         [[ -f "$GURU_LOG" ]] || return 0
    #         # log without colorcodes
    #         printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    #     fi

    [[ $_exit ]] && exit $_exit

    return 0
}


gask () {
    local _ask="$1"
    local _ans

    read -n 1 -p "$_ask [y/n]: " _ans
    echo

    case $_ans in y|Y|yes|Yes)
            return 0
        esac
    return 1
}


import () {
    # source all bash function in module. input: import <module_name> <py|sh|php..>
    local _module=$1 ; shift
    local _type=sh ; [[ $1 ]] && _type=$1

    if ! [[ -d $_module ]] ; then
            gmsg -c yellow "no module $_module exist"
            return 100
        fi

    for lib in $_module/*$_type ; do
            gmsg -v2 "library $lib"

            if [[ -f $lib ]] ; then
                    source $lib
                else
                    gmsg -c yellow "no $_type files in $_module/ folder"
                    return 101
                fi
        done
}

module.installed () {

    local i=0
    local _to_find=$1

    while [[ "$i" -lt "${#GURU_MODULES[@]}" ]] ; do
            if [[ "${GURU_MODULES[$i]}" == "$_to_find" ]] ; then
                    return 0
                fi
            ((i++))
        done
    return 100
}


#`TBD`declase -xf ? rather than export?
export -f system.core-dump
export -f daemon.poll_order
export -f gmsg
export -f gask
export -f import


