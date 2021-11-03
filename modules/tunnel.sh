#!/bin/bash
# guru-client tunneling functions 2021

source common.sh
#source system.sh

tunnel.help () {
    # genereal help

    gmsg -v1 -c white "guru-client tunnel help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL tunnel status|ls|open|close|add|rm|start|end|install|remove] "
    gmsg -v2
    gmsg -v1 -c white  "commands:"
    gmsg -v1 " ls               list, active highlighted"
    gmsg -v1 " status           tunnel status "
    gmsg -v1 " open <service>   open known tunnel set in user.cfg"
    gmsg -v1 " close <service>  close open tunnels"
    gmsg -v2 " add              add tunnel to .ssh/config"
    gmsg -v2 " rm               remove tunnel from .ssh/config"
    gmsg -v1 " install          install requirements "
    gmsg -v1 " remove           remove installed requirements "
    gmsg -v2 " poll start|end   start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white  "example:"
    gmsg -v1 "    $GURU_CALL tunnel open wiki"
    gmsg -v2
}


# xprop -id 0x5600001

tunnel.main () {
    # command parser

    command="$1"; shift
    case "$command" in

        toggle|check|status|poll|help)
                tunnel.$command "$@"
                return $?
                ;;

        add|rm|open|close|ls|tmux)
                case $1 in
                    all)    for service in ${GURU_TUNNEL_LIST[@]} ; do
                                tunnel.$command $service
                            done ;;
                      *) tunnel.$command $@
                esac
                return $?
                ;;

        install|remove)
                tunnel.requirements "$command"
                return $?
                ;;
        *)
                tunnel.open $command $@
                return $?
                ;;

        esac
}


tunnel.status () {
    # check tunnel is reachable

    # ptrintout timestamp and function name
    gmsg -n -v1 -t "${FUNCNAME[0]}: "

    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"

    # check system is able to service
    if [[ -f /usr/bin/ssh ]] ; then
            gmsg -v1 -n -c green "available " -k $tunnel_indicator_key
        else
            gmsg -v1 -c red "not installed" -k $tunnel_indicator_key
            return 2
        fi

    # list of tunnels all verbose levels
    [[ $GURU_VERBOSE -gt 0 ]] && tunnel.ls

    # indicate user if active tunnels
    if ps -x | grep -v grep | grep "ssh -L " | grep localhost >/dev/null; then
            gmsg -v4 -c aqua "active tunnels detected" -k $tunnel_indicator_key
        fi
    return 0
}


tunnel.add () {
    # add ssh tunnel to .ssh_config

    echo TBD
    # https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/
    # ~/.ssh/config
    #   Host wiki
    #   HostName      ujo.guru
    #   User          hesus
    #   Port          2010
    #   # IdentityFile  ~/.ssh/id_rsa-cytopia@everythingcli
    #   LocalForward  5000 localhost:3306
    #   ServerAliveInterval 30
    #   ServerAliveCountMax 3

    return 0
}


tunnel.rm () {
    # remove ssh tunnel from ssh config

    echo TBD
    return 0
}


tunnel.toggle () {
    # open default tunnel list and closes

    declare -l state="/tmp/tunnel.toggle"

    if [[ -f $state ]] && tunnel.ls >/dev/null; then
            tunnel.close # &&
            rm $state
        else
            tunnel.open ${GURU_TUNNEL_DEFAULT[@]} # &&
            touch $state
        fi
    #tunnel.ls
    return 0
}


tunnel.ls () {
    # list of ssh tunnels

    local all_services=(${GURU_TUNNEL_LIST[@]})
    [[ $1 ]] && all_services=($@)
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"
    local _return=1

    # non color system get only list og active tunnels and do not set corsair stuff
    if ! [[ $DISPLAY ]] ; then
        for service in ${all_services[@]} ; do
            tunnel.get_config $service
            if ps -x | grep -v grep | grep "ssh" | grep "$to_port:" >/dev/null; then
                    gmsg  "$service"
                    _return=0
                fi
            done

        return $_return
        fi

    # check only given service
    if [[ $service ]] ; then
            tunnel.get_config $service
            if ps -x | grep -v grep | grep "ssh -L $to_port:localhost:" >/dev/null; then
                    gmsg -v2 -c aqua "$service"  -k $tunnel_indicator_key
                    return 0
                else
                    gmsg -v3 -c green "$service" -k $tunnel_indicator_key
                    return 1
                fi
        fi

    # check all tunnels
    gmsg -n -v2 "tunnels: "
    for service in ${all_services[@]} ; do
        tunnel.get_config $service
        if ps -x | grep -v grep | grep "ssh" | grep "$to_port:" >/dev/null; then
                gmsg -n -c aqua "$service " -k $tunnel_indicator_key
                _return=0
            else
                gmsg -n -c light_blue "$service "
            fi
        done
    echo

    if (( _return > 0 )) ; then
        gmsg -v3 -c green "reset" -k $tunnel_indicator_key
        return 1
    else
        return 0
    fi
}


tunnel.get_config () {
    # get tunnel configuration an populate common variables

    declare -l service_name=$1
    declare -l all_services=(${GURU_TUNNEL_LIST[@]})
    declare -l options=${GURU_TUNNEL_OPTIONS[@]}

    # exit is not in list
    if ! echo "${all_services[@]}" | grep "$service_name" >/dev/null ; then
        gmsg -c yellow "no service $service_name in user configuration"
        return 1
        fi

    # get location in array
    local service_nr=0
    for service in ${all_services[@]} ; do
            if [[ "$service" == "$service_name" ]] ; then break ; fi
            (( service_nr++ ))
        done

    local i=0
    for parameter in ${options[@]} ; do
        local value="GURU_TUNNEL_${GURU_TUNNEL_LIST[$service_nr]^^}[$i]"
        #gmsg -c pink "$value $parameter=${!value}"
        eval $parameter=${!value}
        (( i++ ))
        done
    return 0
}


tunnel.open () {
    # open local ssh tunnel

    local service_name=()

    if ! [[ $DISPLAY ]] ; then
            gmsg -v1 "Seems that session is not local, least it does not have DISPLAY variable set."
            gmsg -v2 "Therefore multible terminal windows cannot be lauched automatically."
            gmsg -v0 "Open another terminal and paste following commands to avoid tunnel to open here."
        fi

    if [[ $1 ]] ; then
            service_name=($@)
        else
            service_name=(${GURU_TUNNEL_DEFAULT[@]})
        fi

    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"
    local ssh_param="-o ClearAllForwardings=yes -o ServerAliveInterval=15"

    for _service in ${service_name[@]} ; do

            if ! tunnel.get_config $_service ; then
                gindicate error $tunnel_indicator_key
                continue
            fi

            local url="http://localhost:$to_port"
            [[ $url_end ]] && url="$url/$url_end"

            if tunnel.ls $_service ; then
                    # gmsg -v2 -n -c light_blue "$_service "
                    gmsg -v1 -c white "$_service: $url"
                    continue
                fi

            if [[ $DISPLAY ]] ; then

                    gnome-terminal  --hide-menubar --geometry 47x10 --zoom 0.5 \
                                    --title "$_service"  -- \
                                    ssh -L $to_port:localhost:$from_port \
                                    $user@$domain -p $ssh_port \
                                    $ssh_param \
                                    ; pidof gnome-terminal &

                    # echo $_output
                    # TBD not able to get pig of gnome-terminal session =/
                    # local process_id=$(sh -c "echo && ; gnome-terminal --hide-menubar --geometry 47x10 --zoom 0.5 --title $_service  -- ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port")
                    # process_id=$(sh -c 'gnome-terminal --hide-menubar --geometry 47x10 --zoom 0.5 --title kukka  -- ssh -L 8181:localhost:8181 casa@roima -p 22')
                    # process_id=$(sh -c 'echo $$; exec gnome-terminal --hide-menubar --geometry 47x10 --zoom 0.5 --title kukka  -- ssh -L 8181:localhost:8181 casa@roima -p 22')
                    #gmsg -v2 -c white -n "$_service $from_port "
                    # check if graphical environment or forced not to open window
                    # local process_id=$!
                    # gmsg -v2 -c white -n "pid: $process_id "

                    # get tunnel pid
                    # local tunnel_pid=$(ps a | \
                    #         grep -v grep | \
                    #         grep "ssh -L" | \
                    #         grep $from_port | \
                    #         head -n 1  | sed 's/^[[:space:]]*//' | \
                    #         cut -d " "  -f 1 \
                    #     )
                    # # gmsg -v2 -c white -n "tunnel_process: $tunnel_pid "

                    # try to minimaze window
                    #local window_id=$(system.get_window_id $tunnel_pid)
                    # local window_id=$(system.get_window_id $process_id)

                    # if [[ $window_ssh id ]] ; then
                    #         # gmsg -v2 -c white -n "window_id: $window_id "
                    #         xdotool windowminimize ${window_id}
                    #     fi

                else
                    # console environment
                    gmsg -v0 -c light_blue "ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port"
                    #gindicate fail $tunnel_indicator_key

                fi

            gmsg -v1 -c aqua "$_service: $url" -k $tunnel_indicator_key

        done
    return 0
}


tunnel.close () {
    # close ssh tunnel

    local data_folder="$GURU_SYSTEM_MOUNT/tunnel/$(hostname)"
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"
    local pid_list=()

    if [[ $1 ]] ; then
        local service_name=($@)
        # go trough tunnel list
        for service in ${service_name[@]} ; do
            # get config
            tunnel.get_config $service
            # get pid from ps list, must be a ssh local tunnel and contains right to_port
            pid_list=($pid_list $(ps a | \
                                grep -v grep | \
                                grep "ssh -L" | \
                                grep $from_port | \
                                head -n 1  | sed 's/^[[:space:]]*//' | \
                                cut -d " "  -f 1 \
                                ))
        done
    else
        # try to find all tunnels tunnels
        pid_list=($(ps a | \
            grep -v grep | \
            grep "ssh -L" | \
            sed 's/^[[:space:]]*//' | \
            cut -d " "  -f 1 \
            ))

    fi

    # check that pid is number
    if ! [[ ${pid_list[@]} ]] ; then
        gmsg "no tunnels"
        return 0
    fi

    # kill those tunnels
    for pid in ${pid_list[@]} ; do

            gmsg -v2 "killing pid $pid"
            if ! echo $pid | grep -E ^\-?[0-9]?\.?[0-9]+$ >/dev/null; then
                    gmsg -v2 -c yellow "tunnel '$service_name' not found "
                    return 0
                fi

            if kill -15 $pid ; then
                    gmsg -c green "$pid killed"
                    gindicate ok $tunnel_indicator_key
                else
                    kill -9 $pid || gmsg -c yellow "$pid kill failed"
                fi
        done

    if tunnel.ls >/dev/null; then
            gmsg -v2 -c yellow "active tunnels detected"
            gindicate error $tunnel_indicator_key
        fi

    return 0
}


tunnel.tmux () {
    # add new session "tunnels", open new pane to main window for all tunnel sessions

    gmsg -v2 -c blue "TBD tmux ahve A lot of vibstagels, later"
    # local session=tunnels
    # local window=${session}:0
    # local pane=${window}.0

    # if ! tmux attach -t $session ; then
    #         gnome-terminal -- tmux new -s $session &

    #         sleep 1 ; gmsg "sending C-b"
    #         tmux send-keys -t "$pane" C-b C-b
    #         sleep 0,2 : gmsg "sending d"
    #         tmux send-keys -t "$pane" d
    #     fi

    # tmux select-pane -t "$pane"
    # tmux select-window -t "$window"
    # #tmux send-keys -t "$pane" C-z 'some -new command' Enter

}


tunnel.poll () {
    # daemon poller will run this

    local _cmd="$1" ; shift
    tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: tunnel status polling started" -k $tunnel_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: tunnel status polling ended" -k $tunnel_indicator_key
            ;;
        status )
            tunnel.status $@
            ;;
        *)  tunnel.help
            ;;
        esac

}


tunnel.requirements () {
    # install and remove needed applications. input "install" or "remove"

    local action=$1
    [[ "$action" ]] || read -r -p "install or remove? :" action
    local require="ssh rsync"
    gmsg -c yellow "need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && gmsg -c yellow "guru is now ready to tunnel"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    tunnel.main "$@"
    exit 0
fi

