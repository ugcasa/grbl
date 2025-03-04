#!/bin/bash
# grbl common functions
# collection of functions be sourced every time module needs it
# casa@ujo.guru 2019 - 2023

__config=$(readlink --canonicalize --no-newline $BASH_SOURCE)

gr.dump () {
# dump environmental status to file
    # TBD revisit this
    local _dump=/tmp/$USER/GRBL_dump
    echo "core dumped to $_dump"
    set > "$_dump"
    echo "environment  lines $(set | wc | xargs)"  >> "$_dump"
    getconf -a | grep ARG_MAX >> "$_dump"
    true | xargs --show-limits >> "$_dump"
    exit 0
}


gr.ts () {
# returns current timestamp in different formats
    local _timestamp
    case $1 in
        epoch|-e) _timestamp="$(date -d now +"%s")" ;;
         file|-f) _timestamp="$(date -d now +$GRBL_FORMAT_FILE_DATE-$GRBL_FORMAT_FILE_TIME)" ;;
        human|-h) _timestamp=$(date -d now +"$GRBL_FORMAT_DATE $GRBL_FORMAT_TIME") ;;
         nice|-n) _timestamp=$(date -d now +"$GRBL_FORMAT_NICE") ;;
               *) _timestamp="$(date -d now +$GRBL_FORMAT_TIMESTAMP)" ;;
    esac
    printf "$_timestamp"
}


gr.poll () {
# get polling order

    local _to_find="$1"
    local i=0
    #source "$HOME/.grblrc"

    for val in ${GRBL_DAEMON_POLL_ORDER[@]} ; do
        ((i++))
        #echo "$i: $val"
        if [[ "$val" == "$_to_find" ]] ; then break ; fi
    done

    if [[ "$i" -gt "${#GRBL_DAEMON_POLL_ORDER[@]}" ]] ; then
        echo "NA"
        return 1
    else
        echo $i
        return 0
    fi
}


gr.source () {
# source only wanted functions to save environment space

    gr.msg "TBD, how to detect end function, read till }?"
    return 0

    # local file=$1 ; shift
    # local functions=($@)

    # # use ram disk as a temp to avoid ssd wear out and might be little faster?
    # if df -T | grep /dev/shm >/dev/null; then
    #     gtemp=/dev/shm/grbl
    # else
    #     gtemp=/tmp/$USER/grbl
    # fi

    # if ! [[ -d $gtemp ]] ; then
    #     mkdir -p $gtemp
    # fi
    # echo "script: $GRBL_BIN/$file, temp_folder: $gtemp"
    # for function in ${functions[@]} ; do
    #     sed -n "/$function ()/,/$'\n'    }/p" $GRBL_BIN/$file >> $gtemp/functions.sh
    # done

    # source $gtemp/functions.sh
    # rm $gtemp/functions.sh
}

gr.ok () {
# printout ok sing defined in system.cfg chapter [sing]
    gr.msg -c green "$GRBL_SING_OK"
}

gr.error () {
# printout ok sing defined in system.cfg chapter [sing]
    gr.msg -c yellow "$GRBL_SING_ERROR"
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
    TEMP=`getopt --long -o "tlsrnhNpde:x:w:V:v:c:C:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            #-r ) _repeat="$2 "                              ; shift ;;
            -t ) _timestamp="$(date +$GRBL_FORMAT_TIME) "   ; shift ;;
            -l ) _logging=true                              ; shift ;;
            -s ) _say=true                                  ; shift ;;
            -h ) _color_code="$C_HEADER"                    ; shift ;;
            -n ) _newline=                                  ; shift ;;
            -p ) _newline="\n\n"                            ; shift ;;
            -r ) _return="\r" ;_newline=                    ; shift ;;
            -N ) _pre_newline="\n"                          ; shift ;;
            -d ) _debug=true                                ; shift ;;
            -e ) _error=$2                                  ; shift 2 ;;
            -x ) _exit=$2                                   ; shift 2 ;;
            -w ) _column_width=$2                           ; shift 2 ;;
            -V ) verbose_limiter=$2                         ; shift 2 ;;
            -v ) verbose_trigger=$2                         ; shift 2 ;;
            -m ) _mqtt_topic="$2"                           ; shift 2 ;;
            -q ) _mqtt_topic="$GRBL_HOSTNAME/$2"            ; shift 2 ;;
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
    if [[ $_indicator_key ]] && [[ $GRBL_CORSAIR_ENABLED ]]; then
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
    if [[ $_mqtt_topic ]] && [[ $GRBL_MQTT_ENABLED ]]; then
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
    if [[ $verbose_trigger -gt $GRBL_VERBOSE ]]; then
        return 0
    fi

    # -V) given verbose level is higher than high limiter, do not print
    # "do not print after this verbose level"
    if [[ $verbose_limiter -le $GRBL_VERBOSE ]]; then
        return 0
    fi

    # -w) fill message length to column limiter
    if ! [[ $_column_width ]] ; then
        _column_width=${#_message}
    fi

    _message_length=$_column_width
    # [[ ${#_column_width} -gt 1 ]] && local _message_length=$(( $_column_width - 1))

    # -e) error messages to stderr
    if [[ $_error ]] ; then
        if [[ $GRBL_COLOR ]] && ! [[ $GRBL_VERBOSE -eq 0 ]]; then
            case $_error in
                0) _c_var="C_WHITE" ;;
                1) _c_var="C_YELLOW" ;;
                2) _c_var="C_ORANGE" ;;
                3) _c_var="C_RED" ;;
                4) _c_var="C_FUCHSIA" ;;
                ""|*) _c_var="C_YELLOW" ; _message="undefined error" ; _column_width=${#_message};;
            esac
            _color_code=${!_c_var}
            printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline\033[0m$_return" "${_timestamp}" "${_message}" >&2
        else
            printf "$_pre_newline%s%-${_column_width}s$_newline$_return" "${_timestamp}" "${_message:0:$_message_length}" >&2
        fi
        return 0
    fi

    # -c) color printout
    if [[ $GRBL_COLOR ]] && ! [[ $GRBL_VERBOSE -eq 0 ]]; then
        printf "$_pre_newline$_color_code%s%-${_column_width}s$_newline\033[0m$_return" "${_timestamp}" "${_message:0:$_message_length}"
    else
        # *) normal printout without formatting
        printf "$_pre_newline%s%-${_column_width}s$_newline$_return" "${_timestamp}" "${_message:0:$_message_length}"
    fi

    if [[ $_say ]] && [[ $GRBL_SOUND_ENABLED ]] && [[ $GRBL_SPEECH_ENABLED ]] || [[ $GRBL_SPEAK ]]; then

        # remove colors and stuff
        local say_message=$(echo ${_message[@]} | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' )
        # remove options
        say_message=${say_message//-}
        # add pauses if more spaces than two.. not working
        #say_message="$(echo $say_message | sed -r 's/ {2,}/, /g')"

        #[[ $GRBL_VERBOSE -gt 0 ]] && printf "%s\n" "$_message"
        [[ $GRBL_DEBUG ]] || espeak "${say_message//-}"  #-p $GRBL_SPEAK_PITCH -s $GRBL_SPEAK_SPEED -v $GRBL_SPEAK_LANG "$_message"
        #return 0
    fi

    # -x) printout and exit for development use
    [[ $_exit ]] && exit $_exit

    return 0
}

gr.emsg () {
# sond know what this is, remove
     printf "$_color_code%s%-${_column_width}s$_newline\033[0m$_return" "${_timestamp}" "${_message:0:$_message_length}"
    $@
}

gr.end () {
# stop blinking in next cycle

    local key="caps"
    [[ $1 ]] && key=$1 ; shift

    [[ -f /tmp/$USER/blink_$key ]] && rm /tmp/$USER/blink_$key
    sleep 1
    return 0
}

gr.blink () {
# bliks corsair keyboard keys
    local key="caps"
    local mood="panic"
    [[ $1 ]] && key=$1; shift
    [[ $1 ]] && mood=$1; shift
    $GRBL_CALL corsair indicate $mood $key
}

gr.ind () {
# indicate status by message, voice  and keyboard indicators

    local _timestamp=
    local _mqtt_topic="/status/$(hostname)"
    local _indicator_key="caps"
    local _color="black"
    local _status="message"
    local _message=""

    # parse arguments
    TEMP=`getopt --long -o "tlnhNx:w:V:v:c:C:q:k:m:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -t ) _timestamp="$(date +$GRBL_FORMAT_TIME) "   ; shift ;;
            -m ) _message="$2 "                             ; shift 2 ;;
            -k ) _indicator_key=$2                          ; shift 2 ;;
            -c ) _color=$2                                  ; shift 2 ;;
             * ) break
        esac
    done
    # --) check message for long parameters (don't remember why like this)
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _status="${_arg#* }"

    # gr.debug "_timestamp:$_timestamp"
    # gr.debug "_mqtt_topic:$_mqtt_topic"
    # gr.debug "_indicator_key:$_indicator_key"
    # gr.debug "_color:$_color"
    # gr.debug "_status:$_status"
    # gr.debug "_message:$_message"

    if ! [[ $_status ]] ; then
        return 0
    fi

    if [[ $GRBL_CORSAIR_ENABLED ]] && [[ $_indicator_key ]] ; then
        source corsair.sh
        corsair.main indicate $_status $_indicator_key
    fi

    if [[ $_message ]] ; then

        if [[ $_color ]] ; then
            gr.msg -v3 -c $_color "$timestamp$_status: $_message"
        else
            gr.msg -v3 "$timestamp$_status: $_message"
        fi

        if [[ $GRBL_MQTT_ENABLED ]] && [[ $_mqtt_topic ]] ; then
            source mqtt.sh
            #mqtt.pub $_mqtt_topic $_message
            mqtt.pub $_mqtt_topic "$timestamp$_status $_message"
        fi
    fi

    if [[ $GRBL_SOUND_ENABLED ]] ; then

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
            error)          espeak -p 85 -s 130 -v en "Error! $_message" ;;
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
                                [[ -f /tmp/$USER/blink_$_indicator_key ]] || break
                                sleep 2
                            done ;;
            customer)       for i in {0..5} ; do
                                espeak -p 75 -s 90 -v finnish "$_message,"
                                espeak -p 75 -s 90 -v en-us  "is calling! "
                                [[ -f /tmp/$USER/blink_$_indicator_key ]] || break
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
    local _comment=
    local _comment_box=

    # parse arguments
    TEMP=`getopt --long -o "csht:d:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in

            -s) # speak question out
                _read_it=true
                shift
                ;;
            -h) # highlight last word
                _highlight=true
                shift
                ;;
            -t)
                _timeout=$2
                _options="-t $_timeout"
                shift 2
                ;;
            -c) # ask comment
                _comment=true
                shift
                ;;
            -d)
                _def_answer=$2

                    case $_def_answer in
                        y*|Y*) _ano_answer='n' ;;
                        n*|N*|*) _ano_answer='y' ;;
                    esac
                _answer=$2
                shift 2
                ;;
             *)
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
    if [[ $GRBL_CORSAIR_ENABLED ]] ; then
        source corsair.sh
        corsair.indicate yes y 2>/dev/null >/dev/null
        sleep 0.75
        corsair.indicate no n 2>/dev/null >/dev/null
    fi

    # format [Y/n]: box
    if [[ $_comment ]]; then
        _comment_box='/c'
    fi

    case $_def_answer in
        y) _box="[${_def_answer^^}/${_ano_answer,,}$_comment_box]: " ;;
        n) _box="[${_ano_answer,,}/${_def_answer^^}$_comment_box]: " ;;
    esac

    # speak
    [[ $_read_it ]] && espeak "$_message" #& >/dev/null

    # colorize message
    if [[ $GRBL_COLOR ]]; then
        # highlight last word
        if [[ $_highlight ]]; then
            _highlight="${_message##* }"
            _message="$(sed '1{s/[^ ]\+\s*$//}' <<<$_message)"
            _message="$(gr.msg -n -c dark_cyan $_message) $(gr.msg -n -c cyan $_highlight)"
        else
        _message="$(gr.msg -n -c dark_cyan $_message)"
        fi
    fi

    # ask the question
    if [[ $GRBL_FORCE ]] ; then
        _answer=y
    else
        read $_options -n 1 -p "${_message} $_box" _answer
        echo
    fi

    if [[ $_comment ]] || [[ $_answer == c ]]; then
        read -p "comment: " _comment_ans
        gr.msg -v3 -c white "$_comment_ans"
        echo $_comment_ans >/tmp/$USER/ask.comment
    fi

    # fulfill default answer
    _answer="${_answer:-$_def_answer}"

    # stop blinking the keys
    if [[ $GRBL_CORSAIR_ENABLED ]] ; then
        corsair.blink_stop y >/dev/null 2>/dev/null
        corsair.blink_stop n >/dev/null 2>/dev/null
    fi

    # return for callers if statement
    case ${_answer^^} in Y)
        [[ $_read_it ]] && espeak "yes" #& >/dev/null
        return 0
    esac
    [[ $_read_it ]] && espeak "no" #& >/dev/null
    return 1
}

# TBD rename following three functions

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


gr.varlist(){
# print key value pairs based list of variable names
    local input=($@)
    local _i=0

    # if first argument is debug, print list only if debu mode is on
    if [[ ${input%% *} == "debug" ]]; then
        [[ $GRBL_DEBUG ]] || return 0
        _i=1
    fi

    for (( i = $_i ; i < ${#input[@]} ; i++ )); do
        gr.msg -n -c light_blue "${input[$i]}" >&2
        gr.msg -n -c white " = " >&2
        gr.msg -c aqua_marine "'$(eval echo '$'${input[$i]})'" >&2
    done
}

gr.kvp () {
# compatibility alias
  gr.kvp $@
}

gr.installed () {
# check is module installed

    local i=0
    local _to_find=$1

    while [[ "$i" -lt "${#GRBL_MODULES[@]}" ]] ; do

        if [[ "${GRBL_MODULES[$i]}" == "$_to_find" ]] ; then
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
            touch /tmp/$USER/hello.killer
            return 0
        ;;
    esac

    [[ -f /tmp/$USER/hello.killer ]] && rm /tmp/$USER/hello.killer

    source android.sh
    local _interv=5

    gr.msg "checking $GRBL_ANDROID_NAME wifi every $_interv seconds.."

    while true ; do

        if [[ -f /tmp/$USER/hello.killer ]] ; then
            rm /tmp/$USER/hello.killer
            gr.msg "stopping.."
            return 0
        fi

        if android.connected ; then

            if [[ -f /tmp/$USER/hello.indicator ]] ; then
                grbl start
                gr.ind available -m "$GRBL_USER seems to be active"
                grbl mount
                rm /tmp/$USER/hello.indicator
            fi

        else
            # me leaving
            if ! [[ -f /tmp/$USER/hello.indicator ]] ; then
                touch /tmp/$USER/hello.indicator
                gr.ind available -m "$GRBL_USER has left the building"
                grbl unmount all
                grbl daemon stop
                cinnamon-screensaver-command --lock
                # sleep 10
                # grbl system suspend now
            fi
        fi
        sleep $_interv
    done
}


gr.contain () {
# check item is in list
    # shopt -s nocasematch # Can be useful to disable case-matching
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

gr.date () {
# printout date in readable format
    local when="now"
    [[ $1 ]] && when="$@"
    echo $(date -d "$when" +$GRBL_FORMAT_DATE)
}


gr.time () {
# printout time in readable format
    local when="now"
    [[ $1 ]] && when="$@"
    echo $(date -d "$when" +$GRBL_FORMAT_TIME)
}


gr.datestamp () {
# printout date stamp
    local when="now"
    [[ $1 ]] && when="$@"
    echo $(date -d "$when" +$GRBL_FORMAT_FILE_DATE)
}


gr.timestamp () {
# printout date
    local when="now"
    [[ $1 ]] && when="$@"
    echo $(date -d "$when" +$GRBL_FORMAT_FILE_TIME)
}


gr.epoch () {
# printout date
    local when="now"
    [[ $1 ]] && when="$@"
    echo $(date -d "$when" +%s)
}


gr.filedate () {
    echo "$(gr.datestamp)-$(gr.timestamp)"

}


gr.debug2 () {
# printout debug messages
    local colors=(white fuchsia deep_pink hot_pink orchid dark_orchid dark_violet)
    # local colors=(white red dark_orange orange salmon moccasin)
    local words=(${@})
    if [[ $GRBL_DEBUG ]] ; then
        gr.msg -n -c fuchsia "${FUNCNAME[0]^^}: " -n >&2
        for (( i = 0; i < ${#words[@]}; i++ )); do
            [[ ${colors[$i]} ]] || colors[$i]=${colors[-1]}
            gr.msg -n -c ${colors[$i]} "${words[$i]} " >&2
        done
        echo
    fi
}


gr.debug () {
# printout debug messages
    if [[ $GRBL_DEBUG ]] ; then
        gr.msg -d "${FUNCNAME[0]^^}: " >&2
        echo ${@} >&2
    fi
}


gr.colors () {
# printout available colors
    export GRBL_COLOR=true
    export GRBL_VERBOSE=2

    case $1 in
        "")
            for color in ${GRBL_COLOR_LIST[@]} ; do
                gr.msg -n -c $color "$color "
            done
            ;;
        *)
            for color in ${GRBL_COLOR_LIST[@]} ; do
                gr.msg -n -c $color "$1"
            done

            ;;

        esac
        echo
}

# TBD is following really needed or some old tail?
# export -f gr.poll
export -f gr.msg
export -f gr.ask
export -f gr.end
export -f gr.ind
export -f gr.debug

