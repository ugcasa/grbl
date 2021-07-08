#!/bin/bash
# mount tools for guru-client
#source "$HOME/.gururc"
source $GURU_BIN/common.sh

mount.main () {
    # mount command parser

    all_list=($(\
            cat $GURU_RC | \
            grep 'GURU_MOUNT_' | \
            grep -v "DEFAULT_LIST" | \
            sed 's/^.*MOUNT_//' | \
            cut -d '=' -f1))
    all_list=(${all_list[@],,})


    indicator_key='f'"$(daemon.poll_order mount)"
    argument="$1" ; shift

    case "$argument" in
       all|defaults|system|status|help)
                            mount.$argument                     ; return $? ;;
                 ls|list)   mount.list                          ; return $? ;;
                    info)   mount.info | column -t -s $' '      ; return $? ;;
                   check)   mount.online "$@"                   ; return $? ;;
            check-system)   mount.check "$GURU_SYSTEM_MOUNT"    ; return $? ;;
                      "")   mount.defaults                      ; return $? ;;
                       *)
                            if echo ${GURU_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$argument" ; then
                                    gmsg -v3 -c green "found in defauls list"
                                    mount.known_remote $argument $@

                                elif echo ${all_list[@]} | grep -q -w "$argument" ; then
                                    gmsg -v3 -c green "found in all list"
                                    mount.known_remote $argument $@

                                else
                                    gmsg -v3 -c yellow "not in any list"
                                    mount.remote $argument $@
                                fi

                            return $? ;;
        esac
}


mount.help () {
    gmsg -v1 -c white "guru-client mount help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL mount|unount|check|check-system <source> <target>"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " ls                       list of mounted folders "
    gmsg -v1 " check [target]           check that mount point is mounted "
    gmsg -v2 " check-system             check that guru system folder is mounted "
    gmsg -v1 " mount [source] [target]  mount folder in file server to local folder "
    gmsg -v1 " mount all                mount all known folders in server "
    gmsg -v2 "                          edit $GURU_CFG/$USER/user.cfg or run "
    gmsg -v2 "                          '$GURU_CALL config user' to setup default mountpoints "
    gmsg -v2 "                          more information of adding default mountpoint type: $GURU_CALL mount help-default"
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL mount /home/$GURU_CLOUD_USERNAME/share /home/$USER/guru/projects"
    gmsg -v1 "      $GURU_CALL umount /home/$USER/guru/projects"
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

    gmsg -v2 -n "checking system data folder.."
    if [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] ; then
            gmsg -v1 -c green "mounted "
        else
            gmsg -v1 -n "mounting.. "
            # gmsg -v3 -c deep_pink "${GURU_SYSTEM_MOUNT[1]} -> $GURU_SYSTEM_MOUNT"
            mount.remote "$GURU_SYSTEM_MOUNT" "${GURU_SYSTEM_MOUNT[1]}" \
                && gmsg -c green "ok"  \
                || gmsg -c yellow "error $?"
          fi
}


mount.online () {  # check if mountpoint "online", no printout, return code only
                   # input: mount point folder.
                   # usage: mount.online mount_point && echo "mounted" || echo "not mounted"

    local _target_folder="$1"
    gmsg -N -n -v3 -c pink "checking $_target_folder "
    if [[ -f "$_target_folder/.online" ]] ; then
        gmsg -v3 -c green "mounted"
        return 0
    else
        gmsg -v3 -c dark_grey "offline"
        return 1
    fi
}


mount.check () {  # check mountpoint is mounted, output status

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


mount.remote () {  # mount any remote location
    # usage: mount_point remote_folder optional: domain port symlink_to

    # set defaults
    local _target_folder=
    local _source_folder=
    local _source_server="$GURU_CLOUD_DOMAIN"
    local _source_port="$GURU_CLOUD_PORT"
    local _symlink=

    # temporary
    local _temp_folder="/tmp/guru/mount"
    local _reply=
    # to avoid read function to pass without input set force mode off
    unset FORCE

    [[ "$1" ]] && _target_folder="$1" || read -r -p "input target mount point: " _target_folder
    [[ "$2" ]] && _source_folder="$2" || read -r -p "input source folder at server: " _source_folder
    [[ "$3" ]] && _source_server="$3"
    [[ "$4" ]] && _source_port="$4"
    [[ "$5" ]] && _symlink="$5"

    # gmsg -v3 -c deep_pink "$FUNCNAME: $_source_folder|$_target_folder|$_source_server|$_source_port|$_temp_folder"
    # gmsg -c deep_pink "$_target_folder:$_source_folder:$_source_server:$_source_port:$_symlink:"

    gmsg -v2 -n "mounting "
    gmsg -v1 -n "$_target_folder.. "

    # check is already mounted
    if  [[ -f $_target_folder/.online ]] ; then
            gmsg -v1 -c green "mounted"
            return 0
        fi

    # double check is already mounted
    if grep "$_target_folder" /etc/mtab >/dev/null ; then
            gmsg -v1 -c green "mounted"
            return 0
        fi

    # check mount point exist, create if not
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

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p "$_source_port" "$GURU_CLOUD_USERNAME@$_source_server:$_source_folder" "$_target_folder"
    error=$?

    # copy files from temp if exist
    if [[ -d "$_temp_folder/${_target_folder##*/}" ]] ; then
            # new fucket up space dot --> if [[ -d "$_temp_folder" ]] ; then
            gmsg -c pink -v3 "cp $_temp_folder/${_target_folder##*/} > $_target_folder"
            cp -a "$_temp_folder/${_target_folder##*/}/." "$_target_folder" || gmsg -c yellow "failed to append/return files to $_target_folder, check also $_temp_folder"
            rm -rf "$_temp_folder" || gmsg -c yellow "failed to remote $_temp_folder"
        fi

    # if symlink given check if exist and create if not
    if [[ $_symlink ]] ; then
            gmsg -n -v1 "symlink "

            if file -h $_symlink | grep "symbolic" >/dev/null ; then
                    gmsg -n -v1 "exist "
                else
                    gmsg -n -v1 "creating.. "
                    ln -s $_target_folder $_symlink && error=0 || gmsg -x 25 -c yellow "error creating $_symlink"
                fi
        fi

    # check sshfs error
    if ((error>0)) ; then
            gmsg -c yellow "error $error when sshf"
            gmsg -v2 "check user cofiguration '$GURU_CALL config user'"

            ## check that is not listed in /etc/mtab
            if grep -wq $_target_folder /etc/mtab ; then
                    gmsg -c yellow "listed in mtab, not able to remove $_target_folder"
                    return 27
                fi

            # remove folder only if empty
            [[ -d "$_target_folder" ]] && rmdir "$_target_folder"
            return $error
        else
            [[ -f "$_target_folder/.online" ]] || touch "$_target_folder/.online"
            gmsg -v1 -c green "ok"
            return 0
        fi
}


mount.defaults () { # mount all GURU_CLOUD_* defined in userrc
                    # mount all local/cloud pairs defined in userrc
    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _mount_list=(${GURU_MOUNT_DEFAULT_LIST[@]^^})

    [[ ${_mount_list[@]} ]] || _mount_list=(${all_list[@]})

    if [[ $_mount_list ]] ; then
                gmsg -v3 -c light_blue "${_mount_list[@]}"
            else
                gmsg -c yellow "default mount list is empty, edit $GURU_CFG/$GURU_USER/user.cfg and then '$GURU_CALL config export'"
            return 1
        fi

    for _item in "${_mount_list[@]}" ; do
            # go trough of found variables
            _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
            _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            _symlink=$(eval echo '${GURU_MOUNT_'"${_item}[2]}")
            IFS=':' read -r _server _port _source_folder <<<"$_source"

            if ! [[ $_source_folder ]] ; then
                    _source_folder=$_source
                    _server=
                    _port=
                fi

            gmsg -v3 -c deep_pink "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote  "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done

    IFS="$_IFS"
    return $_error
}


mount.all () { # mount all GURU_CLOUD_* defined in userrc
                    # mount all local/cloud pairs defined in userrc
    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _mount_list=(${all_list[@]^^})

    if [[ $_mount_list ]] ; then
                gmsg -v3 -c light_blue "${_mount_list[@]}"
            else
                gmsg -c yellow "default mount list is empty, edit $GURU_CFG/$GURU_USER/user.cfg and then '$GURU_CALL config export'"
            return 1
        fi

    for _item in "${_mount_list[@]}" ; do
            # go trough of found variables
            _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
            _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            _symlink=$(eval echo '${GURU_MOUNT_'"${_item}[2]}")
            IFS=':' read -r _server _port _source_folder <<<"$_source"

            if ! [[ $_source_folder ]] ; then
                    _source_folder=$_source
                    _server=
                    _port=
                fi

            # gmsg -v3 -c deep_pink "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done

    IFS="$_IFS"
    return $_error
}




mount.known_remote () { # mount single GURU_CLOUD_* defined in userrc

    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    local _source=$(eval echo '${GURU_MOUNT_'"${1^^}[1]}")
    local _symlink=$(eval echo '${GURU_MOUNT_'"${1^^}[2]}")
    local _IFS=$IFS
    IFS=':' read -r _server _port _source_folder <<<"$_source"
    #GURU_VERBOSE=3
    # gmsg -v3 -c deep_pink "$FUNCNAME: $_source_folder|$_target|$_server|$_port"

    if ! [[ $_source_folder ]] ; then
            _source_folder=$_source
            _server=
            _port=
        fi

    # gmsg -v3 -c deep_pink "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
    mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
    IFS=$_IFS
    return $?
}


mount.install () {  # install and remove install applications. input "install" or "remove"
    local action="$1"
    [[ "$action" ]] || read -r -p "install or remove? " action
    local require="ssh rsync"
    gmsg "Need to install $require, ctrl+c? or input local "
    sudo apt update && eval sudo apt "$action" "$require" && gmsg "guru is now ready to mount"
    return 0
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
        source "$GURU_RC"
        mount.main "$@"
        exit "$?"
    fi
