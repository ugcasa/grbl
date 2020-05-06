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
    printf " pull       copy configuration files from access point server \n"
    printf " push       copy configuration files to access point server \n"
    printf " install    install requirements \n"
    printf "\nexample:"
    printf "    %s remote mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_POINT_USER" "$USER" "$GURU_ACCESS_POINT"
}


remote.warning () {
    echo "running on server installation, remote is a client tool. exiting.."
    exit 1
}


remote.check() {

    local user="$GURU_CLOUD_NEAR_USER"
    local server="$GURU_CLOUD_NEAR"                                            # assume that server is in local network
    local server_port="$GURU_CLOUD_NEAR_PORT"

    msg "$user@$server status.. "
    if ! ssh -q -p "$server_port" "$user@$server" exit ; then                  # check local server connection
        msg "${YEL}local fileserver is not reachable.${NC} trying remote."
        user="$GURU_CLOUD_FAR_USER"
        server="$GURU_CLOUD_FAR"                                               # if no connection try remote server connection
        server_port="$GURU_CLOUD_FAR_PORT"
        msg "\n$user@$server status.. "
    fi

    if ssh -q -p "$server_port" "$user@$server" exit ; then
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

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_PORT" \
        "$GURU_ACCESS_POINT_USER@$GURU_ACCESS_POINT:/home/$GURU_ACCESS_POINT_USER/usr/$GURU_HOSTNAME/$GURU_USER/" \
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

    ssh "$GURU_ACCESS_POINT_USER@$GURU_ACCESS_POINT" \
        -p "$GURU_ACCESS_POINT_PORT" \
        ls "/home/$GURU_ACCESS_POINT_USER/usr/$GURU_HOSTNAME/$GURU_USER" >/dev/null 2>&1 || \

    ssh "$GURU_ACCESS_POINT_USER@$GURU_ACCESS_POINT" \
        -p "$GURU_ACCESS_POINT_PORT" \
        mkdir -p "/home/$GURU_ACCESS_POINT_USER/usr/$GURU_HOSTNAME/$GURU_USER"

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_ACCESS_POINT_USER@$GURU_ACCESS_POINT:/home/$GURU_ACCESS_POINT_USER/usr/$GURU_HOSTNAME/$GURU_USER/"

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

