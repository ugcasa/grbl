#!/bin/bash
# unmount tools for guru-client
#source "$HOME/.gururc"


#### TBD 1) figure out how to minimalize unmount.sh
#### TBD 2) remove this and integrate functions to mount.sh


source $GURU_BIN/common.sh

unmount.main () {
    # mount command parser

    mounted_list=($(unmount.ls))

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

        ls|all|defaults|status|help|system)
            unmount.$argument $@    ; return $? ;;
       "")  unmount.defaults        ; return $? ;;
       *)
            if echo ${GURU_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$argument" ; then
                    gmsg -v3 -c green "found in defauls list"
                    unmount.known_remote $argument $@

                elif echo ${all_list[@]} | grep -q -w "$argument" ; then
                    gmsg -v3 -c green "found in all list"
                    unmount.known_remote $argument $@

                elif echo ${mounted_list[@]} | grep -q -w "$argument" ; then
                    gmsg -v3 -c green "found mounted list"

                    local val=
                    for val in ${mounted_list[@]}; do
                       if echo $val | grep -q -w $argument ; then
                            gmsg -v3 -c yellow "mountpoint: $val"
                            unmount.remote $mount_point $val
                        fi
                    done

                else
                    gmsg -v3 -c yellow "not in any list"
                    unmount.remote $argument $@
                fi

                mount.status >/dev/null
    esac
}


unmount.help () {
    gmsg -v1 -c white "guru-client unmount help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL unmount <mount_point(s)>|defaults|all"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " ls               list of mounted folders "
    gmsg -v1 " <mount_point>    unmount mount point "
    gmsg -v1 " mp1 mp2 mp3      unmount varies known mountpoints set in user config "
    gmsg -v1 " defaults         unmount default mount points set in user config "
    gmsg -v1 " all              unmount all mounted (exept /guru/.data) "
    gmsg -v1 " system           unmount /guru/.data "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL umount /home/$USER/guru/projects "
    gmsg -v1 "      $GURU_CALL umount projects "
    gmsg -v1 "      $GURU_CALL umount defaults "
}


unmount.ls () {
    # simple list of mounted mountpoints
    local list=$(mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)')
    gmsg -c light_blue "$list"
    return $?
}


unmount.system () {
    # unmount system data
    local system_indicator_key="f$(daemon.poll_order system)"

    gmsg -v2 -n "checking system data folder.."
    if ! [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] ; then
            gmsg -c red "not mounted " -k $system_indicator_key
        else
            gmsg -v2 -n "unmounting.. "
            gmsg -v3 -c deep_pink "${GURU_SYSTEM_MOUNT[1]} -> $GURU_SYSTEM_MOUNT"
            unmount.remote "$GURU_SYSTEM_MOUNT" \
                && gmsg -v2 -c red ".data forlder unmounted, guru is unstable" -k $system_indicator_key \
                || gmsg -c yellow "error $?" -k $system_indicator_key
          fi
}


unmount.remote () {  # unmount mount point
    source mount.sh
    local _mountpoint="$1"
    local _numbers='^[0-9]+$'
    local _symlink=
    local _i=0

    if ! [[ "$_mountpoint" ]] ; then

            local _list=($(unmount.ls | grep -v $GURU_SYSTEM_MOUNT))
            for item in "${_list[@]}" ; do
                gmsg -n -c white "$_i: "
                gmsg -c light_blue "${_list[_i]}"
                let _i++
            done
            let _i--

            (( $_i < 1 )) && return 0
            read -p "select mount point (0..$_i) " _ii

            [[ $_ii ]] || return 0

            if [[ $_ii =~ $_numbers ]] && (( _ii <= _i )) && (( _ii >= 0 ))  ; then
                    _mountpoint=${_list[_ii]}
                else
                    gmsg -c yellow "invalid selection"
                    return 12
                fi
        fi

    # empty
    gmsg -n -v2 "unmounting "
    gmsg -n -v1 "$_mountpoint.. "

    # check is mounted
    if ! grep -wq "$_mountpoint" /etc/mtab ; then
            gmsg -v1 -c dark_gray "is not mounted"
            return 0
        fi

    if ! [[ -f "$_mountpoint/.online" ]] ; then
            gmsg -n -v2 -c yellow ".online flag file missing "
         fi

    # unmount (normal)
    if ! fusermount -u "$_mountpoint" ; then
            gmsg -v2 -c yellow "error $? "
        fi

    if ! mount.online "$_mountpoint" ; then
            gmsg -v1 -c green "ok"
            rmdir $_mountpoint
            return 0
        fi

    gmsg -n -v1 "trying to force unmount.. "

    if sudo umount -l "$_mountpoint" ; then
            gmsg -v1 -c green "ok"
            rmdir $_mountpoint
            return 0
        else
            gmsg -c red "failed to force unmount"
            gmsg -v1 -c white "seems that some of open program like terminal or editor is blocking unmount, try to close those first"
            return 124
        fi
}


unmount.defaults () {  # unmount all GURU_CLOUD_* defined in userrc
                       # unmount all local/cloud pairs defined in userrc

    local _unmount_list=(${GURU_MOUNT_DEFAULT_LIST[@]^^})

    # fill default list if not set in user configuration
    # [[ $_unmount_list ]] || _unmount_list=($(\
    #         cat $GURU_RC | \
    #         grep 'GURU_MOUNT_' | \
    #         grep -v "DEFAULT_LIST" | \
    #         sed 's/^.*MOUNT_//' | \
    #         cut -d '=' -f1))

    [[ "$1" ]] && _unmount_list=(${1[@]})

    if [[ $_unmount_list ]] ; then
            gmsg -v3 -c light_blue "$_unmount_list"
        else
            gmsg -c yellow "default list is empty"
            return 1
        fi

    for _item in "${_unmount_list[@]}" ; do
        # go trough of found variables
        _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
        # gmsg -v3 -c pink "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    return $_error

}


unmount.all () {  # unmount all GURU_CLOUD_* defined in userrc
    # unmount all local/cloud pairs defined in userrc

    local _default_list=($(\
            cat $GURU_RC | \
            grep 'GURU_MOUNT_' | \
            grep -v "DEFAULT_LIST" | \
            grep -v '$GURU_MOUNT' | \
            sed 's/^.*MOUNT_//' | \
            cut -d '=' -f1))

    [[ "$1" ]] && _default_list=(${1[@]})

    if [[ $_default_list ]] ; then
            gmsg -v3 -c light_blue "$_default_list"
        else
            gmsg -c yellow "default list is empty"
            return 1
        fi

    for _item in "${_default_list[@]}" ; do
        # go trough of found variables
        _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
        gmsg -v3 -c pink "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    return $_error
}


unmount.known_remote () { # unmount single GURU_CLOUD_* defined in userrc

    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    gmsg -v3 -c pink "$FUNCNAME: ${_item,,} $_target"
    unmount.remote "$_target"
    return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # if sourced only import functions
        source "$GURU_RC"
        unmount.main "$@"
        exit "$?"
    fi
