#!/bin/bash

# mount tools for guru-client
#source "$HOME/.gururc"
source $GURU_BIN/common.sh


mount.main () {
    # mount command parser
    indicator_key='f'"$(poll_order mount)"
    argument="$1"; shift
    case "$argument" in
               start|end)   gmsg -v 1 "mount.sh: no $argument function"         ; return 0 ;;
                  system)   mount.system                                        ; return $? ;;
                     all)   mount.defaults                                      ; return $? ;;
                      ls)   mount.list                                          ; return $? ;;
                    info)   mount.info | column -t -s $' '                      ; return $? ;;
                  status)   mount.status                                        ; return $? ;;
                   check)   mount.online "$@"                                   ; return $? ;;
            check-system)   mount.check "$GURU_SYSTEM_MOUNT"                    ; return $? ;;
           mount|unmount)   case "$1" in all) $argument.defaults                ; return $? ;;
                                           *) $argument.known_remote $@         ; return $? ;;
                                esac                                            ; return $? ;;
          install|remove)   mount.install "$argument"                           ; return $? ;;
       help|help-default)   mount.$argument "$1"                                ; return 0  ;;
                       *)   if [[ "$1" ]] ; then mount.remote "$argument" "$1"  ; return $? ; fi
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
    gmsg -v3 " poll start|end           start or end module status polling "
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
    [ $TEST ] || gmsg -c white "user@server remote_folder local_mountpoint  uptime pid"
    # header (stdout when -v)
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |
    # get the mount data

    while read mount ; do
        # Iterate over them
        mount | grep -w "$mount" |
        # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GURU_USER'\@$1 $2 $3"'
        # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?
        local _mount_pid="$(pgrep -f $mount | head -1)"
        _mount_age="$(ps -p $_mount_pid o etime | grep -v ELAPSED | xargs)"
        echo " $_mount_age $_mount_pid"

    done

    ((_error>0)) && gmsg -c yellow "perl not installed or internal error, pls try to install perl and try again."
    return $_errorB
}


mount.list () {
    # simple list of mounted mountpoints

    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


mount.system () {
    # mount system data

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
    gmsg -N -n -v3 -c pink "checking $_target_folder "
    if [[ -f "$_target_folder/.online" ]] ; then
        gmsg -v3 -c green "mounted"
        return 0
    else
        gmsg -v3 -c blue "offline"
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

    local _source_folder=
    local _target_folder=
    local _reply=
    unset FORCE
    if [[ "$1" ]] ; then _source_folder="$1" ; else read -r -p "input source folder at server: " _source_folder ; fi
    if [[ "$2" ]] ; then _target_folder="$2" ; else read -r -p "input target mount point: " _target_folder ; fi
    local _temp_folder="/tmp/guru/mount"
    gmsg -v1 -n "mounting $_target_folder.. "

    # check is already mounted
    if mount.online "$_target_folder" ; then
            gmsg -v1 -c green "mounted"
            return 0
        fi

    # double check is already mounted
    if grep "$_target_folder" /etc/mtab >/dev/null ; then
            gmsg -v1 -c green "mounted"
            return 0
        fi

    # check mount point exist
    if ! [[ -d "$_target_folder" ]] ; then
            mkdir -p "$_target_folder"
        fi

    # check is target populated and append if is
    if ! [[ -z "$(ls -A $_target_folder)" ]] ; then
            # Check that targed directory is empty
            gmsg -c yellow "target folder is not empty!"
            if ! [[ $GURU_FORCE ]] ; then
                    gmsg -v2 -c white "try '-f' to force or: '$GURU_CALL -f mount $_source_folder $_target_folder"
                    return 25
                fi

            # move found files to temp
            gmsg -c light_blue "$(ls $_target_folder)"
            read -r -p "append above files to $_target_folder?: " _reply
            case $_reply in
                y)
                    [[ -d $_temp_folder ]] && rm -rf "$_temp_folder"
                    gmsg -c pink -v3 "mv $_target_folder -> $_temp_folder"
                    mkdir -p "$_temp_folder"
                    mv "$_target_folder" "$_temp_folder"
                    ;;
                *)  gmsg -c red "unable to mount $_target_folder is populated"
                    return 26
                esac
        fi

    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$GURU_CLOUD_PORT" "$GURU_CLOUD_USERNAME@$GURU_CLOUD_DOMAIN:$_source_folder" "$_target_folder"
    error=$?

    # copy files from temp if exist

    if [[ -d "$_temp_folder/${_target_folder##*/}" ]] ; then
    # new fucket up space dot --> if [[ -d "$_temp_folder" ]] ; then
            gmsg -c pink -v3 "juppi: $_temp_folder/${_target_folder##*/}"
            gmsg -c pink -v3 "cp $_temp_folder/${_target_folder##*/}/*" "$_target_folder"
            cp -a "$_temp_folder/${_target_folder##*/}/." "$_target_folder" || gmsg -c yellow "failed to append/return files to $_target_folderm, check also $_temp_folder"
            rm -rf "$_temp_folder" || gmsg -c yellow "failed to remote $_temp_folder"
        fi

    # check sshfs error
    if ((error>0)) ; then
            gmsg -v1 -c yellow "source folder not found, check user cofiguration '$GURU_CALL config user'"
            # remove folder only if empty
            [[ -d "$_target_folder" ]] && rmdir "$_target_folder"
            return 25
        else
            [[ -f "$_target_folder/.online" ]] || touch "$_target_folder/.online"
            gmsg -v1 -c green "ok"
            return 0
        fi
}


unmount.remote () {
    # unmount mountpoint
    local _mountpoint=

    if [[ "$1" ]] ; then
        _mountpoint="$1"
    else
        local _list=($(mount.list | grep -v $GURU_SYSTEM_MOUNT))
        local _i=0

        for item in "${_list[@]}" ; do
            gmsg -c light_blue "$_i: ${_list[_i]}"
            let _i++
            #statements
        done

        _i=0
        read -p "select mount point: " _i
    fi

    _mountpoint=${_list[_i]}

    gmsg -n -v1 "unmounting $_mountpoint.. "
    # check is mounted
    if ! grep "$_mountpoint" /etc/mtab >/dev/null ; then
            gmsg -v1 -c dark_gray "is not mounted"
            return 0
        fi

    if ! [[ -f "$_mountpoint/.online" ]] ; then
            gmsg -n -v2 -c yellow ".online missing, "
         fi


    # unmount (normal)
    if ! fusermount -u "$_mountpoint" ; then
            gmsg -v2 -c yellow "error $? "
        fi

    if ! mount.online "$_mountpoint" ; then
            gmsg -v1 -c green "OK"
            rmdir $_mountpoint
            return 0
        fi

    gmsg -n -v1 "trying to force unmount.. "

    if sudo umount -l "$_mountpoint" ; then
            gmsg -v1 -c green "OK"
            rmdir $_mountpoint
            return 0
        else
            gmsg -c red "failed to force unmount"
            gmsg -v1 -c white "seems that some of open program like terminal or editor is blocking unmount, try to close those first"
            return 124
        fi
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

    for _item in "${_default_list[@]}" ; do
        # go trough of found variables
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

    for _item in "${_default_list[@]}" ; do
        # go trough of found variables
        _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")        #
        #gmsg -v3 -c pink "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    return $_error
}


mount.known_remote () {

    # mount single GURU_CLOUD_* defined in userrc
    local _source=$(eval echo '${GURU_MOUNT_'"${1^^}[1]}")
    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    gmsg -v3 -c pink "$FUNCNAME: ${_item,,} $_target < $_source"
    mount.remote "$_source" "$_target"
    return $?
}


unmount.known_remote () {

    # unmount single GURU_CLOUD_* defined in userrc
    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    gmsg -v3 -c pink "$FUNCNAME: ${_item,,} $_target"
    unmount.remote "$_target"
    return $?
}


mount.install () {
    #install and remove install applications. input "install" or "remove"
    local action="$1"
    [[ "$action" ]] || read -r -p "install or remove? " action
    local require="ssh rsync"
    gmsg "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && gmsg "guru is now ready to mount"
    return 0
}


mount.system () {

    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
            gmsg -v1 -c green "system is mounted"
            return 0
        fi

    mount.remote /home/$GURU_ACCESS_USERNAME/data $GURU_SYSTEM_MOUNT
}



mount.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: mount status polling started" -k $indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: mount status polling ended" -k $indicator_key
            ;;
        status )
            mount.status $@
            ;;
        *)  mount.help
            ;;
        esac

}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # if sourced only import functions
        source "$GURU_RC"
        mount.main "$@"
        exit "$?"
    fi
