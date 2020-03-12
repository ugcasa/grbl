#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/lib/ssh.sh"

remote.main() {

    command="$1"
    shift
    
    case "$command" in

        check)
                remote.check "$@"
                ;;
        push|send)
                remote.push_config
                ;;
        pull|get)
                remote.pull_config
                ;;
        install)
                remote.install "$@"
                ;;
        test)                
                case "$1" in 
                    1) remote.check ;;
                    3) remote.test_config ;;
                    all) remote.test_config ;;
                    *) echo "remote.sh no test case for $1"
                esac
                
                ;;
        help|*)
                echo "-- guru tool-kit remote help -----------------------------------------------"
                printf "Usage:\t $0 [command] [arguments] \n\t $0 remote [source] [target] \n"
                printf "\ncommands:\n"
                printf " pull                     copy configuration files from access point server \n"
                printf " push                     copy configuration files to access point server \n"
                printf " install                  install requirements \n"   
                printf " test <case_nr>|all       run given test case \n"
                printf "\nExample:"
                printf "    %s remote mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
    esac
    return 0
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

    printf "testing connection to $user@$server.. " | tee -a "$GURU_LOG"

    if ssh -q -p "$server_port" "$user@$server" exit; then        
        PASSED 
        return 0
    else
        FAILED
        return 132
    fi
}


remote.install() {
    sudo apt install sshfs
}


remote.pull_config(){
    local hostname=$(hostname)
    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER" 
    return $?
}


remote.push_config(){
    
    local hostname=$(hostname)

    ssh "$GURU_USER@$GURU_ACCESS_POINT_SERVER" -p "$GURU_ACCESS_POINT_SERVER_PORT" \
         ls "/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER" >/dev/null 2>&1 || \
    ssh "$GURU_USER@$GURU_ACCESS_POINT_SERVER" -p "$GURU_ACCESS_POINT_SERVER_PORT" \
         mkdir -p "/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER"

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER/"
    return $?
}


remote.test_config(){

    #echo "guru cloud configuration storage"
    printf "configuration push.. " | tee -a "$GURU_LOG"
    remote.push_config && PASSED || FAILED

    printf "configuration pull.. " | tee -a "$GURU_LOG"
    remote.pull_config && PASSED || FAILED
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    source "$GURU_CFG/$GURU_USER/deco.cfg"
    source "$GURU_BIN/functions.sh"
    remote.main "$@"
    exit 0
fi

