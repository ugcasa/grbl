#!/bin/bash
# guru-client tunneling functions 2021

source common.sh

tunnel.help () {
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
    gmsg -v1 "    $GURU_CALL tunnel "
    gmsg -v2
}


tunnel.main () {

    [[ "$GURU_INSTALL" == "server" ]] && tunnel.warning

    command="$1"; shift
    case "$command" in

        check|status|poll|help)
                tunnel.$command "$@"
                return $? ;;

        add|rm|open|close|ls|tmux)

                case $1 in
                    all)    for service in ${GURU_TUNNEL_LIST[@]} ; do
                                tunnel.$command $service
                            done ;;
                      *) tunnel.$command "$@"
                esac
                return $? ;;
        install|remove)
                tunnel.requirements "$command"
                return $? ;;
        *)
                tunnel.open $command
                return $?
        esac
}


tunnel.status () {
    # check tunnel is reachable. daemon poller will run this
    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"

    if [[ -f /usr/bin/ssh ]] ; then
            gmsg -n -c green "available " -k $tunnel_indicator_key
        else
            gmsg -n -c red "not installed" -k $tunnel_indicator_key
            return 2
        fi

    if tunnel.ls ; then
            gmsg -n -v3 -c aqua "active tunnels" -k $tunnel_indicator_key
        fi
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

tunnel.ls () {
    # list of ssh tunnels
    local all_services=${GURU_TUNNEL_LIST[@]}
    local service=
    [[ $1 ]] && service=$1
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"
    local to_ports=ps a | grep -v grep | grep "ssh -L" | cut -d " " -f13 | cut -d ":" -f1

    # check only given service
    if [[ $service ]] ; then
            tunnel.parameters $service
                if ps -x | grep -v grep | grep "ssh -L $to_port:localhost:" >/dev/null; then
                        # gmsg -v2 -c aqua "$service"
                        return 0
                    else
                        gmsg -v3 -c reset "$service" -k $tunnel_indicator_key
                        return 1
                    fi
        fi

    # check all tunnels
    local _return=1
    gmsg -n -v2 "tunnels: "
    for service in ${all_services[@]} ; do
        tunnel.parameters $service
        if ps -x | grep -v grep | grep "ssh -L $to_port:localhost:" >/dev/null; then
                gmsg -n -c aqua "$service " -k $tunnel_indicator_key
                _return=0
            else
                gmsg -n -c light_blue "$service "
            fi
        done
        echo
    (( _return != 0 )) && gmsg -v3 -c reset "reset"  -k $tunnel_indicator_key
    return $_return
}


tunnel.parameters () {
    # get tunnel configuration an populate common variables
    source $GURU_RC
    local service_name=$1
    local all_services=(${GURU_TUNNEL_LIST[@]})
    local options=${GURU_TUNNEL_OPTIONS[@]}

    # TBD get all_sevices list automatically
    # local all_services=$(set | grep "GURU_TUNNEL" | grep -v "LIST" | grep -v "OPTIONS" \
    #                          | cut  -d '=' -f 1 | cut -d '_' -f 3 )
    # all_services=(${all_services,,})

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
    local service_name="wiki" ;
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"

    if [[ $1 ]] ; then
            service_name=$1
        else
            source $GURU_RC
            gmsg -v2 -n -c white "available: "
            gmsg -c light_blue "${GURU_TUNNEL_LIST[@]}"
            read -p "input tunnel name: " service_name
        fi

    tunnel.parameters $service_name
    local url="http://localhost:$to_port"
    [[ $url_end ]] && url="$url/$url_end"


    if tunnel.ls $service ; then
            gmsg -v2 -n -c white "$service at "
            gmsg -v1 -c aqua "$url"
            return 0
        fi

    # local ssh_param="-oClearAllForwardings=yes -oServerAliveInterval=15 "


    gmsg -v2 -n -c white "$service at "
    gmsg -v1 -c aqua "$url" -k $tunnel_indicator_key

    # open session
    case $GURU_PREFERRED_TERMINAL in

            gnome-terminal)
                    if [[ $TMUX ]] ; then
                        ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port #$ssh_param
                    else
                        gnome-terminal -- ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port
                    fi
                    return 0
                    ;;
            tmux)

                    # TBD send to session "tunnel" following command
                    ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port #$ssh_param
                    return $?
                    ;;
            esac
    return 0
}


tunnel.close () {
    # ssh tunnel

    local data_folder="$GURU_SYSTEM_MOUNT/tunnel/$(hostname)"
    local tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"


    if [[ $1 ]] ; then
        local service_name=$1
        # get config
        tunnel.parameters $service_name
        # get pid from ps list, must be a ssh local tunnel and contains right to_port
        local pid=$(ps a |grep "ssh -L" | grep $from_port | grep -v grep | cut -d " "  -f 1)
    else
        # try to find a tunnel
        local pid=$(ps a | grep -v grep | grep "ssh -L" | head -1 | cut -d " "  -f 1)
        service_name="unknown"
    fi

    # check that pid is number
    if ! echo $pid | grep -E ^\-?[0-9]?\.?[0-9]+$ >/dev/null; then
            gmsg -v2 -c yellow "tunnel '$service_name' not found "
            return 2
        fi

    gmsg -v2 "killing tunnel '$service_name' localhost:$to_port pid: $pid"
    kill $pid

    # verify and indicate
    if tunnel.ls $service_name ; then
            gmsg -v2 -c green "$service_name kill verified" -k $tunnel_indicator_key
        fi

    if tunnel.ls >/dev/null; then
            gmsg -v2 -c aqua "active tunnels detected" -k $tunnel_indicator_key
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
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    [[ "$action" ]] || read -r -p "install or remove? :" action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to tunnel \n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    tunnel.main "$@"
    exit 0
fi

