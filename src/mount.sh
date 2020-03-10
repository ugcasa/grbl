#!/bin/bash
# mount tools for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/counter.sh"

mount_main() {

    help() {
        printf "\nUsage:\n\t $0 [command] [arguments] \n\t $0 mount [source] [target] \n"
        printf "\nCommands:\n\n"
        printf " ls                       list of mounted folders \n" 
        printf " mount [source] [target]  mount folder in file server to local folder \n"
        printf " mount all                mount primary file server default folders \n"
        printf "                          Warning! Mount point may be generic location as '~/Pictures' \n"
        printf " unmount [mount_point]    unmount [mount_point] \n"
        printf " unmount [all]            unmount all default folders \n"
        printf " test <case_nr>|all       run given test case \n"
        printf "\nExample:\n"
        printf "\t %s mount /home/%s/share /home/%s/mount/%s/\n\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
        
        echo 
    }
    
    argument="$1"; shift
    
    case "$argument" in
    
        ls|list)
            grep "sshfs" < /etc/mtab
            ;;

        try|try-mount)
            try-mount "$@"
            ;;

        mount)
            mount_sshfs "$1" "$2"               
            ;;

        unmount)           
            mount_sshfs "unmount" "$1" || sudo fusermount -u "$1"
            ;;


        all|defaults|def) 
            
            case "$GURU_CMD" in             # get gurus first argument
                mount)              
                    mount_guru_defaults
                    return "$?"
                    ;;      
                unmount) 
                    unmount_guru_defaults 
                    return "$?"
                    ;;
                *) help
            esac    
            ;;  
    
        test)                
            case "$1" in 
                1) test_mount ;;                    
                2) test_default_mounts ;;
                all) 
                     test_mount 
                     test_default_mounts 
                     ;;
                *) 
                    echo "no test case for $1"
            esac
            ;;

        help )
            help "$@"
            ;;
        *)
            case "$GURU_CMD" in             

                    mount)
                        mount_sshfs "$argument" "$1"               
                        ;;
                    unmount)           
                        mount_sshfs "unmount" "$argument" || sudo fusermount -u "$1"                       
                        ;;
                    *) help
            esac
    esac
}


mount_sshfs() {
    #mount_sshfs remote_foder mount_point, servers are already known
    
    local source_folder="$1"
    local target_folder="$2"    

    [ -d "$target_folder" ] ||mkdir -p "$target_folder"                                 # be sure that mount point exist
    grep "$target_folder" < /etc/mtab >/dev/null && fusermount -u "$target_folder"      # unmount target if mounted  
    [ "$source_folder" == "unmount" ] && return 0                                       # if first argument is "unmount" all done for now, exit
    [ "$(ls $target_folder)" ] && return 23                                             # Check that directory is empty

    local server="$GURU_LOCAL_FILE_SERVER"                                              # assume that server is in local network
    local server_port="$GURU_LOCAL_FILE_SERVER_PORT"
    local user="$GURU_LOCAL_FILE_SERVER_USER"

    if ! ssh -q -p "$server_port" "$user@$server" exit; then                            # check local server connection 
        server="$GURU_REMOTE_FILE_SERVER"                                               # if no connection try remote server connection
        server_port="$GURU_REMOTE_FILE_SERVER_PORT"
        user="$GURU_REMOTE_FILE_SERVER_USER"
    fi

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
          -p "$server_port" "$user@$server:$source_folder" "$target_folder"
    return $?
          #&& echo "mounted $server:$source_folder to $target_folder" || error="$?"    
}


mount_guru_defaults() {
    # mount guru tool-kit defaults + backup method if sailing. TODO do better: list of key:variable pairs while/for loop
    local error=""
    mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" || error=100
    mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" || error=100
    mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" || error=100
    mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" || error=100
    mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" || error=100
    mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" || error=100
    return $error
}


unmount_guru_defaults() {
    # unmount all TODO do better
    local error=""
    mount_sshfs "unmount" "$GURU_NOTES" || error=100
    mount_sshfs "unmount" "$GURU_TEMPLATES" || error=100
    mount_sshfs "unmount" "$GURU_PICTURES" || error=100
    mount_sshfs "unmount" "$GURU_AUDIO" || error=100
    mount_sshfs "unmount" "$GURU_VIDEO" || error=100
    mount_sshfs "unmount" "$GURU_MUSIC" || error=100
    return $error
}


test_mount() {

    printf "file server sshfs mount.. " | tee -a "$GURU_LOG"
    mount_sshfs "/home/$GURU_USER/usr/test" "$HOME/tmp/test_mount" && PASSED || FAILED
    sleep 2
    printf "testing un-mount.. " | tee -a "$GURU_LOG"
    mount_sshfs unmount "$HOME/tmp/test_mount" && PASSED || FAILED
    rm -rf "$HOME/tmp/test_mount" || ERROR
    return 0
}


test_default_mounts(){

    printf "testing sshfs file server default folder mount.. " | tee -a "$GURU_LOG"
    mount_guru_defaults && PASSED || FAILED
    sleep 3
    printf "un-mount defaults.. " | tee -a "$GURU_LOG"
    unmount_guru_defaults && PASSED || FAILED
    return 0
}




if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    source "$HOME/.gururc"
    source "$GURU_CFG/$GURU_USER/deco.cfg"
    source "$GURU_BIN/functions.sh"
    mount_main "$@"
    exit "$?"
fi


