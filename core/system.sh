#!/bin/bash
# system tools for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh

system_suspend_flag="/tmp/suspend.flag"
system_suspend_script="/lib/systemd/system-sleep/guru-client-suspend.sh"
# system_suspend_script="/etc/pm/sleep.d/system-suspend.sh" # before ubuntu 16.04

system.help () {
    # system help printout
    gmsg -v1 -c white "guru-client system help TODO "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL system [core-dump|get|set|upgrade|rollback|status|start|end|suspend] "
    gmsg -v2
    gmsg -v3 " poll start|end           start or end module status polling "
}


system.main () {
    # system command parser
    local tool="$1" ; shift
    indicator_key="f$(poll_order system)"

    case "$tool" in

            status|poll|suspend|core-dump|get|set|update|upgrade|rollback)
                system.$tool $@
                return $?
                ;;

            env)
                re='^[0-9]+$'
                if [[ $1 =~ $re ]] ; then
                        system.get_env $@
                    else
                        system.get_env_by_name $@
                    fi
                ;;

            help)
                system.help
                ;;

            *)  system.help
                ;;

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
    [[ $_pid ]] || gmsg -x 127 -c yellow  "pid name required "
    local _pattern=$2
    local _variable_to_find=$3

    # find variables pattern
    if [[ $_pattern ]] ; then
            local _variables=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep $_pattern || gmsg -c yellow "no variables")
        else
            local _variables=$(cat /proc/$_pid/environ | tr '\0' '\n' || gmsg -c yellow "no variables")
        fi

    if ! [[ $_variable_to_find ]] ; then
            gmsg -c light_blue "$_variables"
            return 0
        fi

    local _variables_found=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep "$_pattern*" | grep $_variable_to_find | awk '{ print length(), $0 | "sort -n" }' | cut -f2 -d " " || gmsg -c yellow "variable not found")

    # single variable
    local _variable_found=$(cat /proc/$_pid/environ | tr '\0' '\n' | grep "$_pattern*" | grep $_variable_to_find | awk '{ print length(), $0 | "sort -n" }' | cut -f2 -d " " | head -1 || gmsg -c yellow "variable not found")
    local _variable=$(echo  $_variable_found | cut -f1 -d "=")
    # single value
    local _value=$(echo  $_variable_found | cut -f2 -d "=")

    # printout
    gmsg -v1 -c white "found variables:"
    gmsg -v1 -c light_blue "$_variables_found"
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
    local _found_processes=$(ps auxf | grep "$_process" | grep -v grep | grep -v "system" )

    # pid where environment ir read
    local _pid=$(echo $_found_processes | head -1 | xargs | cut -f2 -d " ")

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
    gmsg -v1 -c deep_pink -n "$_pid"

    # check putput (bash return annoying is hrr)
    local re='^[0-9]+$' ; if ! [[ $_pid =~ $re ]] ; then return 102 ; fi
    local found_process="$(ps auxf | grep $_pid | grep -v grep | head -1 | xargs | rev | cut -d " " -f1-4 | rev)"
    [[ $_pid ]] || gmsg -x 111 -c red "no pid found" && gmsg -v1 " $found_process"

    # pattern in variable name
    system.get_env $_pid $_pattern $_variable_to_find
}


system.guru-client_update () {
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
    $GURU_BIN/$GURU_CALL start
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
                gmsg -v1 "setting suspend flag.. "
                touch $system_suspend_flag
                ;;

            rm_flag )
                gmsg -v1 "removing suspend flag.. "
                rm -f $system_suspend_flag
                ;;

            install )
                gmsg -v1 "adding suspend script.. "
                system.suspend_script add
                ;;

            remove )
                gmsg -v1 "removing suspend script.. "
                sudo rm -f $system_suspend_script
                ;;
            "" )
                systemctl suspend
                ;;

            *)  gmsg "unknown suspend command: $1"
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
