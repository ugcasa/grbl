#!/bin/bash
# mount tools for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/counter.sh"

mount_main() {

    help() {
        printf "\nUsage:\n\t $0 [command] [arguments] \n\t $0 mount [source] [target] \n"
        printf "\nCommands:\n\n"
        printf " ls                       list of mounted folders \n" 
        printf " check [target]           check that mount point is mounted \n"
        printf " check-system             check that guru system folders are mounted \n"
        printf " mount [source] [target]  mount folder in file server to local folder \n"
        printf " mount all                mount primary file server default folders \n"
        printf "                          Warning! Mount point may be generic location as '~/Pictures' \n"
        printf " unmount [mount_point]    unmount [mount_point] \n"
        printf " unmount [all]            unmount all default folders \n"
        printf " test <case_nr>|all       run given test case \n"
        printf "\nExample:\n"
        printf "\t %s mount /home/%s/share /home/%s/test-mount/\n\n" "$GURU_CALL" "$GURU_REMOTE_FILE_SERVER_USER" "$USER" 
        printf "Statuses is located in environment variables 'GURU_SYSTEM_STATUS' and 'GURU_REMOTE_FILE_SERVER_STATUS'\n"
        printf "Currently system mount status is '%s' and file server status is '%s'" "$GURU_SYSTEM_STATUS" "$GURU_FILESERVER_STATUS"
        echo 
        return 0
    }
    
    argument="$1"; shift
   
    case "$argument" in
  
        check)                        
            [ "$1" ] && check_mount_status "$@" ||echo "pls input mount point"
            return $?            
            ;;
        
        check-system)
            check_system_mount_status
            ;;

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
            mount_sshfs "unmount" "$1" 
            [ "$2" == force ] && sudo fusermount -u "$1"
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
            mount_sshfs "$GURU_CLOUD_TRACK" "$GURU_TRACK" || return 100
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
                        mount_sshfs "unmount" "$argument" 
                        [ "$1" == "force" ] && sudo fusermount -u "$argument"                       
                        ;;
                    *) help
            esac
    esac
}

check_system_mount_status() {
    # mountpoint 
        printf "system mount status.. "
        grep "sshfs" < /etc/mtab | grep "$GURU_TRACK" >/dev/null && status="mounted" || status="offline"

        ls -1qA "$GURU_TRACK" | grep -q . >/dev/null 2>&1 && contans_stuff="yes" || contans_stuff=""

        if [ $status == "mounted" ] && [ "$contans_stuff" ]; then             
            export GURU_SYSTEM_STATUS="mounted"
            export GURU_FILESERVER_STATUS="online"
            ONLINE
            return 1
        elif [ $status == "mounted" ]; then             
            export GURU_SYSTEM_STATUS="mounted"
            export GURU_FILESERVER_STATUS="unknown"            
            printf "$ERROR mounted but empty system folder detected\n"         
            return 1
        elif [ $status == "offline" ]; then
            printf "$OFFLINE"        # do not to like write logs if unmounted
            export GURU_SYSTEM_STATUS="offline"
            export GURU_FILESERVER_STATUS="offline"
            return 0
        else 
            printf "$ERROR"        # do not to like write logs if unmounted
            export GURU_SYSTEM_STATUS="error"
            export GURU_FILESERVER_STATUS="unknown"
            export 0
        fi
}


check_mount_status() {
    # mountpoint 
        
        local target_folder=$1; shift
        local contans_stuff=""

        if ! [ -d "$target_folder" ]; then 
            printf "folder '$target_folder' does not exist" >$GURU_ERROR_MSG
            return 123
        fi

        check_system_mount_status >/dev/null

        if ! [ "$GURU_FILESERVER_STATUS"=="online" ]; then 
            printf "$ERROR:\nFile server mount unstable \n"        # do not to like write logs if unmounted
            printf "Mount $target_folder status $UNKNOWN \n"
            return 0
        fi

        printf "checking $target_folder status.. " | tee -a "$GURU_LOG"
        
        grep "sshfs" < /etc/mtab | grep "$target_folder" >/dev/null && local status="mounted" || local status="offline"


        ls -1qA "$target_folder" | grep -q . >/dev/null 2>&1 && contans_stuff="yes" || contans_stuff="" 

        if [ status=="mounted" ] && [ "$contans_stuff" ]; then
            ONLINE
            return 0
        else
            OFFLINE             # if here, Track is online feel free to log
            return 1
        fi

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
    [ "$GURU_CLOUD_COMPANY" ]   && mount_sshfs "$GURU_CLOUD_COMPANY" "$GURU_COMPANY" 
    [ "$GURU_CLOUD_FAMILY" ]    && mount_sshfs "$GURU_CLOUD_FAMILY" "$GURU_FAMILY" 
    [ "$GURU_CLOUD_NOTES" ]     && mount_sshfs "$GURU_CLOUD_NOTES" "$GURU_NOTES" 
    [ "$GURU_CLOUD_TEMPLATES" ] && mount_sshfs "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" 
    [ "$GURU_CLOUD_MUSIC" ]     && mount_sshfs "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" 
    [ "$GURU_CLOUD_PICTURES" ]  && mount_sshfs "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" 
    [ "$GURU_CLOUD_PHOTOS" ]    && mount_sshfs "$GURU_CLOUD_PHOTOS" "$GURU_PHOTOS"
    [ "$GURU_CLOUD_AUDIO" ]     && mount_sshfs "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" 
    [ "$GURU_CLOUD_VIDEO" ]     && mount_sshfs "$GURU_CLOUD_VIDEO" "$GURU_VIDEO"     
    return 0
}


unmount_guru_defaults() {
    # unmount all TODO do better    
    [ "$GURU_CLOUD_VIDEO" ]       && mount_sshfs "unmount" "$GURU_VIDEO" 
    [ "$GURU_CLOUD_AUDIO" ]       && mount_sshfs "unmount" "$GURU_AUDIO" 
    [ "$GURU_CLOUD_MUSIC" ]       && mount_sshfs "unmount" "$GURU_MUSIC" 
    [ "$GURU_CLOUD_PICTURES" ]    && mount_sshfs "unmount" "$GURU_PICTURES" 
    [ "$GURU_CLOUD_PHOTOS" ]      && mount_sshfs "unmount" "$GURU_PHOTOS" 
    [ "$GURU_CLOUD_TEMPLATES" ]   && mount_sshfs "unmount" "$GURU_TEMPLATES" 
    [ "$GURU_CLOUD_NOTES" ]       && mount_sshfs "unmount" "$GURU_NOTES" 
    [ "$GURU_CLOUD_FAMILY" ]      && mount_sshfs "unmount" "$GURU_FAMILY" 
    [ "$GURU_CLOUD_COMPANY" ]     && mount_sshfs "unmount" "$GURU_COMPANY" 
    return 0
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


