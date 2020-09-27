#!/bin/bash
# sshfs mount functions for guru client

source $GURU_BIN/lib/common.sh

remote.main() {
    command="$1"; shift
    case "$command" in
              push|pull)    remote.$command"_config"                       ; return $? ;;
             check|help)    remote.$command "$@"                           ; return $? ;;
         install|remove)    remote.needed "$command"                       ; return $? ;;
                   test)    source $GURU_BIN/test.sh; remote.test "$@"     ; return $? ;;
                      *)    remote.help ;;
    esac
    return 0
}


remote.help () {
    echo "-- guru client remote help -----------------------------------------------"
    printf "usage:\t %s remote [command] [arguments] \n\t $0 remote [source] [target] \n" "$GURU_CALL"
    printf "\ncommands:\n"
    printf " pull                     copy configuration files from access point server \n"
    printf " push                     copy configuration files to access point server \n"
    printf " install                  install requirements \n"
    printf "\nexample:"
    printf "    %s remote mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
}


remote.check(){

    local server="$GURU_LOCAL_FILE_SERVER"                                              # assume that server is in local network
    local server_port="$GURU_LOCAL_FILE_SERVER_PORT"
    local user="$GURU_LOCAL_FILE_SERVER_USER"

    if ! ssh -q -p "$server_port" "$user@$server" exit; then                            # check local server connection
        server="$GURU_REMOTE_FILE_SERVER"                                               # if no connection try remote server connection
        server_port="$GURU_REMOTE_FILE_SERVER_PORT"
        user="$GURU_REMOTE_FILE_SERVER_USER"
    fi

    msg "$user@$server status.. "
    if ssh -q -p "$server_port" "$user@$server" exit; then
        msg "${GRN}ONLINE${NC}\n"
        return 0
    else
        msg "${RED}OFFLINE${NC}\n"
        return 132
    fi
}


remote.pull_config(){
    msg "pulling configs.. "
    local _error=0
    local hostname=$(hostname)
    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)); then
            SUCCESS
        else
            FAILED
        fi
    return $_error
}


remote.push_config(){
    msg "pushing configs.. "
    local _error=0
    local hostname=$(hostname)
    ssh "$GURU_USER@$GURU_ACCESS_POINT_SERVER" -p "$GURU_ACCESS_POINT_SERVER_PORT" \
         ls "/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER" >/dev/null 2>&1 || \
    ssh "$GURU_USER@$GURU_ACCESS_POINT_SERVER" -p "$GURU_ACCESS_POINT_SERVER_PORT" \
         mkdir -p "/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER"

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER/"
    _error=$?

    if ((_error<9)); then
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
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to remote\n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    remote.main "$@"
    exit 0
fi

