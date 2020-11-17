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
            -h ) _color_code="$C_HEADER"                         ; shift ;;
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

    # check message
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    # add exit code to message
    [[ $_exit -gt 0 ]] && _message="$_exit: $_message"

    if [[ $GURU_VERBOSE -ge $_verbose_trigger ]] ; then

            if [[ $GURU_VERBOSE -ge $_verbose_limiter ]] ; then return 0 ; fi

            if [[ $_color_code ]] ; then
                    printf "$_pre_newline$_color_code%s%s$_newline$C_NORMAL" "$_timestamp" "$_message"
                else
                    printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
                fi
        fi

    # publish to mqtt if '-q <topic>' used
    if [[ $_mqtt_topic ]] ; then
            mosquitto_pub -h $GURU_MQTT_BROKER -p $GURU_MQTT_PORT -t "$_mqtt_topic" -m "$_message"
        fi

    # set corsair key
    if [[ $_indicator_key ]] ; then
        corsair.main set "$_indicator_key" "$_color"
    fi

    # logging
    if [[ "$LOGGING" ]] || [[ "$_logging" ]] ; then                          # log without colorcodes ets.
        [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] || return 0                    # check that system mount is online before logging
        [[ -f "$GURU_LOG" ]] || return 0                                     # log inly is log exist (hmm.. this not really neede)
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


core.help () {
    # functional core help

    core.help_flags () {
            gmsg -v2
            gmsg -v0 "general flags:"
            gmsg -v2
            gmsg -v0 " -v               set verbose, headers and success are printed out"
            gmsg -v0 " -V               more deep verbose"
            gmsg -v1 " -u <username>    change guru user name temporary  "
            gmsg -v1 " -h <hosname>     change computer host name name temporary "
            gmsg -v1 " -l               set logging on to file $GURU_LOG"
            gmsg -v1 " -f               set force mode on, be more aggressive"
            gmsg -v2
            return 0
        }

    core.help_system () {
            gmsg -v2
            gmsg -v1 -c white  "system tools"
            gmsg -v1 "  install         install tools "
            gmsg -v1 "  uninstall       remove guru toolkit "
            gmsg -v1 "  set             set options "
            gmsg -v1 "  counter         to count things"
            gmsg -v1 "  status          status of stuff"
            gmsg -v1 "  upgrade         upgrade guru toolkit "
            gmsg -v1 "  shell           start guru shell"
            gmsg -v1 "  version         printout version "
            gmsg -v2 "  os              basic operating system library"
            gmsg -v2
            gmsg -v2 "to refer detailed tool help, type '$GURU_CALL <module> help'"
            return 0

    }

    local _arg="$1"
    if [[ "$_arg" ]] ; then
            GURU_VERBOSE=2
            case "$_arg" in
                    all) core.multi_module_function help        ; return 0 ;;
                    flags) core.help_flags                      ; return 0 ;;
                      *) core.run_module_function "$_arg" help  ; return 0 ;;
                    esac
        fi

    gmsg -v1 -c white "guru-client help "
    gmsg -v2
    gmsg -v0  "usage:    $GURU_CALL [-flags] [tool] [argument] [variables]"
    gmsg -v1
    gmsg -v1 -c white  "Flags"
    gmsg -v1 " -v   set verbose, headers and success are printed out"
    gmsg -v1 " -V   more deep verbose"
    gmsg -v1 " -l   set logging on to file $GURU_LOG"
    gmsg -v1 " -f   set force mode on, be more aggressive"
    gmsg -v1 " -u   run as user"
    gmsg -v2
    gmsg -v1 -c white  "connection tools"
    gmsg -v1 "  remote          accesspoint access tools"
    gmsg -v1 "  ssh             ssh key'and connection tools"
    gmsg -v1 "  mount|umount    mount remote locations"
    gmsg -v1 "  phone           get data from android phone"
    gmsg -v2
    gmsg -v1 -c white  "work track and documentation"
    gmsg -v1 "  note            greate and edit daily notes"
    gmsg -v1 "  timer           work track tools"
    gmsg -v1 "  translate       google translator in terminal"
    gmsg -v1 "  document        compile markdown to .odt format"
    gmsg -v1 "  scan            sane scanner tools"
    gmsg -v2
    gmsg -v1 -c white  "clipboard tools"
    gmsg -v1 "  stamp           time stamp to clipboard and terminal"
    gmsg -v2
    gmsg -v1 -c white  "entertainment"
    gmsg -v1 "  news|uutiset    text tv type reader for rss news feeds"
    gmsg -v1 "  play            play videos and music"
    gmsg -v1 "  silence         kill all audio and lights "
    gmsg -v2
    gmsg -v1 -c white  "hardware and io devices"
    gmsg -v1 "  input           to control varies input devices (keyboard etc)"
    gmsg -v1 "  keyboard        to setup keyboard shortcuts"
    gmsg -v1 "  radio           listen FM- radio (HW required)"
    gmsg -v2
    gmsg -v1 -c white  "examples"
    gmsg -v1 "  $GURU_CALL note yesterday           open yesterdays notes"
    gmsg -v2 "  $GURU_CALL install mqtt-server      isntall mqtt server"
    gmsg -v1 "  $GURU_CALL ssh key add github       addssh keys to github server"
    gmsg -v1 "  $GURU_CALL timer start at 12:00     start work time timer"
    gmsg -v1
    gmsg -v1 "More detailed help, try '$GURU_CALL <tool> help'"
    gmsg -v1 "Use verbose mode -v to get more information in help printout. "
    gmsg -v1 "Even more detailed, try -V"
}


export -f gmsg
export -f gask
export -f system.core-dump
export -f poll_order
source $GURU_BIN/os.sh
source $GURU_BIN/style.sh
source $GURU_BIN/counter.sh

