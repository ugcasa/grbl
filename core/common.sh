# guru-client common functions
# TODO remove common.sh, not practical way cause of namespacing

system.core-dump () {
    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}


poll_order() {
    local i=0 ;  while [ "$i" -lt "${#GURU_DAEMON_POLL_LIST[@]}" ] && [ "${GURU_DAEMON_POLL_LIST[$i]}" != "$1" ] ; do ((i++)); done ; ((i=i+1)) ; echo $i;
}


msg() {         # function for ouput messages and make log notifications. TODO remove this..

    if ! [[ "$1" ]] ; then return 0 ; fi                            # no message, just return
    # print to stdout
    if [[ $GURU_VERBOSE ]] ; then printf "$@" ; fi                  # print out if verbose set

    # logging (and error messages)
    #printf "$@" >"$GURU_ERROR_MSG" ;                               # keep last message to las error
    if ! [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] ; then return 0 ; fi  # check that system mount is online before logging
    if ! [[ -f "$GURU_LOG" ]] ; then return 0 ; fi                  # log inly is log exist (hmm.. this not really neede)
    if [[ "$LOGGING" ]] ; then                                      # log without colorcodes ets.
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}

export -f msg


gmsg() {
    # function for ouput messages and make log notifications - revisited

    # default values
    local _verbose_trigger=0                        # prinout if verbose trigger is not set in options
    local _verbose_limiter=4                        # maximum + 1 verbose level
    local _newline="\n"                             # newline is on by default
    local _pre_newline=                             # newline before text disable by default
    local _timestamp=                               # timestamp is disabled by default
    local _message=                                 # message container
    local _logging=                                 # logging is disabled by default
    local _color=
    local _color_code=                                   # default color if none
    local _exit=                                    # exit with code (exit not return!)
    local _mqtt_topic=
    local _indicator_key=
    # parse flags
    TEMP=`getopt --long -o "tlnhNx:V:v:c:q:k:" "$@"`
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

    # publish to mqtt if '-q <topic>' used
    if [[ $_mqtt_topic ]] ; then
            mosquitto_pub -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic" -m "$_message"
        fi

    # set corsair key is '-k <key>' used
    if [[ $_indicator_key ]] ; then

        if [[ "$_color" == "reset" ]] ; then
                corsair.main reset "$_indicator_key"
            else
                corsair.main set "$_indicator_key" "$_color"
            fi
       fi

    # printout message if verbose level is more than verbose trigger
    if [[ $GURU_VERBOSE -ge $_verbose_trigger ]] ; then

            if [[ $GURU_VERBOSE -ge $_verbose_limiter ]] ; then return 0 ; fi

            if [[ $_color_code ]] ; then
                    printf "$_pre_newline$_color_code%s%s$_newline$C_NORMAL" "$_timestamp" "$_message"
                else
                    printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
                fi
        fi

    # print to log if '-l' set
    if [[ "$LOGGING" ]] || [[ "$_logging" ]] ; then
        # check that system mount is online before logging
        [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] || return 0
        # log only is log exist
        [[ -f "$GURU_LOG" ]] || return 0
        # log without colorcodes
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi

    [[ $_exit ]] && exit $_exit
}


gask () {
    local _ask="$1"
    local _ans

    #corsair.main init yes-no               # TODO found need of question wrapper: gask
    read -n 1 -p "$_ask? [y/n]: " _ans
    echo
    #corsair.main init status

    case $_ans in y|Y|yes|Yes)
        return 0
    esac
    return 1
}


export -f gmsg
export -f gask
export -f system.core-dump
export -f poll_order
source $GURU_BIN/os.sh
source $GURU_BIN/style.sh
source $GURU_BIN/counter.sh

