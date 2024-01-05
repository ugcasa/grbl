#!/bin/bash
# guru-client common functions
# collection of functions be sourced every time module needs it
# casa@ujo.guru 2019 - 2023

gr.help () {

    gr.help_msg(){

        gr.msg -v0 'gr.msg <options> "message"' -hN
        gr.msg -v2
        gr.msg -v1 "print out text, colors and mqtt messages. Supports verbose leveling, text color, "
        gr.msg -v1 "speak out, control line width, blink indication keys on keyboard, timestamps etc."
        gr.msg -v2
        gr.msg -v1 "    -v <1..4>       verbose_trigger, print after given verbose level"
        gr.msg -v1 "    -k <key_name>   keyboard key="
        gr.msg -v1 "    -c <color>      text and key color"
        gr.msg -v1 "    -l              write to log"
        gr.msg -v1 "    -s              speaks message out "
        gr.msg -v1 "    -q              quick message to default MQTT topic "
        gr.msg -v1 "    -t              timestamp"
        gr.msg -v1 "    -h              header formatting"
        gr.msg -v1 "    -n              add newline after string"
        gr.msg -v1 "    -N              add newline before string"
        gr.msg -v1 "    -w <width>      column width"
        gr.msg -v1 "    -m <topic>      MQTT server topic "
        gr.msg -v1 "    -V <1..4>       verbose limiter, do not print higher than this verbose level"
        gr.msg -v1 "    -C <color>      change line color"
        gr.msg -v1 "    -x <exit_code>  exit after message with error code"
        gr.msg -v2
    }

    gr.help_ask() {

        gr.msg -v0 'gr.ask <options> "message"' -hN
        gr.msg -v2
        gr.msg -v1 "simple yes no selector."
        gr.msg -v2
        gr.msg -v1 "    -v <1..4>       verbose_trigger, print after given verbose level"
        gr.msg -v1 "    -k <key_name>   keyboard key="
        gr.msg -v1 "    -c <color>      text and key color"
        gr.msg -v1 "    -l              write to log"
        gr.msg -v1 "    -s              speaks message out "
        gr.msg -v1 "    -q              quick message to default MQTT topic "
        gr.msg -v1 "    -t              timestamp"
        gr.msg -v1 "    -h              header formatting"
        gr.msg -v1 "    -n              add newline after string"
        gr.msg -v1 "    -N              add newline before string"
        gr.msg -v1 "    -w <width>      column width"
        gr.msg -v1 "    -m <topic>      MQTT server topic "
        gr.msg -v1 "    -V <1..4>       verbose limiter, do not print higher than this verbose level"
        gr.msg -v1 "    -C <color>      change line color"
        gr.msg -v1 "    -x <exit_code>  exit after message with error code"

        gr.msg -v1 "known issues" -c white
        gr.msg -v1 " With both, message string cannot start with a line '-'"
        gr.msg -v2
    }

    gr.help_dump () {

        gr.msg -v0 'gr.dump ' -hN
        gr.msg -v2
        gr.msg -v1 "core dump to $GURU_CORE_DUMP"
        gr.msg -v2
    }

    gr.help_ts () {

        gr.msg -v0 'gr.ts <format> ' -hN
        gr.msg -v2
        gr.msg -v1 "timestamp printout in different formats + place to clipboard"
        gr.msg -v2
        gr.msg -v1 "    epoch|-e    epoch format: $(date -d now +"%s")"
        gr.msg -v1 "    file|-f     file name compatible: $(date -d now +$GURU_FORMAT_FILE_DATE-$GURU_FORMAT_FILE_TIME)"
        gr.msg -v1 "    human|-h    human readable: $(date -d now +$GURU_FORMAT_DATE $GURU_FORMAT_TIME)"
        gr.msg -v1 "    nice|-n     nice TBD: $(date -d now +$GURU_FORMAT_NICE)"
        gr.msg -v1 "                default is: $(date -d now +$GURU_FORMAT_TIMESTAMP)"
        gr.msg -v2
    }

    gr.help_poll () {

        gr.msg -v0 'gr.poll <module_name> ' -hN
        gr.msg -v2
        gr.msg -v1 "returns module polling order"
        gr.msg -v2
    }

    gr.help_source () {

        gr.msg -v0 'gr.source <module_name> [list on wanted functions] ' -hN
        gr.msg -v2
        gr.msg -v1 "source only wanted functions from module"
        gr.msg -v2

    }

    gr.help_end () {

        gr.msg -v0 'gr.end <keyboard_key> ' -hN
        gr.msg -v2
        gr.msg -v1 "ends blinking animation on keys of corsair keyboard"
        gr.msg -v2
    }

    gr.help_ind () {

        gr.msg -v0 'gr.ind <options> <action> ' -hN
        gr.msg -v2
        gr.msg -v1 "keyboard, text and audio indication actions"
        gr.msg -v2
        gr.msg -v1 "  -m     message string"
        gr.msg -v1 "  -k     keyboard key"
        gr.msg -v1 "  -c     color name"
        gr.msg -v1 "  -t     timestamp  "
        gr.msg -v2
        gr.msg -v1 "currently available actions: keyboard and audio indications "
        gr.msg -v1 "   done, available, recovery, working, pause, cancel, error, offline, "
        gr.msg -v1 "   warning, alert, panic, pass, failed, message, flash, cops, police, "
        gr.msg -v1 "   calm, hacker, russia, china, call and customer"
        gr.msg -v2
    }

    gr.help_installed () {
        gr.msg -v0 'gr.installed <module> ' -hN
        gr.msg -v2
        gr.msg -v1 "check is module installed"
        gr.msg -v2
    }

    gr.help_presence () {

        gr.msg -v0 'gr.presence <action> ' -hN
        gr.msg -v2
        gr.msg -v1 "user presence check based on phone wifi"
        gr.msg -v2
        gr.msg -v1 "actions: stop|end stop polling phone"
        gr.msg -v2

    }

    gr.help.kv () {
        gr.msg -v0 'gr.kv <variable> <value> ' -hN
        gr.msg -v2
        gr.msg -v1 "print one line of variable value list. "
    }

    gr.help_kvt () {
        gr.msg -v0 'gr.kvt <variable> <value> <variable> <value> ... ' -hN
        gr.msg -v2
        gr.msg -v1 "format list of sting pairs to two column list view"
    }

    gr.help_debug () {
        gr.msg -v0 'gr.debug <string> ' -hN
        gr.msg -v2
        gr.msg -v1 "printout pink debug stuff"
        gr.msg -v2
    }

    function=$1

    case $function in
        msg|ask|dump|ts|poll|source|end|ind|installed|presence|debug)
            gr.help_$function
            ;;
        all)
            gr.help_msg
            gr.help_ask
            gr.help_dump
            gr.help_ts
            gr.help_poll
            gr.help_source
            gr.help_end
            gr.help_ind
            gr.help_installed
            gr.help_presence
            gr.help_debug
            ;;
        *)
            gr.msg -c yellow "unknown function '$function'"
            gr.msg "available: msg, ask, dump, ts, poll, source, end, ind, installed, presence and debug "
            ;;
    esac

}


gr.dump () {
# dump environmental status to file
    # TBD revisit this
    echo "core dumped to /tmp/guru_dump"
    set > "/tmp/guru_dump"
    echo "environment  lines $(set | wc | xargs)"  >> "/tmp/guru_dump"
    getconf -a | grep ARG_MAX >> "/tmp/guru_dump"
    true | xargs --show-limits >> "/tmp/guru_dump"
    exit 0
}


gr.ts () {
# returns current timestamp in different formats
    local _timestamp
    case $1 in
        epoch|-e) _timestamp="$(date -d now +"%s")" ;;
         file|-f) _timestamp="$(date -d now +$GURU_FORMAT_FILE_DATE-$GURU_FORMAT_FILE_TIME)" ;;
        human|-h) _timestamp=$(date -d now +"$GURU_FORMAT_DATE $GURU_FORMAT_TIME") ;;
         nice|-n) _timestamp=$(date -d now +"$GURU_FORMAT_NICE") ;;
               *) _timestamp="$(date -d now +$GURU_FORMAT_TIMESTAMP)" ;;
    esac
    printf "$_timestamp"
}


gr.poll () {
# get polling order

    local _to_find="$1"
    local i=0
    #source "$HOME/.gururc"

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


gr.source () {
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


gr.msg () {
# function for output messages and make log notifications

    local verbose_trigger=0
    local verbose_limiter=5                         # maximum + 1 verbose level
    local _newline="\n"                             # newline is on by default
    local _pre_newline=                             # newline before text disable by default
    local _timestamp=                               # timestamp is disabled by default
    local _message=                                 # message container
    local _logging=                                 # logging is disabled by default
    local _say=                                     # speak
    local _color=
    local _color_code=                              # default color if none
    local _exit=                                    # exit with code (exit not return!)
    local _mqtt_topic=
    local _indicator_key=
    local _color_only=
    local _c_var=
    local _column_width=
    local _debug=
    local _error=
    local _return=

    # parse flags
    TEMP=`getopt --long -o "tlsrnhNde:x:w:V:v:c:C:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            #-r ) _repeat="$2 "                              ; shift ;;
            -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
            -l ) _logging=true                              ; shift ;;
            -s ) _say=true                                  ; shift ;;
            -h ) _color_code="$C_HEADER"                    ; shift ;;
            -n ) _newline=                                  ; shift ;;
            -r ) _return="\r" ;_newline=                    ; shift ;;
            -N ) _pre_newline="\n"                          ; shift ;;
            -d ) _debug=true                                ; shift ;;
            -e ) _error=$2                                  ; shift 2 ;;
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

    # -d) debug messages to stderr
    if [[ $_debug ]] ; then
        _c_var="C_FUCHSIA"
        _color_code=${!_c_var}
        >&2 printf "$_color_code%s\033[0m" "${_message}"
        return 0
    fi

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
    # "print only if higher verbose level than this"
    if [[ $verbose_trigger -gt $GURU_VERBOSE ]]; then
        return 0
    fi

    # -V) given verbose level is higher than high limiter, do not print
    # "do not print after this verbose level"
    if [[ $verbose_limiter -le $GURU_VERBOSE ]]; then
        return 0
    fi

    # On verbose level 3+ timestamp is always on
    if [[ $verbose_trigger -gt 3 ]] && [[ ${#_message} -gt 1 ]]; then
        _timestamp="$(date +$GURU_FORMAT_TIME.%3N) DEBUG: "
    fi

    # -w) fill message length to column limiter
    if ! [[ $_column_width ]] ; then
        _column_width=${#_message}
    fi

    # -e) error messages to stderr
    if [[ $_error ]] ; then
        if [[ $GURU_COLOR ]] && ! [[ $GURU_VERBOSE -eq 0 ]]; then
            case $_error in
                0) _c_var="C_WHITE" ;;
                1) _c_var="C_YELLOW" ;;
                2) _c_var="C_ORANGE" ;;
                3) _c_var="C_RED" ;;
                4) _c_var="C_FUCHSIA" ;;
                ""|*) _c_var="C_YELLOW" ; _message="undefined error" ; _column_width=${#_message};;
            esac
            _color_code=${!_c_var}
            >&2 printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline\033[0m$_return" "${_timestamp}" "${_message}"
        else
            >&2 printf "$_pre_newline%s%-${_column_width}s$_newline$_return" "${_timestamp}" "${_message:0:$_column_width}"
        fi
        return 0
    fi

    # -c) color printout
    if [[ $GURU_COLOR ]] && ! [[ $GURU_VERBOSE -eq 0 ]]; then
        printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline\033[0m$_return" "${_timestamp}" "${_message:0:$_column_width}"
    else
        # *) normal printout without formatting
        printf "$_pre_newline%s%-${_column_width}s$_newline$_return" "${_timestamp}" "${_message:0:$_column_width}"
    fi

    if [[ $_say ]] && [[ $GURU_SOUND_ENABLED ]] && [[ $GURU_SPEECH_ENABLED ]] || [[ $GURU_SPEAK ]]; then

        # remove colors and stuff
        local say_message=$(echo ${_message[@]} | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' )
        # remove options
        say_message=${say_message//-}
        # add pauses if more spaces than two.. not working
        #say_message="$(echo $say_message | sed -r 's/ {2,}/, /g')"

        #[[ $GURU_VERBOSE -gt 0 ]] && printf "%s\n" "$_message"
        [[ $GURU_DEBUG ]] || espeak "${say_message//-}"  #-p $GURU_SPEAK_PITCH -s $GURU_SPEAK_SPEED -v $GURU_SPEAK_LANG "$_message"
        #return 0
    fi

    # -x) printout and exit for development use
    [[ $_exit ]] && exit $_exit

    return 0
}


gr.end () {
# stop blinking in next cycle

    local key="esc"
    [[ $1 ]] && key=$1 ; shift

    [[ -f /tmp/blink_$key ]] && rm /tmp/blink_$key
    return 0
}


gr.ind () {
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
            gr.msg -v3 -c $_color "$timestamp$_status: $_message"
        else
            gr.msg -v3 "$timestamp$_status: $_message"
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
            say)            espeak -p 85 -s 130 -v en "$_message" ;;
            done)           espeak -p 100 -s 120 -v en "$_message done! " ;;
            available)      espeak -p 100 -s 130 -v en "$_message" ;;
            recovery)       espeak -p 85 -s 130 -v en "recovering $_message" ;;
            working)        espeak -p 85 -s 130 -v en "working... $_message" ;;
            pause)          espeak -p 85 -s 130 -v en "$_message is paused" ;;
            cancel)         espeak -p 85 -s 130 -v en "$_messagasde is canceled. I repeat, $_message is canceled" ;;
            error)          espeak -p 85 -s 130 -v en "Error! $_message. I repeat, $_message" ;;
            offline)        espeak -p 85 -s 130 -v en "$_message" ;;
            warning)        espeak -p 85 -s 130 -v en "Warning! $_message. I repeat, $_message" ;;
            alert)          espeak -p 85 -s 130 -v en "Alarm! $_message. I repeat, $_message" ;;
            panic)          espeak -p 85 -s 130 -v en-sc "Critical alarm! $_message... ${_message^} Critical alarm! ${_message^^}" ;;
            passed|pass)    espeak -p 85 -s 130 -v en-us  "$_message... passed" ;;
            fail|failed)    espeak -p 85 -s 130 -v en-us "$_message... failed" ;;
            message)        espeak -p 85 -s 130 -v fi  "Message! $_message! new message $_message" ;;
            # flash)          espeak -p 0 -s 100 -v fi "Thunder" ;;
            # cops)           espeak -p 85 -s 130 -v en "Police patrol located at $_message" ;;
            # police)         espeak -p 85 -s 130 -v en "Police in block! Dump your stash and duck! ... $_message" ;;
            # calm)           espeak -p 0 -s 80 -v en-us  "Breath... slowly... in... and... out. and calm down. " ;;
            # hacker)         espeak -p 85 -s 130 -v en-us  "Warning! An hacker activity detected. $_message" ;;
            # russia)         espeak -p 5 -s 90 -v russian  "Warning! An Russian hacker activity detected... releasing honeypot vodka bottles on the battle field" ;;
            # china)          espeak -p 10 -s 180 -v cantonese "Warning! An Chinese hacker activity detected. please disconnect mainframe from internetz" ;;
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


gr.ask () {
# yes or no with y and n bling on keyboard

    local _answer=
    local _def_answer='n'
    local _ano_answer='y'
    local _options=
    local _timeout=
    local _read_it=
    local _message=
    local _box=

    # parse arguments
    TEMP=`getopt --long -o "st:d:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -s )
                _read_it=true
                shift
                ;;
            -t )
                _timeout=$2
                _options="-t $_timeout"
                shift 2
                ;;
            -d )
                _def_answer=$2

                    case $_def_answer in
                        y*|Y*) _ano_answer='n' ;;
                        n*|N*|*) _ano_answer='y' ;;
                    esac
                _answer=$2
                shift 2
                ;;
             * )
              break
        esac
    done

    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    # format timeout box
    if [[ $_timeout ]] ; then
        _message="$_message ($_timeout sec timeout)"
     fi

    # make y and n blink on keyboard
    if [[ GURU_CORSAIR_ENABLED ]] ; then
        source corsair.sh
        corsair.indicate yes y 2>/dev/null >/dev/null
        sleep 0.75
        corsair.indicate no n 2>/dev/null >/dev/null
    fi

    # format [Y/n]: box
    case $_def_answer in
        y) _box="[${_def_answer^^}/${_ano_answer,,}]: " ;;
        n) _box="[${_ano_answer,,}/${_def_answer^^}]: " ;;
    esac

    # ask from user
    [[ $_read_it ]] && espeak "$_message" #& >/dev/null

    # colorize message
    [[ $GURU_COLOR ]] && _message="$(gr.msg -n -c gold $_message)"

    # ask the question
    if [[ $GURU_FORCE ]] ; then
        _answer=y
    else
        read $_options -n 1 -p "${_message} $_box" _answer
        echo
    fi

    # fulfill default answer
    _answer="${_answer:-$_def_answer}"

    # stop blinking the keys
    if [[ GURU_CORSAIR_ENABLED ]] ; then
        corsair.blink_stop y
        corsair.blink_stop n
    fi

    # return for callers if statement
    case ${_answer^^} in Y)
        [[ $_read_it ]] && espeak "yes" #& >/dev/null
        return 0
    esac
    [[ $_read_it ]] && espeak "no" #& >/dev/null
    return 1
}


gr.kv() {
# print key value pair

    local variable="$1"; shift
    IFS=
    local value=$@ ; shift
    local column=20
    local colors=(light_blue aqua_marine deep_pink)
    [[ $variable ]] || variable='NaN'
    [[ $value ]] || value='NaN'

    # cut and add '..'
    if [[ $(expr length $variable) -ge $((column)) ]]; then
        [[ $column -gt 6 ]] \
            && variable="$(head -c$((column - 3)) <<<$variable).." \
            || variable="$(head -c$((column - 1)) <<<$variable)"
    fi

    gr.msg -c ${colors[0]} -w$column -n "$variable"

    [[ "$value" == *' '* ]] \
        && gr.msg -c ${colors[1]} "'$value'" \
        || gr.msg -c ${colors[1]} "$value"
}


gr.kvt () {
# print key value pair list
    input=($@)
    for (( i = 0; i < ${#input[@]}; i++ )); do
        gr.kv "${input[$i]}" "${input[$(($i+1))]}"
        i=$(( i + 1 ))
    done
}


gr.kvp () {
# print key value pairs based list of variable names
    input=($@)
    for (( i = 0 ; i < ${#input[@]} ; i++ )); do
        gr.msg -n -c light_blue "${input[$i]}"
        gr.msg -n -c white " = "
        gr.msg -c aqua_marine "$(eval echo '$'${input[$i]})"
    done
}


gr.installed () {
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


gr.presence () {
# poll is phone in wifi network, and sleep computer if it leaves
    case $1 in
        stop|end)
            touch /tmp/hello.killer
            return 0
        ;;
    esac

    [[ -f /tmp/hello.killer ]] && rm /tmp/hello.killer

    source android.sh
    local _interv=5

    gr.msg "checking $GURU_ANDROID_NAME wifi every $_interv seconds.."

    while true ; do

        if [[ -f /tmp/hello.killer ]] ; then
            rm /tmp/hello.killer
            gr.msg "stopping.."
            return 0
        fi

        if android.connected ; then

            if [[ -f /tmp/hello.indicator ]] ; then
                guru start
                gr.ind available -m "$GURU_USER seems to be activated"
                guru mount
                # guru note
                rm /tmp/hello.indicator
            fi

        else
            # me leaving
            if ! [[ -f /tmp/hello.indicator ]] ; then
                touch /tmp/hello.indicator
                gr.ind available -m "$GURU_USER has left the building"
                guru unmount all
                guru daemon stop
                #cinnamon-screensaver-command --lock
                sleep 10
                guru system suspend now
            fi
        fi
        sleep $_interv
    done
}


gr.date () {
# printout date
    local when="now"

    if [[ $1 ]] ; then
        when="$@"
        shift
    fi

    local output=$(date -d "$when" +$GURU_FORMAT_DATE)
    echo $output
    # echo $output | xclip -selection clipboard
}


gr.time () {
# printout date
    local when="now"

    if [[ $1 ]] ; then
        when="$@"
        shift
    fi

    local output=$(date -d "$when" +$GURU_FORMAT_TIME)
    echo $output
    # echo $output | xclip -selection clipboard
}


gr.datestamp () {

    local when="now"

    if [[ $1 ]] ; then
        when="$@"
        shift
    fi

    local output=$(date -d "$when" +$GURU_FORMAT_FILE_DATE)
    echo $output
    # echo $output | xclip -selection clipboard
}


gr.timestamp () {
# printout date
    local when="now"

    if [[ $1 ]] ; then
        when="$@"
        shift
    fi

    local output=$(date -d "$when" +$GURU_FORMAT_FILE_TIME)
    echo $output
    # echo $output | xclip -selection clipboard
}


gr.epoch () {
# printout date
    local when="now"

    if [[ $1 ]] ; then
        when="$@"
        shift
    fi

    local output=$(date -d "$when" +%s)
    echo $output
    # echo $output | xclip -selection clipboard
}


gr.filedate () {
    echo "$(gr.datestamp)-$(gr.timestamp)"
}


gr.debug2 () {
# printout debug messages
    # local colors=(white red dark_orange orange salmon moccasin)
    local colors=(white fuchsia deep_pink hot_pink orchid dark_orchid dark_violet)
    local words=(${@})
    if [[ $GURU_DEBUG ]] ; then
        gr.msg -n -c fuchsia "${FUNCNAME[0]^^}: " -n
        for (( i = 0; i < ${#words[@]}; i++ )); do
            [[ ${colors[$i]} ]] || colors[$i]=${colors[-1]}
            gr.msg -n -c ${colors[$i]} "${words[$i]} "
        done
        echo
    fi
}

gr.debug () {
# printout debug messages
    if [[ $GURU_DEBUG ]] ; then
        gr.msg -d "${FUNCNAME[0]^^}: "
        >&2 echo ${@}
    fi
}

gr.colors () {
# printout available colors

    for color in ${GURU_COLOR_LIST[@]} ; do
        gr.msg -n -c $color "$color "
    done
}

# export -f gr.poll
export -f gr.msg
export -f gr.ask
export -f gr.end
export -f gr.ind
export -f gr.debug

