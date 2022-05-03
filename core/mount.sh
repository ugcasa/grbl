#!/bin/bash
# mount tools for guru-client
#source "$HOME/.gururc"
source $GURU_BIN/common.sh

all_list=($(\
        grep "export GURU_MOUNT_" $GURU_RC | \
        grep -ve "_LIST" -ve "_ENABLED" | \
        sed 's/^.*MOUNT_//' | \
        cut -d '=' -f1))

all_list=(${all_list[@],,})

mount_indicator_key='f'"$(gr.poll mount)"

mount.main () {
    # mount command parser

    local command="$1" ; shift

    case "$command" in

            defaults|system|all|help|ls|info|check|\
            poll|status|start|stop|toggle|list|kill)

                            mount.$command $@
                            return $? ;;

            check-system)   mount.check "$GURU_SYSTEM_MOUNT"
                            return $? ;;

                      "")   mount.list default
                            return $? ;;
                       # TBD this is bullshit
                       *)   if echo ${GURU_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$command" ; then
                                    gr.msg -v4 -c pink "found in defauls list"
                                    mount.known_remote $command $@

                                elif echo ${all_list[@]} | grep -q -w "$command" ; then
                                    gr.msg -v4 -c pink "found in all list"
                                    mount.known_remote $command $@

                                else
                                    gr.msg -v4 -c pink "not in any list"
                                    mount.remote $command $@
                                fi
                            mount.status >/dev/null
                            return $? ;;
        esac
}


mount.help () {
    # general help

    gr.msg -v1 -c white "guru-client mount help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL mount|unount|check|check-system <source> <target>"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " ls                         list of mounted folders "
    gr.msg -v1 " check mount_name           check that mount point is mounted "
    gr.msg -v2 " check-system               check that guru system folder is mounted "
    gr.msg -v1 " mount mount_name           mount folder in file server to local folder "
    gr.msg -v1 " mount all                  mount all known folders in server "
    gr.msg -v1 " mount kill mount_name      kill mount process "
    gr.msg -v2 "                            edit $GURU_CFG/$USER/user.cfg or run "
    gr.msg -v2 "                            '$GURU_CALL config user' to setup default mountpoints "
    gr.msg -v3 " poll start|end             start or end module status polling "
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GURU_CALL mount /home/$GURU_CLOUD_USERNAME/share /home/$USER/guru/projects"
    gr.msg -v1 "      $GURU_CALL umount /home/$USER/guru/projects"
}


mount.info () {
    # detailed list of mounted mountpoints. nice list of information of sshfs mount points

    local _error=0
    # header (stdout if verbose rised)
    gr.msg -v2 -c white "user@server remote_folder local_mountpoint  uptime pid"
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |

    # get the mount data
    while read mount ; do
        # iterate over them
        mount | grep -w "$mount" |
        # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GURU_USER'\@$1 $2 $3"'
        # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?

        local _mount_pid="$(pgrep -f $mount \
                        | head -1)"

        local _mount_age="$(ps -p $_mount_pid o etime \
                        | grep -v ELAPSED \
                        | xargs)"

        echo " $_mount_age $_mount_pid"

    done

    ((_error>0)) && gr.msg -c yellow "perl not installed or internal error, pls try to install perl and try again."
    return $_error
}


mount.ls () {
    # simple list of mounted mountpoints

    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}


mount.system () {
    # mount system data

    gr.msg -v3 -n "checking system data folder.."
    if [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] ; then
            gr.msg -v3 -c green "mounted "
        else
            gr.msg -v3 -n "mounting.. "
            # gr.msg -v3 -c deep_pink "${GURU_SYSTEM_MOUNT[1]} -> $GURU_SYSTEM_MOUNT"
            mount.remote "$GURU_SYSTEM_MOUNT" "${GURU_SYSTEM_MOUNT[1]}" \
                && gr.msg -v3 -c green "ok"  \
                || gr.msg -v3 -c yellow "error $?"
          fi
}


mount.online () {
    # check if mountpoint "online", no printout, return code only input: mount point folder. usage: mount.online mount_point && echo "mounted" || echo "not mounted"

    local _target_folder="$GURU_SYSTEM_MOUNT"
    [[ "$1" ]] && _target_folder="$1"

    if [[ -f "$_target_folder/.online" ]] ; then
        return 0
    else
        return 1
    fi
}


mount.check () {
    # check mountpoint is mounted, output status

    local _err=0
    local _target_folder=$GURU_SYSTEM_MOUNT
    [[ "$1" ]] && _target_folder="$1"

    gr.msg -n -v1 -V2 -c light_blue "${_target_folder##*/} "
    gr.msg -n -v2 -c light_blue "$_target_folder "

    mount.online $_target_folder
    _err=$?

    if [[ $_err -gt 0 ]] ; then
            gr.msg -v2 -c dark_grey "not mounted"
            return 1
        fi

    # colors
    case $_target_folder in
        *'.data'*)  gr.msg -v2 -c cadet_blue "system"
                    ;;
            *'.'*)  gr.msg -v2 -c deep_pink "private"
                    ;;
                *)  gr.msg -v2 -c green "available"
                    ;;
                esac
    return 0
}


mount.remote () {
    # mount any remote location. usage: mount_point remote_folder optional: domain port symlink_to

    # set defaults
    local _target_folder=
    local _source_folder=
    local _source_server=$GURU_CLOUD_DOMAIN
    local _source_port=$GURU_CLOUD_PORT
    local _symlink=

    # temporary
    local _temp_folder="/tmp/guru/mount"
    local _reply=
    # to avoid read function to pass without input set force mode off
    unset FORCE

    [[ "$1" ]] && _target_folder="$1" || read -r -p "local target mount point: " _target_folder
    [[ "$2" ]] && _source_folder="$2" || read -r -p "source folder at server: " _source_folder
    [[ "$3" ]] && _source_server="$3"
    [[ "$4" ]] && _source_port="$4"
    [[ "$5" ]] && _symlink="$5"

    gr.msg -v1 -n "$_target_folder.. "


    # double check is in /etc/mtab  already mounted and .online file exists
    if [[ -f $_target_folder/.online ]] && grep -qw "$_target_folder" /etc/mtab ; then #>/dev/null
            gr.msg -v1 -c green "mounted"
            return 0
        fi

    # check mount point exist, create if not
    if ! [[ -d "$_target_folder" ]] ; then
            mkdir -p "$_target_folder"
        fi

    # check is target populated and append if is
    if ! [[ -z "$(ls -A $_target_folder)" ]] ; then
            # Check that targed directory is empty
            gr.msg -c yellow "target folder is not empty!"

            if ! [[ $GURU_FORCE ]] ; then
                    gr.msg -v2 -c white "try '-f' to force or: '$GURU_CALL -f mount $_source_folder $_target_folder"
                    return 25
                fi

            # move found files to temp
            gr.msg -c light_blue "$(ls $_target_folder)"
            read -r -p "append above files to $_target_folder?: " _reply

            case $_reply in
                y)
                    [[ -d $_temp_folder ]] && rm -rf "$_temp_folder"
                    gr.msg -c pink -v3 "mv $_target_folder -> $_temp_folder"
                    mkdir -p "$_temp_folder"
                    mv "$_target_folder" "$_temp_folder"
                    ;;
                *)  gr.msg -c red "unable to mount $_target_folder is populated"
                    return 26
                esac
        fi

    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
          -p "$_source_port" \
          "$GURU_CLOUD_USERNAME@$_source_server:$_source_folder" \
          "$_target_folder"

    error=$?

    # copy files from temp if exist
    if [[ -d "$_temp_folder/${_target_folder##*/}" ]] ; then
            # new fucket up space dot --> if [[ -d "$_temp_folder" ]] ; then
            gr.msg -c pink -v3 "cp $_temp_folder/${_target_folder##*/} > $_target_folder"

            cp -a "$_temp_folder/${_target_folder##*/}/." "$_target_folder" \
                || gr.msg -c yellow "failed to append/return files to $_target_folder, check also $_temp_folder"

            rm -rf "$_temp_folder" \
                || gr.msg -c yellow "failed to remote $_temp_folder"
        fi

    # if symlink given check if exist and create if not
    if [[ $_symlink ]] ; then
            gr.msg -n -v1 "symlink "

            if file -h $_symlink | grep "symbolic" >/dev/null ; then
                    gr.msg -n -v1 "exist "
                else
                    gr.msg -n -v1 "creating.. "
                    ln -s $_target_folder $_symlink && error=0 \
                        || gr.msg -x 25 -c yellow "error creating $_symlink"
                fi
        fi

    # check sshfs error
    if ((error>0)) ; then
            gr.msg -c yellow "error $error when sshf"
            gr.msg -v2 "check user cofiguration '$GURU_CALL config user'"

            ## check that is not listed in /etc/mtab
            if grep -wq $_target_folder /etc/mtab ; then
                    gr.msg -c yellow "listed in mtab, not able to remove $_target_folder"
                    return 27
                fi

            # remove folder only if empty
            [[ -d "$_target_folder" ]] && rmdir "$_target_folder"
            return $error
        else
            [[ -f "$_target_folder/.online" ]] || touch "$_target_folder/.online"
            gr.msg -v1 -c green "ok"
            return 0
        fi
}


mount.list () {
    # mount all GURU_MOUNT_<list_name>_LIST defined in userrc

    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _list_name="default" ; [[ $1 ]] && _list_name=$1

    #local _mount_list=(${GURU_MOUNT_DEFAULT_LIST[@]^^})
    local _mount_list=$(eval echo '${GURU_MOUNT_'"${_list_name^^}_LIST[@]^^}")

    [[ ${_mount_list[@]} ]] || _mount_list=(${all_list[@]})

    if [[ ${_mount_list} ]] ; then
                gr.msg -v3 -c light_blue "${_mount_list[@]}"
            else
                gr.msg -c yellow "default mount list is empty, edit $GURU_CFG/$GURU_USER/user.cfg and then '$GURU_CALL config export'"
            return 1
        fi

    #gr.msg -v2 -c white "mounted: "
    for _item in ${_mount_list[@]} ; do
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

            gr.msg -v3 -c deep_pink "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done
    mount.status >/dev/null
    IFS="$_IFS"

    # gr.msg -v2 -n -c white "available: "
    # gr.msg -v1 -c light_blue "${all_list[@]}"

    return $_error
}


mount.all () {
    # mount all GURU_CLOUD_* defined in userrc

    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _mount_list=(${all_list[@]^^})

    if [[ $_mount_list ]] ; then
                gr.msg -v3 -c light_blue "${_mount_list[@]}"
            else
                gr.msg -c yellow "default mount list is empty, edit $GURU_CFG/$GURU_USER/user.cfg and then '$GURU_CALL config export'"
            return 1
        fi

    for _item in "${_mount_list[@]}" ; do
            # go trough of found variables
            _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
            _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            _symlink=$(eval echo '${GURU_MOUNT_'"${_item}[2]}")
            IFS=':' read -r _server _port _source_folder <<<"$_source"
            IFS="$_IFS"

            if ! [[ $_source_folder ]] ; then
                    _source_folder=$_source
                    _server=
                    _port=
                fi

            gr.msg -v3 -c deep_pink "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done

    #mount.status >/dev/null
    return $_error
}

mount.known_remote () {
    # mount single GURU_CLOUD_* defined in userrc

    local _target=$(eval echo '${GURU_MOUNT_'"${1^^}[0]}")
    local _source=$(eval echo '${GURU_MOUNT_'"${1^^}[1]}")
    local _symlink=$(eval echo '${GURU_MOUNT_'"${1^^}[2]}")
    local _IFS=$IFS
    IFS=':' read -r _server _port _source_folder <<<"$_source"

    if ! [[ $_source_folder ]] ; then
            _source_folder=$_source
            _server=
            _port=
        fi
    mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
    IFS=$_IFS
    return $?
}


mount.status () {
    # daemon status function

    # printout header for status output
    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    # check is enabled
    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
            gr.msg -v1 -n -c green "available " -k $mount_indicator_key
            gr.msg -v2
        else
            #gr.msg -v1 -c reset "disabled" -k $mount_indicator_key
            gr.msg -v1 -c red "unavailable" -k $mount_indicator_key
            return 100
        fi

    # printout list of mountponts
    local mount_list=($(mount.ls))

    for _mount_point in ${mount_list[@]} ; do
            mount.check $_mount_point
        done

    # serve enter
    gr.msg -v1 -V2

    # serve indication
    if [[ ${#mount_list[@]} -gt 1 ]] ; then
            gr.msg -v4 -c aqua -k $mount_indicator_key
        fi

    # indicate personal mount locations
    local sripped=("${mount_list[@]/$GURU_SYSTEM_MOUNT}")
    for _mount_point in ${sripped[@]} ; do
            case $_mount_point in
                *'/.'*)  gr.msg -v4 -c deep_pink -k $mount_indicator_key
                esac
        done
    return 0
}


mount.toggle () {
    # unmount all or mount defaults by pressing key

    local _list=($(mount.ls))

    if  [[ ${#_list[@]} -gt 1 ]] ; then
            unmount.all
        else
            mount.list default
        fi
    return 0
}


mount.poll () {
    # daemon poll api

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: mount status polling started" -k $mount_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: mount status polling ended" -k $mount_indicator_key
            ;;
        status )
            mount.status $@
            ;;
        *)  mount.help
            ;;
        esac
}


mount.kill () {
    # Kill single mount process by mount_name or mount_point
    source mount.sh
    source common.sh

    if ! [[ $1 ]] ; then
            gr.msg -c yellow "enter mount_name"
            return 2
        fi

    local _mount_name="$1"
    local _find=

    # Check is given string in mountable list
    if grep -q $_mount_name <<<${all_list[@]} ; then
            _find=$(eval echo '${GURU_MOUNT_'"${_mount_name^^}}")
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




mount.install () {
    # install and remove install applications. input "install" or "remove"

    if sudo apt update && eval sudo apt install "ssh rsync" ; then
            gr.msg -c green "guru is now ready to mount"
            return 0
        else
            gr.msg -c yellow "error during isntallation $?"
            return 100
    fi
}


mount.remove () {
    # install and remove install applications. input "install" or "remove"

    gr.msg "wont remove 'ssh' or 'rsync', do it manually if really needed"
    return 0
}


# unmount.remote () {  # unmount mount point

#     local _mountpoint="$1"
#     local _numbers='^[0-9]+$'
#     local _symlink=
#     local _i=0

#     if ! [[ "$_mountpoint" ]] ; then

#             local _list=($(unmount.ls | grep -v $GURU_SYSTEM_MOUNT))
#             for item in "${_list[@]}" ; do
#                 gr.msg -n -c white "$_i: "
#                 gr.msg -c light_blue "${_list[_i]}"
#                 let _i++
#             done
#             let _i--

#             (( $_i < 1 )) && return 0
#             read -p "select mount point (0..$_i) " _ii

#             [[ $_ii ]] || return 0

#             if [[ $_ii =~ $_numbers ]] && (( _ii <= _i )) && (( _ii >= 0 ))  ; then
#                     _mountpoint=${_list[_ii]}
#                 else
#                     gr.msg -c yellow "invalid selection"
#                     return 12
#                 fi
#         fi

#     # empty
#     gr.msg -n -v2 "unmounting "
#     gr.msg -n -v1 "$_mountpoint.. "

#     # check is mounted
#     if ! grep -wq "$_mountpoint" /etc/mtab ; then
#             gr.msg -v1 -c dark_gray "is not mounted"
#             return 0
#         fi

#     if ! [[ -f "$_mountpoint/.online" ]] ; then
#             gr.msg -n -v2 -c yellow ".online flag file missing "
#          fi

#     # unmount (normal)
#     if ! fusermount -u "$_mountpoint" ; then
#             gr.msg -v2 -c yellow "error $? "
#         fi

#     if ! mount.online "$_mountpoint" ; then
#             gr.msg -v1 -c green "ok"
#             rmdir $_mountpoint
#             return 0
#         fi

#     gr.msg -n -v1 "trying to force unmount.. "

#     if sudo umount -l "$_mountpoint" ; then
#             gr.msg -v1 -c green "ok"
#             rmdir $_mountpoint
#             return 0
#         else
#             gr.msg -c red "failed to force unmount"
#             gr.msg -v1 -c white "seems that some of open program like terminal or editor is blocking unmount, try to close those first"
#             return 124
#         fi
# }



# unmount.all () {  # unmount all GURU_CLOUD_* defined in userrc
#     # unmount all local/cloud pairs defined in userrc

#     local _default_list=

#     if [[ "$1" ]] ; then
#             _default_list=(${1[@]})
#         else
#             _default_list=($(\
#                 cat $GURU_RC | \
#                 grep 'GURU_MOUNT_' | \
#                 grep -v '$GURU_' | \
#                 grep -v "LIST" | \
#                 sed 's/^.*MOUNT_//' | \
#                 cut -d '=' -f1))
#         fi

#     if [[ $_default_list ]] ; then
#             gr.msg -v3 -c light_blue "$_default_list"
#         else
#             gr.msg -c yellow "default list is empty"
#             return 1
#         fi

#     for _item in "${_default_list[@]}" ; do
#             # go trough of found variables
#             _target=$(eval echo '${GURU_MOUNT_'"${_item}[0]}")
#             gr.msg -v3 -c pink "$FUNCNAME: ${_item,,} "
#             source unmount.sh
#             unmount.remote "$_target" || _error=$?
#         done

#     mount.status >/dev/null

#     return $_error
# }


# get_env () {
#     gr.msg -v4 -c pink "BIN:${GURU_BIN[@]}"
#     gr.msg -v4 -c pink "RC:${GURU_RC[@]}"
#     gr.msg -v4 -c pink "SYSTEM_MOUNT:${GURU_SYSTEM_MOUNT[@]}"
#     gr.msg -v4 -c pink "CALL:${GURU_CALL[@]}"
#     gr.msg -v4 -c pink "CFG:${GURU_CFG[@]}"
#     gr.msg -v4 -c pink "CLOUD_DOMAIN:${GURU_CLOUD_DOMAIN[@]}"
#     gr.msg -v4 -c pink "CLOUD_PORT:${GURU_CLOUD_PORT[@]}"
#     gr.msg -v4 -c pink "FORCE:${GURU_FORCE[@]}"
#     gr.msg -v4 -c pink "CLOUD_USERNAME:${GURU_CLOUD_USERNAME[@]}"
#     gr.msg -v4 -c pink "USER:${GURU_USER[@]}"
# }

if [[ ${BASH_SOURCE[0]} == ${0} ]] ; then
        #get_env
        [[ $GURU_SYSTEM_MOUNT ]] || source $GURU_RC
        mount.main $@
        exit $?
    fi
