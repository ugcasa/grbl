#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020


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
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$GURU_REMOTE_FILE_SERVER_PORT" "$USER@$GURU_REMOTE_FILE_SERVER:$source_folder" "$target_folder"
    else
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$GURU_LOCAL_FILE_SERVER_PORT" "$USER@$GURU_LOCAL_FILE_SERVER:$source_folder" "$target_folder"
    fi

    return "$?"
}


mount_guru_defaults() {
    # mount guru tool-kit defaults + backup method if sailing. TODO do better: list of key:variable pairs while/for loop
    mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" ||mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" -remote
    mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" ||mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" -remote
    mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" ||mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" -remote
    mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" ||mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" -remote
    mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" ||mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" -remote
    mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" ||mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" -remote
}


unmount_guru_defaults() {
    # unmount all TODO do better
    mount_sshfs "unmount" "$GURU_NOTES"
    mount_sshfs "unmount" "$GURU_TEMPLATES"
    mount_sshfs "unmount" "$GURU_PICTURES"
    mount_sshfs "unmount" "$GURU_AUDIO"
    mount_sshfs "unmount" "$GURU_VIDEO"
    mount_sshfs "unmount" "$GURU_MUSIC"
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    command="$1"
    shift
    
    case "$command" in

        install)
            sudo apt install sshfs
            ;;
        mount|connect)
            if [ "$1" == "all" ]; then 
                mount_guru_defaults 
            else
                mount_sshfs "$1" "$2"           
            fi
            ;;

        unmount|umount|remove)           
            [ "$1" == "all" ] && unmount_guru_defaults ||mount_sshfs "unmount" "$1"
            ;;

        ls|list)
            grep "sshfs" < /etc/mtab

            ;;
        *)
        echo "Usage: $0 [unmount|umount|ls] [source_folder_at_server|all] [target_folder_local_fs]"
    esac
    exit 0
fi

