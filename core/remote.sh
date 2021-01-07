#!/bin/bash
# sshfs mount functions for guru-client
source common.sh

remote_indicator_key='f'"$(poll_order remote)"

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
    gmsg -v1 "    $GURU_CALL remote mount /home/$GURU_ACCESS_USERNAME/share /home/$USER/mount/$GURU_ACCESS_DOMAIN/"
    gmsg -v2
}


remote.main () {

    [[ "$GURU_INSTALL" == "server" ]] && remote.warning
    remote_indicator_key='f'"$(poll_order remote)"

    command="$1"; shift
    case "$command" in
              push|pull)    remote.$command"_config"    ; return $? ;;
      check|status|poll)    remote.$command "$@"        ; return $? ;;
         install|remove)    remote.install "$command"    ; return $? ;;
                      *)    remote.help ;;
        esac
}


remote.status () {
    # check remote is reachable. daemon poller will run this
    if remote.online ; then
            gmsg -v 1 -t -c green "${FUNCNAME[0]}: local accesspoint available" -k $remote_indicator_key
            return 0
        elif remote.online "$GURU_ACCESS_DOMAIN" "$GURU_ACCESS_PORT" ; then
            gmsg -v 1 -t -c yellow "${FUNCNAME[0]}: remote accesspoint available" -k $remote_indicator_key
            return 0
        else
            gmsg -v 1 -t -c red "${FUNCNAME[0]}: accesspoint offline" -k $remote_indicator_key
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


remote.pull_config () {
    gmsg -v1 -n -V2 "pulling configs.. "
    gmsg -v2 -n "pulling configs from $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
    local _error=0

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)) ; then
            gmsg -c green "ok"
            return 0
        else
            gmsg -c red "failed"
            return $_error
        fi
}


remote.push_config () {
    gmsg -v1 -n -V2 "pushing configs.. "
    gmsg -v2 -n "pushing configs to $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
    local _error=0

    ssh "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN" \
        -p "$GURU_ACCESS_PORT" \
        ls "/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER" >/dev/null 2>&1 || \

    ssh "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN" \
        -p "$GURU_ACCESS_PORT" \
        mkdir -p "/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER"

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/"

    _error=$?
    if ((_error<9)) ; then
            gmsg -c green "ok"
            return 0
        else
            gmsg -c red "failed"
            return $_error
        fi
}


remote.poll () {

    local _cmd="$1" ; shift

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
    #source "$GURU_RC"
    remote.main "$@"
    exit 0
fi

