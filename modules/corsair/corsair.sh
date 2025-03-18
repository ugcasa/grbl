#!/bin/bash
# grbl corsair led notification functions
# casa@ujo.guru 2020-2025

__corsair_color="light_blue"
__corsair=$(readlink --canonicalize --no-newline $BASH_SOURCE)

corsair_rc=/tmp/$USER/corsair.rc
corsair_config="$GRBL_CFG/$GRBL_USER/corsair.cfg"
# active key list
key_pipe_list=$(file /tmp/ckbpipe0* | grep fifo | cut -f1 -d ":")
# modes with status bar function set. if add on this list, add name=<rgb color> to rgb-color.cfg
status_modes=(olive fullpipe, halfpipe, blue, eq)
corsair_last_mode="/tmp/$USER/corsair.mode"
# service configurations for ckb-next application
corsair_service="$HOME/.config/systemd/user/corsair.service"
corsair_daemon_service="/usr/lib/systemd/system/ckb-next-daemon.service"
# just know what to delete then disable option/lib/systemd/system-sleep/grbl-suspend.sh
suspend_script="/lib/systemd/system-sleep/grbl-suspend.sh"
# poll order is read from  environment list ${GRBL_DAEMON_POLL_ORDER[@]} set in user.cfg
pipelist_file="$GRBL_CFG/corsair-pipelist.cfg"
ms_available=
kb_available=
corsair_mode=
#home="$GRBL_BIN/corsiar"
home="/home/casa/code/grbl/modules/corsair"

# import colors f
[[ -f "$GRBL_CFG/rgb-color.cfg" ]] && source "$GRBL_CFG/rgb-color.cfg"

# fullpipe profile all keys are piped
# halfpipe profile only keys are available: esc,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12, y, n and caps
# nopipe profile none of keys piped
declare -ga corsair_keytable=(\
    esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12          print scroll pause      stop prev play next\
    half 1 2 3 4 5 6 7 8 9 0 plus query backscape       insert home pageup      numlc div mul sub\
    tab q w e r t y u i o p å tilde enter               del end pagedown        np7 np8 np9 add\
    caps a s d f g h j k l ö ä asterix                                          np4 np5 np6\
    shiftl less z x c v b n m comma perioid minus shiftr      up                np1 np2 np3 count\
    lctrl func alt space altgr fn set rctrl             left down right         np0 decimal\
    brightness sleep\
    )
    #thumb wheel logo mouse


corsair.main () {
# command parser
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    # ckb-next last mode data
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GRBL_CORSAIR_MODE
        fi

    local cmd="$1"
    shift

    case "$cmd" in
        # indicator functions
        status|init|set|reset|clear|end|indicate|keytable|key-id|type)
            # corsair efect library
            source $home/efects.sh
            corsair.$cmd $@
            return $?
            ;;

        # blink functions
        blink|b)
            [[ $GRBL_CORSAIR_ENABLED ]] || return 2
            # corsair efect library
            source $home/efects.sh
            local tool=$1
            shift

            case $tool in
                set|stop|kill|test)
                    corsair.blink_$tool $@
                    return $?
                    ;;
                *)  corsair.blink_set $tool $@
            esac
            ;;

        # systemd method is used after v0.6.4
        enable|start|stop|restart|disable)
            ource $home/systemd.sh
            corsair.systemd_main $cmd $@
            return $?
            ;;

        # grbl.client daemon functions
        check|install|patch|compile|remove|poll)
            source $home/install.sh
            corsair.$cmd $@
            return $?
            ;;

        # non systemd control aka. raw_method for non systemd releases like devuan
        raw)
            source $home/corsair-raw.sh
            corsair.raw.$1 $@
            ;;

        '--')
            return 3
            ;;

        help)
           source $home/help.sh
           case $1 in  profile) corsair.help-profile ;;
                  *) corsair.help
            esac
            ;;
        *)
            gr.msg -c yellow "corsair: unknown command: $cmd"
            return 2
    esac
}

corsair.systemd_main () {
# systemd control command parser
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local first=$1
    shift
    local second=$1
    shift

    source system.sh #
    source $home/systemd.sh # corsiar module systemd controls

    if ! system.init_system_check systemd >/dev/null; then
        gr.msg -c yellow -x 133 "corsair systemd: systemd not in use, try raw_start or raw_stop"
        return 10
    fi

    case $first in

        status|fix|setup|disable)
            corsair.systemd_$first
            return $?
            ;;

        init)
            corsair.systemd_make_app_service $@ || return $?
            corsair.systemd_make_daemon_service $@
            return $?
            ;;

        stop|start|restart)
            case $second in
                app|application)
                    corsair.systemd_${first}_app
                    return $?
                    ;;
                daemon|service|backend|driver)
                    corsair.systemd_${first}_daemon
                    return $?
                    ;;
                "")
                    corsair.systemd_${first}
                    return $?
                    ;;
                *)
                    corsair.systemd_${first}_daemon
                    corsair.systemd_${first}_app
                    return $?
                    ;;
            esac
            ;;
        "")
            corsair.systemd_status $@
            return $?
            ;;
        *)
            gr.msg -e1 "corsair systemd: unknown sub command '$_first'"
            return 2
    esac
    return 0
}

corsair.enabled () {
# check is corsair enabled in current user config
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -n -v2 "checking corsair is enabled.. "
    if [[ $GRBL_CORSAIR_ENABLED ]] ; then
        gr.msg -v2 -c green "enabled"
        return 0
    else
        gr.msg -v2 -c dark_grey "disabled"
        return 1
    fi
}

corsair.check () {
# Check keyboard driver is available, app and pipes are started and launch those if needed
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -n -v3 "checking corsair is enabled.. "
    if [[ $GRBL_CORSAIR_ENABLED ]] ; then
        gr.msg -v3 -c green "enabled"
        gr.msg -n -v2 -V3 -c green "enabled "
    else
        gr.msg -v3 -c dark_grey "disabled"
        gr.msg -n -v2 -V3 -c dark_grey "disabled "
        return 1
    fi

    gr.msg -n -v3 "checking ${GRBL_CORSAIR_KEYBOARD}.. "
    #TODO: save device ID during config
    if [[ ${GRBL_CORSAIR_KEYBOARD_ID} ]]; then
            gr.msg -v3 -n -c green "configured, "
        if lsusb | grep -q ${GRBL_CORSAIR_KEYBOARD_ID}; then
            gr.msg -v3 -c green "connected"
            gr.msg -n -v2 -V3 -c green "kb "
            kb_available=true
        else
            gr.msg -v3 -c black "disconnected"
            gr.msg -n -v2 -V3 -c black "kb "
            kb_available=
        fi
    else
        gr.msg -v3 -c black "not configured"
        gr.msg -n -v2 -V3 -c dark_grey "kb "
    fi

    gr.msg -n -v3 "checking ${GRBL_CORSAIR_MOUSE}.. "
    #TODO: save device ID during config
    if [[ ${GRBL_CORSAIR_KEYBOARD_ID} ]]; then
        gr.msg -v3 -n -c green "configured, "
        if lsusb | grep -q ${GRBL_CORSAIR_MOUSE_ID}; then
            gr.msg -v3 -c green "connected"
            gr.msg -n -v2 -V3 -c green "ms "
            ms_available=true
        else
            gr.msg -v3 -c black "disconnected"
            gr.msg -n -v2 -V3 -c black "ms "
            ms_available=
        fi
    else
        gr.msg -v3 -c black "not configured"
        gr.msg -n -v2 -V3 -c dark_grey "ms "
    fi

    gr.msg -n -v3 "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -q -v grep; then
        gr.msg -v3 -c green "daemon running"
        gr.msg -n -v2 -V3 -c green "daemon "
    else
        gr.msg -v3 -c red "daemon off"
        gr.msg -n -v2 -V3 -c red "daemon "
        [[ $GRBL_FORCE ]] || gr.msg -v3 -c white "start by '$GRBL_CALL corsair start -f'"
        return 13
    fi

    gr.msg -n -v3 "checking ckb-next.. "
    if ps auxf | grep "ckb-next" | grep -v "daemon" | grep -q -v grep; then
        gr.msg -v3 -c green "app running"
        gr.msg -n -v2 -V3 -c green "app "

    else
        gr.msg -v3 -c red "app off"
        gr.msg -n -v2 -V3 -c red "app "
        [[ $GRBL_FORCE ]] || gr.msg -v3 -c white "command: $GRBL_CALL corsair start"
        return 14
    fi

    source system.sh

    if system.suspend flag ; then
        gr.msg -v3 -c yellow "computer suspended, ckb-next restart requested"
        gr.msg -v3 -c white "command: $GRBL_CALL corsair start -f"
        return 15
    fi

    gr.msg -n -v3 "checking pipes.. "

    corsair_mode=$(< $corsair_last_mode)

    gr.debug "corsair mode: $corsair_mode" # debug
    gr.debug "status modes: ${status_modes[@]}" # debug

    case ${status_modes[@]} in

        *"$corsair_mode"*)
            # check pipes exists
            ps x | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/tmp/$USER/result
            amount=$(wc -l < /tmp/$USER/result)

            if [[ $amount -gt 0 ]] ; then
                gr.msg -v3 -c green "$amount pipe(s)"
                gr.msg -n -v2 -V3 -c green "$amount "
                rm /tmp/$USER/result
            else
                gr.msg -v3 -c black "no pipes"
                gr.msg -n -v2 -V3 -c black "0 "
                if [[ $kb_available ]]; then
                    corsair.help-profile
                    return 16
                fi

            fi
        ;;

        *)
            gr.msg -v3 -c yellow "not available in '$corsair_mode' mode"
            gr.msg -v3 -c white "select one of following modes to plumber: " -v3 -n
            gr.msg -v3 -c list "${status_modes[@]}" -v3
        ;;
    esac

    # check daemon warnings
    gr.msg -n -v3 "checking daemon warnings.. "
    if systemctl status ckb-next-daemon.service |grep -q -e Timeout -e Unable; then
        gr.msg -v3 -e1 "warnings found:"
        [[ $GRBL_VERBOSE -gt 2 ]] && systemctl status ckb-next-daemon.service |grep -e Timeout -e Unable;
    fi

    # check daemon is responsive
    # TODO how to figure out is all fine when:
    #   - device is connected
    #   - service is running
    #   - app is running
    #   - pipes working..
    # but, default animation is running and no connection between device and app?
    # this happens after sleep, every time, but following fixes it:
    gr.msg -v3 -c white "If not responsive try to restart daemon by '$GRBL_CALL corsair restart' "

    # all fine
    return 0
}

corsair.init () {
# load default profile and set wanted mode, default is set in user configuration
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _mode=$GRBL_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p grbl -m $_mode 2>/dev/null ; then
        export corsair_mode=$_mode
        echo $_mode > $corsair_last_mode
    else
        local _error=$?
        gr.msg -c yellow "corsair initialize failure"
        return $_error
    fi
}

corsair.set () {
# write color to key: input <key> <color>  speed test: ~25 ms
    #gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    #corsair.check is too slow to go trough here
    if ! [[ $GRBL_CORSAIR_ENABLED ]] ; then
        gr.debug "corsair disabled"
        return 1
    fi

    # get user input
    local _key=$1
    local _color='rgb_'"$2"
    local _bright="FF"
    [[ $3 ]] && _bright="$3"

    # get input key pipe file location
    local key_pipefile=$(corsair.get_pipefile $_key || return 100)

    # get input color code
    _color=$(eval echo '$'$_color)
    if ! [[ $_color ]] ; then
        gr.msg -v3 -c yellow "please input color '$_color'"
        return 102
    fi

    # corsairlize RGB code
    _color="$_color""$_bright"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $key_pipefile | grep -q fifo >/dev/null ; then
        echo "rgb $_color" > $key_pipefile
        gr.msg -v4 -n -t -c $2 "$1 < $2"
    else
        gr.msg -c yellow "io error, $key_pipefile check cbk-next profile settings"
        return 103
    fi

    return 0
}

corsair.reset () {
# application level function, not restarting daemon or application, return normal, if no input reset all
    #gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local keylist=($@)

    if [[ ${keylist[0]} ]] ; then
        for key in $@; do
            corsair.set $key $corsair_mode 10
        done
    else
        for _key_pipe in $key_pipe_list ; do
            corsair.pipe $_key_pipe $(eval echo '$'rgb_$corsair_mode)
        done
    fi
}

corsair.clear () {
# set key to black, input <known_key> default is F1 to F12
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _keylist=($key_pipe_list)
    [[ "$1" ]] && _keylist=(${@})
    for _key in $_keylist ; do
        corsair.set $_key black
    done
}

corsair.get_key_id () {
# printout key id number

    local find_list=($@)
    local got_value=

    #echo "${find_list[@]}" >>/home/casa/temp.log
    for to_find in ${find_list[@]} ; do
        for (( i=0 ; i < ${#corsair_keytable[@]} ; i++ )) ; do
            # echo "$i:$got_value" >>/home/casa/temp.log
            if [[ ${corsair_keytable[$i]} == $to_find ]] ; then
                got_value=$i
                printf "%03d" $got_value
                break
            fi
        done
    done

    [[ $got_value ]] && return 0 || return 1
}

corsair.get_pipefile () {
# printout pipe file for given key

    [[ $1 ]] || return 124

    local id=$(corsair.get_key_id $1)

    if (( $? > 0 )) ; then
        gr.msg -c yellow "key id '$id' not found"
        return 1
    fi

    local pipefile="/tmp/ckbpipe$id"

    if file $pipefile | grep fifo >/dev/null; then
        echo $pipefile
        return 0
    else
        gr.msg -c yellow "pipefile '$pipefile' not exist"
        corsair.blink_stop $1
        return 2
    fi
}

corsair.key-id () {
# printout key number for key pipe file '/tmp/$USER/ckbpipeNNN'

    local to_find=$1
    # if individual key is asked, print it out and exit

    # if no user input printout all
    if ! [[ $to_find ]] ; then

        for (( i = 0; i < ${#corsair_keytable[@]}; i++ )); do
            gr.msg -n -c white "${corsair_keytable[$i]}"
            gr.msg -n -c gray ":$(printf "%03d" $i) "
        done

        gr.msg
    fi

    # otherwise go trough key table to find requested word
    for (( i = 0; i < ${#corsair_keytable[@]}; i++ )); do

        if [[ "${corsair_keytable[$i]}" == "$to_find" ]] ; then

            # print out findings if verbose less than 1
            gr.msg -V2 -v1 "${corsair_keytable[$i]}:" -n
            gr.msg -V2 "$(printf "%03d" $i)"

            # print out with colors if verbose more than 1
            if [[ $GRBL_VERBOSE -gt 1 ]] ; then
                gr.msg -c white -v$GRBL_VERBOSE "${corsair_keytable[$i]}" -n
                gr.msg -c grey -v2 ":$(printf "%03d" $i)"
            fi
            return 0
        fi

    done

    gr.msg -c yellow "no '$1' found in key table"
    return 1
}

corsair.pipe () {
# write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _button=$1
    shift

    local _color=$1
    shift

    local _bright="FF"
    [[ $1 ]] && _bright="$1"

    echo "rgb $_color$_bright" > "$_button"
    return 0
}

corsair.check_pipe () {
# check that piping is activated. timeout can be set by first paramater
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local timeout=10
    [[ $1 ]] && timeout=$1

    for (( i = 0; i < $((timeout*2)); i++ )); do
        if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
            continue
        fi
        sleep 0.5
    done
    return 127
}

# run these functions every time corsair is called
source $home/config.sh
corsair.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    corsair.main $@
    exit "$?"
else
    gr.msg -v4 -c $__corsair_color "$__corsair [$LINENO] sourced " >&2 # debug
fi
