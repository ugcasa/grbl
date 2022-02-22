#!/bin/bash
# guru-client common functions
# collection of functions be sourced every time module needs it
# casa@ujo.guru 2019 - 2022

## TODO remove common.sh, not practical way cause of namespacing
##  - no rush, good enough for now
##  - ISSUE function naming should be fixed dough

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


gsource () {
    # source only wanted functions. slow ~0,03 sec, but saves environment space

    local file=$1 ; shift
    local functions=($@)

    # use ram disk as a temp to avoid ssd wear out and might be little faster?
    if df -T | grep /dev/shm >/dev/null; then
            gtemp=/dev/shm/guru
        else
            gtemp=/tmp/guru
        fi

    if ! [[ -d $gtemp ]] ; then
            mkdir -p $gtemp
        fi

    for function in ${functions[@]} ; do
        sed -n "/$function ()/,/}/p" $file >> $gtemp/functions.sh
    done

    source $gtemp/functions.sh
    rm $gtemp/functions.sh
}


gmsg () {
    # function for output messages and make log notifications

    local verbose_trigger=0                         # prinout if verbose trigger is not set in options
    local verbose_limiter=5                         # maximum + 1 verbose level
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
                -V ) verbose_limiter=$2                         ; shift 2 ;;
                -v ) verbose_trigger=$2                         ; shift 2 ;;
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
    if [[ $_indicator_key ]] && [[ $GURU_CORSAIR_ENABLED ]] ; then
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
    # "print only if higher verbose level than this"
    if [[ $verbose_trigger -gt $GURU_VERBOSE ]] ; then
            return 0
        fi

    # -V) given verbose level is higher than high limiter, do not print
    # "do not print after this verbose level"
    if [[ $verbose_limiter -le $GURU_VERBOSE ]] ; then
            return 0
        fi

    # On verbose level 3+ timestamp is always on
    if [[ $verbose_trigger -gt 3 ]] && [[ ${#_message} -gt 1 ]]; then
        _timestamp="$(date +$GURU_FORMAT_TIME.%3N) "
    fi

    # print to shell
    if [[ $_color_code ]] && [[ $GURU_COLOR ]] && [[ $GURU_VERBOSE -gt 0 ]] ; then

            # -w) fill message length to column limiter
            if ! [[ $_column_width ]] ; then
                    _column_width=${#_message}
                fi
            # -c) color printout
            printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline${C_NORMAL}" "${_timestamp}" "${_message:0:$_column_width}"

        else
            # *) normal printout without formatting
            printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
            return 0
    fi


    # echo "saata $GURU_VERBOSE:$verbose_trigger<$verbose_limiter"
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


gend_blink () {
    # stop blinking in next cycle

    local key="esc"
    [[ $1 ]] && key=$1 ; shift

    [[ -f /tmp/blink_$key ]] && rm /tmp/blink_$key
    return 0
}


gindicate () {
    # indicate status by message, voice  and keyboard indicators

    local _timestamp=
    local _mqtt_topic="/status/$(hostname)"
    local _indicator_key="esc"
    local _color="black"
    local _status="message"
    local _message=""

    # parse arguments
    TEMP=`getopt --long -o "tlnhNx:w:V:v:c:C:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
            case "$1" in
                -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
                -m ) _message="$2 "                             ; shift 2 ;;
                -k ) _indicator_key=$2                          ; shift 2 ;;
                -c ) _color=$2                                  ; shift 2 ;;
                 * ) break
            esac
        done
    # --) check message for long parameters (don't remember why like this)
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _status="${_arg#* }"

    if ! [[ $_status ]] ; then
            return 0
        fi

    if [[ $GURU_CORSAIR_ENABLED ]] && [[ $_indicator_key ]] ; then
            source corsair.sh
            corsair.main indicate $_status $_indicator_key
        fi

    if [[ $_message ]] ; then

            if [[ $_color ]] ; then
                    gmsg -c $_color "$timestamp$_status: $_message"
                else
                    gmsg "$timestamp$_status: $_message"
                fi

            if [[ $GURU_MQTT_ENABLED ]] && [[ $_mqtt_topic ]] ; then
                    source mqtt.sh
                    #mqtt.pub $_mqtt_topic $_message
                    mqtt.pub $_mqtt_topic "$timestamp$_status $_message"
                fi
        fi

    if [[ $GURU_SOUND_ENABLED ]] ; then

        # TBD source sound.sh
        # TBD sound.main nnn

        [[ $_message ]] || _message=$_status
        case $_status in
            done)           espeak -p 100 -s 120 -v en "Done $_message. " ;;
            working)        espeak -p 85 -s 130 -v en "working... $_message" ;;
            pause)          espeak -p 85 -s 130 -v en "$_message is paused" ;;
            cancel)         espeak -p 85 -s 130 -v en "$_messagasde is canceled. I repeat, $_message is canceled" ;;
            error)          espeak -p 85 -s 130 -v en "Error! $_message. I repeat, $_message" ;;
            warning)        espeak -p 85 -s 130 -v en "Warning! $_message. I repeat, $_message" ;;
            alert)          espeak -p 85 -s 130 -v en "Alarm! $_message. I repeat, $_message" ;;
            panic)          espeak -p 85 -s 130 -v en-sc "mayday.. Mayday? Mayday! $_message... ${_message^}? ${_message^^}" ;;
            passed|pass)    espeak -p 85 -s 130 -v en-us  "$_message... passed" ;;
            fail|failed)    espeak -p 85 -s 130 -v en-us "$_message... failed" ;;
            message)        espeak -p 85 -s 130 -v fi  "Message! $_message! new message $_message" ;;
            flash)          espeak -p 0 -s 100 -v fi "Thunder" ;;
            cops)           espeak -p 85 -s 130 -v en "Police patrol located at $_message" ;;
            police)         espeak -p 85 -s 130 -v en "Police in block! Dump your stash and duck! ... $_message" ;;
            calm)           espeak -p 0 -s 80 -v en-us  "Breath... slowly... in... and... out. and calm down. " ;;
            hacker)         espeak -p 85 -s 130 -v en-us  "Warning! An hacker activity detected. $_message" ;;
            russia)         espeak -p 5 -s 90 -v russian  "Warning! An Russian hacker activity detected... releasing honeypot vodka bottles on the battle field" ;;
            china)          espeak -p 10 -s 180 -v cantonese "Warning! An Chinese hacker activity detected. please disconnect mainframe from internetz" ;;
            call)           for i in {0..5} ; do
                                espeak -p 60 -s 80 -v en-sc "Incoming call from number $(echo $_message | sed 's/./& /g')"
                                [[ -f /tmp/blink_$_indicator_key ]] || break
                                sleep 2
                            done ;;
            customer)       for i in {0..5} ; do
                                espeak -p 75 -s 90 -v finnish "$_message,"
                                espeak -p 75 -s 90 -v en-us  "is calling! "
                                [[ -f /tmp/blink_$_indicator_key ]] || break
                                sleep 2
                            done ;;
        esac
    fi
}


gask () {
    # yes or no shortcut

    local _message="$1"
    local _ans
     #TBD --kill-after

   # parse flags
    TEMP=`getopt --long -o "k:" "$@"`
    eval set -- "$TEMP"

    while true ; do
            case "$1" in
                -k ) local kill_time=$1
                    ;;
                 * ) break
            esac
        done

    # --) check message for long parameters (don't remember why like this)
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    # just for showup ;)=
    if [[ GURU_CORSAIR_ENABLED ]] ; then
            source $GURU_BIN/corsair.sh
            # corsair.init yes-no
        fi

    if [[ $kill_time ]] ; then
            # NOT TESTED, not even run. ever
            timeout 10 "read -n 1 -p $_message [y/n]: " _ans
        else
            read -n 1 -p "$_message [y/n]: " _ans
        fi

    echo

    [[ $GURU_CORSAIR_ENABLED ]] && corsair.init # $GURU_CORSAIR_MODE

    case ${_ans^^} in Y|YES|YEP)
            return 0
        esac
    return 1
}


contains() {
    [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]] && return 0 || return 1
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




#`TBD`declare -xf ? rather than export? - no
export -f system.core-dump
export -f daemon.poll_order
export -f gmsg
export -f gask
export -f import



