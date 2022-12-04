#!/bin/bash
# mount tools for guru-client

source common.sh

all_list=($(\
        grep "export GURU_MOUNT_" $GURU_RC | \
        grep -ve '_LIST' -ve '_ENABLED' -ve '_PROXY' | \
        sed 's/^.*MOUNT_//' | \
        cut -d '=' -f1))
all_list=(${all_list[@],,})

mount_indicator_key='f'"$(gr.poll mount)"

mount.main () {
# mount command parser
    local _error=0
    local command="$1"
    shift

    case "$command" in

            system|help|ls|info|check|\
            poll|status|start|stop|list|uninstall|available|online)
                mount.$command $@
                _error=$?
                ;;

            defaults|all|toggle)
                mount.$command $@
                _error=$?
                mount.status >/dev/null
                ;;

            check-system)
                mount.check "$GURU_SYSTEM_MOUNT"
                _error=$?
                ;;

            folder|mount)
                mount.remote $command $@
                ;;

            "")
                mount.list default
                _error=$?
                mount.status >/dev/null
                ;;

            *)
                if echo ${GURU_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$command" ; then
                        gr.msg -v4 -c pink "found in defauls list"
                        mount.known_remote $command $@

                    elif echo ${all_list[@]} | grep -q -w "$command" ; then
                        gr.msg -v4 -c pink "found in all list"
                        mount.known_remote $command $@
                    else
                        gr.msg -c yellow "unknown mountpoint, available:"
                        mount.available

                    fi

                mount.status >/dev/null
                error=$?
                ;;
        esac

        return $_error
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
    #gr.msg -v1 " mount kill mount_name      kill mount process "
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
# check is mount point "online", no printout,

    local _target_folder="$GURU_SYSTEM_MOUNT"
    [[ "$1" ]] && _target_folder="$1"

    if [[ -f "$_target_folder/.online" ]] ; then
        return 0
    else
        return 1
    fi
}


mount.check () {
# check is mount point mounted, output status

    local _target_folder=$GURU_SYSTEM_MOUNT
    [[ "$1" ]] && _target_folder="$1"

    local color=grey
    local _online

    mount.online $_target_folder && _online=1 || _online=

    case $_target_folder in
        *.data)  [[ $_online ]] \
                        && color=sky_blue \
                        || color=dark_grey
                    ;;
            */.*)  [[ $_online ]] \
                        && color=hot_pink \
                        || return 1

                    ;;
                *)  [[ $_online ]] \
                        && color=aqua \
                        || color=dark_cyan
                    ;;
                esac
    gr.msg -n -v1 -c $color "${_target_folder##*/} "

    [[ $_online ]] && return 0 || return 1
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
    if [[ -f $_target_folder/.online ]] && grep -qw "$_target_folder" /etc/mtab ; then
            gr.msg -v1 -c green "mounted"
            return 0
        fi

    # check mount point exist, create if not
    if ! [[ -d "$_target_folder" ]] ; then
            mkdir -p "$_target_folder"
        fi

    # check is target populated and append if is
    if ! [[ -z "$(ls -A $_target_folder)" ]] ; then
            # Check that target directory is empty
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
            # new fucked up space dot --> if [[ -d "$_temp_folder" ]] ; then
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
            gr.msg -v2 "check user configuration '$GURU_CALL config user'"

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

mount.available () {
# printout list of available mount points
    gr.msg -c light_blue "${all_list[@]}"

    # local lists=($(\
    #         grep "export GURU_MOUNT_" $GURU_RC | \
    #         grep -e "_LIST" -ve "_ENABLED" | \
    #         sed 's/^.*MOUNT_//' | \
    #         cut -d '=' -f1))
    # lists=(${lists[@],,})

    # gr.msg "available lists: ${lists[@]}"

    return 0

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
    # mount.status >/dev/null
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
    local _target
    local _private=

    # check is enabled
    if [[ $GURU_MOUNT_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled " -k $mount_indicator_key
        else
            gr.msg -v1 -c reset "disabled" -k $mount_indicator_key
            return 100
        fi

    # check is system
    if mount.check ; then
            gr.msg -v1 -n -c green "available "
        else
            gr.msg -v1 -c red "unavailable" -k $mount_indicator_key
            return 101
        fi

    # go trough mount points
    for _mount_point in ${all_list[@]} ; do
            _target=$(eval echo '${GURU_MOUNT_'"${_mount_point^^}[0]}")
            mount.check $_target &&
                case $_target in \
                    *'/.'*)  _private=true
                            ;;
                    esac
        done

    # serve enter
    [[ $_private ]] \
        && gr.msg -c deep_pink -k $mount_indicator_key \
        || gr.msg -c aqua -k $mount_indicator_key

    return 0
}


mount.toggle () {
# unmount all or mount defaults by pressing key

    local _list=($(mount.ls | grep -v '.data'))

    if  [[ ${#_list[@]} -gt 1 ]] ; then
            source unmount.sh
            unmount.main all
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
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $mount_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $mount_indicator_key
            ;;
        status )
            mount.status $@
            ;;
        *)  mount.help
            ;;
        esac
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


mount.uninstall () {
# install and remove install applications. input "install" or "remove"

    gr.msg "wont remove 'ssh' or 'rsync', do it manually if really needed"
    return 0
}


if [[ ${BASH_SOURCE[0]} == ${0} ]] ; then

        [[ "$1" == "test" ]] && is_test=true

        # try to source guru variable set
        [[ $GURU_SYSTEM_MOUNT ]] || source $GURU_RC

        # fulfill required variables when run as stand alone
        [[ $GURU_BIN ]]     || declare -g GURU_BIN="$HOME/bin"  # 2>/dev/null?
        [[ $GURU_RC ]]      || declare -g GURU_RC="$HOME/.gururc"
        [[ $GURU_CALL ]]    || declare -g GURU_CALL='guru'
        [[ $GURU_CFG ]]     || declare -g GURU_CFG="$HOME/.config/guru"
        [[ $GURU_USER ]]    || declare -g GURU_USER=$USER

        # if test of stand alone fulfill with guest information
        [[ $is_test ]] || ! [[ $GURU_SYSTEM_MOUNT ]]    && declare -g GURU_SYSTEM_MOUNT=/tmp/guru-temp-data
        [[ $is_test ]] || ! [[ $GURU_CLOUD_USERNAME ]]  && declare -g GURU_CLOUD_USERNAME=guest
        [[ $is_test ]] || ! [[ $GURU_CLOUD_DOMAIN ]]    && declare -g GURU_CLOUD_DOMAIN=guest.ujo.guru
        [[ $is_test ]] || ! [[ $GURU_CLOUD_PORT ]]      && declare -g GURU_CLOUD_PORT=2023

        mount.main $@
        exit $?
    fi
