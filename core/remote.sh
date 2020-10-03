#!/bin/bash
# sshfs mount functions for guru-client
source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh

remote.main() {
    [[ "$GURU_INSTALL" == "server" ]] && remote.warning
    indicator_key='F'"$(poll_order remote)"
    source $GURU_BIN/corsair.sh
    command="$1"; shift
    case "$command" in
              push|pull)    remote.$command"_config"    ; return $? ;;
             check|help)    remote.$command "$@"        ; return $? ;;
       status|start|end)    remote.$command             ; return $? ;;
         install|remove)    remote.needed "$command"    ; return $? ;;
                      *)    remote.help ;;
        esac
}


remote.end () {                        # return normal, assuming that while is normal
    gmsg -v 1 -t "${FUNCNAME[0]}"
    corsair.write $indicator_key white
}


remote.start () {                      # set leds  F1 -> F4 off
    gmsg -v 1 -t "${FUNCNAME[0]}"
    corsair.write $indicator_key off
}


remote.status () {

    # check remote is reachable. daemon poller will run this
    if remote.online ; then
            gmsg -v 1 -t -c green "${FUNCNAME[0]}: local accesspoint connection"
            corsair.write $indicator_key green
            return 0
        elif remote.online "$GURU_ACCESS_DOMAIN" "$GURU_ACCESS_PORT" ; then
            gmsg -v 1 -t -c yellow "${FUNCNAME[0]}: remote accesspoint connection"
            corsair.write $indicator_key yellow
            return 0
        else
            gmsg -v 1 -t -c red "${FUNCNAME[0]}: accesspoint offline"
            corsair.write $indicator_key red
            return 101
        fi
}


remote.help () {
    gmsg -v1 -c white "guru-client remote help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL remote [push|pull|check|help|status|start|end|install|remove] "
    gmsg -v2
    gmsg -v1 -c white  "commands:"
    gmsg -v1 " check      check that connection to accesspoint server is available "
    gmsg -v1 " add_key    add key pair with $GURU_ACCESS_DOMAIN and $(hostname) "
    gmsg -v1 " pull       copy configuration files from access point server "
    gmsg -v1 " push       copy configuration files to access point server "
    gmsg -v1 " install    install requirements "
    gmsg -v2
    gmsg -v1 -c white  "example:"
    gmsg -v1 "    $GURU_CALL remote mount /home/$GURU_ACCESS_USERNAME/share /home/$USER/mount/$GURU_ACCESS_DOMAIN/"
    gmsg -v2
}


remote.warning () {
    echo "running on server installation, remote is a client tool. exiting.."
    exit 1
}


remote.online() {

    local _user="$GURU_ACCESS_USERNAME"
    local _server="$GURU_ACCESS_LAN_IP" ; [[ "$1" ]] && _server="$1" ; shift
    local _server_port="$GURU_ACCESS_LAN_PORT" ; [[ "$1" ]] && _server_port="$1" ; shift

    if ssh -o ConnectTimeout=3 -q -p "$_server_port" "$_user@$_server" exit ; then
        gmsg -v1 -t -c green "${FUNCNAME[0]} $_server"
        return 0
    else
        gmsg -v0 -t -c red "${FUNCNAME[0]} $_server offline"
        return 132
    fi
}


remote.check() {
    # same shit than onlin but silent (shortcut)
    remote.online $@ >/dev/null
    return $?
}


remote.pull_config() {
    msg "pulling configs.. "
    local _error=0

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)) ; then
            $SUCCESS
        else
            $FAILED
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
    #source "$HOME/.gururc2"
    remote.main "$@"
    exit 0
fi

