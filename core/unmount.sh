#!/bin/bash
# unmount tools for grbl

source common.sh

# TBD fix this
temp_rc="/tmp/$USER/mount.rc"
source config.sh
config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $temp_rc
chmod +x $temp_rc
source $temp_rc

all_list=($(\
        grep "export GRBL_MOUNT_" $temp_rc | \
        grep -ve '_LIST' -ve '_ENABLED' -ve '_PROXY' -ve '_INDICATOR_KEY' | \
        grep -v "GRBL_MOUNT_SYSTEM" | \
        sed 's/^.*MOUNT_//' | \
        cut -d '=' -f1))
all_list=(${all_list[@],,})

_default_list=($(\
        cat $temp_rc | \
        grep 'GRBL_MOUNT_' | \
        grep -v "PROXY1_" | \
        grep -v "ENABLED" | \
        grep -v "GRBL_MOUNT_SYSTEM" | \
        grep -v "LIST" | \
        grep -v '$GRBL_MOUNT' | \
        grep -v 'INDICATOR_KEY' | \
        sed 's/^.*MOUNT_//' | \
        cut -d '=' -f1))

rm $temp_rc

unmount.main () {
# mount command parser

    mounted_list=($(unmount.ls))

    indicator_key='f'"$(gr.poll mount)"
    local argument="$1" ; shift

    case "$argument" in

        all)
            gr.end $GRBL_MOUNT_INDICATOR_KEY
            unmount.all
            # mount.status quiet
            ;;

        ls|defaults|status|help|status)
            unmount.$argument $@
            return $?
            ;;
       "")
            gr.end $GRBL_MOUNT_INDICATOR_KEY
            unmount.defaults
            # mount.status quiet
            return $?
            ;;
       *)

            gr.end $GRBL_MOUNT_INDICATOR_KEY
            if echo ${GRBL_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$argument" ; then
                gr.msg -v3 -c green "found in defauls list"
                unmount.known_remote $argument $@

            elif echo ${all_list[@]} | grep -q -w "$argument" ; then
                gr.msg -v3 -c green "found in all list"
                unmount.known_remote $argument $@

            # check is there list named as user input
            elif [[ $(eval echo '${GRBL_MOUNT_'${argument^^}'_LIST[@]^^}') ]]; then
                unmount.listed $command

            elif echo ${mounted_list[@]} | grep -q -w "$argument" ; then
                gr.msg -v3 -c green "found mounted list"

                local val=
                for val in ${mounted_list[@]}; do
                   if echo $val | grep -q -w $argument ; then
                        # gr.msg -v3 -c yellow "mountpoint: $val"
                        unmount.remote $mount_point $val
                    fi
                done

            else
                gr.debug "trying to mount location defined in other module configuration"
                unmount.known_remote $argument $@
            fi
            source mount.sh
            # mount.status quiet
    esac
}


unmount.status () {
# daemon status function

    # printout header for status output
    gr.msg -t -v1 -n "${FUNCNAME[0]}: "
    local _target
    local _private=

    # check is enabled
    if [[ $GRBL_MOUNT_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled " -k $GRBL_MOUNT_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled" -k $GRBL_MOUNT_INDICATOR_KEY
            return 100
        fi

    # go trough mount points
    for _mount_point in ${all_list[@]} ; do
            _target=$(eval echo '${GRBL_MOUNT_'"${_mount_point^^}[0]}")
            mount.check $_target &&
                case $_target in \
                    *'/.'*)  _private=true
                            ;;
                    esac
        done

    # serve enter
    [[ $_private ]] \
        && gr.msg -c deep_pink -k $GRBL_MOUNT_INDICATOR_KEY \
        || gr.msg -c aqua -k $GRBL_MOUNT_INDICATOR_KEY

    return 0
}


unmount.help () {
    gr.msg -v1 -c white "grbl unmount help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL unmount <mount_point(s)>|defaults|all"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " ls               list of mounted folders "
    gr.msg -v1 " <mount_point>    unmount mount point "
    gr.msg -v1 " mp1 mp2 mp3      unmount varies known mountpoints set in user config "
    gr.msg -v1 " defaults         unmount default mount points set in user config "
    gr.msg -v1 " all              unmount all mounted (exept /grbl/.data) "
    gr.msg -v1 " system           unmount /grbl/.data "
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GRBL_CALL umount /home/$USER/grbl/projects "
    gr.msg -v1 "      $GRBL_CALL umount projects "
    gr.msg -v1 "      $GRBL_CALL umount defaults "
}


unmount.ls () {
# simple list of mounted mountpoints
    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


unmount.system () {
# unmount system data
    local system_indicator_key="f$(gr.poll system)"

    gr.msg -v2 -n "checking system data folder.."
    if ! [[ -f "$GRBL_SYSTEM_MOUNT/.online" ]] ; then
            gr.msg -c red "not mounted " -k $system_indicator_key
        else
            gr.msg -v2 -n "unmounting.. "
            gr.msg -v3 -c deep_pink "${GRBL_SYSTEM_MOUNT[1]} -> $GRBL_SYSTEM_MOUNT"
            unmount.remote "$GRBL_SYSTEM_MOUNT" \
                && gr.msg -v2 -c red ".data folder unmounted, grbl is unstable" -k $system_indicator_key \
                || gr.msg -c yellow "error $?" -k $system_indicator_key
          fi
}


unmount.online () {
# check if mountpoint "online", no printout, return code only input: mount point folder. usage: mount.online mount_point && echo "mounted" || echo "not mounted"

    local _target_folder="$GRBL_SYSTEM_MOUNT"
    [[ "$1" ]] && _target_folder="$1"

    if [[ -f "$_target_folder/.online" ]] ; then
        return 0
    else
        return 1
    fi
}

unmount.remote () {
# unmount single mount point name given as argument

    local _mountpoint="$1"
    local _numbers='^[0-9]+$'
    local _symlink=
    local _i=0

    if ! [[ "$_mountpoint" ]] ; then

            local _list=($(unmount.ls | grep -v $GRBL_SYSTEM_MOUNT))
            for item in "${_list[@]}" ; do
                gr.msg -n -c white "$_i: "
                gr.msg -c light_blue "${_list[_i]}"
                let _i++
            done
            let _i--

            (( $_i < 1 )) && return 0
            read -p "select mount point (0..$_i) " _ii

            [[ $_ii ]] || return 0

            if [[ $_ii =~ $_numbers ]] && (( _ii <= _i )) && (( _ii >= 0 ))  ; then
                    _mountpoint=${_list[_ii]}
                else
                    gr.msg -c yellow "invalid selection"
                    return 12
                fi
        fi

    local _mount_name=${_mountpoint##*/}

    # empty
    gr.msg -n -v2 "unmounting "
    gr.msg -n -v1 "$_mount_name "

    # check is mounted
    if ! grep -wq "$_mountpoint" /etc/mtab ; then
            gr.msg -v1 -c dark_gray "not mounted"
            return 0
        fi

    if ! [[ -f "$_mountpoint/.online" ]] ; then
            gr.msg -n -v2 -c yellow "online flag file missing "
         fi

    # unmount target (normal action)
    if ! fusermount -u "$_mountpoint" 2>/dev/null; then
            gr.msg -v3 -c yellow "error $? "
        fi

    # check is target unmounted
    if ! unmount.online "$_mountpoint" ; then
            gr.msg -v1 -c green "done"
            rmdir $_mountpoint
            return 0
        fi

    if ! [[ $GRBL_FORCE ]] ; then
            gr.msg -c yellow "device busy"
            return 0
        fi

    gr.msg -n -v1 -c white "force unmount "

    # force unmount
    if unmount.kill "$_mountpoint" ; then
            gr.msg -v1 -c green "done"
            rmdir $_mountpoint
            return 0
        else
            gr.msg -c red "failed to force unmount $_mount_name "
            return 124
        fi
}


unmount.listed () {
# unmount all local/cloud pairs defined in userrc

    local list_name=$1
    local _error=()
    local _unmount_list=($(eval echo '${GRBL_MOUNT_'${list_name^^}'_LIST[@]^^}'))

    if [[ $_unmount_list ]] ; then
        # gr.debug "$FUNCNAME: _unmount_list: ${_unmount_list[@]}"
        true
    else
        gr.msg -e0 "$FUNCNAME: no list"
        return 1
    fi

    for _item in "${_unmount_list[@]}" ; do
        _target=$(eval echo '${GRBL_MOUNT_'"${_item}[0]}")
        if ! [[ $_target ]] ; then
            gr.msg -e0 "<empty>"
        fi
        unmount.remote "$_target" || _error+=$?
    done

    return ${_error[0]}
}

unmount.defaults () {
# unmount all local/cloud pairs defined in userrc

    local _unmount_list=(${GRBL_MOUNT_DEFAULT_LIST[@]^^})

    [[ "$1" ]] && _unmount_list=(${1[@]})

    if [[ $_unmount_list ]] ; then
            gr.msg -v3 -c light_blue "$_unmount_list"
        else
            gr.msg -c yellow "default list is empty"
            return 1
        fi

    for _item in "${_unmount_list[@]}" ; do
        # go trough of found variables
        _target=$(eval echo '${GRBL_MOUNT_'"${_item}[0]}")
        # gr.msg -v3 -c pink "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    return $_error
}


unmount.kill () {
# Kill single mount process by mount_name or mount_point

    if ! [[ $1 ]] ; then
            gr.msg -c yellow "enter mount_name"
            return 2
        fi

    local _mount_name="$1"
    local _find=

    # Check is given string in mountable list
    if grep -q $_mount_name <<<${all_list[@]} ; then
            _find=$(eval echo '${GRBL_MOUNT_'"${_mount_name^^}}")
        fi

    # Check is given string mount_point
    if [[ -d $_mount_name ]] ; then
            _find=$_mount_name
        fi

    # Debug
    gr.msg -v3 -c pink "m:$_mount_name|f:$_find|p:$_pid|a:${all_list[@]}"

    # Exit if nothing to find
    if ! [[ $_find ]] ; then
            gr.msg -c yellow "mount name '$_mount_name' not recognized"
            return 3
        fi

    # Find pid of mount_name or mount_point
    local _pid=$(ps auxf \
        | grep -v grep \
        | grep sshfs \
        | grep "$_find" \
        | sed -e 's/  */ /g'  \
        | cut -d' ' -f2 \
        | head -n1)

    gr.msg -v3 -c pink "p:$_pid"

    if ! [[ $_pid ]] ; then
    # Find it but not find pid
            gr.msg -c yellow "'$_mount_name' not mounted"
            return 3
        fi

    # Kill the pid and exit
    gr.msg -v2 "killing $_pid.. "
    kill $_pid
    local _error=$?

    # Check errors
    if [[ $_error -lt 1 ]] ; then
            gr.msg -v1 -c green "killed"
            return 0
        else
            gr.msg -v1 -c yellow "error $?"
            return $_error
        fi
}



unmount.all () {
# unmount all GRBL_CLOUD_* defined in userrc
# unmount all local/cloud pairs defined in userrc
    # TBD this is terrible method to parse configs, figure some other way

    #[[ $1 ]] && _default_list=(${@})
    [[ "$1" ]] && _default_list=(${1[@]})

    if [[ $_default_list ]] ; then
            gr.msg -v3 -c light_blue "$_default_list"
        else
            gr.msg -c yellow "default list is empty"
            return 1
        fi

    for _item in "${_default_list[@]}" ; do
        # go trough of found variables
        _target=$(eval echo '${GRBL_MOUNT_'"${_item}[0]}")
        gr.msg -v3 -c pink "$FUNCNAME: ${_item,,} "
        unmount.remote "$_target" || _error=$?
    done

    if [[ $_error -lt 1 ]] ; then
        gr.msg -c green "unmounted" -k $indicator_key
    else
        gr.msg -c red "error: $_error" -k $indicator_key
        return $_error
    fi
}


unmount.known_remote () { # unmount single GRBL_CLOUD_* defined in userrc

    local _target=$(eval echo '${GRBL_MOUNT_'"${1^^}[0]}")
    gr.msg -v3 -c pink "$FUNCNAME: ${_item,,} $_target"
    unmount.remote "$_target"
    return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # if sourced only import functions
        #source "$GRBL_RC"
        unmount.main "$@"
        exit "$?"
    fi
