#!/bin/bash
# system tools for guru-client
source os.sh

system_suspend_flag="/tmp/guru-suspend.flag"
# system_suspend_script="/etc/pm/sleep.d/system-suspend.sh" # before ubuntu 16.04
system_suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh" # ubuntu 18.04 > like mint 20.0
system_indicator_key="f5"

system.help () {
# system help printout

    gr.msg -v1 -c white "guru-client system help"
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL system [core-dump|update|rollback|status|suspend|env] "
    gr.msg -v2
    gr.msg -v1 " core-dump            dump data for development "
    gr.msg -v1 " env get <pid>        get environmental value running process (default is guru-daemon)"
    gr.msg -v1 " env set <pid>        set environmental value of running process"
    gr.msg -v1 " update               update and upgrade os"
    gr.msg -v1 " client-update        upgrade and reinstall guru-client"
    gr.msg -v1 " client-rollback      rollback to last known working version "
    gr.msg -v1 " status               system status output"
    gr.msg -v1 " suspend <sub_cmd>    suspend functions '$GURU_CALL system suspend help' for more details "
    gr.msg -v2 " flags                show system flag status"
    gr.msg -v2 " set_flag             arise system flag"
    gr.msg -v2 " rm_flag              remove system flag"
    gr.msg -v1 " suspend now          suspend computer"
    gr.msg -v1 " poll start|end       start or end module status polling "
}


system.suspend_help () {
# suspend help

    gr.msg -v1 -c white "guru-client system suspend help"
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL system suspend [flag|set_flag|rm_flag|install|remove]"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v2
    gr.msg -v1 " flag         read flag status"
    gr.msg -v1 " install      add suspend script "
    gr.msg -v1 " remove       remove suspend script"
    gr.msg -v2
    gr.msg -v1 " BE CAREFUL Save the state of your system before install"
    gr.msg -v1 " or remove parts to/from working system. Proceed in your own risk"
    gr.msg -v2
}


system.env_help () {
# system environment help printout

    gr.msg -v1 -c white "guru-client system flag help"
    gr.msg -v2
    gr.msg -v1 "get or set environmental variable list or single variable with values of running process"
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL system env [get|set] <pid|process> <variable>"
    gr.msg -v2
    gr.msg -v2 " env get|set <pid|process_name>  <variable_name>"
    gr.msg -v2 -N -c white "example:"
    gr.msg -v1 "      $GURU_CALL system env get mosquitto_sub TERM"
    gr.msg -v2
    gr.msg -v2 "if variable name is not given all variables will be printed out."
}


system.flag-help () {
# flag help

    gr.msg -v1 -c white "guru-client system suspend help"
    gr.msg -v2
    gr.msg -v1 "set flags that can control daemon processes (systemdless method) "
    gr.msg -v0 "usage:    $GURU_CALL system flag [ls|set|rm|help]"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v2
    gr.msg -v1 " <flag>         return flag status"
    gr.msg -v1 " check <flag>   return flag status"
    gr.msg -v1 " ls             list of flags with status"
    gr.msg -v1 " set <flag>     set flag"
    gr.msg -v1 " rm <flag>      remove flag"
    gr.msg -v2 " help           this help"
    gr.msg -v2
}


system.main () {
# system command parser

    local tool="$1" ; shift
    #system_indicator_key="f$(gr.poll system)"

    case "$tool" in

            status|poll|suspend|core-dump|upgrade|flag|rollback|help)
                system.$tool $@
                return $?
                ;;

            update)
                system.client_update
                return $?
                ;;

            env)
                local re='^[0-9]+$'
                local cmd=$1 ; shift

                case $cmd in
                        get|set)
                            if [[ $2 =~ $re ]] ; then
                                    system."$cmd"_env $@
                                else
                                    system."$cmd"_env_by_name $@
                                fi
                            ;;
                        *)
                            gr.msg -c yellow "get or set please"
                            GURU_VERBOSE=2
                            system.help
                    esac
                ;;

            init_system)
                system.init_system_check "$@"
                return $?
                ;;

            "--") return 0 ;;

            *)  gr.msg -c yellow "${FUNCNAME[0]}: unknown command '$tool'"
                system.help
                return 0
        esac

    return 0
}


system.status () {
# system status

    gr.msg -v1 -t -n "${FUNCNAME[0]}: "
    if [[ -f ${GURU_SYSTEM_MOUNT[0]}/.online ]] ; then
            gr.msg -n -v1 -c green "all fine with " #-k $system_indicator_key
        else
            gr.msg -n -v1 -c yellow ".data is unmounted " #-k $system_indicator_key
        fi

    gr.msg -v1 -n "$(os.status)"
    gr.msg -v2 -n "caps lock $(os.capslock state)"

}

# ISSUE #7 broken
system.flag () {
# set flags

    local cmd=$1 ; shift
    case $cmd in
            set|rm|unset|reset|ls|toggle|check)
                    system.$cmd-flag $@
                    return $?
                    ;;
            status)
                    system.flag-status $1
                    ;;
            help)   system.flag-help
                    return 0
                    ;;
            "")     system.ls-flag
                    return $?
                    ;;
            *)      system.check-flag $cmd
                    return $?
                    ;;
        esac
}


system.check-flag () {
# returen true if flag is set, no printout

    if [[ -f /tmp/guru-$1.flag ]] ; then
            return 0
        else
            return 1
        fi
}


system.flag-status () {
# returen true if flag is set, no printout

    if system.check-flag ; then
            gr.msg -v1 -c aqua "set"
        else
            gr.msg -v1 -c dark_gray "not set"
        fi
}


system.ls-flag () {
# list of flags

    gr.msg -v2 -c white "system flag status:"
    local flag_list=(fast pause suspend stop running)

    local flag=
    for flag in ${flag_list[@]} ; do
            gr.msg -V1 -n "$flag:"
            gr.msg -v1 -n "$flag flag: "
            if system.check-flag $flag ; then
                    gr.msg -c aqua "set"
                else
                    gr.msg -c dark_grey "disabled"
                fi
        done
}


system.set-flag () {
# set flag

    local flag="$1"

    if ! [[ $flag ]] ; then
            gr.msg -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
            return 0
        fi

    if [[ -f /tmp/guru-$flag.flag ]] ; then
            gr.msg -t -v3 "$flag flag already set"
            return 0
        else
            touch /tmp/guru-$flag.flag && gr.msg -t -v1 "$flag flag set"
        fi
}


system.rm-flag () {
# release flag

    local flag="$1"

    if ! [[ $flag ]] ; then
            gr.msg  -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
            return 0
        fi

    if [[ -f /tmp/guru-$flag.flag ]] ; then
            rm -f /tmp/guru-$flag.flag && gr.msg -t -v1 "$flag flag disabled"
            return 0
        else
            gr.msg -t -v3 "$flag flag not set"
        fi
}


system.reset-flag() {
    system.rm-flag $@
    return $?
}


system.unset-flag() {
    system.rm-flag $@
    return $?
}


system.toggle-flag () {
# toggle flag status

    local flag="$1"

    if ! [[ $flag ]] ; then
            gr.msg -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
            return 0
        fi

    if [[ -f /tmp/guru-$flag.flag ]] ; then
            rm -f /tmp/guru-$flag.flag && gr.msg -t -v1 "$flag flag disabled"
            return 0
        else
            touch /tmp/guru-$flag.flag && gr.msg -t -v1 "$flag flag set"
        fi
}


system.get_env () {
# get running process variable values by pid

    local _pid=$1
    [[ $_pid ]] || gr.msg -x 127 -c yellow "pid name required "
    local _pattern=$2
    local _variable_to_find=$3

    # find variables pattern
    if [[ $_pattern ]] ; then
            local _variables=$(cat /proc/$_pid/environ \
                | tr '\0' '\n' \
                | grep $_pattern \
                || gr.msg -c yellow "no v ariables")
        else
            local _variables=$(cat /proc/$_pid/environ \
                | tr '\0' '\n' \
                || gr.msg -c yellow "no variables")
        fi

    if ! [[ $_variable_to_find ]] ; then
            gr.msg "$_variables"
            return 0
        fi

    local _variables_found=$(cat /proc/$_pid/environ \
        | tr '\0' '\n' \
        | grep "$_pattern*" \
        | grep $_variable_to_find \
        | awk '{ print length(), $0 | "sort -n" }' \
        | cut -f2 -d " " \
        || gr.msg -c yellow "variable not found")

    # single variable
    local _variable_found=$(cat /proc/$_pid/environ \
        | tr '\0' '\n' \
        | grep "$_pattern*" \
        | grep $_variable_to_find \
        | awk '{ print length(), $0 | "sort -n" }' \
        | cut -f2 -d " " \
        | head -1 \
        || gr.msg -c yellow "variable not found")

    local _variable=$(echo  $_variable_found \
        | cut -f1 -d "=")

    # single value
    local _value=$(echo  $_variable_found \
        | cut -f2 -d "=")

    # printout
    gr.msg -v1 -c white "found variables:"
    gr.msg "$_variables_found"

    if [[ $_variable_found ]] ; then
            gr.msg -v1 -c white "$_variable value is:"
            gr.msg "$_value"
            return 0
        else
            gr.msg -v1 -c yellow "no variable found"
            return 1
        fi
}


system.get_pid_by_name () {
# get process pid by name

    local _process="$1"
    [[ $_process ]] || read -p "process name: " _process

    # find process
    local _found_processes=$(ps auxf \
        | grep "$_process" \
        | grep -v grep \
        | grep -v "system" )

    # pid where environment ir read
    local _pid=$(echo $_found_processes \
        | head -1 \
        | xargs \
        | cut -f2 -d " ")

    if ! [[ $_pid ]] ; then
            gr.msg -c yellow "no process '$_process'"
            return 101
        fi

    # check is number
    local re='^[0-9]+$'
    if ! [[ $_pid =~ $re ]] ; then
            gr.msg -c yellow "no process '$_process' or found got bad PID '$_pid'"
            return 102
        fi

    echo $_pid
    return 0
}


system.get_env_by_name () {
    # get running process variable values by process name

    local _process=$1
    local _pattern=$2
    local _variable_to_find=$3

    # get PID
    local _pid=$(system.get_pid_by_name $_process)
    gr.msg -v2 -c white "pid: $_pid"

    # check user input
    local re='^[0-9]+$'
    if ! [[ $_pid =~ $re ]] ; then return 102 ; fi

    local found_process="$(ps auxf \
        | grep $_pid \
        | grep -v grep \
        | head -1 \
        | xargs \
        | rev \
        | cut -d " " -f1-4 | rev)"

    [[ $_pid ]] || gr.msg -x 111 -c yellow "no process with id $_pid"

    gr.msg -v2 -c white "found: $_process $found_process"

    # pattern in variable name
    system.get_env $_pid $_pattern $_variable_to_find
}


system.get_window_id () {
# input process id, output window id to std

    local findpid=$1
    local known_windows=$(xwininfo -root -children | sed -e 's/^ *//' | grep -E "^0x" | awk '{ print $1 }')

    for id in ${known_windows} ;  do

            # echo "${id}|${pid}|${findpid}" >>/home/casa/git/guru-client/modules/log.log
            local xx=$(xprop -id $id _NET_WM_PID)
            if test $? -eq 0; then
                    pid=$(xprop -id $id _NET_WM_PID | cut -d '=' -f2 | tr -d ' ')
                    if [[ "${pid}" -eq "${findpid}" ]] ; then
                            echo "$id"
                        fi
                fi
        done
}


system.client_update () {
 # update guru-client

    local temp_dir="/tmp/guru"
    local source="https://github.com/ugcasa/guru-client.git"
    local branch="dev"

    # [[ "$GURU_USE_VERSION" ]] && branch="$GURU_USE_VERSION"
    [[ "$1" ]] && branch="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"

    git clone -b "$branch" "$source" || return 100
    # bash $GURU_BIN/uninstall.sh -f
    cd "$temp_dir/guru-client"
    bash install.sh -fc $@
    cd
    rm -fr $temp_dir
}


system.upgrade () {
# upgrade system

    #gr.ind doing -k $system_indicator_key

    sudo apt-get update \
        || gr.msg -c red -x 100 "update failed" -k $system_indicator_key

    gr.msg -v2 -c white "upgradable list: "
    gr.msg -v2 -c light_blue "$(sudo apt list --upgradable)"

    sudo apt-get upgrade -y \
        || gr.msg -c red -x 101 "upgrade failed" -k $system_indicator_key

    sudo apt-get autoremove --purge \
        || gr.msg -c yellow "autoremove returned warning" -k $system_indicator_key

    sudo apt-get autoclean \
        || gr.msg -c yellow "autoclean returned warning" -k $system_indicator_key


    /usr/bin/python3 -m pip install --upgrade pip \
        && gr.msg -c green "pip upgrade ok" \
        || gr.msg -c yellow "pip upgrade warning: $? check log above" -k $system_indicator_key

    #gr.end -k $system_indicator_key

    sudo apt-get check \
        && gr.msg -c green "check ok" -k $system_indicator_key \
        || gr.msg -c yellow "warning: $? check log above" -k $system_indicator_key

}


system.update () {
# upgrade system

    system.upgrade
    return $?
}


system.rollback () {
# rollback to version

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-client.git"
    local _roll_to="1"
    [ "$1" ] && _roll_to="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"
    git clone -b "rollback$_roll_to" "$source" || return 100
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-client"
    bash install.sh "$@"
    cd
    # bash $GURU_BIN/$GURU_CALL version
    [ "$temp_dir" ] && [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}


system.init_system_check () {
# check init system, return 0 if match with input sysv-init|systemd|upstart
# see issue #62
    local user_input=

    [[ "$1" ]] && user_input=$1

    if [[ `/sbin/init --help` =~ upstart ]] ; then # TBD: test with upstart
            init_system="upstart"

        elif [[ `systemctl` =~ -\.mount ]] ; then
            # kind of same as "systemctl | grep  '\.mount'"
            init_system="systemd"

        elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]] ; then # TBD: test with sysv"
            init_system="sysv-init"

        else
            init_system=
    fi

    [[ $init_system ]] || gr.msg -x 135 -c yellow "cannot detect init system"
    [[ $user_input ]] || gr.msg -V1 "$init_system"
    # TBD possible issue, should exit here if input empy, or set default init system = systemdf in defination?
    # now function returns 0 if null init_system from elif else. if input is required, if fine but should
    # exit with error

    if [[ "$init_system" == "$user_input" ]] ; then
            gr.msg -v1 -V2 -c green "ok"
            gr.msg -v2 -c green "$init_system"
            return 0
        else
            gr.msg -v1 -c yellow "init system did not match, got '$init_system'"
            return 100

        fi
}


system.suspend_script () {
# launch stuff on suspend

    temp="/tmp/suspend.temp"
    gr.msg -v1 "updating $system_suspend_script.. "

    [[ -d  ${system_suspend_script%/*} ]] || sudo mkdir -p ${system_suspend_script%/*}
    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

# following lines should be without indentation
    cat > "$temp" <<EOL
#!/bin/bash
case \${1} in
  pre|suspend )
        [[ -f $system_suspend_flag ]] || touch $system_suspend_flag
        chown $USER:$USER $system_suspend_flag
    ;;
  post|resume|thaw )
        systemctl restart ckb-next-daemon
        systemctl --user restart corsair.service
        # systemctl restart guru-daemon
    ;;
esac
EOL

    if sudo cp -f $temp $system_suspend_script ; then

            sudo chmod +x $system_suspend_script || return 2
            rm -f $temp
            gr.msg -v1 -c green "success"
            return 0
       else
            gr.msg -c yellow "failed update $system_suspend_script"
            return 1
        fi

}


system.suspend () {
# suspend control

    case "$1" in

            now )
                gr.msg -v1 "suspending.."
                #system.flag set suspend
                [[ $GURU_FORCE ]] || sleep 3
                systemctl suspend
                ;;

            flag )
                gr.msg -v3 -n "checking is system been suspended.. "
                if system.flag suspend ; then
                        gr.msg -v1 -c yellow "system were suspended"
                        return 0
                    else
                        gr.msg -v3 -c dark_grey "nope"
                        return 1
                    fi
                ;;

            set_flag )
                system.flag set suspend
                ;;

            rm_flag )
                system.flag rm suspend
                ;;

            install )
                system.suspend_script
                ;;

            remove )
                gr.msg -n -v1 "removing suspend script.. "
                sudo rm -f $system_suspend_script \
                    && gr.msg -v1 -c green "ok" || gr.msg -c red "failed"
                ;;

            help )
                system.suspend_help
                ;;
            *)
                gr.msg -c yellow "${FUNCNAME[0]}: unknown suspend command: $1"
                system.suspend_help
                ;;

        esac
}


system.poll () {
# daemon poller interface

    local _cmd="$1" ; shift

    case $_cmd in

        # start|end) #
        #     gr.msg -v1 -t -c $_cmd "${FUNCNAME[0]}: $_cmded" -k $system_indicator_key
        #     ;;

        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $system_indicator_key

            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $system_indicator_key

            ;;
        status )
            system.status $@
            return $?
            ;;
        *)  system.help
            ;;
        esac
}


system.check_fs_access_flag_enabled () {
# check is system recording file access
# often when SSD dirve is used the accessed timestamp function is disabled

    echo "acccess flag is" >/tmp/test_access

    local orig=$(stat -c '%X' /tmp/test_access)
    sleep 1
    gr.msg -n -v1 "$(cat /tmp/test_access) "
    local edit=$(stat -c '%X' /tmp/test_access)
    rm -f /tmp/test_access

    if [[ "$orig" -eq "$edit" ]] ; then
        gr.msg -v1 -c red "disabled"
        return 1
    else
        gr.msg -v1 -c green "enabled"
        return 0
    fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source $GURU_RC # issue with bash? all other variables EXEPT lists are filled when sourced by previous script (the who calls this one)
    system.main "$@"
    exit $?
fi
