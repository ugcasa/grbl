#!/bin/bash
# system tools for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh

system_suspend_flag="/tmp/guru-suspend.flag"
# system_suspend_script="/etc/pm/sleep.d/system-suspend.sh" # before ubuntu 16.04
system_suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh" # ubuntu 18.04 > like mint 20.0

system_indicator_key="f$(daemon.poll_order system)"

system.help () {
    # system help printout
    gmsg -v1 -c white "guru-client system help"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL system [core-dump|update|rollback|status|suspend|env] "
    gmsg -v2
    gmsg -v1 " core-dump            dump data for development "
    gmsg -v1 " env get <pid>        get environmental value running process (default is guru-daemon)"
    gmsg -v1 " env set <pid>        set environmental value of running process"
    gmsg -v1 " update               update and upgrade os"
    gmsg -v1 " client-update        upgrade and reinstall guru-client"
    gmsg -v1 " client-rollback      rollback to last known working version "
    gmsg -v1 " status               system status output"
    gmsg -v1 " suspend <sub_cmd>    suspend functions '$GURU_CALL system suspend help' for more details "
    gmsg -v2 " flags                show system flag status"
    gmsg -v2 " set_flag             arise system flag"
    gmsg -v2 " rm_flag              remove system flag"
    gmsg -v1 " suspend now          suspend computer"
    gmsg -v1 " poll start|end       start or end module status polling "
}


system.suspend_help () {
    gmsg -v1 -c white "guru-client system suspend help"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL system suspend [flag|set_flag|rm_flag|install|remove]"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v2
    gmsg -v1 " flag         read flag status"
    gmsg -v1 " install      add suspend script "
    gmsg -v1 " remove       remove suspend script"
    gmsg -v2
}


system.env_help () {
    # system help printout
    gmsg -v1 -c white "guru-client system flag help"
    gmsg -v2
    gmsg -v1 "get or set environmental variable list or single variable with values of running process"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL system env [get|set] <pid|process> <variable>"
    gmsg -v2
    gmsg -v2 " env get|set <pid|process_name>  <variable_name>"
    gmsg -v2 -N -c white "example:"
    gmsg -v1 "      $GURU_CALL system env get mosquitto_sub TERM"
    gmsg -v2
    gmsg -v2 "if variable name is not given all variables will be printed out."
}


system.flag-help () {
    gmsg -v1 -c white "guru-client system suspend help"
    gmsg -v2
    gmsg -v1 "set flags that can control daemon processes (systemdless method) "
    gmsg -v0 "usage:    $GURU_CALL system flag [ls|set|rm|help]"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v2
    gmsg -v1 " <flag>         return flag status"
    gmsg -v1 " ls             list of flags with status"
    gmsg -v1 " set <flag>     set flag"
    gmsg -v1 " rm <flag>      remove flag"
    gmsg -v2 " help           this help"
    gmsg -v2
}


system.main () {
    # system command parser
    local tool="$1" ; shift
    #system_indicator_key="f$(daemon.poll_order system)"

    case "$tool" in

            status|poll|suspend|core-dump|update|upgrade|flag|rollback)
                system.$tool $@
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
                            gmsg -c yellow "get or set please"
                            GURU_VERBOSE=2
                            system.help
                    esac
                ;;

            init_system)
                system.init_system_check "$@"
                return $?
                ;;

            "--") return 0 ;;

            *)  gmsg -c yellow "unknown command $tool"
                system.help
                return 0
        esac

    return 0
}


system.status () {
    # system status
    gmsg -v 1 -t -n "${FUNCNAME[0]}: "
    if mount.online "$GURU_SYSTEM_MOUNT" ; then
        gmsg -v 1 -c green "guru on service" -k $system_indicator_key
        return 0
    else
        gmsg -v 1 -c red ".data is unmounted" -k $system_indicator_key
        return 101
    fi
}


system.flag () {
    # set flags

    local cmd=$1 ; shift
    case $cmd in
            set|rm|ls)
                    system.$cmd-flag $@
                    return $? ;;
            help)   system.flag-help
                    return 0 ;;
            "")     system.ls-flag
                    return $? ;;
            *)      system.check-flag $cmd
                    return $? ;;
        esac
}


system.check-flag () {

    if [[ -f /tmp/guru-$1.flag ]] ; then
            return 0
        else
            return 1
        fi
}


system.ls-flag () {

    gmsg -v2 -c white "system flag status:"
    local flag_list=(fast pause suspend stop running)

    local flag=
    for flag in ${flag_list[@]} ; do
            gmsg -V1 -n "$flag:"
            gmsg -v1 -n "$flag flag: "
            if system.check-flag $flag ; then
                    gmsg -c aqua "set"
                else
                    gmsg -c dark_grey "disabled"
                fi
        done

    # gmsg -v2 -c white "user flag status:"
    # flag=
    # flag_file_list=$(ls -l /tmp/guru-* | grep '.flag' | rev | cut -f1 -d ' ' | rev 2>&1 >/dev/null)
    # for flag_file in ${flag_file_list[@]} ; do
    #         # remove ".flag"
    #         flag=${flag_file%.*}
    #         # remove "/tmp/guru-"
    #         flag=${flag#*-}

    #         # remove system flags
    #         case $flag in ${flag_list[@]}) continue ;; esac

    #         gmsg -v1 -n "$flag flag: "
    #         gmsg -V1 -n "$flag:"
    #         if [[ -f /tmp/guru-$flag.flag ]] ; then
    #                 gmsg -c aqua "set"
    #             else
    #                 # this obviously never happen
    #                 gmsg -c dark_grey "disabled"
    #             fi
    #     done


}


system.set-flag () {

    [[ $1 ]] || gmsg -x 100 -c red "system.set_flag error: flag missing"
    local flag="$1"

    if [[ -f /tmp/guru-$flag.flag ]] ; then
            gmsg -t -v3 "$flag flag already set"
            return 0
        else
            gmsg -t -v1 "$flag flag set"
            touch /tmp/guru-$flag.flag
        fi

}


system.rm-flag () {

    [[ $1 ]] || gmsg -x 100 -c red "system.rm_flag error: flag missing"
    local flag="$1"

    if [[ -f /tmp/guru-$flag.flag ]] ; then
            rm -f /tmp/guru-$flag.flag && \
            gmsg -t -v1 "$flag flag disabled"
            return 0
        else
            gmsg -t -v3 "$flag flag not set"
        fi
}



system.get_env () {
    # get running process variable values by pid

    local _pid=$1
    [[ $_pid ]] || gmsg -x 127 -c yellow "pid name required "
    local _pattern=$2
    local _variable_to_find=$3

    # find variables pattern
    if [[ $_pattern ]] ; then
            local _variables=$(cat /proc/$_pid/environ \
                | tr '\0' '\n' \
                | grep $_pattern \
                || gmsg -c yellow "no v ariables")
        else
            local _variables=$(cat /proc/$_pid/environ \
                | tr '\0' '\n' \
                || gmsg -c yellow "no variables")
        fi

    if ! [[ $_variable_to_find ]] ; then
            gmsg "$_variables"
            return 0
        fi

    local _variables_found=$(cat /proc/$_pid/environ \
        | tr '\0' '\n' \
        | grep "$_pattern*" \
        | grep $_variable_to_find \
        | awk '{ print length(), $0 | "sort -n" }' \
        | cut -f2 -d " " \
        || gmsg -c yellow "variable not found")

    # single variable
    local _variable_found=$(cat /proc/$_pid/environ \
        | tr '\0' '\n' \
        | grep "$_pattern*" \
        | grep $_variable_to_find \
        | awk '{ print length(), $0 | "sort -n" }' \
        | cut -f2 -d " " \
        | head -1 \
        || gmsg -c yellow "variable not found")

    local _variable=$(echo  $_variable_found \
        | cut -f1 -d "=")

    # single value
    local _value=$(echo  $_variable_found \
        | cut -f2 -d "=")

    # printout
    gmsg -v1 -c white "found variables:"
    gmsg "$_variables_found"

    if [[ $_variable_found ]] ; then
            gmsg -v1 -c white "$_variable value is:"
            gmsg "$_value"
            return 0
        else
            gmsg -v1 -c yellow "no variable found"
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
            gmsg -c yellow "no process '$_process'"
            return 101
        fi

    # check is number
    local re='^[0-9]+$'
    if ! [[ $_pid =~ $re ]] ; then
            gmsg -c yellow "no process '$_process' or found got bad PID '$_pid'"
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
    gmsg -v2 -c white "pid: $_pid"

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

    [[ $_pid ]] || gmsg -x 111 -c yellow "no process with id $_pid"

    gmsg -v2 -c white "found: $_process $found_process"

    # pattern in variable name
    system.get_env $_pid $_pattern $_variable_to_find
}


system.client_update () {

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-client.git"
    local _banch="master" ;

    [[ "$GURU_USE_VERSION" ]] && _branch="$GURU_USE_VERSION"
    [[ "$1" ]] && _branch="$1"

    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir"
    cd "$temp_dir"

    git clone -b "$_branch" "$source" || return 100
    bash $GURU_BIN/uninstall.sh -f
    cd "$temp_dir/guru-client"
    bash install.sh "$@"
    cd
    rm -fr $temp_dir
}


system.upgrade () {
    # upgrade guru-client

    sudo apt-get update || gmsg -c red -x 100 "apt update failed"
    gmsg -v2 -c white "upgradable list: "
    gmsg -v2 -c light_blue "$(sudo apt list --upgradable)"
    sudo apt-get upgrade -y || gmsg -c red -x 101 "apt updgrade failed"
    sudo apt-get autoremove
    sudo apt-get autoclean
    sudo apt-get check || gmsg -c yellow "Warning: $? check did nod pass"
}


system.update () {

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

    local user_input=

    [[ "$1" ]] && user_input=$1

    if [[ `/sbin/init --help` =~ upstart ]] ; then # TBD: test with upstart
            init_system="upstart"

        elif [[ `systemctl` =~ -\.mount ]] ; then
            init_system="systemd"

        elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]] ; then # TBD: test with sysv"
            init_system="sysv-init"

        else
            init_system=
    fi

    [[ $init_system ]] || gmsg -x 135 -c yellow "cannot detect init system"
    [[ $user_input ]] || gmsg -V1 "$init_system"

    if [[ "$init_system" == "$user_input" ]] ; then
            gmsg -v1 -V2 -c green "ok"
            gmsg -v2 -c green "$init_system"
            return 0
        else
            gmsg -v1 -c yellow "init system did not match, got '$init_system'"
            return 100

        fi
}


system.suspend_script () {
    # launch stuff on suspend

    temp="/tmp/suspend.temp"
    gmsg -n -v2 "$system_suspend_script.. "

    [[ -d  ${system_suspend_script%/*} ]] || sudo mkdir -p ${system_suspend_script%/*}
    [[ -d  ${temp%/*} ]] || sudo mkdir -p ${temp%/*}
    [[ -f $temp ]] && rm $temp

# following lines should be without indentation
    cat >"$temp" <<EOL
#!/bin/bash
case \${1} in
  pre|suspend )
    [[ -f $system_suspend_flag ]] || touch $system_suspend_flag
    chown $USER:$USER $system_suspend_flag
    ;;
  post|resume|thaw )
    # failed - cannot run on root space
    # ckb-next -c ; ckb-next -b &

    # failed - cannot connec dbus
    # systemctl --user restart corsair.service

    # failed - cannot run on root space
    # $GURU_BIN/$GURU_CALL corsair restart

    # failed - works but then not controllable by systemctl and ckb-next should not runned as root
    # HOME=/home/casa
    # USER=casa
    # /home/casa/.gururc
    # PATH=$PATH:/home/casa/bin
    # /home/casa/bin/core.sh corsair raw_start

    # failed - works but password is requested, and does not even give permission
    # su casa <<'EOF'
    # bash
    # /home/casa/.gururc
    # PATH=$PATH:/home/casa/bin
    # /home/casa/bin/core.sh corsair raw_start
    # EOF

    # failed - works but password is requested, and does not even give permission
    # su casa <<'EOF'
    # systemctl --user restart corsair.service
    # EOF

    # suspend flag method is only one that works, but shit it is

    ;;
esac
EOL

    sudo cp $temp $system_suspend_script || return 1
    sudo chmod +x $system_suspend_script || return 2
    rm -f $temp
    gmsg -v2 -c green "ok"
    return 0
}


system.suspend () {
    # suspend control

    case "$1" in

            now )
                gmsg -v1 "suspending.."
                #system.flag set suspend
                [[ $GURU_FORCE ]] || sleep 3
                systemctl suspend
                ;;

            flag )
                gmsg -v3 -n "checking is system been suspended "
                if system.flag suspend ; then
                        gmsg -v1 -c yellow "system were suspended"
                        return 0
                    else
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
                gmsg -n -v1 "removing suspend script.. "
                sudo rm -f $system_suspend_script \
                && gmsg -v1 -c green "ok" || gmsg -c red "failed"
                ;;

            help )
                system.suspend_help
                ;;
            *)  gmsg -c yellow "unknown suspend command: $1"
                system.suspend_help
                ;;

        esac
}


system.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: system status polling started" -k $system_indicator_key

            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: system status polling ended" -k $system_indicator_key

            ;;
        status )
            system.status $@
            return $?
            ;;
        *)  system.help
            ;;
        esac

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$GURU_RC"
    system.main "$@"
    exit $?
fi
