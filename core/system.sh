#!/bin/bash
# system tools for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh

system_suspend_flag="/tmp/suspend.flag"
system_suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh"
# system_suspend_script="/etc/pm/sleep.d/system-suspend.sh" # before ubuntu 16.04


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
    gmsg -v1 " set_flag     set suspend flag"
    gmsg -v1 " rm_flag      remove suspend flag"
    gmsg -v1 " install      add suspend script "
    gmsg -v1 " remove       remove suspend script"
    gmsg -v2
}


system.env_help () {
    # system help printout
    gmsg -v1 -c white "guru-client system env help"
    gmsg -v2
    gmsg -v0 "get or set environmental variable list or single variable with values of running process"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL system env [get|set] <pid|process> <variable>"
    gmsg -v2
    gmsg -v2 " env get|set <pid|process_name>  <variable_name>"
    gmsg -v2 -N -c white "example:"
    gmsg -v1 "      $GURU_CALL system env get mosquitto_sub TERM"
    gmsg -v2
    gmsg -v2 "if variable name is not given all variables will be printed out."
}


system.main () {
    # system command parser
    local tool="$1" ; shift
    indicator_key="f$(poll_order system)"

    case "$tool" in

            status|poll|suspend|core-dump|update|upgrade|rollback)
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

            *)  system.help
        esac

    return 0
}


system.status () {
    # system status
    if mount.online "$GURU_SYSTEM_MOUNT" ; then
        gmsg -v 1 -t -c green "${FUNCNAME[0]}: guru on service" -k $indicator_key
        return 0
    else
        gmsg -v 1 -t -c red "${FUNCNAME[0]}: .data is unmounted" -k $indicator_key
        return 101
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
    bash $GURU_BIN/uninstall.sh
    cd "$temp_dir/guru-client"
    bash install.sh "$@"
    cd
    rm -fr $temp_dir
}


system.upgrade () {
    # upgrade guru-client
    sudo apt-get update || gmsg -c red -x 100 "apt update failed"
    gmsg -v2 -c white "upgradable list: "
    gmsg -v2 -c light_blue "$(sudo apt list --upgradable)"
    sudo apt-get upgrade -y || gmsg -c red -x 101 "apt updgrade failed"
    sudo apt-get autoremove
    sudo apt-get autoclean
    sudo apt-get check || gmsg -c yellow "Warning: $? check did nod pass"
}


system.update () {
    system.upgrade
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


system.suspend_script () {
    temp="/tmp/suspend.temp"
    gmsg -v1 -V2 -n "setting suspend script.. "
    gmsg -v2 -n "setting suspend script $system_suspend_script.. "

    if [[ -d  ${system_suspend_script%/*} ]] ; then
        sudo mkdir -p ${system_suspend_script%/*} \
        || gmsg -x 100 "no permission to create folder ${system_suspend_script%/*}"
    fi

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
    $GURU_BIN/$GURU_CALL corsair start
    ;;
esac
EOL

    if ! sudo cp $temp $system_suspend_script ; then
            gmsg -c red "script copy failed"
            return 101
        fi

    sudo chmod +x $system_suspend_script
    rm -f $temp
    gmsg -v1 -c green "ok"
    return 0
}


system.suspend () {
    # suspend control
    case $1 in

            flag )
                gmsg -v1 -n "checking system suspend flag status: "
                if [[ -f  $system_suspend_flag ]] ; then
                        gmsg -c yellow "system were suspended"
                        return 0
                    else
                        gmsg -c dark_grey "system were not suspended"
                        return 1
                    fi
                ;;

            set_flag )
                gmsg -n -v1 "setting suspend flag.. "
                touch $system_suspend_flag \
                && gmsg -v1 -c green "ok" || gmsg -c red "failed"
                ;;

            rm_flag )
                gmsg -n -v1 "removing suspend flag.. "
                rm -f $system_suspend_flag \
                && gmsg -v1 -c green "ok" || gmsg -c red "failed"
                ;;

            install )
                system.suspend_script add
                ;;

            remove )
                gmsg -n -v1 "removing suspend script.. "
                sudo rm -f $system_suspend_script \
                && gmsg -v1 -c green "ok" || gmsg -c red "failed"
                ;;
            "" )
                gmsg "suspending.. " -q "/status/suspended"
                [[ $GURU_FORCE ]] || sleep 3
                systemctl suspend
                ;;

            *)  gmsg -c yellow  "unknown suspend command: $1"
                ;;

        esac
}


system.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: system status polling started" -k $indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: system status polling ended" -k $indicator_key
            ;;
        status )
            system.status $@
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
