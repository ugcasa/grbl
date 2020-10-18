#!/bin/bash
# mount tools for guru-client
#source "$HOME/.gururc"
source $GURU_BIN/common.sh


mount.main () {
    # mount command parser
    indicator_key='F'"$(poll_order mount)"
    argument="$1"; shift
    case "$argument" in
               start|end)   gmsg -v 1 "mount.sh: no $argument function"         ; return 0 ;;
                     all)   mount.defaults                                      ; return $? ;;
                      ls)   mount.list                                          ; return $? ;;
                    info)   mount.info | column -t -s $' '                      ; return $? ;;
                  status)   mount.status                                        ; return $? ;;
                   check)   mount.online "$@"                                   ; return $? ;;
            check-system)   mount.check "$GURU_SYSTEM_MOUNT"                    ; return $? ;;
           mount|unmount)   case "$1" in all) $argument.defaults                ; return $? ;;
                                           *) $argument.remote $@               ; return $? ;;
                                esac                                            ; return $? ;;
          install|remove)   mount.install "$argument"                           ; return $? ;;
       help|help-default)   mount.$argument "$1"                                ; return 0  ;;
                       *)   if [ "$1" ] ; then mount.remote "$argument" "$1"    ; return $? ; fi
                            case $GURU_CMD in
                                mount|unmount)
                                    case $argument in
                                    all) $GURU_CMD.defaults                     ; return $? ;;
                                      *) $GURU_CMD.known_remote "$argument"     ; return $? ;;
                                    esac                                                    ;;
                                *) echo "$GURU_CMD: bad input '$argument' "     ; return 1  ;;
                                esac                                                        ;;
                            esac
}


mount.help () {
    # printout help
    gmsg -v1 -c white "guru-client mount help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mount|unount|check|check-system <source> <target>"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " ls                       list of mounted folders "
    gmsg -v1 " mount [source] [target]  mount folder in file server to local folder "
    gmsg -v1 " unmount [mount_point]    unmount [mount_point] "
    gmsg -v1 " mount all                mount all known folders in server "
    gmsg -v1 "                          edit $GURU_CFG/$USER/user.cfg or run "
    gmsg -v1 "                          '$GURU_CALL config user' to setup default mountpoints "
    gmsg -v2 "                          more information of adding default mountpoint type: $GURU_CALL mount help-default"
    gmsg -v1 " unmount [all]            unmount all default folders "
    gmsg -v1 " check [target]           check that mount point is mounted "
    gmsg -v2 " check-system             check that guru system folder is mounted "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL mount /home/$GURU_CLOUD_USERNAME/share /home/$USER/test-mount"
    gmsg -v1 "      $GURU_CALL umount /home/$USER/test-mount"

}


mount.status () {
    # check status of GURU_CLOUD_* mountpoints defined in userrc
    local _active_mount_points=$(mount.list)
    for _mount_point in ${_active_mount_points[@]}; do
        mount.check $_mount_point
        done
    return 0
}


mount.info () {
    # detailed list of mounted mountpoints
    # nice list of information of sshfs mount points
    local _error=0
    [ $TEST ] || msg "${WHT}user@server remote_folder local_mountpoint  uptime pid${NC}\n"                 # header (stdout when -v)
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |                                          # get the mount data

    while read mount ; do                                                                               # Iterate over them
        mount | grep -w "$mount" |                                                                      # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GURU_USER'\@$1 $2 $3"'   # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?
        local _mount_pid="$(pgrep -f $mount | head -1)"
        _mount_age="$(ps -p $_mount_pid o etime | grep -v ELAPSED | xargs)"
        echo " $_mount_age $_mount_pid"

    done

    ((_error>0)) && msg "perl not installed or internal error, pls try to install perl and try again."
    return $_errorB
}


mount.list () {                         # simple list of mounted mountpoints
    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


mount.system () {                       # mount system data
    gmsg -v2 "checking system folder"
    if ! mount.online "$GURU_SYSTEM_MOUNT" ; then
            gmsg -v2 "mounting system folder"
            mount.remote "${GURU_SYSTEM_MOUNT[1]}" "$GURU_SYSTEM_MOUNT"
        fi
}


mount.online () {
    # check if mountpoint "online", no printout, return code only
    # input: mount point folder.
    # usage: mount.online mount_point && echo "mounted" || echo "not mounted"

    local _target_folder="$1"

    if [[ -f "$_target_folder/.online" ]] ; then
        return 0
    else
        return 1
    fi
}


mount.check () {
    # check mountpoint is mounted, output status

    local _target_folder="$1"
    local _err=0
    [[ "$_target_folder" ]] || _target_folder="$GURU_SYSTEM_MOUNT"

    gmsg -t -n -v 1 "$_target_folder status "
    mount.online "$_target_folder" ; _err=$?

    if [[ $_err -gt 0 ]] ; then
            gmsg -v 1 -c red "OFFLINE"
            return 1
        fi
    gmsg -v 1 -c green "MOUNTED"
    return 0
}


mount.remote () {
    # mount remote location
    # input remote_foder and mount_point

    local _source_folder=""
    if [[ "$1" ]] ; then _source_folder="$1"; else read -r -p "input source folder at server: " _source_folder ; fi

    local _target_folder=""
    if [[ "$2" ]] ; then _target_folder="$2"; else read -r -p "input target mount point: " _target_folder ; fi

    gmsg -v2 -c dark_gray "$FUNCNAME: $_source_folder > $_target_folder"

    if mount.online "$_target_folder"; then
            gmsg -v1 "$_target_folder $ONLINE"                                 # already mounted
            return 0
        fi

    # TODO important: clean-up messy and unclear now, can cause file losses

    if [[ "$(ls -A $_target_folder >/dev/null 2>&1)" ]] ; then                  # Check that targed directory is empty
            gmsg -v1 "$WARNING $_target_folder is not empty"

            if [[ $GURU_FORCE ]] ; then
                    local _reply=""
                    FORCE=                                                      # Too dangerous to continue if set
                    ls "$_target_folder"
                    read -r -p "remove above files and folders?: " _reply
                    if [[ $_reply == "y" ]] ; then

                            if ! [[ -f "$_target_folder/.online" ]] ; then      # to be sure that non of other processes did just now mounted the folder
                                    rm -r "$_target_folder"
                                fi

                        else
                            gmsg -v1 "$ERROR: unable to mount $_target_folder, mount point contains files"
                            return 25
                        fi
                else
                    gmsg "try '-f' to force or: '$GURU_CALL -f mount $_source_folder $_target_folder"
                    return 25
                fi
        fi

    if ! [[ -d "$_target_folder" ]] ; then
        mkdir -p "$_target_folder"                                              # be sure that mount point exist
        fi

    local server="$GURU_CLOUD_LAN_IP"                                           # assume that server is in local network
    local server_port="$GURU_CLOUD_LAN_PORT"
    local user="$GURU_CLOUD_USERNAME"

    if ! ssh -q -p "$server_port" "$user@$server" exit ; then                   # check local server connection
            server="$GURU_CLOUD_DOMAIN"                                         # if no connection try remote server connection
            server_port="$GURU_CLOUD_PORT"
            user="$GURU_CLOUD_USERNAME"
        fi

    gmsg -v1 -n "mounting $_target_folder "

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$server_port" "$user@$server:$_source_folder" "$_target_folder"
    error=$?

    if ((error>0)) ; then
            gmsg -v1 "$WARNING source folder not found, check $GURU_SYSTEM_RC"
            [[ -d "$_target_folder" ]] && rmdir "$_target_folder"
            return 25
        else
            [[ -f "$_target_folder/.online" ]] && touch "$_target_folder/.online"
            gmsg -v1 "$MOUNTED"
            return 0                                                         # && echo "mounted $server:$_source_folder to $_target_folder" || error="$
        fi
}


unmount.remote () {
    # unmount mountpoint

    if [[ "$1" ]] ; then
        local _mountpoint="$1"
    else

        mount.list | grep -v $GURU_SYSTEM_MOUNT
        read -p "select mount point: " _mountpoint
    fi

    gmsg -v2 -c dark_gray "$FUNCNAME: $_mountpoint"

    if ! mount.online "$_mountpoint" ; then
            gmsg -v1 "$_mountpoint is not mounted $IGNORED"
            return 0
        fi

    if fusermount -u "$_mountpoint" ; then
            gmsg -v1 "$_mountpoint $UNMOUNTED"
            return 0
        fi

    # once more or if force
    if [[ "$GURU_FORCE" ]] || mount.online "$_mountpoint" ; then

            gmsg -v1 "force unmount.. "
            if fusermount -u "$_mountpoint" ; then

                    gmsg -v1 "$_mountpoint force $UNMOUNTED"
                    return 0
                else
                    if sudo fusermount -u "$_mountpoint" ; then
                            gmsg -v1 "$_mountpoint SUDO FORCE $UNMOUNTED"
                            return 0
                        else
                            gmsg "$FAILED: sudo force unmount $_mountpoint."
                            gmsg -v1 "seems that some of open program like terminal or editor is blocking unmount, try to close those first"
                            return 1
                    fi
            fi
    fi

    return 0
}


mount.defaults () {
    # mount all GURU_CLOUD_* defined in userrc
    # mount all local/cloud pairs defined in userrc
    local _error=0
    local _default_list=($(cat $GURU_RC | grep 'GURU_MOUNT_' | sed 's/^.*MOUNT_//' | cut -d '=' -f1))

    if ! [[ $_default_list ]] ; then
            gmsg -c yellow "default mount list is empty, edit $GURU_CFG/$GURU_USER/user.cfg and then '$GURU_CALL config export'"
            return 1
        fi

    for _item in "${_default_list[@]}" ; do                       # go trough of found variables
        _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")        #
        _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")        #
        gmsg -v2 -c dark_gray "$FUNCNAME: ${_item,,} "
        mount.remote "$_source" "$_target" || _error=$?
    done
    return $_error
}


unmount.defaults () {
    # unmount all GURU_CLOUD_* defined in userrc
    # unmount all local/cloud pairs defined in userrc
    local _default_list=($(cat $GURU_RC | grep 'GURU_MOUNT_' | sed 's/^.*MOUNT_//' | cut -d '=' -f1))

    if ! [[ $_default_list ]] ; then
            gmsg -c yellow "default list is empty"
            return 1
        fi

    for _item in "${_default_list[@]}" ; do                       # go trough of found variables
        _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")        #
        gmsg -v2 -c dark_gray "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    return $_error
}


mount.known_remote () {
    # mount single GURU_CLOUD_* defined in userrc

    local _source=$(eval echo '${GURU_MOUNT_'"${1^^}[1]}")      ; echo $_source
    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")      ; echo $_target
    gmsg -v2 -c dark_gray "$FUNCNAME: ${_item,,} $_target"
    mount.remote "$_source" "$_target"
    return $?
}


unmount.known_remote () {
    # unmount single GURU_CLOUD_* defined in userrc

    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    gmsg -v2 -c dark_gray "$FUNCNAME: ${_item,,} $_target"
    unmount.remote "$_target"
    return $?
}


mount.install () {
    #install and remove install applications. input "install" or "remove"

    local action="$1"
    [[ "$action" ]] || read -r -p "install or remove? " action
    local require="ssh rsync"
    printf "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to mount\n\n"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then    # if sourced only import functions
        source "$GURU_RC"
        mount.main "$@"
        exit "$?"
    fi
