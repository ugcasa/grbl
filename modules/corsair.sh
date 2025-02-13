#!/bin/bash
# guru-client corsair led notification functions
# casa@ujo.guru 2020-2021

# TBD tests for update version 0.4.4 to v0.5.0 (2022-05-27)
# Full Changelog

# Support for new devices:
#     K95 Platinum XT
#     Katar Pro
#     Katar Pro XT
#     Glaive Pro
#     M55
#     K60 Pro RGB
#     K60 Pro RGB Low Profile
#     K60 Pro RGB SE
# K68 patch still needed? TBD


# Important bugfixes:
#     Scroll wheels are now treated as axes (Responsiveness should be improved for specific mice)
#     The lights on the K95 RGB Platinum top bar are now updated correctly
#   ! An infinite loop is prevented if certain USB information can not be read
#  !! GUI no longer crashes on exit under certain conditions
#     Mouse scrolling works again when combined with specific libinput versions
#  !! The daemon no longer hangs when quitting due to LED keyboard indicators
#     The lighting programming key can now be rebound on K95 Legacy
#   ! Animations won't break due to daylight savings / system time changes
#  !! GUI doesn't crash when switching to a hardware mode on a fresh installation
# !!! Daemon no longer causes a kernel Oops on resume under certain conditions (Devices now resume correctly from sleep)
#     Window detection is more reliable and works correctly on system boot
#     Settings tab now stretches correctly
#     Profile switch button can now be bound correctly on mice
#     ISO Enter key is now aligned correctly
#     Bindings are now consistent between demo and new modes
#     Firmware update dialog is no longer cut off and can be resized
#     RGB data won't be sent to the daemon when brightness is set to 0%

# New features:
#     German translation
#     66 service (not installed automatically)
#     Device previews are now resizable

# first installation on 24.04
# PPA method worked fine
# config: /home/casa/.config/ckb-next/ckb-next.conf
#
#

__corsair_color="light_blue"
__corsair=$(readlink --canonicalize --no-newline $BASH_SOURCE)

source common.sh

# active key list
key_pipe_list=$(file /tmp/$USER/ckbpipe0* | grep fifo | cut -f1 -d ":")
# modes with status bar function set. if add on this list, add name=<rgb color> to rgb-color.cfg
status_modes=(olive fullpipe, halfpipe, blue, eq)
corsair_last_mode="/tmp/$USER/corsair.mode"
# service configurations for ckb-next application
corsair_service="$HOME/.config/systemd/user/corsair.service"
corsair_daemon_service="/usr/lib/systemd/system/ckb-next-daemon.service"
# just know what to delete then disable option/lib/systemd/system-sleep/guru-client-suspend.sh
suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh"
# poll order is read from  environment list ${GURU_DAEMON_POLL_ORDER[@]} set in user.cfg
pipelist_file="$GURU_CFG/corsair-pipelist.cfg"

# import colors f
[[ -f "$GURU_CFG/rgb-color.cfg" ]] && source "$GURU_CFG/rgb-color.cfg"

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
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    # ckb-next last mode data
    if [[ -f $corsair_last_mode ]] ; then
            corsair_mode="$(head -1 $corsair_last_mode)"
        else
            corsair_mode=$GURU_CORSAIR_MODE
        fi

    local cmd="$1"
    shift

    case "$cmd" in
            # indicator functions
            status|init|set|reset|clear|end|indicate|keytable|key-id|type)
                    ## [[ $GURU_CORSAIR_ENABLED ]] || return 0
                    corsair.$cmd $@
                    return $?
                    ;;
            # blink functions
            blink)
                    [[ $GURU_CORSAIR_ENABLED ]] || return 0
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
                    gr.msg -n -v2 "checking launch system.. "
                    source system.sh
                    if ! system.init_system_check systemd ; then
                            gr.msg -c yellow -x 133 "systemd not in use, try raw_start or raw_stop"
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
                            gr.msg -c yellow "install dev modules first by 'install.sh -df' "
                        fi
                    return $?
                    ;;
            # hmm..
            '--')
                    return 0
                    ;;

            help)   case $1 in  profile) corsair.help-profile ;;
                                      *) corsair.help
                        esac
                    ;;
            *)  gr.msg -c yellow "corsair: unknown command: $cmd"
        esac

    return 0
}


corsair.help-profile () {
# inform user to set profile manually (should never need)
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -c white "set ckb-next profile manually"
    gr.msg -v1 -n "1) open ckb-next and click profile bar and select "
    gr.msg -v1 -c white "Manage profiles "
    gr.msg -v1 -n "2) then click "
    gr.msg -v1 -n -c white "Import "
    gr.msg -v1 -n "and navigate to "
    gr.msg -v1 -n -c white "$GURU_CFG "
    gr.msg -v1 -n "select "
    gr.msg -v1 -c white "corsair-profile.ckb "
    gr.msg -v1 -n "3) then click "
    gr.msg -v1 -n -c white "open "
    gr.msg -v1 "and close ckb-next"
}


corsair.help () {
# general help
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    gr.msg -v1 "guru-client corsair keyboard indicator help" -c white
    gr.msg -v2
    gr.msg -v0 "usage:           $GURU_CALL corsair start|init|reset|end|status|help|set|blink <key/profile> <color>"
    gr.msg -v1 "setup:           install|compile|patch|remove"
    gr.msg -v2 "without systemd: raw start|raw status|raw stop "
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v1 "  status                            printout status "
    gr.msg -v1 "  start                             start ckb-next-daemon "
    gr.msg -v1 "  stop                              stop ckb-next-daemon"
    gr.msg -v1 "  init                              initialize keyboard mode" -V2
    gr.msg -v2 "  init <mode>                       initialize keyboard mode listed below:  "
    gr.msg -v2 "                                    olive, blue, eq, trippy, rainbow"
    gr.msg -v1 "  set <key> <color>                 write key color <color> to keyboard key <key> "
    gr.msg -v1 "  reset <key>                       reset one key or if empty, all pipes "
    gr.msg -v1 "  blink set|stop|kill <key>         control blinking keys" -V2
    gr.msg -v2 "  blink set|stop|kill <key>         control blinking keys. to set key following:"
    gr.msg -v2 "    set <key color1 color2 speed delay leave_color>  "
    gr.msg -v2 "    stop <key>                      release one key from blink loop"
    gr.msg -v2 "    kill <key>                      kill all or just one key blink"
    gr.msg -v1 "  indicate <state> <key>            set varies blinks to indicate states." -V2
    gr.msg -v2 "  indicate <state> <key>            set varies blinks to indicate states. states below:"
    gr.msg -v2 "    done, active, pause, cancel, error, warning, alert, calm"
    gr.msg -v2 "    panic, passed, ok, failed, message, call, customer, hacker"
    gr.msg -v1 "  type <strig>                      blink string characters by keylights "
    gr.msg -v1 "  end                               end playing with keyboard, reset all keys "
    gr.msg -v1 "  key-id                            printout key indication codes"
    gr.msg -v1 "  keytable                          printout key table, with id's increase verbose -v2"
    gr.msg -v2
    gr.msg -v1 "installation and setup" -c white
    gr.msg -v2 "  patch <device>                    edit source devices: K68, IRONCLAW"
    gr.msg -v2 "  compile                           only compile, do not clone or patch"
    gr.msg -v1 "  install                           install requirements "
    gr.msg -v1 "  remove                            remove corsair driver "
    gr.msg -v2 "  set-suspend                       active suspend control to avoid suspend issues"
    gr.msg -v1
    gr.msg -v1 "For more detailed help, increase verbose with option '-v2'" -V2
    gr.msg -v1 -V2
    gr.msg -v2 "WARNING: This module can prevent system to go suspend and stop keyboard for responding" -c white
    gr.msg -v2 "If this happens please be patient, control will be returned:"
    gr.msg -v2 "  - wait until login window reactivate, it should take less than 2 minutes "
    gr.msg -v2 "  - log back in and remove file '/lib/systemd/system-sleep/guru-client-suspend.sh'"
    gr.msg -v2 "System suspending should work normally. You may try to install suspend scripts again "
    gr.msg -v2
    gr.msg -v2 "setting up daemon and suspend manually: " -c white
    gr.msg -v2 "  $GURU_CALL corsair help profile       show how configure profile"
    gr.msg -v2 "  $GURU_CALL corsair enable             enable corsair background service"
    gr.msg -v2 "  $GURU_CALL system suspend install     set up guru-client suspend scripts"
    gr.msg -v2
    gr.msg -v1 "examples:" -c white
    gr.msg -v1 "  $GURU_CALL corsair help -v2            get more detailed help by adding verbosity flag"
    gr.msg -v1 "  $GURU_CALL corsair status              printout status report "
    gr.msg -v1 "  $GURU_CALL corsair init trippy         initialize trippy color profile"
    gr.msg -v1 "  $GURU_CALL corsair indicate panic esc  to blink red and white"
    gr.msg -v2 "  $GURU_CALL corsair blink set f1 red blue 1 10 green"
    gr.msg -v2 "                                         set f1 to blink red and blue second interval "
    gr.msg -v2 "                                         for 10 seconds and leave green when exit"
}


corsair.keytable () {
# printout key table with numbers when verbose is increased
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    case $1 in number|numbers) GURU_VERBOSE=2 ;; esac
    gr.msg -v1
    gr.msg -v1 "keyboard indicator pipe file id's"
    gr.msg -v1
    gr.msg -v0 -c white "                                                  brtightness  sleep"
    gr.msg -v2 -c dark  "                                                     109        110 "
    gr.msg -v0 -c white "esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12        print  scroll  pause      stop prev play next"
    gr.msg -v2 -c dark  " 0   1  2  3  4  5  6  7  8  9  10  11  12         13      14      15        16   17   18   19"
    gr.msg -v3
    gr.msg -v0 -c white "half 1 2 3 4 5 6 7 8 9 0  plus query backscape    insert  home   pageup     numlc div  mul  sub"
    gr.msg -v2 -c dark  " 20  1 2 3 4 5 6 7 8 9 30  31  32      33          34      35      36        37   38   39   40"
    gr.msg -v3
    gr.msg -v0 -c white "tab q w e r t y u i o p  å tilde enter             del   end  pagedown      np7   np8  np9  add"
    gr.msg -v2 -c dark  " 41 2 3 4 5 6 7 8 9 50 1 2  53    54               55      56      57        58   59   60   61"
    gr.msg -v3
    gr.msg -v0 -c white "caps a s d f g h j k  l ö ä asterix                                         np4   np5  np6"
    gr.msg -v2 -c dark  " 62  3 4 5 6 7 8 9 70 1 2 3    74                                            75   76   77"
    gr.msg -v3
    gr.msg -v0 -c white "shiftl less z x  c v b n m comma perioid minus shiftr     up                np1   np2  np3 count"
    gr.msg -v2 -c dark  "  78    79 80 1  2 3 4 5 6   87     88     89    90       91                92    93   94   95"
    gr.msg -v3
    gr.msg -v0 -c white "lctrl func alt space altgr fn set rctrl           left   down  right        np0   decimal "
    gr.msg -v2 -c dark  "  96   97   98   99  100  101 102  103            104    105    106         107     108"
    gr.msg -v1
    gr.msg -v2 "mouse indicator pipe file id's TBD Not implemented!"
    gr.msg -v3
    gr.msg -v3 -c white "thumb  wheel logo "
    gr.msg -v3 -c dark  " 201    202   200 "
    gr.msg -v1
    gr.msg -v2 " use thee digits to indicate id in file name example: 'F12' pipe is '/tmp/$USER/ckbpipe012'"
    gr.msg -v3
    gr.msg -v3 "corsair_key_table list: "
    gr.msg -v3 "$(corsair.key-id)}"
    return 0
}


corsair.blink_all () {
# set blink animation to whole key map
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    for key in ${corsair_keytable[@]} ; do
            # corsair.set $key $color
            corsair.indicate panic $key
        done

    sleep 3

    for key in ${corsair_keytable[@]} ; do
            # corsair.set $key $color
            gr.end $key
        done

    sleep 3
    corsair.init olive
}


corsair.get_key_id () {
# printout key id number
    # gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
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
    #gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    [[ $1 ]] || return 124

    local id=$(corsair.get_key_id $1)

    if (( $? > 0 )) ; then
            gr.msg -c yellow "key id '$id' not found"
            return 1
        fi

    local pipefile="/tmp/$USER/ckbpipe$id"

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
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
            if [[ $GURU_VERBOSE -gt 1 ]] ; then
                gr.msg -c white -v$GURU_VERBOSE "${corsair_keytable[$i]}" -n
                gr.msg -c grey -v2 ":$(printf "%03d" $i)"
            fi
            return 0
        fi

    done

    gr.msg -c yellow "no '$1' found in key table"
    return 1
}


corsair.enabled () {
# check is corsair enabled in current user config
# remove?: none of functions using this exept user call?
# nothing should go broken, calling from main is not even listed
# some other moduĺe might still use this ahter soursing this file

    # gr.msg -n -v2 "checking corsair is enabled.. "
    #     if [[ $GURU_CORSAIR_ENABLED ]] ; then
    #             gr.msg -v1 -c green "enabled"
    #         else
    #             gr.msg -v1 -c dark_grey "disabled"
    #             # remove?: why make difference, some bubble cum?
    #             # gr.msg -v1 -V2 -c dark_grey "corsair disabled"
    #             return 1
    #         fi

    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    gr.debug  "function disabled, if see this during debug run, inform casa "

}


corsair.check () {
# Check keyboard driver is available, app and pipes are started and launch those if needed
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source system.sh

    gr.msg -n -v2 "checking corsair is enabled.. "
    if [[ $GURU_CORSAIR_ENABLED ]] ; then
            gr.msg -v2 -c green "enabled"
        else
            gr.msg -v2 -c dark_grey "disabled"
            return 1
        fi

    gr.msg -n -v2 "checking ${GURU_CORSAIR_KEYBOARD}.. "
    if lsusb | grep "CORSAIR ${GURU_CORSAIR_KEYBOARD^^}" >/dev/null ; then
            gr.msg -v2 -c green "connected"
        else
            gr.msg -c dark_grey "disconnected"
            return 2
        fi

    gr.msg -n -v2 "checking ${GURU_CORSAIR_MOUSE}.. "
    if lsusb | grep "CORSAIR ${GURU_CORSAIR_MOUSE^^}" >/dev/null ; then
            gr.msg -v2 -c green "connected"
        else
            gr.msg -c dark_grey "disconnected"
            # not show stopper
        fi

    gr.msg -n -v2 "checking ckb-next-daemon.. "
    if ps auxf | grep "ckb-next-daemon" | grep -v grep >/dev/null ; then
            gr.msg -v2 -c green "running"
        else
            gr.msg -c dark_grey "ckb-next-daemon not running"
            [[ $GURU_FORCE ]] || gr.msg -v2 -c white "start by '$GURU_CALL corsair start -f'"
            return 3
        fi

    gr.msg -n -v2 "checking ckb-next.. "
    if ps auxf | grep "ckb-next" | grep -v "daemon" | grep -v grep >/dev/null ; then
            gr.msg -v2 -c green "running"

        else
            gr.msg -c yellow "ckb-next application not running"
            [[ $GURU_FORCE ]] || gr.msg -v2 -c white "command: $GURU_CALL corsair start"
            return 4
        fi

    if system.suspend flag ; then
            gr.msg -v2 -c yellow "computer suspended, ckb-next restart requested"
            gr.msg -v3 -c white "command: $GURU_CALL corsair start -f"
            return 4
        fi

    gr.msg -n -v2 "checking pipes.. "
    # gr.msg -n -v2 "checking mode supports piping.. "
    #if [[ "${status_modes[@]}" =~ "$corsair_mode" ]] ; then
    corsair_mode=$(< $corsair_last_mode)

    gr.debug "corsair mode: $corsair_mode"
    gr.debug "status modes: ${status_modes[@]}"

    case ${status_modes[@]} in

        *"$corsair_mode"*)

            # check pipes exists
            ps x | grep "ckb-next" | grep "ckb-next-animations/pipe" | grep -v grep >/tmp/$USER/result
            amount=$(wc -l < /tmp/$USER/result)

            if [[ $amount -gt 0 ]] ; then
                    gr.msg -v2 -c green "found $amount pipe(s)"
                    rm /tmp/$USER/result
                else
                    gr.msg -c red "no pipes found"
                    corsair.help-profile
                    return 6
                fi
            ;;

        *)
            gr.msg -c yellow "not available in '$corsair_mode' mode"
            gr.msg -c white "select one of following modes to plumber: " -v3 -n
            gr.msg -c list "${status_modes[@]}" -v3
            return 0
            ;;
        esac


    # all fine
    return 0
}


corsair.init () {
# load default profile and set wanted mode, default is set in user configuration
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local _mode=$GURU_CORSAIR_MODE ; [[ $1 ]] && _mode="$1"

    if ckb-next -p guru -m $_mode 2>/dev/null ; then
            export corsair_mode=$_mode
            echo $_mode > $corsair_last_mode
        else
            local _error=$?
            gr.msg -c yellow "corsair initialize failure"
            return $_error
        fi

    return 0
}


corsair.set () {
# write color to key: input <key> <color>  speed test: ~25 ms
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    #corsair.check is too slow to go trough here
    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
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
            return 0
        else
            gr.msg -c yellow "io error, $key_pipefile check cbk-next profile settings"
            return 103
        fi

}


corsair.pipe () {
# write color to key: input <KEY_PIPE_FILE> _<COLOR_CODE>
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local _button=$1
    shift

    local _color=$1
    shift

    local _bright="FF"
    [[ $1 ]] && _bright="$1"

    echo "rgb $_color$_bright" > "$_button"
    return 0
}


corsair.reset () {
# application level function, not restarting daemon or application, return normal, if no input reset all
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    if [[ "$1" ]] ; then
            corsair.set $1 $corsair_mode 10 || return 100
        else
            for _key_pipe in $key_pipe_list ; do
                corsair.pipe $_key_pipe $(eval echo '$'rgb_$corsair_mode) 10 || return 101
            done
        fi

    return 0
}


corsair.clear () {
# set key to black, input <known_key> default is F1 to F12
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local _keylist=($key_pipe_list)
    [[ "$1" ]] && _keylist=(${@})
    for _key in $_keylist ; do
            corsair.set $_key black
        done
}


corsair.end () {
# reserve some keys for future purposes by coloring them now
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
# wtf above means? Anyway, this is not endig shit, just chanching profile twice.
# what is the point? commenting out extra showcase 20240602
    #corsair.init ftb
    #sleep 1

    corsair.init $GURU_CORSAIR_MODE
    return $?
}


corsair.check_pipe () {
# check that piping is activated.
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
# timeout can be set by first paramater

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
# indicate state to given key.
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
# input mode_name and key_name

    # corsair.check is too slow to go trough here
    if ! [[ $GURU_CORSAIR_ENABLED ]] ; then
            gr.msg -v2 -c dark_grey "corsair disabled"
            return 1
        fi

    # default values
    local concern="warning"
    local key="esc"
    local color="aqua_marine"
    local blink="white black 0.2 1"

    # user input
    [[ $1 ]] && concern=$1 ; shift
    [[ $1 ]] && key=$1 ; shift
    [[ $GURU_PROJECT_COLOR ]] && color=$GURU_PROJECT_COLOR

    case $concern in
        # positions: fg color bg_color blink_interval timeout leave_color
        ok)             blink="green slime 0.5 3 green" ;;
        available)      blink="green aqua_marine 0.2 1 green" ;;
        yes)            blink="green black 0.75 10 " ;;
        no)             blink="red black 0.75 10 " ;;
        cancel)         blink="orange $GURU_CORSAIR_MODE 0.2 3 " ;;
        init)           blink="blue dark_blue 0.1 5 " ;;
        pass*)          blink="slime $GURU_CORSAIR_MODE 1 300 green" ;;
        fail*)          blink="red $GURU_CORSAIR_MODE 1 300 red" ;;
        done)           blink="green slime 4 $GURU_DAEMON_INTERVAL green" ;;
        do*)            blink="aqua aqua_marine 1 $GURU_DAEMON_INTERVAL" ;;
        work*)          blink="aqua aqua_marine 5 $GURU_DAEMON_INTERVAL" ;;
        recovery)       blink="blue black 5 $GURU_DAEMON_INTERVAL blue" ;;
        grinding)       blink="blue aqua_marine 1 $GURU_DAEMON_INTERVAL" ;;
        play*)          blink="aqua aqua_marine 2 $GURU_DAEMON_INTERVAL" ;;
        active)         blink="aqua aqua_marine 0.5 5" ;;
        pause)          blink="black $GURU_CORSAIR_MODE 1 3600";;
        error)          blink="orange yellow 1 5 yellow" ;;
        message)        blink="deep_pink dark_orchid 2 1200 dark_orchid" ;;
        call)           blink="deep_pink black 0.75 30 deep_pink" ;;
        customer)       blink="deep_pink white 0.75 30 deep_pink" ;;
        offline)        blink="blue orange 1.25 $GURU_DAEMON_INTERVAL orange" ;;
        secred)         blink="deep_pink blue 1.25 $GURU_DAEMON_INTERVAL orange" ;;
        partly)         blink="aqua blue 1.25 $GURU_DAEMON_INTERVAL orange" ;;
        warn*)          blink="red orange 0.75 3600 orange" ;;
        alert)          blink="red black 0.5 $GURU_DAEMON_INTERVAL" ;;
        blue)           blink="blue black 0.5 $GURU_DAEMON_INTERVAL" ;;
        notice)         blink="orange_red black 0.75 $GURU_DAEMON_INTERVAL " ;;
        panic)          blink="red white 0.2 $GURU_DAEMON_INTERVAL red" ;;
        breath|calm)    blink="dark_cyan dark_turquoise 6 600" ;;
        cops|police)    blink="medium_blue red 0.75 60" ;;
        hacker)         blink="white black 0.2 3600 red" ;;
        important)      blink="red yellow 0.75 3600" ;;
    esac

    corsair.blink_set $key $blink >/dev/null 2>/dev/null

    return 0
}


corsair.blink_set () {
# start to blink input: key_name base_color high_color delay_sec timeout_sec leave_color
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
# leave color is color what shall be left on key shen stoppend or killed.

    # all options are optional but position is critical cause read from left to right default setting below:
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
    if [[ -f /tmp/$USER/blink_pid ]] && cat /tmp/$USER/blink_pid | grep "\b$key\b" 2>/dev/null ; then
            corsair.blink_kill $key 2>/dev/null
        fi

    touch /tmp/$USER/blink_$key
    time_out=$(date +%s)
    time_out=$(( time_out + timeout ))

    # https://stackoverflow.com/questions/11097761/is-there-a-way-to-make-bash-job-control-quiet
    (while true ; do

            time_now=$(date +%s)

            if ! [[ -f /tmp/$USER/blink_$key ]] || (( time_now > time_out )) ; then
                corsair.set $key $leave_color
                grep -v "\b$key\b" /tmp/$USER/blink_pid >/tmp/$USER/tmp_blink_pid
                mv -f /tmp/$USER/tmp_blink_pid /tmp/$USER/blink_pid
                break
            else
                corsair.set $key $base_c
                [[ $delay ]] && (sleep $delay)
                corsair.set $key $high_c
                [[ $delay ]] && (sleep $delay)
            fi


        done & )
    pid=$!
    echo "$pid;$key" >>/tmp/$USER/blink_pid
    return 0
}


corsair.blink_stop () {
# stop blinking in next cycle
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local key="esc"
    [[ $1 ]] && key=$1 ; shift

    [[ -f /tmp/$USER/blink_$key ]] && rm /tmp/$USER/blink_$key
    return 0
}


corsair.blink_kill () {
# stop blinking process now, input keyname
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    [[ -f /tmp/$USER/blink_pid ]] && pids_to_kill=($(cat /tmp/$USER/blink_pid))

    local pid=""
    local key=""
    local _pid=""
    local leave_color="$GURU_CORSAIR_MODE"

    for _to_kill in ${pids_to_kill[@]} ; do

        if [[ $1 ]] ; then
                key=$1
                _pid=$(cat /tmp/$USER/blink_pid | grep "\b$key\b")
                pid=$(echo ${_pid} | cut -d ';' -f1)
            else
                key=$(echo ${_to_kill[@]} | cut -d ';' -f2)
                pid=$(echo ${_to_kill[@]} | cut -d ';' -f1)
            fi

        [[ $pid ]] || return 0

        [[ -f "/tmp/$USER/blink_$key" ]] && rm "/tmp/$USER/blink_$key"

        if kill -15 $pid 2>/dev/null ; then
                # gr.msg -n -c reset -k $key
                corsair.set $key $leave_color
                #echo "$pid;$key" >>/tmp/$USER/blink_pid
                grep -v "\b$key\b" /tmp/$USER/blink_pid >/tmp/$USER/tmp_blink_pid
                mv -f /tmp/$USER/tmp_blink_pid /tmp/$USER/blink_pid
                [[ $1 ]] && return 0

            else
                kill -9 $pid 2>/dev/null || \
                    gr.msg -v1 -c yellow "failed to kill $pid" -k $key
                    return 100
            fi
        done
    return 0
}


corsair.blink_test () {
# quick test that lights up esc and function keys
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source flag.sh

    list=(working pause cancel error warning alert panic passed failed message call customer)

    flag.set pause

    gr.msg -c white -n "testing set, stop and kill with arguments.. "
    corsair.blink_set esc white black 0 3 red
    sleep 0.5
    corsair.blink_kill esc
    corsair.blink_set esc yellow blue 0 5 green
    corsair.blink_stop esc
    gr.msg -c green "ok"

    key=1
    gr.msg -c white -n "testing corsair.indicate: "
    for item in ${list[@]} ; do

            (( key > 12 )) && key=1

            if corsair.indicate $item "f$key" 2>/dev/null ; then
                    gr.msg -n "f$key "
                else
                    gr.msg -n -c yellow "f$key $? "
                fi
            (( key++ ))

        done \
            && gr.msg -c green "passed" \
            || gr.msg -c red "failed"

    sleep 3

    gr.msg -c white -n "testing corsair.blink_kill.. "
    corsair.blink_kill 2>/dev/null
    file /tmp/$USER/blink_pid | grep "empty" >/dev/null \
        && gr.msg -c green "passed" \
        || gr.msg -c red "failed $?"
    #gr corsair end
    flag.rm pause
    return 0
}


corsair.type_end () {
# end current type process
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    if [[ -f /tmp/$USER/guru-cli_corsair-typing ]] ; then
            rm /tmp/$USER/guru-cli_corsair-typing
            #kill /tmp/$USER/guru-cli_corsair.pid
            #rm /tmp/$USER/guru-cli_corsair.pid
        fi
}


corsair.type () {
# blink string characters by key lights
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
# input color of keys and then string
    color=$1
    shift
    string=${@,,}

    touch /tmp/$USER/guru-cli_corsair-typing

    for (( i=0 ; i < ${#string} ; i++ )) ; do

            # TBD following does not work when called from script, dunno why
            [[ -f /tmp/$USER/guru-cli_corsair-typing ]] || break

            key="${string:$i:1}"

            case $key in
              \ )
                  gr.msg -n -v3  " "
                  key="space"
                ;;
              "."|":")
                  gr.msg -n -v3 "$key"
                  key="perioid"
                ;;
              ","|":")
                  gr.msg -n -v3 "$key"
                  key="comma"
                ;;
              "-"|"_")
                  gr.msg -n -v3 "$key"
                  key="minus"
                ;;
              "/")
                  gr.msg -n -v3 "/"
                  key="7"
                ;;
              "!")
                  gr.msg -n -v3 ""
                  key="1"
                ;;
              "?"|"+")
                  gr.msg -n -v3 "$key"
                  key="plus"
                ;;
              "'"|'"'|'('|')')
                  continue
                ;;
              *)
                gr.msg -n -v3 $key
                ;;
            esac


            corsair.main set $key ${color,,}
            # if color given in upcase, leave letters to shine
            [[ ${color:0:1} == [A-Z] ]] && continue
            sleep 0.5
            corsair.main reset $key

        done & 2>/dev/null
        #echo $! >/tmp/$USER/guru-cli_corsair.pid
    gr.msg -v3
}


############################ systemd methods ###############################


corsair.systemd_status () {
# printout systemd service status
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    systemctl --user status corsair.service
}


corsair.systemd_start_application () {
# try to start, if fails, restart and it that failes to run setup again
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    systemctl --user start corsair.service \
         || systemctl --user restart corsair.service\
         #|| corsair.systemd_enable

    sleep 2
    corsair.init
    local _error=$?

    # # is non clean way to start daemon, but for now enought
    # source daemon.sh
    # daemon.start &

    return $_error
}


corsair.systemd_start () {
# check and start stack based on corsair.check return code
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source system.sh
    if [[ $1 ]] ; then
            local _status="$1"
        else
            corsair.check
            local _status="$?"
            gr.debug "corsair.check: $_status"
        fi

    [[ $GURU_FORCE ]] && _status="7"

    gr.msg -v3 "status/given: $_status"
    case $_status in
        1 )     gr.msg -v1 -c black "corsair disabled by user configuration" ;;
        2 )     gr.msg -v1 -c black "no corsair devices connected" ;;

        3 )     gr.msg -v1 "corsair daemon not running, starting.. "
                if ! sudo systemctl start ckb-next-daemon ; then
                        gr.msg -c yellow "start failed, trying to restart.."
                        sudo systemctl restart ckb-next-daemon
                        return 112
                    fi
                    corsair.systemd_start_application
                ;;
        4 )     gr.msg -v1 "starting corsair application.. "
                corsair.systemd_start_application
                return $?
                ;;
        5 )     gr.msg -v1 "no pipe support in current profile..  "
                corsair.init
                return $?
                ;;
        6 )     gr.msg -v1 "re-starting corsair application.. "
                systemctl --user stop corsair.service
                system.suspend rm_flag
                corsair.systemd_start_application
                ;;
        7 )     gr.msg -v1 "force re-start full corsair stack.. "
                sudo systemctl restart ckb-next-daemon
                systemctl --user restart corsair.service

                corsair.systemd_start_application
                ;;
        * )     gr.msg -v1 -t -c green "corsair on service"
                return 0
    esac
}


corsair.systemd_restart () {
# systemd method restart function
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -h "restarting corsair service.. "
    systemctl --user restart corsair.service && gr.msg -c green "ok" || gr.msg -e1 "failed"

    gr.msg -h "restarting daemon service.. "
    sudo systemctl restart ckb-next-daemon && gr.msg -c green "ok" || gr.msg -e1 "failed"


}


corsair.systemd_stop () {
# systemd method stop service function
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -h "stopping corsair service.. "
    systemctl --user stop corsair.service || gr.msg -c yellow "stop failed"

    if [[ $GURU_FORCE ]] ; then
            gr.msg -h "stopping corsair daemon service.. "
            sudo systemctl stop ckb-next-daemon
        fi
}


corsair.make_daemon_service () {
# ckb-next-daemon service
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

     local temp="/tmp/$USER/suspend.temp"

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
            gr.msg -c yellow "ckb-next-daemon service update failed"
            return 101
        fi

    return $?
}


corsair.make_app_service () {
# ckb-next application service
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local temp="/tmp/$USER/suspend.temp"

    if ! [[ -d  ${corsair_service%/*} ]] ; then
        mkdir -p ${corsair_service%/*} \
            || gr.msg -e1 "no permission to create folder ${corsair_service%/*}"
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
            gr.msg -c yellow "ckb-next service update failed"
            return 102
        fi

    return $?
}


corsair.systemd_enable () {
# set and enable corsair service based on systemd, enable suspend script, load profile and start
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source system.sh

    # make ckb-next-daemon service
    gr.msg -v1 "generating ckb-next-daemon service file.. "

    corsair.make_daemon_service
    sudo systemctl daemon-reload                         || gr.msg -c yellow "daemon daemon-reload failed"
    sudo systemctl enable ${corsair_daemon_service##*/}  || gr.msg -c yellow "daemon enable failed"
    sudo systemctl start ${corsair_daemon_service##*/}   || gr.msg -c yellow "daemon start failed"

    ## ckb-next application service
    gr.msg -v1 "generating ckb-next application service file.. "
    corsair.make_app_service
    systemctl --user daemon-reload                  || gr.msg -c yellow "user daemon-reload failed"
    systemctl --user enable ${corsair_service##*/}  || gr.msg -c yellow "enable failed"
    systemctl --user start ${corsair_service##*/}   || gr.msg -c yellow "start failed"

    # setup suspend script
    system.main suspend rm_flag
    system.main suspend install

    # load default profile
    # corsair.check
    corsair.init status

    rm -f $temp
    #gr.msg -v1 -c green "ok"
    return 0
}


corsair.systemd_disable () {
# systemd method disable service function
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source system.sh

    cp -f $corsair_daemon_service $GURU_CFG

    systemctl --user stop corsair.service       || gr.msg -c yellow "stop failed"
    systemctl --user disable corsair.service    || gr.msg -c yellow "disable failed"
    rm $corsair_service                         || gr.msg -c yellow "rm failed"
    systemctl --user daemon-reload              || gr.msg -c yellow "reload failed"
    systemctl --user reset-failed               || gr.msg -c yellow "reset failed"

    sudo systemctl stop ckb-next-daemon         || gr.msg -c yellow "daemon stop failed"
    sudo systemctl disable ckb-next-daemon      || gr.msg -c yellow "daemon disable failed"

    system.main suspend remove
    rm -f $corsair_service
}


corsair.suspend_recovery () {
# check is system suspended during run and restart ckb-next application to re-connect led pipe files
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    source system.sh
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
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    cd /tmp
    [[ -d ckb-next ]] && rm -rf ckb-next
    git clone https://github.com/ckb-next/ckb-next.git \
        && gr.msg -c green "ok" \
        || gr.msg -x 101 -c yellow "cloning error"
}


corsair.patch () {
# patch corsair k68 to avoid long daemon stop time
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    cd /tmp/$USER/ckb-next

    case $1 in
            K68|k68|keyboard)
                gr.msg -c white "1) find 'define NEEDS_UNCLEAN_EXIT(kb)' somewhere near line ~195"
                gr.msg -c white "2) add '|| (kb)->product == P_K68_NRGB' to end of line before ')'"
                subl src/daemon/usb.h
                ;;
            IRONCLAW|ironclaw|mouse)
                gr.msg "no patches yet needed for ironclaw mice"
                ;;
            *)  gr.msg -c yellow "unknown patch"
        esac

    read -p "press any key to continue"
    return 0
}


corsair.compile () {
# compile ckb-next and ckb-next-daemon
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    [[ -d /tmp/$USER/ckb-next ]] || corsair.clone
    cd /tmp/$USER/ckb-next
    gr.msg -c white "running installer.."
    ./quickinstall && gr.msg -c green "ok" || gr.msg -x 103 -c yellow "quick installer error"
    return 0
}


corsair.requirements () {
# install required libs and apps
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    # https://github.com/ckb-next/ckb-next/wiki/Linux-Installation#build-from-source
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

    gr.msg -c white "installing needed software: $_needed "

    sudo apt-get install -y $_needed \
            || gr.msg -x 101 -c yellow "apt-get error $?" \
            && gr.msg -c green "ok"

    return 0

}


######################### guru.client required functions ###########################


corsair.poll () {
# guru daemon api functions
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started"
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended"
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
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    if corsair.check ; then
            gr.msg -v1 -c green "corsair on service"
            return 0
        else
            gr.msg -v1 -c red "corsair is not in service"
            return 100
        fi
}


corsair.install () {
# install essentials, driver and application
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    if corsair.check && ! [[ $GURU_FORCE ]] ; then
            gr.msg -v1 "corsair seems to be working. use force flag '-f' to re-install"
            return 0
        fi

    if ! lsusb | grep "Corsair" ; then
            echo "no corsair devices connected, exiting.."
            return 100
        fi


    source /etc/os-release
    source /etc/upstream-release/lsb-release
    # gr.msg "$NAME $VERSION_ID '$VERSION_CODENAME' based on $DISTRIB_ID $DISTRIB_RELEASE '$DISTRIB_CODENAME' $HOME_URL" ;;
    # Ubuntu (18.04, 20.04, 22.04, 23.04) or equivalent (Linux Mint 19+, Pop!_OS)
    if [[ $DISTRIB_ID != "Ubuntu" ]] ; then
        gr.msg "Ubuntu based systems only!"
        return 2
    fi

    case $DISTRIB_RELEASE in
        18.*|19.*|20.*|22.*|23.*)
            # There is PPA but K68 dows not work with it, need patch source code, then compile
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
        ;;
        24.*)
            # https://launchpad.net/~tatokis/+archive/ubuntu/ckb-next
            # Trying with re-compiled version
            sudo add-apt-repository ppa:tatokis/ckb-next
            sudo apt update
            sudo apt install ckb-next
        ;;
    esac
    return 0
}


corsair.remove () {
# get rid of driver and shit
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    # https://github.com/ckb-next/ckb-next/wiki/Linux-Installation#uninstallation
    gr.ask "really remove corsair" || return 100

    if [[ /tmp/$USER/ckb-next ]] ; then
        cd /tmp/$USER/ckb-next
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
    #source "$GURU_RC"
    corsair.main "$@"
    exit "$?"
else
    gr.msg -v4 -c $__corsair_color "$__corsair [$LINENO] sourced " >&2
fi


