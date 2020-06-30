#!/bin/bash
# sshfs mount functions for guru tool-kit
source $GURU_BIN/lib/common.sh

remote.main() {
    [[ "$GURU_INSTALL" == "server" ]] && remote.warning

    command="$1"; shift
    case "$command" in
              push|pull)    remote.$command"_config"    ; return $? ;;
             check|help)    remote.$command "$@"        ; return $? ;;
         install|remove)    remote.needed "$command"    ; return $? ;;
                      *)    remote.help ;;
        esac
}


remote.help () {
    echo "-- guru tool-kit remote help -----------------------------------------------"
    printf "usage:\t %s remote [command] [arguments] \n\t $0 remote [source] [target] \n" "$GURU_CALL"
    printf "\ncommands:\n"
    printf " check      check that connection to accesspoint server is available \n"
    printf " add_key    add key pair with %s and \n" "$(hostname)" "$GURU_ACCESS_DOMAIN"
    printf " pull       copy configuration files from access point server \n"
    printf " push       copy configuration files to access point server \n"
    printf " install    install requirements \n"
    printf "\nexample:"
    printf "    %s remote mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_USERNAME" "$USER" "$GURU_ACCESS_DOMAIN"
}


remote.warning () {
    echo "running on server installation, remote is a client tool. exiting.."
    exit 1
}


remote.online() {

    local _user="$GURU_ACCESS_USERNAME"
    local _server="$GURU_ACCESS_LAN_IP" ; [[ "$1" ]] && _server="$1" ; shift
    local _server_port="$GURU_ACCESS_LAN_PORT" ; [[ "$1" ]] && _server_port="$1" ; shift

    if ssh -q -p "$_server_port" "$_user@$_server" exit ; then
        gmsg -v 1 "$(ONLINE "$_server")"
        return 0
    else
        gmsg -v 1  $(OFFLINE "$_server")
        return 132
    fi
}


remote.check() {

    local _user="$GURU_ACCESS_USERNAME"
    local _server="$GURU_ACCESS_LAN_IP"                                            # assume that _server is in local network
    local _server_port="$GURU_ACCESS_LAN_PORT"

    msg "$_user@$_server status.. "
    if ! ssh -q -p "$_server_port" "$_user@$_server" exit ; then                  # check local _server connection
        msg "${YEL}local file_server is not reachable.${NC} trying remote."
        _server="$GURU_ACCESS_DOMAIN"                                               # if no connection try remote _server connection
        _server_port="$GURU_ACCESS_PORT"
        msg "\n$_user@$_server status.. "
    fi

    if ssh -q -p "$_server_port" "$_user@$_server" exit ; then
        ONLINE
        return 0
    else
        OFFLINE
        return 132
    fi
}


remote.pull_config() {
    msg "pulling configs.. "
    local _error=0

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)) ; then
            SUCCESS
        else
            FAILED
        fi
    return $_error
}


remote.push_config() {
    msg "pushing configs.. "
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
            SUCCESS
        else
            FAILED
        fi
    return $_error
}


remote.needed() {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    [ "$action" ] || read -r -p "install or remove? :" action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to remote \n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    remote.main "$@"
    exit 0
fi

