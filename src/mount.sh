#!/bin/bash
# mount tools for guru tool-kit

source $GURU_BIN/functions.sh
source $GURU_BIN/counter.sh
source $GURU_BIN/lib/deco.sh

mount.main() {
    # mount tool command parser
    argument="$1"; shift
    case "$argument" in
            check-system)   mount.check_system      ; return $? ;;
                   check)   mount.check "$@"        ; return $? ;;
                 ls|list)   mount.list              ; return $? ;;
                    info)   mount.sshfs_info        ; return $? ;;
                   mount)   mount.remote "$1" "$2"  ; return $? ;;
                 unmount)   mount.unmount "$1"      ; return $? ;;
                 install)   mount.needed install    ; return $? ;;
         unistall|remove)   mount.needed remove     ; return $? ;;
                    help)   mount.help "$@"         ; return 0  ;;
        all|defaults|def)   case "$GURU_CMD" in
                               mount)   mount.defaults_raw      ; return $? ;;
                             unmount)   unmount.defaults_raw    ; return $? ;;
                                   *)   help
                            esac ;;
                       *)   case "$GURU_CMD" in
                               mount)   if [ "$1" ]; then
                                                mount.remote "$argument" "$1"
                                                return $?
                                            else
                                                mount.known_remote "$argument"
                                                return $?
                                            fi                              ;;
                             unmount)   if [ $FORCE ]; then
                                                sudo fusermount -u "$argument"
                                                return $?
                                            else
                                                mount.unmount "$argument"
                                             fi                              ;;
                                    *)  mount.help
                            esac ;;
    esac
}

mount.help() {
    echo "-- guru tool-kit mount help -----------------------------------------------"
    printf "usage:\t\t %s mount [source] [target] \n" "$GURU_CALL"
    printf "\t\t %s mount [command] [known_mount_point|arguments] \n" "$GURU_CALL"
    printf "commands:\n"
    printf " check-system             check that guru system folders are mounted \n"
    printf " check [target]           check that mount point is mounted \n"
    printf " mount [source] [target]  mount folder in file server to local folder \n"
    printf " unmount [mount_point]    unmount [mount_point] \n"
    printf " mount all                mount primary file server default folders \n"
    printf " unmount [all]            unmount all default folders \n"
    printf " ls                       list of mounted folders \n"
    printf "\nexample:"
    printf "\t %s mount /home/%s/share /home/%s/test-mount\n" "$GURU_CALL" "$GURU_REMOTE_FILE_SERVER_USER" "$USER"
    return 0
}


mount.sshfs_info(){
    local _error=0
    [ $TEST ] || msg "${WHT}user@server:source_folder   >   local_mount_point   uptime [day-h:m:s]${NC}\n"  # header (stdout when -v)
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |                                              # get the mount data
    while read mount; do                                                                                    # Iterate over them
        mount | grep -w "$mount" |                                                                          # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GURU_USER'\@$1:$2\  >  $3"'  # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?                                                                                           # last error, maily if perl is not installed
        printf "%s\n" "$(ps -p $(pgrep -f "$mount") o etime=)"                                              # uptime
    done
    ((_error>0)) && echo "perl not installed or internal error, pls try to install perl and try again." >$GURU_ERROR_MSG
    return $_error
}


mount.list () {
    #mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)'       remote
    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


mount.check_system_mount() {
    grep "sshfs" < /etc/mtab | grep "$GURU_TRACK" >/dev/null && status="mounted" || status="offline"
    ls -1qA "$GURU_TRACK" | grep -q . >/dev/null 2>&1 && contans_stuff="yes" || contans_stuff=""

    if [ "$status" == "mounted" ] && [ "$contans_stuff" ] && [ -f "$GURU_TRACK/.online" ]; then
        GURU_SYSTEM_STATUS="ready"
        GURU_FILESERVER_STATUS="online"
        return 0

    elif [ "$status" == "mounted" ] && [ "$contans_stuff" ]; then
        GURU_SYSTEM_STATUS="validating system mount.. "
        GURU_FILESERVER_STATUS=".online file not found"
        return 20

    elif [ "$status" == "mounted" ]; then
        GURU_SYSTEM_STATUS="validating system mount.."
        GURU_FILESERVER_STATUS="empty system mount point"
        return 20

    elif [ "$status" == "offline" ]; then
        GURU_SYSTEM_STATUS="offline"
        GURU_FILESERVER_STATUS="offline"
        return 20

    else
        GURU_SYSTEM_STATUS="error"
        GURU_FILESERVER_STATUS="unknown"
        return 20
    fi
}


mount.check_system() {
    msg "checking system mountpoint.. "
    mount.check_system_mount;  result=$?
    if ((result<1)); then
            PASSED
        else
            FAILED
            echo "system status: $GURU_SYSTEM_STATUS"
            echo "file server status: $GURU_FILESERVER_STATUS"
            echo "system mount $GURU_FILESERVER_STATUS" >$GURU_ERROR_MSG
        fi
    return $result
}

mount.system () {
    if ! mount.check_system_mount; then
            mount.remote "$GURU_CLOUD_TRACK" "$GURU_TRACK"
        fi
}

mount.online() {
    # input: mount point folder.
    # returns: 0 if on line 1 of off line + log and nice colorful output for terminal
    # usage: mount.online mount_point && echo "mounted" || echo "not mounted"
    #        mount.online && OK || WARNING
    local target_folder=$1; shift
    local contans_stuff=""

    if ! [ -d "$target_folder" ]; then
        msg "$WARNING folder '$target_folder' does not exist\n" >$GURU_ERROR_MSG
        return 123
    fi

    mount.check_system_mount                                       # Check that system mount is ok

    if ! [ "$GURU_FILESERVER_STATUS"=="online" ]; then
        msg "$WARNING system mount unstable \n"         # do not to like write logs if unmounted
        #msg "Mount $target_folder status $UNKNOWN \n"
        return 24
    fi

    msg "$target_folder status "
    grep "sshfs" < /etc/mtab | grep "$target_folder" >/dev/null && local status="mounted" || local status="offline"
    ls -1qA "$target_folder" | grep -q . >/dev/null 2>&1 && contans_stuff="yes" || contans_stuff=""

    if [ status=="mounted" ] && [ "$contans_stuff" ]; then
        ONLINE
        return 0
    else
        OFFLINE
        return 23
    fi
}

mount.check() {
    mount.online "$@"
    return $?
}


mount.unmount () {
    local target_folder="$1"
    if ! [ -d "$target_folder" ]; then
        WARNING "folder '$target_folder' dopes not exist\n"
        return 132
    fi
    #msg "un-mounting $target_folder.. "
    grep "$target_folder" < /etc/mtab >/dev/null || msg "not mounted "

    if [ "$FORCE" ]; then
        sudo fusermount -u "$target_folder" && msg "force $UNMOUNTED $target_folder" || FAILED
    else
        mount.online "$target_folder" >/dev/null && fusermount -u "$target_folder" && UNMOUNTED $target_folder || msg "$target_folder $IGNORED"    # unmount target if mounted
    fi
}



mount.remote() {
    # input remote_foder and mount_point. servers are already known
    # returns error code of sshfs mount, 0 is success.
    local source_folder=""
    local target_folder=""

    [ "$1" ] && source_folder="$1" ||read -r -p "input source folder at server: " source_folder
    [ "$2" ] && target_folder="$2" ||read -r -p "input target mount point: " target_folder

    printf "target folder crate problems" >$GURU_ERROR_MSG
    [ -d "$target_folder" ] ||mkdir -p "$target_folder"                 # be sure that mount point exist
    echo >$GURU_ERROR_MSG

    mount.online "$target_folder" && return 1                           # mount.unmount "$target_folder"
    #[ "$source_folder" == "unmount" ] && return 0                      # if first argument is "unmount" all done for now, exit
    printf "non empty target $target_folder" >$GURU_ERROR_MSG
    [ "$(ls $target_folder)" ] && return 28                             # Check that directory is empty

    local server="$GURU_LOCAL_FILE_SERVER"                              # assume that server is in local network
    local server_port="$GURU_LOCAL_FILE_SERVER_PORT"
    local user="$GURU_LOCAL_FILE_SERVER_USER"

    if ! ssh -q -p "$server_port" "$user@$server" exit; then            # check local server connection
        server="$GURU_REMOTE_FILE_SERVER"                               # if no connection try remote server connection
        server_port="$GURU_REMOTE_FILE_SERVER_PORT"
        user="$GURU_REMOTE_FILE_SERVER_USER"
    fi
    msg "mounting $target_folder "

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$user@$server:$source_folder" "$target_folder"
    error=$?

    if ((error>0)); then
            WARNING "source folder not found, check $GURU_USER_RC\n"
            [ -d "$target_folder" ] && rmdir "$target_folder"
            return 25
        else
            MOUNTED
            return 0                                                                           #&& echo "mounted $server:$source_folder to $target_folder" || error="$
        fi
}


mount.known_remote () {
    local _target=$(eval echo '$'"GURU_${1^^}")
    local _source=$(eval echo '$'"GURU_CLOUD_${1^^}")
    mount.remote $_target $_source
    return $?
}


mount.defaults_raw() {
    # mount guru tool-kit defaults + backup method if sailing. TODO do better: list of key:variable pairs while/for loop
   local _error="0"
    if [ "$GURU_CLOUD_COMPANY" ]; then   mount.remote "$GURU_CLOUD_COMPANY" "$GURU_COMPANY" || _error="1"; fi
    if [ "$GURU_CLOUD_FAMILY" ]; then    mount.remote "$GURU_CLOUD_FAMILY" "$GURU_FAMILY" || _error="1"; fi
    if [ "$GURU_CLOUD_NOTES" ]; then     mount.remote "$GURU_CLOUD_NOTES" "$GURU_NOTES" || _error="1"; fi
    if [ "$GURU_CLOUD_TEMPLATES" ]; then mount.remote "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES" || _error="1"; fi
    if [ "$GURU_CLOUD_PICTURES" ]; then  mount.remote "$GURU_CLOUD_PICTURES" "$GURU_PICTURES" || _error="1"; fi
    if [ "$GURU_CLOUD_PHOTOS" ]; then    mount.remote "$GURU_CLOUD_PHOTOS" "$GURU_PHOTOS" || _error="1"; fi
    if [ "$GURU_CLOUD_AUDIO" ]; then     mount.remote "$GURU_CLOUD_AUDIO" "$GURU_AUDIO" || _error="1"; fi
    if [ "$GURU_CLOUD_VIDEO" ]; then     mount.remote "$GURU_CLOUD_VIDEO" "$GURU_VIDEO" || _error="1"; fi
    if [ "$GURU_CLOUD_MUSIC" ]; then     mount.remote "$GURU_CLOUD_MUSIC" "$GURU_MUSIC" || _error="1"; fi

    [ "$_error" -gt "0" ] && return 1 || return 0
}


unmount.defaults_raw() {
    # unmount all TODO do better
    local _error=0
    if [ "$GURU_CLOUD_VIDEO" ]; then      mount.unmount "$GURU_VIDEO" || _error="true"; fi
    if [ "$GURU_CLOUD_AUDIO" ]; then      mount.unmount "$GURU_AUDIO" || _error="true"; fi
    if [ "$GURU_CLOUD_MUSIC" ]; then      mount.unmount "$GURU_MUSIC" || _error="true"; fi
    if [ "$GURU_CLOUD_PICTURES" ]; then   mount.unmount "$GURU_PICTURES" || _error="true"; fi
    if [ "$GURU_CLOUD_PHOTOS" ]; then     mount.unmount "$GURU_PHOTOS" || _error="true"; fi
    if [ "$GURU_CLOUD_TEMPLATES" ]; then  mount.unmount "$GURU_TEMPLATES" || _error="true"; fi
    if [ "$GURU_CLOUD_NOTES" ]; then      mount.unmount "$GURU_NOTES" || _error="true"; fi
    if [ "$GURU_CLOUD_FAMILY" ]; then     mount.unmount "$GURU_FAMILY" || _error="true"; fi
    if [ "$GURU_CLOUD_COMPANY" ]; then    mount.unmount "$GURU_COMPANY" || _error="true"; fi

    [ "$_error" -gt "0" ] && return 0 || return 0           # do not care errors
}


mount.needed() {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    [ "$action" ] || read -r -p "install or remove? " action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to mount\n\n"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    source $GURU_BIN/lib/common.sh
    source "$HOME/.gururc"
    mount.main "$@"
    exit "$?"
fi


