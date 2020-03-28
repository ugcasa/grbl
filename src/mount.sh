#!/bin/bash
# mount tools for guru tool-kit

source $GURU_BIN/lib/common.sh

mount.main() {
    # mount tool command parser
    argument="$1"; shift
    case "$argument" in
            check-system)   mount.check_system      ; return $? ;;
                   check)   mount.online "$@"       ; return $? ;;
                 ls|list)   mount.list              ; return $? ;;
                    info)   mount.sshfs_info        ; return $? ;;
                   mount)   mount.remote "$1" "$2"  ; return $? ;;
                 unmount)   unmount.remote "$1"     ; return $? ;;
                 install)   mount.needed install    ; return $? ;;
         unistall|remove)   mount.needed remove     ; return $? ;;
                    help)   mount.help "$@"         ; return 0  ;;
                    test)   source $GURU_BIN/test.sh; mount.test "$@" ;;
        all|defaults|def)   case "$GURU_CMD" in
                               mount)   mount.defaults_raw      ; return $? ;;
                             unmount)   unmount.defaults_raw    ; return $? ;;
                                   *)   help
                            esac ;;
                       *)   case "$GURU_CMD" in
                               mount)   if [ "$1" ]; then
                                                mount.remote "$argument" "$1"  ; return $?
                                            else
                                                mount.known_remote "$argument" ; return $? ; fi ;;
                             unmount)   if [ $FORCE ]; then
                                                sudo fusermount -u "$argument" ; return $?
                                            else
                                                unmount.remote "$argument"     ; fi ;;
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


mount.sshfs_get_info(){
    local _error=0
    [ $TEST ] || msg "${WHT}user@server remote_folder local_mountpoint  uptime ${NC}\n"                      # header (stdout when -v)
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |                                              # get the mount data
    while read mount ; do                                                                                    # Iterate over them
        mount | grep -w "$mount" |                                                                          # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GURU_USER'\@$1 $2 $3"'  # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?                                                                                           # last error, maily if perl is not installed
        printf " %s\n" "$(ps -p $(pgrep -f $mount) -eo %t)"
        #ps -p $(pgrep -f /home/casa/Track) -eo %t     # passed
    done
    ((_error>0)) && msg "perl not installed or internal error, pls try to install perl and try again."
    return $_error
}


mount.sshfs_info() {
    mount.sshfs_get_info | column -t -s $' '
    return $?
}


mount.list () {
    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


## VVV paskaa
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

    elif [ "$status" == "mounted" ] ; then
        GURU_SYSTEM_STATUS="validating system mount.."
        GURU_FILESERVER_STATUS="empty system mount point"
        return 20

    elif [ "$status" == "offline" ] ; then
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
    mount.check_system_mount ; result=$?
    if ((result<1)); then
            PASSED
        else
            FAILED
            echo "system status: $GURU_SYSTEM_STATUS"
            echo "file server status: $GURU_FILESERVER_STATUS"
            msg "system mount $GURU_FILESERVER_STATUS"
        fi
    return $result
}



mount.system () {
    if ! mount.check_system_mount ; then
            mount.remote "$GURU_CLOUD_TRACK" "$GURU_TRACK"
        fi
}


mount.online() {
    # input: mount point folder.
    # usage: mount.online mount_point && echo "mounted" || echo "not mounted"
    local _target_folder="$1"

    if [ -f "$_target_folder/.online" ] ; then
        return 0
    else
        return 1
    fi
}


mount.check() {
    # check mountpoint status with putput
    local _target_folder="$1"
    local _err=0
    [ "$_target_folder" ] || _target_folder="$GURU_TRACK"

    msg "$_target_folder status "
    mount.online "$_target_folder" ; _err=$?

    if [ $_err -gt 0 ] ; then
            OFFLINE
            return 1
        fi
    MOUNTED
    return 0
}


unmount.force_remote () {
    local target_folder="$1"
    msg "need to force unmount.. "

    if sudo fusermount -u "$target_folder" ; then
            UNMOUNTED "$target_folder FORCE"
            return 0
        else
            FAILED "$target_folder FORCE"
            return 101
        fi
}


unmount.remote () {
    local target_folder="$1"

    if ! mount.online "$target_folder" ; then
            IGNORED "$target_folder not mounted"
            return 0
        fi

    if fusermount -u "$target_folder"; then
            UNMOUNTED "$target_folder"
            return 0
        else
             unmount.force_remote "$target_folder"
        fi

    # once more or if force
    if [ "$FORCE" ] && mount.online "$target_folder"; then
        unmount.force_remote "$target_folder"
        return $?
        fi
}



mount.remote() {
    # input remote_foder and mount_point
    local _source_folder=""
    local _target_folder=""

    if [ "$1" ]; then _source_folder="$1"; else read -r -p "input source folder at server: " _source_folder; fi
    if [ "$2" ]; then _target_folder="$2"; else read -r -p "input target mount point: " _target_folder; fi

    if ! [ -d "$_target_folder" ]; then
        mkdir -p "$_target_folder"                                      # be sure that mount point exist
        fi

    if mount.online "$_target_folder"; then
        ONLINE "$_target_folder"                                        # already mounted
        return 0
    fi
    [ "$(ls $_target_folder)" ] && return 25                            # Check that directory is empty

    local server="$GURU_LOCAL_FILE_SERVER"                              # assume that server is in local network
    local server_port="$GURU_LOCAL_FILE_SERVER_PORT"
    local user="$GURU_LOCAL_FILE_SERVER_USER"

    if ! ssh -q -p "$server_port" "$user@$server" exit; then            # check local server connection
        server="$GURU_REMOTE_FILE_SERVER"                               # if no connection try remote server connection
        server_port="$GURU_REMOTE_FILE_SERVER_PORT"
        user="$GURU_REMOTE_FILE_SERVER_USER"
    fi
    msg "mounting $_target_folder "

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$user@$server:$_source_folder" "$_target_folder"
    error=$?

    if ((error>0)); then
            WARNING "source folder not found, check $GURU_USER_RC\n"
            [ -d "$_target_folder" ] && rmdir "$_target_folder"
            return 25
        else
            MOUNTED
            return 0                                                                           #&& echo "mounted $server:$_source_folder to $_target_folder" || error="$
        fi
}


mount.known_remote () {
    local _target=$(eval echo '$'"GURU_${1^^}")
    local _source=$(eval echo '$'"GURU_CLOUD_${1^^}")

    mount.remote "$_target" "$_source"
    return $?
}

unmount.known_remote () {
    local _target=$(eval echo '$'"GURU_${1^^}")
    unmount.remote "$_target"
    return $?
}


mount.defaults_raw () {
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


unmount.defaults_raw () {
    # unmount all TODO do better
    local _error=0
    if [ "$GURU_CLOUD_VIDEO" ]; then      unmount.remote "$GURU_VIDEO" || _error="true"; fi
    if [ "$GURU_CLOUD_AUDIO" ]; then      unmount.remote "$GURU_AUDIO" || _error="true"; fi
    if [ "$GURU_CLOUD_MUSIC" ]; then      unmount.remote "$GURU_MUSIC" || _error="true"; fi
    if [ "$GURU_CLOUD_PICTURES" ]; then   unmount.remote "$GURU_PICTURES" || _error="true"; fi
    if [ "$GURU_CLOUD_PHOTOS" ]; then     unmount.remote "$GURU_PHOTOS" || _error="true"; fi
    if [ "$GURU_CLOUD_TEMPLATES" ]; then  unmount.remote "$GURU_TEMPLATES" || _error="true"; fi
    if [ "$GURU_CLOUD_NOTES" ]; then      unmount.remote "$GURU_NOTES" || _error="true"; fi
    if [ "$GURU_CLOUD_FAMILY" ]; then     unmount.remote "$GURU_FAMILY" || _error="true"; fi
    if [ "$GURU_CLOUD_COMPANY" ]; then    unmount.remote "$GURU_COMPANY" || _error="true"; fi

    [ "$_error" -gt "0" ] && return 0 || return 0           # do not care errors
}


mount.needed () {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    [ "$action" ] || read -r -p "install or remove? " action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to mount\n\n"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    VERBOSE="true"
    source "$HOME/.gururc"
    mount.main "$@"
    exit "$?"
fi


