#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/lib/ssh.sh"

remote_main() {

    command="$1"
    shift
    
    case "$command" in

        ls|list)
                grep "sshfs" < /etc/mtab
                ;;
        mount)
                [ "$1" == "all" ] && mount_guru_defaults ||mount_sshfs "$@"                
                ;;
        unmount|umount)           
                [ "$1" == "all" ] && unmount_guru_defaults ||mount_sshfs "unmount" "$1"
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
                echo "# Test Report $0 $1 $(date)"
                case "$1" in 
                    1) test_config ;;
                    2) test_mount ;;                    
                    3) test_default_mounts ;;
                    all) test_config && test_mount ;;
                    *) echo "no test case for $1"
                esac
                ;;
        help|*)
                printf "\nUsage:\n\t $0 [command] [arguments] \n\t $0 mount [source] [target] \n"
                printf "\nCommands:\n\n"
                printf " ls                       list of mounted folders \n" 
                printf " mount [source] [target]  mount folder in file server to local folder \n"
                printf " mount all                mount primary file server default folders \n"
                printf "                          Warning! Mount point may be generic location as '~/Pictures' \n"
                printf " unmount [mount_point]    unmount [mount_point] \n"
                printf " unmount [all]            unmount all default folders \n"
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
          -p "$server_port" "$user@$server:$source_folder" "$target_folder" \
          && echo "mounted $server:$source_folder to $target_folder"
    
    return "$?"
}


mount_guru_defaults() {
    # mount guru tool-kit defaults + backup method if sailing. TODO do better: list of key:variable pairs while/for loop
    mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" || return "$?"
    mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" || return "$?"
    mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" || return "$?"
    mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" || return "$?"
    mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" || return "$?"
    mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" || return "$?"
    return 0
}


unmount_guru_defaults() {
    # unmount all TODO do better
    mount_sshfs "unmount" "$GURU_NOTES"
    mount_sshfs "unmount" "$GURU_TEMPLATES"
    mount_sshfs "unmount" "$GURU_PICTURES"
    mount_sshfs "unmount" "$GURU_AUDIO"
    mount_sshfs "unmount" "$GURU_VIDEO"
    mount_sshfs "unmount" "$GURU_MUSIC"
    return 0
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

    echo "## guru cloud configuration storage"
    printf "configuration push "
    push_config_files && echo "PASSED" || echo "FAILED"

    printf "configuration pull "
    pull_config_files && echo "PASSED" || echo "FAILED"
    return 0
}

    
test_mount() {

    echo "## single file server sshfs mount "
    mount_sshfs "/home/$GURU_USER/usr/test" "$HOME/tmp/test_mount" && cat "$HOME/tmp/test_mount/test.md" || echo "FAILED"
    sleep 2
    printf "un-mount "
    mount_sshfs unmount "$HOME/tmp/test_mount" && echo "PASSED" || echo "FAILED"
    rm -rf "$HOME/tmp/test_mount" || echo "ERROR"
    return 0
}


test_default_mounts(){

    echo "## sshfs mount file server default folders"
    mount_guru_defaults && echo "PASSED" || echo "FAILED"
    sleep 3
    printf "un-mount defaults "; unmount_guru_defaults && echo "PASSED" || echo "FAILED"
    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    remote_main "$@"
    exit 0
fi

