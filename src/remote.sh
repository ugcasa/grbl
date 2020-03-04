#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/ssh.sh"

remote_main() {

    command="$1"
    shift
    
    case "$command" in

        install)
                install_requirements "$@"
                ;;
        mount)
                if [ "$1" == "all" ]; then 
                    shift
                    mount_guru_defaults "$@"
                else
                    mount_sshfs "$@"       
                fi
                ;;
        unmount|umount)           
                [ "$1" == "all" ] && unmount_guru_defaults ||mount_sshfs "unmount" "$1"        
                ;;
        ls|list)
                grep "sshfs" < /etc/mtab
                ;;
        pull|get)
                pull_config_files
                ;;
        push|set)
                push_config_files
                ;;
        test)                
                echo "TEST"
                test_config "$@"
                test_mounts "$@"
                ;;
        help|*)
                printf "\nUsage:\n\t $0 [command] [arguments] \n\t $0 mount [source] [target] <remote flag> \n"
                printf "\nCommands:\n\n"
                printf " ls                       list all active mounts \n" 
                printf " mount [source] [target]  mount any server [folder_in_fileserver] [mount_point] \n"
                printf " mount all [remote]       mount primary file server default folders \n"
                printf "                          Warning! Mount point may be generic location as '~/Pictures' \n"
                printf "                          [remote] connect to remote file server instead or local one\n"
                printf " unmount [all]            unmount [mount_point] \n"
                printf "                          'all' unmount guru defaul locations \n"
                printf " pull [cfg|all|pro]       copy configuration files from access point server \n"
                printf "                          'cfg' get personal config from server \n"
                printf "                          'pro' project files from server \n"
                printf "                          'all' gets all configurations from server \n"
                printf " push [cfg|all|pro]        copy configuration files to access point server \n"
                printf "                          'cfg' sends current user config to %s \n" "$GURU_ACCESS_POINT_SERVER"
                printf "                          'pro' send project files to server \n"
                printf "                          'all' send all to server (not sure wha all mean for now) \n"
                printf " install                  install requirements \n"   
                printf "\nExample:\n"
                printf "\t %s remote mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
                printf "\t %s remote mount all remote \n\n" "$GURU_CALL"                
    esac
    return 0
}


install_requirements() {
    sudo apt install sshfs
}


mount_sshfs() {
    #mount [what] [where] 
    
    local source_folder="$1"
    local target_folder="$2"    
    local remote_flag="$3"  

    # be sure that mount point exist
    [ -d "$target_folder" ] ||mkdir -p "$target_folder"                

    # unmount target if mounted  
    grep "$target_folder" < /etc/mtab >/dev/null && fusermount -u "$target_folder"         

    # if first argument is "unmount" all done for now, exit
    [ "$source_folder" == "unmount" ] && return 0                                           

    # Check that directory is empty
    [ "$(ls $target_folder)" ] && return 23                                                

    # mount
    if [ "$remote_flag" ]; then 
            server="$GURU_REMOTE_FILE_SERVER"             
            server_port="$GURU_REMOTE_FILE_SERVER_PORT"
            user="GURU_REMOTE_FILE_SERVER_USER"
        else
            server="$GURU_LOCAL_FILE_SERVER"
            server_port="$GURU_LOCAL_FILE_SERVER_PORT"
            user="GURU_LOCAL_FILE_SERVER_USER"
    fi 
    #echo sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$user@$server:$source_folder" "$target_folder"
    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$USER@$server:$source_folder" "$target_folder" && echo "mounted $GURU_USER@$server:$source_folder to $target_folder"
    return "$?"
}


mount_guru_defaults() {
    # mount guru tool-kit defaults + backup method if sailing. TODO do better: list of key:variable pairs while/for loop
    mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" "$1" || return "$?"
    mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" "$1" || return "$?"
    mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" "$1" || return "$?"
    mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" "$1" || return "$?"
    mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" "$1" || return "$?"
    mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" "$1" || return "$?"
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
    rsync -ravz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$USER@$GURU_ACCESS_POINT_SERVER:/home/$USER/usr/cfg" \
        "$GURU_CFG/$GURU_USER" 
    return "$?"
}


push_config_files(){
    rsync -ravz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_CFG/$GURU_USER" \
        "$USER@$GURU_ACCESS_POINT_SERVER:/home/$USER/usr/cfg"
    return "$?"
}


test_mounts(){
    
    echo "mount "; mount_guru_defaults && echo "PASSED" || echo "FAILED"
    sleep 2
    printf "un-mount "; unmount_guru_defaults && echo "PASSED" || echo "FAILED"
    return 0
}


test_config(){
    
    printf "push "; push_config_files && echo "PASSED" || echo "FAILED"
    printf "pull "; pull_config_files && echo "PASSED" || echo "FAILED"
    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote_main "$@"
    exit 0
fi

