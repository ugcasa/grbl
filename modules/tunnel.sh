#!/bin/bash
# sshfs mount functions for guru-client
source common.sh

tunnel.help () {
    gmsg -v1 -c white "guru-client tunnel help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL tunnel [push|pull|check|help|status|start|end|install|remove] "
    gmsg -v2
    gmsg -v1 -c white  "commands:"
    gmsg -v1 " status            check that accesspoint server is available "
    gmsg -v1 " install          install requirements "
    gmsg -v3 " poll start|end   start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white  "example:"
    gmsg -v1 "    $GURU_CALL tunnel "
    gmsg -v2
}


tunnel.main () {

    [[ "$GURU_INSTALL" == "server" ]] && tunnel.warning

    command="$1"; shift
    case "$command" in

        check|status|online|poll)
                tunnel.$command "$@"
                return $? ;;

        add|rm|open|close|ls)
                tunnel.$command "$@"
                return $? ;;


        install|remove)
                tunnel.requirements "$command"
                return $? ;;
        *)
                tunnel.help
        esac
}


tunnel.status () {
    # check tunnel is reachable. daemon poller will run this
    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    tunnel_indicator_key='f'"$(daemon.poll_order tunnel)"
    if tunnel.online ; then
            gmsg -v1 -c green "accesspoint available" -k $tunnel_indicator_key
            return 0
        elif tunnel.online "$GURU_ACCESS_DOMAIN" "$GURU_ACCESS_PORT" ; then
            gmsg -v1 -c green "tunnel accesspoint available" -k $tunnel_indicator_key
            return 0
        else
            gmsg -v1 -c red "accesspoint offline" -k $tunnel_indicator_key
            return 101
        fi
}

tunnel.warning () {
    echo "running on server installation, tunnel is a client tool. exiting.."
    exit 1
}


tunnel.online () {

    local _user="$GURU_ACCESS_USERNAME"
    local _server="$GURU_ACCESS_LAN_IP" ; [[ "$1" ]] && _server="$1" ; shift
    local _server_port="$GURU_ACCESS_LAN_PORT" ; [[ "$1" ]] && _server_port="$1" ; shift

    if ssh -o ConnectTimeout=3 -q -p "$_server_port" "$_user@$_server" exit ; then
        return 0
    else
        return 132
    fi
}


tunnel.add () {
    # add ssh tunnel to .ssh_config
    echo TBD
    return 0
}


tunnel.rm () {
    # remove ssh tunnel from ssh config
    echo TBD
    return 0
}

tunnel.ls () {
    # list of ssh tunnels

    # TBD active tunnel list
    source $GURU_RC
    gmsg -n -V2 "configured tunnels: "
    gmsg -c light_blue "${GURU_TUNNEL_LIST[@]}"

    return 0
}

tunnel.parameters () {

    source $GURU_RC

    local service_name="wiki" ; [[ $1 ]] && service_name=$1
    local all_services=(${GURU_TUNNEL_LIST[@]})
    local options=${GURU_TUNNEL_OPTIONS[@]}
    local i=0

    # TBD check is service configured
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

    i=0
    for parameter in ${options[@]} ; do
        local value="GURU_TUNNEL_${GURU_TUNNEL_LIST[$service_nr]^^}[$i]"
        gmsg -c pink "$value $parameter=${!value}"
        eval $parameter=${!value}
        (( i++ ))
        done
    return 0
}



tunnel.open () {
    # ssh tunnel

    local service_name="wiki" ;
    if [[ $1 ]] ; then
            service_name=$1
        else
            source $GURU_RC
            gmsg -n -V2 "configured tunnels: "
            gmsg -c light_blue "${GURU_TUNNEL_LIST[@]}"
            read -p "input tunnel name: " service_name
        fi

    tunnel.parameters $service_name

    local url="localhost:$to_port"
    [[ $url_end ]] && url="$url/$url_end"

    gmsg "$GURU_PREFERRED_BROWSER $url"
    #gnome-terminal --
    ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port

}


tunnel.close () {
    # ssh tunnel

    if [[ $1 ]] ; then
        local service_name=$1
        # get config
        tunnel.parameters $service_name
        # get pid from ps list, must be a ssh local tunnel and contains right to_port
        local pid=$(ps a |grep "ssh -L" | grep $from_port | grep -v grep | cut -d " "  -f 1)
    else
        # try to find a tunnel
        local pid=$(ps a | grep -v grep | grep "ssh -L" | head -1 | cut -d " "  -f 1)
        service_name=unknown
    fi

    # check that pid is number
    if ! echo $pid | grep -E ^\-?[0-9]?\.?[0-9]+$ >/dev/null; then
            gmsg -c yellow "tunnel '$service_name' not found "
            return 2
        fi

    gmsg "killing tunnel '$service_name' localhost:$to_port pid: $pid"
    kill $pid
    return $?
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
    tunnel.main "$@"
    exit 0
fi

