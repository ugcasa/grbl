# guru-client common functions
# TODO remove common.sh, not practical way cause of namespacing

system.core-dump () {
    # dump environmental status to file

    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}


daemon.poll_order () {
    # set get polling order

    local _to_find="$1"
    local i=0

    source "$HOME/.gururc"

    for val in ${GURU_DAEMON_POLL_ORDER[@]} ; do
        ((i++))
        #echo "$i: $val"
        if [[ "$val" == "$_to_find" ]] ; then break ; fi
    done

    if [[ "$i" -gt "${#GURU_DAEMON_POLL_ORDER[@]}" ]] ; then
            echo "NA"
            return 1
        else
            echo $i
            return 0
        fi
}


daemon.poll_order_old () {
    # old way to get polling order

    local i=0
    local _to_find=$1
    # while [[ "$i" -lt "${#GURU_DAEMON_POLL_ORDER[@]}" ]] && [[ "${GURU_DAEMON_POLL_ORDER[$i]}" != "$_to_find" ]] ; do
    while [[ "$i" -lt "${#GURU_DAEMON_POLL_ORDER[@]}" ]] ; do
             if [[ "${GURU_DAEMON_POLL_ORDER[$i]}" == "$_to_find" ]] ; then break; fi
            ((i++))
        done
    ((i=i+1))
    echo $i
    #return $i
}


gmsg () {
    # function for output messages and make log notifications

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
    local _color_only=
    local _c_var=
    local _column_width

    # parse flags
    TEMP=`getopt --long -o "tlnhNx:w:V:v:c:C:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
            case "$1" in
                -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
                -l ) _logging=true                              ; shift ;;
                -h ) _color_code="$C_HEADER"                    ; shift ;;
                -n ) _newline=                                  ; shift ;;
                -N ) _pre_newline="\n"                          ; shift ;;
                -x ) _exit=$2                                   ; shift 2 ;;
                -w ) _column_width=$2                           ; shift 2 ;;
                -V ) _verbose_limiter=$2                        ; shift 2 ;;
                -v ) _verbose_trigger=$2                        ; shift 2 ;;
                -m ) _mqtt_topic="$2"                           ; shift 2 ;;
                -q ) _mqtt_topic="$GURU_HOSTNAME/$2"            ; shift 2 ;;
                -k ) _indicator_key=$2                          ; shift 2 ;;
                -C ) _color=$2
                     _color_only=true
                     _c_var="C_${_color^^}"
                     _color_code=${!_c_var}
                     shift 2 ;;
                -c ) _color=$2
                     _c_var="C_${_color^^}"
                     _color_code=${!_c_var}
                     shift 2 ;;
                 * ) break
            esac
        done

    # --) check message for long parameters (don't remember why like this)
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    # -x) add exit code to message
    [[ $_exit -gt 0 ]] && _message="$_exit: $_message"


    # -k) set corsair key is '-k <key>' used
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

    # -m) publish to mqtt if '-q|-m <topic>' used
    if [[ $_mqtt_topic ]] && [[ $GURU_MQTT_ENABLED ]]; then
            source mqtt.sh
            # mqtt.enabled || return 0
            mqtt.pub "$_mqtt_topic" "$_message"
        fi



    # -C) print only color code
    if [[ $_color_only ]] ; then
            echo -n "$_color_code"
            return 0
        fi

    # -v) given verbose level is lower than trigger level, do not print
    # "print only if higer verbose level than this"
    if (( _verbose_trigger > GURU_VERBOSE )) ; then
            return 0
        fi

    # -V) given verbose level is higher than high limiter, do not print
    # "do not print after this verbose level"
    if (( _verbose_limiter < GURU_VERBOSE )) ; then
            return 0
        fi

    # print to shell
    if [[ $_color_code ]] && [[ $GURU_COLOR ]] ; then

            # -w) fill message length to column limiter
            if ! [[ $_column_width ]] ; then
                    _column_width=${#_message}
                fi
            # -c) color printout
            printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline${C_NORMAL}" "${_timestamp}" "${_message:0:$_column_width}"

        else
            # *) normal printout no formatting
            printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
            return 0
    fi


    # echo "saata $GURU_VERBOSE:$_verbose_trigger<$_verbose_limiter"
    # echo "$_pre_newline:pre_newline"
    # echo "$_color_code:color_code"
    # echo "$_column_width:column_width"
    # echo "$_newline:newline"
    # echo "$_timestamp:timestamp"
    # echo "$_message:message"

    # -x) printout and exit for development use
    [[ $_exit ]] && exit $_exit

    return 0
}


gask () {
    # yes or no shortcut

    local _ask="$1"
    local _ans

    # just for showup ;)=
    if [[ GURU_CORSAIR_ENABLED ]] ; then
            source $GURU_BIN/corsair.sh
            corsair.init yes-no
        fi

    read -n 1 -p "$_ask [y/n]: " _ans
    echo

    [[ $GURU_CORSAIR_ENABLED ]] && corsair.init # $GURU_CORSAIR_MODE

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
    # check is module installed

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



