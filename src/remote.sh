#!/bin/bash
# sshfs mount functions for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/lib/ssh.sh"

remote_main() {

    command="$1"
    shift
    
    case "$command" in

        install)
                install_requirements "$@"
                ;;

        mount)
                if [ "$1" == "all" ]; then 
                    mount_guru_defaults 
                else
                    mount_sshfs "$1" "$2"           
                fi
                ;;

        unmount|umount)           
                [ "$1" == "all" ] && unmount_guru_defaults ||mount_sshfs "unmount" "$1"
                ;;

        ls|list)
                grep "sshfs" < /etc/mtab
                ;;

        pull|get)
                remote_pull "$@"
                ;;

        push|set)
                remote_push "$@"
                ;;

        help|*)
                printf "\nUsage:\n\t $0 [command] [arguments]\n\t $0 mount [source] [target]\n"
                printf "\nCommands:\n\n"
                printf " ls                     list all active mounts\n" 
                printf " mount [all]            mount remote filesystem [folder_in_fileserver] [mount_point] \n"
                printf "                        [all] mount guru defaults \n\t\t\tWarning! Mount point may be generic location as '~/Pictures'  \n"
                printf " unmount [all]          unmount [mount_point]\n"
                printf "                        [all] unmount guru defaul locations\n"
                printf " pull [variable]        [cfg|config] get personal config from server and replace guru \n\t\t\t'./config/guru/%s/userrc' file \n" "$GURU_USER"
                printf "                        [all] gets all from server (not sure wha all mean for now)\n"
                printf " push [variable]        [cfg|config] sends current user config to %s \n" "$GURU_ACCESS_POINT_SERVER"
                printf "                        [all] send all to server (not sure wha all mean for now)\n"
                printf " install                install requirements\n"   
                printf "\nExample:\n\t %s remote mount /home/%s/share /home/%s/mount/%s/ \n\n"\
                       "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER_USER" "$USER" "$GURU_ACCESS_POINT_SERVER"
    esac

    return 0
}

remote_push(){
    
    case $1 in
        
        all)
            push_guru_config_file
            #+ other
            ;;
        
        config|cfg)
            push_guru_config_file
            ;;
        *)
            echo "guru remote push [config|all]"
    esac            

}

remote_pull() {

    case $1 in
        
        all)
            pull_guru_config_file
            #+ other
            ;;
        
        config|cfg)
            pull_guru_config_file
            ;;
        *)
            echo "guru remote pull [config|all]"
    esac   
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
        else
            server="$GURU_LOCAL_FILE_SERVER"
            server_port="$GURU_LOCAL_FILE_SERVER_PORT"
    fi 

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$GURU_USER@$server:$source_folder" "$target_folder"

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


pull_guru_config_file(){
    rsync -rvz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_USER/usr/cfg/$GURU_USER.userrc.sh" \
        "$GURU_CFG/$GURU_USER/userrc" 
}


push_guru_config_file(){
    rsync -rvz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" \
        "$GURU_CFG/$GURU_USER/userrc" \
        "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_USER/usr/cfg/$GURU_USER.userrc.sh"
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote_main "$@"
    exit 0
fi

