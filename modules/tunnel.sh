#!/bin/bash
# guru-client tunneling functions 2021

tunnel.help () {
    # genereal help

    gr.msg -v1 -c white "guru-client tunnel help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL tunnel status|ls|open|close|add|rm|start|end|install|remove] "
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " ls               list, active highlighted"
    gr.msg -v1 " status           tunnel status "
    gr.msg -v1 " open <service>   open known tunnel set in user config"
    gr.msg -v1 " close <service>  close open tunnels"
    gr.msg -v2 " add              add tunnel to .ssh/config"
    gr.msg -v2 " rm               remove tunnel from .ssh/config"
    gr.msg -v1 " install          install requirements "
    gr.msg -v1 " remove           remove installed requirements "
    gr.msg -v2 " poll start|end   start or end module status polling "
    gr.msg -v3 " hop              TBD hopping tunnel support"

    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL tunnel open wiki"
    gr.msg -v2
}


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


tunnel.config () {
# configure tunnel module

    source config.sh

    declare -g tunnel_indicator_key='f4'
    declare -g tunnel_rc_file="/tmp/tunnel.rc"

    # make rc out of config file and run it
    config.make_rc "$GURU_CFG/$GURU_USER/tunnel.cfg" $tunnel_rc_file
    chmod +x $tunnel_rc_file
    source $tunnel_rc_file
    rm $tunnel_rc_file
}



tunnel.status () {
# check tunnel is reachable

    # ptrintout timestamp and function name
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    # check system is able to service
    if [[ -f /usr/bin/ssh ]] ; then
            gr.msg -v1 -n -c green "available " -k $tunnel_indicator_key
        else
            gr.msg -v1 -c red "not installed" -k $tunnel_indicator_key
            return 2
        fi

    # list of tunnels all verbose levels
    [[ $GURU_VERBOSE -gt 0 ]] && tunnel.ls

    # indicate user if active tunnels
    if ps -x | grep -v grep | grep "ssh -L " | grep localhost >/dev/null; then
            gr.msg -v3 -c aqua "active tunnels" -k $tunnel_indicator_key
        else
            gr.msg -v3 -c reset "no active tunnels" -k $tunnel_indicator_key
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


tunnel.check () {
# check tunnel is active, if no input use first iten on list

    local service=${GURU_TUNNEL_LIST[0]}
    [[ $1 ]] && service=$1

    tunnel.get_config $service

    if ps -x | grep -v grep | grep "ssh -L $to_port:"  >/dev/null; then
        return 0
    else
        return 1
    fi
}


tunnel.toggle () {
# open default tunnel list and closes

    declare -l state="/tmp/tunnel.toggle"

    if [[ -f $state ]] && tunnel.check >/dev/null; then
            tunnel.close && rm $state
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
    # [[ $1 ]] && all_services=($@)
    local _return=1

    gr.msg -n -v2 "tunnels: "
    for service in ${all_services[@]} ; do
        tunnel.get_config $service
        if ps -x | grep -v grep | grep "ssh" | grep "$to_port:" >/dev/null; then
                gr.msg -n -c aqua "$service "
                _return=0
            else
                gr.msg -n -c dark_cyan "$service "
            fi
        done
    gr.msg
}


tunnel.in_list () {
# dub
    local service_name=$1

    for service_list_item in ${GURU_TUNNEL_LIST[@]} ; do
            [[ ${service_list_item} == $service_name ]] && return 0
        done
    return 1
}


tunnel.get_config () {
# get tunnel configuration an populate common variables

    local i=0
    local service_nr=0
    local value=
    local service_name=$1
    local all_services=(${GURU_TUNNEL_LIST[@]})
    local options=${GURU_TUNNEL_OPTIONS[@]}

    # exit if not in list
    if ! tunnel.in_list $service_name ; then
        gr.msg -c yellow "no service $service_name in user configuration"
        return 1
        fi

    # get location in array
    for service in ${all_services[@]} ; do
            if [[ "$service" == "$service_name" ]] ; then break ; fi
            (( service_nr++ ))
        done

    # evaluate variables
    for parameter in ${options[@]} ; do
        value="GURU_TUNNEL_${GURU_TUNNEL_LIST[$service_nr]^^}[$i]"
        gr.msg -v4 -c pink "$value $parameter=${!value}"
        eval $parameter=${!value}
        (( i++ ))
        done
    return 0
}


tunnel.open () {
# open local ssh tunnel

    local service_name=()

    if ! [[ $DISPLAY ]] ; then
            gr.msg -v1 "Seems that session is not local, least it does not have DISPLAY variable set."
            gr.msg -v2 "Therefore multible terminal windows cannot be lauched automatically."
            gr.msg -v0 "Open another terminal and paste following commands to avoid tunnel to open here."
        fi

    if [[ $1 ]] ; then
            service_name=($@)
        else
            service_name=(${GURU_TUNNEL_DEFAULT[@]})
        fi

    local ssh_param="-o ServerAliveInterval=15"

    for _service in ${service_name[@]} ; do

            if ! tunnel.get_config $_service ; then
                gr.ind error $tunnel_indicator_key
                continue
            fi

            local url="http://localhost:$to_port"
            [[ $url_end ]] && url="$url/$url_end"

            if tunnel.check $_service ; then
                    # gr.msg -v2 -n -c light_blue "$_service "
                    gr.msg -v1 -c white "$_service: $url"
                    continue
                fi

            if [[ $DISPLAY ]] ; then

                    gnome-terminal  --hide-menubar --geometry 47x10 --zoom 0.5 \
                                    --title "$_service"  -- \
                                    ssh -L $to_port:localhost:$from_port \
                                    $user@$domain -p $ssh_port \
                                    $ssh_param \
                                    ; pidof gnome-terminal &

                else
                    # console environment
                    gr.msg -v0 -c dark_cyan "ssh -L $to_port:localhost:$from_port $user@$domain -p $ssh_port"
                    #gr.ind fail $tunnel_indicator_key

                fi

            gr.msg -v1 -c aqua "$_service: $url" -k $tunnel_indicator_key

        done
    return 0
}


tunnel.close () {
# close ssh tunnel

    local data_folder="$GURU_SYSTEM_MOUNT/tunnel/$(hostname)"
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
        gr.msg -v1 "no tunnels"
        return 0
    fi

    # kill those tunnels
    for pid in ${pid_list[@]} ; do

            gr.msg -v2 "killing pid $pid"
            if ! echo $pid | grep -E ^\-?[0-9]?\.?[0-9]+$ >/dev/null; then
                    gr.msg -v2 -c yellow "tunnel '$service_name' not found "
                    return 0
                fi

            if kill -15 $pid ; then
                    gr.msg -v1 -c green "$pid killed"
                    gr.ind ok $tunnel_indicator_key
                else
                    kill -9 $pid || gr.msg -c yellow "$pid kill failed"
                fi
        done

    if tunnel.check >/dev/null; then
            gr.msg -v2 -c yellow "active tunnels detected"
            gr.ind error $tunnel_indicator_key
        fi

    return 0
}



ssh.end_remote_tunnel_sessions () {

    local _server="$GURU_USER@$GURU_ACCESS_DOMAIN"
    local _port="$GURU_ACCESS_PORT"

    [[ $1 ]] && _server=$1
    [[ $2 ]] && _port=$2

    local _ifs=$IFS ; IFS=$'\n'
    local _pid_list=($(\
        ssh $_server -p $_port -- ps -xf  \
            | grep -v grep \
            | grep '?' \
            | grep sshd \
            | grep "$GURU_USER@notty"\
            | sed -e's/  */ /g' \
            | cut -d' ' -f 2
            ))
    IFS=$_ifs

    #for item in ${_pid_list[@]} ; do
            echo ssh $_server -p $_port -- kill ${_pid_list[@]}
     #   done
}



tunnel.tmux () {
# add new session "tunnels", open new pane to main window for all tunnel sessions

    gr.msg -v2 -c blue "TBD tmux ahve A lot of vibstagels, later"
    # local session=tunnels
    # local window=${session}:0
    # local pane=${window}.0

    # if ! tmux attach -t $session ; then
    #         gnome-terminal -- tmux new -s $session &

    #         sleep 1 ; gr.msg "sending C-b"
    #         tmux send-keys -t "$pane" C-b C-b
    #         sleep 0,2 : gr.msg "sending d"
    #         tmux send-keys -t "$pane" d
    #     fi

    # tmux select-pane -t "$pane"
    # tmux select-window -t "$window"
    # #tmux send-keys -t "$pane" C-z 'some -new command' Enter

}


tunnel.poll () {
# daemon poller will run this

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: tunnel status polling started" -k $tunnel_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: tunnel status polling ended" -k $tunnel_indicator_key
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
    gr.msg -c yellow "need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && gr.msg -c white "guru is now ready to tunnel"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tunnel.config
    tunnel.main "$@"
    exit 0
fi

