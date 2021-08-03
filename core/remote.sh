#!/bin/bash
# sshfs mount functions for guru-client
source common.sh

remote_indicator_key='f'"$(daemon.poll_order remote)"

remote.help () {
    gmsg -v1 -c white "guru-client remote help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL remote [push|pull|check|help|status|start|end|install|remove] "
    gmsg -v2
    gmsg -v1 -c white  "commands:"
    gmsg -v1 " check            check that connection to accesspoint server is available "
    gmsg -v1 " add_key          add key pair with $GURU_ACCESS_DOMAIN and $(hostname) "
    gmsg -v1 " pull             copy configuration files from access point server "
    gmsg -v1 " push             copy configuration files to access point server "
    gmsg -v1 " install          install requirements "
    gmsg -v3 " poll start|end   start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white  "example:"
    gmsg -v1 "    $GURU_CALL remote "
    gmsg -v2
}


remote.main () {

    [[ "$GURU_INSTALL" == "server" ]] && remote.warning

    command="$1"; shift
    case "$command" in
      check|status|poll)    remote.$command "$@"        ; return $? ;;
         install|remove)    remote.install "$command"    ; return $? ;;
                      *)    remote.help ;;
        esac
}


remote.status () {
    # check remote is reachable. daemon poller will run this
    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    remote_indicator_key='f'"$(daemon.poll_order remote)"
    if remote.online ; then
            gmsg -v1 -c green "accesspoint available" -k $remote_indicator_key
            return 0
        elif remote.online "$GURU_ACCESS_DOMAIN" "$GURU_ACCESS_PORT" ; then
            gmsg -v1 -c green "remote accesspoint available" -k $remote_indicator_key
            return 0
        else
            gmsg -v1 -c red "accesspoint offline" -k $remote_indicator_key
            return 101
        fi
}

remote.warning () {
    echo "running on server installation, remote is a client tool. exiting.."
    exit 1
}


remote.online () {

    local _user="$GURU_ACCESS_USERNAME"
    local _server="$GURU_ACCESS_LAN_IP" ; [[ "$1" ]] && _server="$1" ; shift
    local _server_port="$GURU_ACCESS_LAN_PORT" ; [[ "$1" ]] && _server_port="$1" ; shift

    if ssh -o ConnectTimeout=3 -q -p "$_server_port" "$_user@$_server" exit ; then
        return 0
    else
        return 132
    fi
}


remote.poll () {

    local _cmd="$1" ; shift
    remote_indicator_key='f'"$(daemon.poll_order remote)"

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: remote status polling started" -k $remote_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: remote status polling ended" -k $remote_indicator_key
            ;;
        status )
            remote.status $@
            ;;
        *)  remote.help
            ;;
        esac

}


remote.install () {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    [ "$action" ] || read -r -p "install or remove? :" action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to remote \n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote.main "$@"
    exit 0
fi

