#!/bin/bash
# guru-client corsair led notification functions
# casa@ujo.guru 2020-2021

# WARNING: this module can fuck up system suspend, # if that happens just
# wait until login window activates, it should take less than 2 minutes (cinnamon)
# and remove file '/lib/systemd/system-sleep/guru-client-suspend.sh'

source $GURU_BIN/common.sh
source $GURU_BIN/system.sh

# active key list
key_pipe_list=$(file /tmp/ckbpipe0* | grep fifo | cut -f1 -d ":")
# modes with status bar function set. if add on this list, add name=<rgb color> to rgb-color.cfg
status_modes=(status, test, red, olive, dark, orange, eq)
corsair_last_mode="/tmp/corsair.mode"
# service configurations for ckb-next application
corsair_service="$HOME/.config/systemd/user/corsair.service"
corsair_daemon_service="/usr/lib/systemd/system/ckb-next-daemon.service"
# jsut know what to delete shen disable option/lib/systemd/system-sleep/guru-client-suspend.sh
suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh"
# poll order is read from  environment list ${GURU_DAEMON_POLL_ORDER[@]} set in user.cfg
corsair_indicator_key="f$(daemon.poll_order corsair)"
pipelist_file="$GURU_CFG/corsair-pipelist.cfg"

# import colors f
[[ -f "$GURU_CFG/rgb-color.cfg" ]] && source "$GURU_CFG/rgb-color.cfg"

# # load key pipe file list
# if [[ -f $pipelist_file ]] ; then
#         source $pipelist_file
#     else
#         gmsg -c red "pipelist file $pipelist_file missing"
#     fi

declare -a corsair_keytable=(\
    esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12          print scroll pause      stop brev play next\
    half 1 2 3 4 5 6 7 8 9 0 query backscape            insert home pageup      numlc div mul sub\
    tab q w e r t y u i o p å tilde enter               del end pagedown        np7 np8 np9 add\
    caps a s d f g h j k l ö ä asterix                                          np4 np5 np6\
    shiftl less z x c v b n m comma perioid minus shiftr     up                 np1 np2 np3\
    lctrl func alt space altgr fn set rctrl             left down right         np0 decimal count\
    )

corsair.get_key_id () {

    local find_list=($@)
    local got_value=

    for to_find in ${find_list[@]} ; do
        for (( i=0 ; i < ${#corsair_keytable[@]} ; i++ )) ; do
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

    local id=$(corsair.get_key_id $1)

    if (( $? > 0 )) ; then
            gmsg -c yellow "key not found"
            return 1
        fi

    local pipefile="/tmp/ckbpipe$id"

    if ! ls $pipefile 2>/dev/null; then
            gmsg -c yellow "pipefile not exist"
            # try to stop blink
            corsair.blink_stop $1
            return 2
        fi
    return 0
}



corsair.help () {
    # general help

    gmsg -v1 -c white "guru-client corsair keyboard indicator help"
    gmsg -v2
    gmsg -v0 "usage:           $GURU_CALL corsair start|init|reset|end|status|help|set|blink <key/profile> <color>"
    gmsg -v1 "setup:           install|compile|patch|remove"
    gmsg -v2 "without systemd: raw start|raw status|raw stop "
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " status                            printout status "
    gmsg -v1 " start                             start ckb-next-daemon "
    gmsg -v1 " stop                              stop ckb-next-daemon"
    gmsg -v1 " init <mode>                       initialize keyboard mode "
    gmsg -v2 "   modes:  status, red, olive, dark, orange, eq, trippy, yes-no and rainbow"
    gmsg -v1 " set <key> <color>                 write key color <color> to keyboard key <key> "
    gmsg -v1 " reset <key>                       reset one key or if empty, all pipes "
    gmsg -v1 " blink set|stop|kill               control blinking keys, for more detailed help, use '-v 2'" -V2
    gmsg -v2 " blink set|stop|kill               control blinking keys. to set key give following:"
    gmsg -v2 "   set <key color1 color2 speed delay leave_color>  "
    gmsg -v2 "   stop <key>                      release one key from blink loop"
    gmsg -v2 "   kill <key>                      kill all or just one key blink"
    gmsg -v1 " indicate <state> <key>            set varies blinks to indicate states. see states by-v 2" -V2
    gmsg -v2 " indicate <state> <key>            set varies blinks to indicate states. states below:"
    gmsg -v2 "   done, active, pause, cancel, error, warning, alert, "
    gmsg -v2 "   panic, passed, ok, failed, message, call, customer, calm and hacker"
    gmsg -v1 " end                               end playing with keyboard, set to normal "
    gmsg -v1 " install                           install requirements "
    gmsg -v2 " compile                           only compile, do not clone or patch"
    gmsg -v2 " patch <device>                    edit source devices: K68, IRONCLAW"
    gmsg -v2 " set-suspend                       active suspend control to avoid suspend issues"
    gmsg -v1 " remove                            remove corsair driver "
    gmsg -v2
    gmsg -v1 -c white "examples:"
    gmsg -v1 " '$GURU_CALL corsair help -v2'           get more detailed help by adding verbosity flag"
    gmsg -v1 " '$GURU_CALL corsair status'             printout status report "
    gmsg -v1 " '$GURU_CALL corsair init trippy'        initialize trippy color profile"
    gmsg -v1 " '$GURU_CALL corsair indicate panic esc set esc' "
    gmsg -v1 "                                   to blink red and white wildly "
    gmsg -v2 " '$GURU_CALL corsair blink set f1 red blue '0.5' 10 green'"
    gmsg -v2 "                                   set f1 to blink red and blue second interval "
    gmsg -v2 "                                   for 10 seconds and leave green when exit"
    gmsg -v1 " '$GURU_CALL corsair end'                stop playing with colors, return to normal"
    gmsg -v2
    gmsg -v2 -c white "setting up corsair keyboard and mice indication functions "
    gmsg -v2 -c white "1) to show how configure profile run: "
    gmsg -v2 "              $GURU_CALL corsair help profile "
    gmsg -v2 -c white "2) to enable service run: "
    gmsg -v2 "              $GURU_CALL corsair enable "
    gmsg -v2 -c white "3) to set suspend support run: "
    gmsg -v2 "              $GURU_CALL system suspend install "

    return 0
}


corsair.main () {
    # command parser

    # ckb-next last mode data
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    local cmd="$1" ; shift

    case "$cmd" in
            # indicator functions
            status|init|set|reset|clear|end|indicate)
                    corsair.$cmd $@
                    return $?
                    ;;
            # blink functions
            blink)
                    local tool=$1 ; shift
                    case $tool in
                        set|stop|kill|test)
                            corsair.blink_$tool $@
                            return $?
                            ;;
                        *)  return 1
                        esac
                    ;;
            # systemd method is used after v0.6.4.5
            enable|start|restart|stop|disable)
                    if ! system.init_system_check systemd ; then
                            gmsg -c yellow -x 133 "systemd not in use, try raw_start or raw_stop"
                        fi
                    corsair.systemd_$cmd $@
                    return $?
                    ;;
            # guru.client daemon functions
            check|install|patch|compile|remove|poll)
                    corsair.$cmd $@
                    return $?
                    ;;
            # non systemd control aka. raw_method for non systemd releases like devuan
            raw)
                    if [[ -f $GURU_BIN/corsair-raw.sh ]] ; then
                            source $GURU_BIN/corsair-raw.sh
                            corsair.raw.$1 $@
                        else
                            gmsg -c yellow "install dev modules first by 'install.sh -df' "
                        fi
                    return $?
                    ;;
            # hmm..
            '--')
                    return 12
                    ;;
            #
            help)   case $1 in  profile) corsair.help-profile ;;
                                      *) corsair.help
                        esac
                    ;;
            *)  gmsg -c yellow "corsair: unknown command: $cmd"
        esac

    return 0
}


corsair.help-profile () {
    # inform user to set profile manually (should never need)

    gmsg -c white "set ckb-next profile manually"
    gmsg -v1 -n "1) open ckb-next and click profile bar and select "
    gmsg -v1 -c white "Manage profiles "
    gmsg -v1 -n "2) then click " ; gmsg -v1 -n -c white "Import "
    gmsg -v1 -n "and navigate to " ; gmsg -v1 -n -c white "$GURU_CFG "
    gmsg -v1 -n "select " ; gmsg -v1 -c white "corsair-profile.ckb "
    gmsg -v1 -n "3) then click " ; gmsg -v1 -n -c white "open "
    gmsg -v1 "and close ckb-next"
}


corsair.enabled () {
    # check is corsair enables in user.cfg

    gmsg -n -v2 "checking corsair is enabled.. "
        if [[ $GURU_CORSAIR_ENABLED ]] ; then
                gmsg -v2 -c green "enabled"
            else
                gmsg -v2 -c dark_grey "disabled"
                gmsg -v1 -V2 -c dark_grey "corsair disabled"
                return 1
            fi
}


corsair.check () {
    # Check keyboard driver is available, app and pipes are started and executes if needed

    gmsg -n -v2 "checking corsair is enabled.. "
    if [[ $GURU_CORSAIR_ENABLED ]] ; then
            gmsg -v2 -c green "enabled"
        else
            gmsg  -c dark_grey "disabled"
            return 1
        fi

    gmsg -n -v2 "checking device is connected.. "
    if lsusb | grep "Corsair" >/dev/null ; then
            gmsg -v2 -c green "connected"
        else
            gmsg -c dark_grey "disconnected"
            return 2
        fi

    gmsg -n -v2 "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"
        else
            gmsg -c dark_grey "ckb-next-daemon not running"
            [[ $GURU_FORCE ]] || gmsg -v2 -c white "start by '$GURU_CALL corsair start -f'"
            return 3
        fi

    gmsg -n -v2 "checking ckb-next.. "
    if ps auxf | grep "ckb-next" | grep -v "daemon" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "running"

        else
            gmsg -c yellow "ckb-next application not running"
            [[ $GURU_FORCE ]] || gmsg -v2 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    if system.suspend flag ; then
            gmsg -v2 -c yellow "computer suspended, ckb-next restart requested"
            #gmsg -v2 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    gmsg -n -v2 "checking mode supports piping.. "
    if [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c white "writing not available in '$corsair_mode' mode"
            return 5
        fi

    gmsg -n -v2 "checking pipes.. "
    if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c red "pipe failed"
            corsair.help-profile
            return 6
        fi

    # all fine
    return 0
}


corsair.init () {
    # load default profile and set wanted mode, default is set in user configuration

    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > $corsair_last_mode
        else
            local _error=$?
            gmsg -c yellow "corsair init failure"
            return $_error
        fi

    return 0
}


corsair.set () {
    # write color to key: input <key> <color>  speed test: ~25 ms

    #corsair.check is too slow to go trough here
    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
            # gmsg -c dark_grey "corsair disabled"
            return 1
        fi

    local _key=$1
    # corsairlize RGB code
    local _color='rgb_'"$2"
    local _bright="FF" ; [[ $3 ]] && _bright="$3"

    # get input key pipe file location
    local key_pipefile=$(corsair.get_pipefile $_key || return 100)

    # get input color code
    _color=$(eval echo '$'$_color)
    if ! [[ $_color ]] ; then
            gmsg -v3 -c yellow "no such color '$_color'"
            return 102
        fi

    # add brightness code to color code
    _color="$_color""$_bright"

    # write color code to button pipe file and let device to receive and process command (surprisingly slow)
    if file $key_pipefile | grep fifo >/dev/null ; then
            echo "rgb $_color" > "$key_pipefile"
            # sleep 0.005, hmm.. gmsg take same time: sys 0m0,005s,
            gmsg -v4 -t -c $2 "$1 < $2"
            return 0
        else
            gmsg -c yellow "io error, $key_pipefile check cbk-next profile settings"
            return 103
        fi
}


corsair.pipe () {
    # write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>

    local _button=$1 ; shift
    local _color=$1 ; shift
    local _bright="FF" ; [[ $1 ]] && _bright="$1" ; shift
    # write color code to button pipe file
    echo "rgb $_color$_bright" > "$_button"
    # let device to receive and process command (surprisingly slow)
    #sleep 0.1
    return 0
}


corsair.reset () {
    # application level function, not restarting daemon or application, return normal, if no input reset all

    gmsg -n -v3 "resetting keys "

    if [[ "$1" ]] ; then
            # gmsg -v2 " $1"
            corsair.set $1 $corsair_mode 10 && return 0 || return 100
        else
            for _key_pipe in $key_pipe_list ; do
                gmsg -n -v3 "."
                corsair.pipe $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10 || return 100
            done
           gmsg -v3 -c green " done"
           return 0
        fi
}


corsair.clear () {
    # set key to black, input <known_key> default is F1 to F12

    local _keylist=($key_pipe_list)
    gmsg -n -v3 "setting keys "
    [[ "$1" ]] && _keylist=(${@})
    for _key in $_keylist ; do
            gmsg -n -v3 "."
            gmsg -n -V3 -v2 -c black "$_key "
            corsair.set $_key black
        done
    gmsg -v3 -c green " done"
}


corsair.end () {
    # reserve some keys for future purposes by coloring them now

    corsair.init ftb
    sleep 1
    corsair.init $GURU_CORSAIR_MODE && return 0 || return 100
}


corsair.check_pipe () {
    # check that piping is activated. input timeout in seconds

    declare -i timeout=10
    let timeout=$1 loops=timeout*2

    for (( i = 0; i < $loops; i++ )); do
        if ps auxf | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/dev/null ; then
                continue
            fi
        sleep 0.5
    done
    return 127
}


corsair.indicate () {
    # indicate state to given ke. input: mode_name key_name

    # default settings
    local level="warning"
    local key="esc"

    [[ $1 ]] && level=$1 ; shift
    [[ $1 ]] && key=$1 ; shift

    case $level in

            done)       # relax green jungle, all fine
                        corsair.blink_set $key green lime 6 300 green 2>/dev/null;;
            doing|active|working)  # indicate active job by
                        corsair.blink_set $key aqua aqua_marine 1.25 10 aqua 2>/dev/null;;
            pause)      # yellow/black pause indication
                        corsair.blink_set $key yellow black 1 3600 2>/dev/null;;
            cancel)     # blink red/green shortly
                        corsair.blink_set $key red green 0.75 3 2>/dev/null;;
            error)      # indicate that error happened, stay blinky for one daemon cycle
                        corsair.blink_set $key orange yellow 1 $GURU_DAEMON_INTERVAL yellow >/dev/null;;
            warning)
                        corsair.blink_set $key red orange 0.75 3600 orange 2>/dev/null;;
            alert)
                        corsair.blink_set $key orange_red black 0.5 3600 orange_red 2>/dev/null;;
            panic)
                        corsair.blink_set $key red white 0.2 3600 red 2>/dev/null;;
            passed|pass|ok)
                        corsair.blink_set $key lime $GURU_CORSAIR_MODE 1 300 green 2>/dev/null;;
            fail|failed)
                        corsair.blink_set $key red $GURU_CORSAIR_MODE 1 300 red 2>/dev/null;;
            message)
                        corsair.blink_set $key deep_pink dark_orchid 2 1200 dark_orchid 2>/dev/null;;
            call)
                        corsair.blink_set $key deep_pink black 0.75 30 deep_pink 2>/dev/null;;
            customer)
                        corsair.blink_set $key deep_pink white 0.75 30 deep_pink 2>/dev/null;;
            flash)
                        corsair.blink_set $key white black 0.01 1 2>/dev/null;;
            cops|poliisi)
                        corsair.blink_set $key medium_blue red 0.75 60 2>/dev/null;;
            breath|calm)
                        corsair.blink_set $key dark_cyan dark_turquoise 6 600 2>/dev/null;;
            hacker)
                        corsair.blink_set $key white black 0.2 3600 red 2>/dev/null;;
            russia|china)
                        corsair.blink_set $key red yellow 0.75 3600 red 2>/dev/null;;
        esac

    return 0
}


corsair.blink_set () {
    # start to blink input: key_name base_color high_color delay_sec timeout_sec leave_color_name
    # leave color is color what shall be left on key shen stoppend or killed.

    # all options are optional but position is criticalcause read from left to right default setting below:
    local key="esc"
    local base_c="red"
    local high_c="orange"
    local delay=0
    local timeout=0
    local leave_color=$GURU_CORSAIR_MODE

    [[ $1 ]] && key=$1 ; shift
    [[ $1 ]] && base_c=$1 ; shift
    [[ $1 ]] && high_c=$1 ; shift
    [[ $1 ]] && delay=$1 ; shift
    [[ $1 ]] && timeout=$1 ; shift
    [[ $1 ]] && leave_color=$1 ; shift

    # TBD slow method, do better
    if [[ -f /tmp/blink_pid ]] && cat /tmp/blink_pid | grep "\b$key\b" 2>/dev/null ; then
            corsair.blink_kill $key 2>/dev/null
        fi

    touch /tmp/blink_$key
    time_out=$(date +%s)
    time_out=$(( time_out + timeout ))

    while true ; do

            time_now=$(date +%s)

            if ! [[ -f /tmp/blink_$key ]] || (( time_now > time_out )) ; then
                # gmsg -n -c $leave_color -k $key
                corsair.set $key $leave_color
                #echo "$pid;$key" >>/tmp/blink_pid
                grep -v "\b$key\b" /tmp/blink_pid >/tmp/tmp_blink_pid
                mv -f /tmp/tmp_blink_pid /tmp/blink_pid
                break
            else
                # gmsg -n -k $key -c $base_c
                corsair.set $key $base_c
                [[ $delay ]] && sleep $delay
                # gmsg -n -k $key -c $high_c
                corsair.set $key $high_c
                [[ $delay ]] && sleep $delay
            fi


        done & 2>/dev/null
    pid=$!
    echo "$pid;$key" >>/tmp/blink_pid
    return 0
}


corsair.blink_stop () {
    # stop blinking in next cycle

    local key="esc"
    [[ $1 ]] && key=$1 ; shift

    [[ -f /tmp/blink_$key ]] && rm /tmp/blink_$key
    return 0
}


corsair.blink_kill () {
    # stop blinking process now, input keyname

    [[ -f /tmp/blink_pid ]] && pids_to_kill=($(cat /tmp/blink_pid))

    local pid=""
    local key=""
    local _pid=""
    local leave_color="$GURU_CORSAIR_MODE"

    for _to_kill in ${pids_to_kill[@]} ; do

        if [[ $1 ]] ; then
                key=$1
                _pid=$(cat /tmp/blink_pid | grep "\b$key\b")
                pid=$(echo ${_pid} | cut -d ';' -f1)
            else
                key=$(echo ${_to_kill[@]} | cut -d ';' -f2)
                pid=$(echo ${_to_kill[@]} | cut -d ';' -f1)
            fi

        #gmsg -c deep_pink "key:$key pid:$pid"

        [[ $pid ]] || return 0

        [[ -f "/tmp/blink_$key" ]] && rm "/tmp/blink_$key"

        if kill -15 $pid 2>/dev/null ; then
                # gmsg -n -c reset -k $key
                corsair.set $key $leave_color
                #echo "$pid;$key" >>/tmp/blink_pid
                grep -v "\b$key\b" /tmp/blink_pid >/tmp/tmp_blink_pid
                mv -f /tmp/tmp_blink_pid /tmp/blink_pid
                [[ $1 ]] && return 0

            else
                kill -9 $pid 2>/dev/null || \
                    gmsg -v1 -c yellow "failed to kill $pid" -k $key
                    return 100
            fi
        done
    return 0
}



corsair.blink_test () {
    # quick test that lights up esc and function keys

    list=(working pause cancel error warning alert panic passed failed message call customer)

    system.main flag set pause

    gmsg -c white -n "testing set, stop and kill with arguments.. "
    corsair.blink_set esc white black 0 3 red
    sleep 0.5
    corsair.blink_kill esc
    corsair.blink_set esc yellow blue 0 5 green
    corsair.blink_stop esc
    gmsg -c green "ok"

    key=1
    gmsg -c white -n "testing corsair.indicate: "
    for item in ${list[@]} ; do

            (( key > 12 )) && key=1

            if corsair.indicate $item "f$key" 2>/dev/null ; then
                    gmsg -n "f$key "
                else
                    gmsg -n -c yellow "f$key $? "
                fi
            (( key++ ))

        done \
            && gmsg -c green "passed" \
            || gmsg -c red "failed"

    sleep 3

    gmsg -c white -n "testing corsair.blink_kill.. "
    corsair.blink_kill 2>/dev/null
    file /tmp/blink_pid | grep "empty" >/dev/null && gmsg -c green "passed" || gmsg -c red "failed $?"
    #gr corsair end
    system.main flag rm pause
    return 0
}



############################ systemd method ###############################


corsair.systemd_status () {
    # printout systemd service status

    systemctl --user status corsair.service
}


corsair.systemd_start_application () {
    #s try to start, if fails, restart and it that failes to run setup again

    systemctl --user start corsair.service \
         || systemctl --user restart corsair.service\
         #|| corsair.systemd_enable

    sleep 2
    corsair.init
    return $?
}


corsair.systemd_start () {
    # check and start stack based on corsair.check return code

    if [[ $1 ]] ; then
            local _status="$1"
        else
            corsair.check
            local _status="$?"
            gmsg -v3 -c deep_pink "corsair.check: $_status"
        fi

    [[ $GURU_FORCE ]] && _status="7"

    gmsg -v3 "status/given: $_status"
    case $_status in
        1 )     gmsg -v1 -c black "corsair disabled by user configuration" ;;
        2 )     gmsg -v1 -c black "no corsair devices connected" ;;

        3 )     gmsg -v1 "corsair daemon not running, starting.. "
                if ! sudo systemctl start ckb-next-daemon ; then
                        gmsg -c yellow "start failed, trying to restart.."
                        sudo systemctl restart ckb-next-daemon
                        return 112
                    fi
                    corsair.systemd_start_application
                ;;
        4 )     gmsg -v1 "starting corsair application.. "
                corsair.systemd_start_application
                return $?
                ;;
        5 )     gmsg -v1 "no pipe support in current profile..  "
                corsair.init
                return $?
                ;;
        6 )     gmsg -v1 "re-starting corsair application.. "
                systemctl --user stop corsair.service
                system.suspend rm_flag
                corsair.systemd_start_application
                ;;
        7 )     gmsg -v1 "force re-start full corsair stack.. "
                sudo systemctl restart ckb-next-daemon
                systemctl --user restart corsair.service

                corsair.systemd_start_application
                ;;
        * )     gmsg -v1 -t -c green "corsair on service"
                return 0
    esac
}


corsair.systemd_restart () {
    # systemd method restart function

    gmsg -v1 "restarting corsair service.. "
    systemctl --user restart corsair.service

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "restarting daemon service.. "
            sudo systemctl restart ckb-next-daemon
        fi
}


corsair.systemd_stop () {
    # systemd method stop service function

    gmsg -v1 "stopping corsair service.. "
    systemctl --user stop corsair.service || gmsg -c yellow "stop failed"

    if [[ $GURU_FORCE ]] ; then
            gmsg -v1 "stopping corsair daemon service.. "
            sudo systemctl stop ckb-next-daemon
        fi
}


corsair.make_daemon_service () {
    ## ckb-next-daemon service

     local temp="/tmp/suspend.temp"

    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
# Copyright 2017-2018 ckb-next Development Team <ckb-next@googlegroups.com>
# Distributed under the terms of the GNU General Public License v2

[Unit]
Description=Corsair Keyboards and Mice Daemon

[Service]
ExecStart=/usr/local/bin/ckb-next-daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

    # copy file to from backup to avoid reinstall need after disable
    [[ -f $corsair_daemon_service ]] || cp -f $corsair_daemon_service $GURU_CFG/${corsair_daemon_service##*/}
    if ! sudo cp -f $temp $corsair_daemon_service ; then
            gmsg -c yellow "ckb-next-daemon service update failed"
            return 101
        fi

    return $?
}


corsair.make_app_service () {
    # ckb-next application service

    local temp="/tmp/suspend.temp"

    if ! [[ -d  ${corsair_service%/*} ]] ; then
        mkdir -p ${corsair_service%/*} \
            || gmsg -c yellow "no permission to create folder ${corsair_service%/*}"
    fi


    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

cat >"$temp" <<EOL
[Unit]
Description=run ckb-next application as user
DefaultDependencies=no
After=network.target

[Service]
Type=simple
# User=$USER
# Group=$USER
ExecStart=/usr/local/bin/ckb-next -b -p guru
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=default.target

EOL

    [[ -f $corsair_service ]] || cp -f $corsair_service $GURU_CFG/${corsair_service##*/}

    if ! cp -f $temp $corsair_service ; then
            gmsg -c yellow "ckb-next service update failed"
            return 102
        fi

    return $?
}


corsair.systemd_enable () {
    # set and enable corsair service based on systemd, enable suspend script, load profile and start

    # make ckb-next-daemon service
    gmsg -v1 "generating ckb-next-daemon service file.. "

    corsair.make_daemon_service
    sudo systemctl daemon-reload                         || gmsg -c yellow "daemon daemon-reload failed"
    sudo systemctl enable ${corsair_daemon_service##*/}  || gmsg -c yellow "daemon enable failed"
    sudo systemctl start ${corsair_daemon_service##*/}   || gmsg -c yellow "deamon start failed"

    ## ckb-next application service
    gmsg -v1 "generating ckb-next application service file.. "
    corsair.make_app_service
    systemctl --user daemon-reload                  || gmsg -c yellow "user daemon-reload failed"
    systemctl --user enable ${corsair_service##*/}  || gmsg -c yellow "enable failed"
    systemctl --user start ${corsair_service##*/}   || gmsg -c yellow "start failed"

    # setup suspend script
    system.main suspend rm_flag
    system.main suspend install

    # load default profile
    # corsair.check
    corsair.init status

    rm -f $temp
    #gmsg -v1 -c green "ok"
    return 0
}


corsair.systemd_disable () {
    # systemd method disable service function

    cp -f $corsair_daemon_service $GURU_CFG

    systemctl --user stop corsair.service       || gmsg -c yellow "stop failed"
    systemctl --user disable corsair.service    || gmsg -c yellow "disable failed"
    rm $corsair_service                         || gmsg -c yellow "rm failed"
    systemctl --user daemon-reload              || gmsg -c yellow "reload failed"
    systemctl --user reset-failed               || gmsg -c yellow "reset failed"

    sudo systemctl stop ckb-next-daemon         || gmsg -c yellow "daemon stop failed"
    sudo systemctl disable ckb-next-daemon      || gmsg -c yellow "daemon disable failed"

    system.main suspend remove
    rm -f $corsair_service
}


corsair.suspend_recovery () {
    # check is system suspended during run and restart ckb-next application to re-connect led pipe files

    system.flag rm fast

    [[ $GURU_CORSAIR_ENABLED ]] || return 0

    # restart ckb-next
    corsair.systemd_restart

    # wait corsair to start
    corsair.check_pipe 4
    return $?
}


################# get, patching, compile, install and setup functions ######################

corsair.clone () {
    # get ckb-next source

    cd /tmp
    [[ -d ckb-next ]] && rm -rf ckb-next
    git clone https://github.com/ckb-next/ckb-next.git \
        && gmsg -c green "ok" \
        || gmsg -x 101 -c yellow "cloning error"
}


corsair.patch () {
    # patch corsair k68 to avoid long daemon stop time

    cd /tmp/ckb-next

    case $1 in
            K68|k68|keyboard)
                gmsg -c pink "1) find 'define NEEDS_UNCLEAN_EXIT(kb)' somewhere near line ~195"
                gmsg -c pink "2) add '|| (kb)->product == P_K68_NRGB' to end of line before ')'"
                subl src/daemon/usb.h
                ;;
            IRONCLAW|ironclaw|mouse)
                gmsg "no patches yet needed for ironclaw mice"
                ;;
            *)  gmsg -c yellow "unknown patch"
        esac

    read -p "press any key to continue"
    return 0
}


corsair.compile () {
    # compile ckb-next and ckb-next-daemon

    [[ -d /tmp/ckb-next ]] || corsair.clone
    cd /tmp/ckb-next
    gmsg -c white "running installer.."
    ./quickinstall && gmsg -c green "ok" || gmsg -x 103 -c yellow "quick installer error"
    return 0
}


corsair.requirements () {
    # install required libs and apps

    local _needed="git
                   cmake
                   build-essential
                   pavucontrol
                   ibudev-dev
                   qt5-default
                   zlib1g-dev
                   libappindicator-dev
                   libpulse-dev
                   libquazip5-dev
                   libqt5x11extras5-dev
                   libxcb-screensaver0-dev
                   libxcb-ewmh-dev
                   libxcb1-dev qttools5-dev
                   libdbusmenu-qt5-2
                   libdbusmenu-qt5-dev"

    gmsg -c white "installing needed software: $_needed "

    sudo apt-get install -y $_needed \
            || gmsg -x 101 -c yellow "apt-get error $?" \
            && gmsg -c green "ok"

    return 0

}


######################### guru.client required functions ###########################

corsair.poll () {
    # guru daemon api functions

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: corsair status polling started" -k $corsair_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: corsair status polling ended" -k $corsair_indicator_key
            ;;
        status )
            corsair.status $@
            ;;
        *)  corsair.help
            ;;
        esac

}


corsair.status () {
    # get status for daemon (or user)

    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    if corsair.check ; then
            gmsg -v1 -c green "corsair on service" -k $corsair_indicator_key
            return 0
        else
            local status=$?
            gmsg -v1 -c red "corsair is not in service" # -k $corsair_indicator_key
            return $status
        fi
}


corsair.install () {
    # install essentials, driver and application

    if ! [[ $GURU_FORCE ]] && corsair.check ; then
            gmsg -v1 "corsair seems to be working. use force flag '-f' to re-install"
            return 0
        fi

    if ! lsusb | grep "Corsair" ; then
            echo "no corsair devices connected, exiting.."
            return 100
        fi

    corsair.requirements && \
    corsair.clone && \
    corsair.patch K68 && \
    corsair.compile && \

    corsair.systemd_enable
    corsair.systemd_start

    # TBD system.suspend_control
    # TBD debian suspend control

    # make backup of .service file
    cp -f $corsair_daemon_service $GURU_CFG

    return 0
}


corsair.remove () {
    # get rid of driver and shit

    gask "really remove corsair" || return 100

    if [[ /tmp/ckb-next ]] ; then
        cd /tmp/ckb-next
        sudo cmake --build build --target uninstall
    else
        # if source is not available anymore re clone it to build uninstall method
        cd /tmp
        git clone https://github.com/ckb-next/ckb-next.git
        cd ckb-next
        cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release -DSAFE_INSTALL=ON -DSAFE_UNINSTALL=ON -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBEXECDIR=lib
        cmake --build build --target all -- -j 4
        sudo cmake --build build --target install       # The compilation and installation steps are required because install target generates an install manifest that later allows to determine which files to remove and what is their location.
        sudo cmake --build build --target uninstall
    fi

    rm -f $suspend_script

    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$GURU_RC"
        corsair.main "$@"
        exit "$?"
fi

