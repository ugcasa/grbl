#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/lib/ssh.sh"

remote_main() {

    command="$1"
    shift
    
    case "$command" in

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
                    1) test_config; error=$? ;;
                    all) test_config; error=$? ;;
                    *) echo "no test case for $1"
                esac
                return "$error"
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


install_requirements() {
    sudo apt install sshfs
}


pull_config_files(){
    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/cfg/" \
        "$GURU_CFG/$GURU_USER" 
    return "$?"
}


push_config_files(){
    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_ACCESS_POINT_SERVER_USER/usr/cfg/"
    return "$?"
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

