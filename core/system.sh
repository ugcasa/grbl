#!/bin/bash
# system tools for guru-client

__system_color="light_blue"
__system=$(readlink --canonicalize --no-newline $BASH_SOURCE)
system_suspend_flag="/tmp/guru-suspend.flag"
# system_suspend_script="/etc/pm/sleep.d/system-suspend.sh" # before ubuntu 16.04
system_suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh" # ubuntu 18.04 > like mint 20.0
system_indicator_key="caps"

system.help () {
# system help printout
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -v1 "guru-client system help" -h
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL system [core-dump|update|rollback|status|suspend|env] " -c white
    gr.msg -v2
    gr.msg -v1 " core-dump            dump data for development "
    gr.msg -v1 " env get <pid>        get environmental value running process (default is guru-daemon)"
    gr.msg -v1 " env set <pid>        set environmental value of running process"
    gr.msg -v1 " update               update and upgrade os"
    gr.msg -v1 " client-update        upgrade and reinstall guru-client"
    gr.msg -v1 " client-rollback      rollback to last known working version "
    gr.msg -v1 " status               system status output "
    gr.msg -v1 " top <cpu|mem>        memory and cpu usage view "
    gr.msg -v1 " usage <cpu|mem>      memory and cpu usage view "
    gr.msg -v2 "   --lines <number>   "
    gr.msg -v2 "   --return <usage|pid|user|pmem|pcpu|command|args|top> "
    gr.msg -v2 "   --return pmem,pid,args,user "
    gr.msg -v1 " poll start|end       start or end module status polling "
    gr.msg -v1 " suspend now          suspend computer "
    gr.msg -v1 " suspend help         detailed help for page suspend functions "
    # gr.msg -v1 " flag help            detailed help for page status flag system "
}


system.suspend_help () {
# suspend help
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -v1 -c white "guru-client system flag help"
    gr.msg -v2
    gr.msg -v1 "get or set environmental variable values (or list) of running process"
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL system env [get|set] <pid|process> <variable>"
    gr.msg -v2
    gr.msg -v2 " env get|set <pid|process_name>  <variable_name>"
    gr.msg -v2 -N -c white "example:"
    gr.msg -v1 "      $GURU_CALL system env get mosquitto_sub TERM"
    gr.msg -v2
    gr.msg -v2 "if variable name is not given all variables will be printed out."
}


system.main () {
# system command parser
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local tool="$1" ; shift
    #system_indicator_key="f$(gr.poll system)"

    case "$tool" in

        status|poll|suspend|core-dump|upgrade|flag|rollback|help|update)
            system.$tool $@
            return $?
            ;;

        top)
            local target=cpu
            [[ $1 ]] && target=$1
            while true ; do
                clear
                system.get_usage $target --ret top --lines 20
                read -n1 -t3 ans
                [[ $ans ]] && return 0
            done
            ;;

        usage)
            system.get_usage $@
            ;;

        # package tools, just list for now
        # TBD install/add, remove/purge
        package|packet|pack)
            case $1 in
                ls|list)
                    # nah.. cat /var/lib/apt/extended_states | cut -d":"  -f2

                    if [[ $2 ]] ; then
                        sudo apt list | grep $2
                    else
                        sudo apt list
                    fi
                    ;;
                *)
            esac
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
            system.init_system_check $@
            return $?
            ;;

        "--"*) return 0 ;;

        *)  gr.msg -c yellow "${FUNCNAME[0]}: unknown command '$tool'"
            system.help
            return 0
    esac

    return 0
}


system.status () {
# system status
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -v1 -t -n "${FUNCNAME[0]}: "
    if [[ -f ${GURU_SYSTEM_MOUNT[0]}/.online ]] ; then
        gr.msg -n -v1 -c green "ok "
    else
        gr.msg -n -v1 -c yellow ".data is unmounted " #-k $system_indicator_key
    fi

    system.cpu_usage_check

}


system.upgrade () {
# upgrade system
    source os.shgr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    os.upgrade
    return $?
}




# TBD move flag system to flag.sh THEN remove this and need for it
system.flag () {
# set flags
    gr.debug "sogr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    me routine seems to call system.flag, pls use flag.sh instead!"
    source flag.sh
    flag.main $@
}


system.get_env () {
# get running process variable values by pid
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local _process=$1
    local _pattern=$2
    local _variable_to_find=$3

    # get PID
    local _pid=$(system.get_pid_by_name $_process)
    gr.msg -v2 -c white "pid: $_pid"

    # check user input
    local re='^[0-9]+$'
    if ! [[ $_pid =~ $re ]] ; then
        return 102
    fi

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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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


system.update () {
 # update guru-client
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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


system.cpu_usage_check () {
# cpu usage nnn..
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2


    local high_cpu_flag="/tmp/high.cpu.flag"

    # get highest usage of cpu
    high_usage=$(system.get_usage cpu --ret usage)

    # make integer
    case $high_usage in *.*) high_usage=$(echo $high_usage | cut -d "." -f 1) ;; esac
    [[ $high_usage ]] || gr.debug "$FUNCNAME: usage get failed '$high_usage'"
    gr.debug "$FUNCNAME: cpu usage: $high_usage: trigger: $GURU_SYSTEM_CPU_USAGE_TRIGGER"

    if [[ $high_usage -ge $GURU_SYSTEM_CPU_USAGE_TRIGGER ]] ; then

        # get highest pid of process of usage of cpu
        local new_pid=$(system.get_usage cpu --ret pid)

        if ! [[ $new_pid ]] ; then
            gr.debug "$FUNCNAME: pid get failed '$new_pid'"
            return 1
        fi

        local program=$(ps -p $new_pid -o comm=)

        if ! [[ -f $high_cpu_flag ]] ; then
            gr.debug "$FUNCNAME: flagged $new_pid $high_cpu_flag"
            gr.msg -n -c white "started to follow program ($high_usage) '$program' ($new_pid) "
            echo $new_pid >$high_cpu_flag
            echo
            return 0
        fi

        local old_pid=$(cat $high_cpu_flag)
        gr.debug "$FUNCNAME: old: $old_pid new: $new_pid"

        if [[ $old_pid -eq $new_pid ]] ; then

            gr.msg -n -c red "high cpu usage ($high_usage) '$program' ($new_pid) "

            key=$(( ($high_usage - $GURU_SYSTEM_CPU_USAGE_TRIGGER) + 1 ))
            [[ $key -gt 9 ]] && key=0
            gr.debug "$FUNCNAME: key is: $key"

            source say.sh
            say.main "high cpu usage detected"
        else
            gr.debug "$FUNCNAME: $high_cpu_flag removed"
            [[ -f $high_cpu_flag ]] && rm $high_cpu_flag
        fi
    else
        [[ -f $high_cpu_flag ]] && rm $high_cpu_flag
    fi
    echo

}


system.get_usage() {
# get process that uses most resources of 'cpu' or 'mem'
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

# return first process usage, pid and command
# list of three most memory hungry pids: system_most_usage mem --lines 3 --return pid

    local lines=1
    local order="pid,user,args"
    local got_args=($@)
    local target="cpu"
    local print_single=

    for (( usage_i = 0; usage_i < ${#got_args[@]}; usage_i++ )); do

        case ${got_args[$usage_i]} in

            cpu|mem)
                target=${got_args[$usage_i]}
                ;;

            --lines|--line)
                usage_i=$(($usage_i + 1))
                lines=${got_args[$usage_i]}
                ;;

            --return|--ret)
                usage_i=$(($usage_i + 1))
                case ${got_args[$usage_i]} in

                    pid)
                        order="pid"
                        print_single=true
                        field=2
                        ;;
                    usage)
                        order="p$target"
                        field=2
                        print_single=true
                        ;;
                    command)
                        order="args"
                        print_single=true
                        field=1
                        ;;
                    top)
                        order="p$target,pid,user,args --cols 80"
                        ;;
                    *)  order="${got_args[$usage_i]}"
                    esac
                ;;

        esac
    done

    if [[ $print_single ]] ; then
        local my_Pid=$$
        IFS=$'\n'
        reply=($(ps -eo $order --sort=-p$target --no-headers \
                        | head -n $lines \
                        | tr -s " "))

        for line in ${reply[@]} ; do
            echo $line | grep -v "$my_Pid" | cut -d " " -f $field
        done
    else
        ps -eo $order --sort=-p$target --no-headers \
            | head -n $lines \
            | grep -v "$$"
    fi

}


system.rollback () {
# rollback to version
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
# see issue #62gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    temp="/tmp/suspend.temp"
    gr.msg -v1 "updating $system_suspend_script.. "

    [[ -d  ${system_suspend_script%/*} ]] || sudo mkdir -p ${system_suspend_script%/*}
    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

# following lines should be without indentation
    cat > "$temp" <<EOL
#!/bin/bash
case \${1} in
  pre|suspend)
        [[ -f $system_suspend_flag ]] || touch $system_suspend_flag
        chown $USER:$USER $system_suspend_flag
    ;;
  post|resume|thaw)
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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    source flag.sh
    case "$1" in

        now )
            gr.msg -v1 "suspending.."
            #system.flag set suspend
            [[ $GURU_FORCE ]] || sleep 3
            systemctl suspend
            ;;

        flag )
            gr.msg -v3 -n "checking is system been suspended.. "
            if flag.check suspend ; then
                gr.msg -v1 -c yellow "system were suspended"
                return 0
            else
                gr.msg -v3 -c dark_grey "nope"
                return 1
            fi
            ;;

        set_flag )
            flag.set suspend
            ;;

        rm_flag )
            flag.rm suspend
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
gr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
# often when SSD drive is used the accesgr.msg -v4 -n -c $__system_color "$__system [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
sed timestamp function is disabled
# TBD fix typo

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
    system.main "$@"
    exit $?
else
    gr.msg -v4 -c $__system_color "$__system [$LINENO] sourced "
fi
