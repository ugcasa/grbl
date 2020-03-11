#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/lib/ssh.sh"

remote_main() {

    command="$1"
    shift
    
    case "$command" in

        check)
                check_connection "$@"
                ;;
        push|send)
                push_config_files
                ;;
        pull|get)
                pull_config_files
                ;;
        install)
                install_requirements "$@"
                ;;
        test)                
                case "$1" in 
                    1) check_connection; error=$? ;;
                    3) test_config; error=$? ;;
                    all) test_config; error=$? ;;
                    *) echo "remote.sh no test case for $1"
                esac
                return $error
                ;;
        help|*)
                printf "\nUsage:\n\t $0 [command] [arguments] \n\t $0 mount [source] [target] \n"
                printf "\nCommands:\n\n"
                printf " pull                     copy configuration files from access point server \n"
                printf " push                     copy configuration files to access point server \n"
                printf " install                  install requirements \n"   
                printf " test <case_nr>|all       run given test case \n"
                printf "\nExample:\n"
                printf "\t %s remote mount /home/%s/share /home/%s/mount/%s/\n\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
        
    esac
    return 0
}


check_connection(){
    
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


install_requirements() {
    sudo apt install sshfs
}


pull_config_files(){
    local hostname=$(hostname)
    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/$hostname/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER" 
    return $?
}


push_config_files(){
    
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


test_config(){

    #echo "guru cloud configuration storage"
    printf "configuration push.. " | tee -a "$GURU_LOG"
    push_config_files && PASSED || FAILED

    printf "configuration pull.. " | tee -a "$GURU_LOG"
    pull_config_files && PASSED || FAILED
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    source "$GURU_CFG/$GURU_USER/deco.cfg"
    source "$GURU_BIN/functions.sh"
    remote_main "$@"
    exit 0
fi

