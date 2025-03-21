#!/bin/bash
# grbl mount core module 2019 - 2022 casa@ujo.guru

declare -g mount_rc="/tmp/$USER/grbl_mount.rc"
__mount_color="navy"
__mount=$(readlink --canonicalize --no-newline $BASH_SOURCE)

quiet=

mount.help () {
# mount help
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    gr.msg -v1 -c white "grbl mount help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL mount|unount|check|check-system <source> <target>"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " ls                         list of mounted folders "
    gr.msg -v1 " check mount_name           check that mount point is mounted "
    gr.msg -v2 " check-system               check that grbl system folder is mounted "
    gr.msg -v1 " mount mount_name           mount folder in file server to local folder "
    gr.msg -v1 " mount all                  mount all known folders in server "
    gr.msg -v2 "                            edit $GRBL_CFG/$USER/user.cfg or run "
    gr.msg -v2 "                            '$GRBL_CALL config user' to setup default mountpoints "
    gr.msg -v3 " poll start|end             start or end module status polling "
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GRBL_CALL mount /home/$GRBL_CLOUD_USERNAME/share /home/$USER/grbl/projects"
    gr.msg -v1 "      $GRBL_CALL umount /home/$USER/grbl/projects"
}

mount.main () {
# mount command parser
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _error=0
    local command="$1"
    shift

    case "$command" in

            help|ls|info|check|mounted|poll|status|start|stop|install|uninstall|mounted|online|config)
                mount.$command $@
                _error=$?
                ;;

            list|avail*)
                mount.available $@
                _error=$?
                ;;

            defaults|all|toggle)
                mount.$command $@
                _error=$?
                mount.status quiet
                ;;

            check-system)
                mount.check "$GRBL_SYSTEM_MOUNT"
                _error=$?
                ;;

            mount)
                gr.end $GRBL_MOUNT_INDICATOR_KEY
                mount.remote $command $@
                mount.status quiet
                _error=$?
                ;;

            size)
                mount.local_size $@
                _error=$?
                ;;
            tog)
                gr.end $GRBL_MOUNT_INDICATOR_KEY
                mount.toggle_single $@ && \
                    mount.status quiet
                ;;
            "")
                mount.listed default
                _error=$?
                mount.status quiet
                ;;

            *)
                gr.end $GRBL_MOUNT_INDICATOR_KEY
                if echo ${GRBL_MOUNT_DEFAULT_LIST[@]} | grep -q -w "$command" ; then
                    gr.debug "found in defauls list"
                    mount.known_remote $command $@

                elif echo ${all_list[@]} | grep -q -w "$command" ; then
                    gr.debug "found in all list"
                    mount.known_remote $command $@
                # check is list named as user input
                elif [[ $(eval echo '${GRBL_MOUNT_'${command^^}'_LIST[@]^^}') ]]; then
                    mount.listed $command
                else
                    gr.debug "trying to mount location defined in other module configuration"
                    mount.known_remote $command $@
                fi

                mount.status quiet
                error=$?
                ;;
        esac

        return $_error
}

mount.rc () {
# source configurations
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    if  [[ ! -f $mount_rc ]] || \
        [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $mount_rc) )) -gt 0 ]]
    then
        mount.make_rc && \
            gr.msg -v1 -c dark_gray "$mount_rc updated"
    fi

    gr.debug "mount_rc:'$mount_rc'"
    source $mount_rc
    declare -g all_list=($(\
            grep "export GRBL_MOUNT_" $mount_rc | \
            grep -ve '_LIST' -ve '_ENABLED' -ve '_PROXY' -ve 'INDICATOR_KEY' | \
            sed 's/^.*MOUNT_//' | \
            cut -d '=' -f1))
            all_list=(${all_list[@],,})
    gr.debug "all_list:(${all_list[@]})"

    # declare -g list_list=($(\
    #     grep "export GRBL_MOUNT_" $mount_rc | \
    #     grep -e '_LIST' -ve '_ENABLED' -ve '_PROXY' -ve 'INDICATOR_KEY' | \
    #     sed 's/^.*MOUNT_//' | \
    #     cut -d '=' -f1))
    #     list_list=(${list_list[@],,})
    # gr.debug "list_list:(${list_list[@]})"
}

mount.make_rc () {
# make core module rc file out of configuration file
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    if ! source config.sh ; then
        gr.msg -e1 "unable to load configuration module"
        return 100
    fi

    if [[ -f $mount_rc ]] ; then
        rm -f $mount_rc
    fi

    if ! config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $mount_rc ; then
        gr.msg -e1 "configuration failed"
        return 101
    fi

    chmod +x $mount_rc

    if ! source $mount_rc ; then
        gr.msg -c red "unable to source configuration"
        return 202
    fi

    declare -g all_list=($(\
            grep "export GRBL_MOUNT_" $mount_rc | \
            grep -ve '_LIST' -ve '_ENABLED' -ve '_PROXY' -ve 'INDICATOR_KEY' | \
            sed 's/^.*MOUNT_//' | \
            cut -d '=' -f1))
            all_list=(${all_list[@],,})
}

mount.local_size () {
# check size of files in locally mounted folder
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _mount_target=$GRBL_DATA
    [[ $1 ]] && _mount_target="$1"

    # check is mount available
    gr.msg -n -v2 "checking $_mount_target.. "
    if ! mount.check $_mount_target ; then
        gr.msg -e1 "$_mount_target not mounted"
        return 10
    fi

    # get values
    local _total_size=$(du -s $_mount_target 2>/dev/null)
    local _human_total_size=$(echo "$_total_size" | awk '{ byte =$1 /1024**2 ; print byte " GB" }')

    gr.msg -v2 -n "$_mount_target: "
    gr.msg -v1 "$_human_total_size"
    gr.msg -v0 -V1 "$_total_size"
}

mount.info () {
# detailed list of mounted mountpoints. nice list of information of sshfs mount points
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _error=0
    # header (stdout if verbose rised)
    gr.msg -v1 -c white "user@server remote_folder local_mountpoint  uptime pid"
    mount -t fuse.sshfs | grep -oP '^.+?@\S+?:\K.+(?= on /)' |

    # get the mount data
    while read mount ; do
        # iterate over them       / how these work here?   --^
        mount | grep -w "$mount" |
        # Get the details of this mount
        perl -ne '/.+?@(\S+?):(.+)\s+on\s+(.+)\s+type.*user_id=(\d+)/;print "'$GRBL_USER'\@$1 $2 $3"'
        # perl magic thanks terdon! https://unix.stackexchange.com/users/22222/terdon
        _error=$?

        local _mount_pid="$(pgrep -f $mount \
                        | head -1)"

        local _mount_age="$(ps -p $_mount_pid o etime \
                        | grep -v ELAPSED \
                        | xargs)"

        echo " $_mount_age $_mount_pid"

    done

    ((_error>0)) && gr.msg -e1 "perl not installed or internal error, pls try to install perl and try again."
    return $_error
}

mount.ls () {
# simple list of mounted mountpoints
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    mount -t fuse.sshfs | grep -oP '^.+?@\S+? on \K.+(?= type)'
    return $?
}

mount.system () {
# mount system data
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    gr.msg -v3 -n "checking system data folder.."
    if [[ -f "$GRBL_SYSTEM_MOUNT/.online" ]] ; then
            gr.debug "$FUNCNAME: mounted "
    else
        gr.msg -v3 -n "mounting.. "
        # gr.debug "$FUNCNAME: ${GRBL_SYSTEM_MOUNT[1]} -> $GRBL_SYSTEM_MOUNT"
        mount.remote "$GRBL_SYSTEM_MOUNT" "${GRBL_SYSTEM_MOUNT[1]}" \
            && gr.debug "$FUNCNAME: ok"  \
            || gr.debug "$FUNCNAME: error $?"
    fi
}

mount.online () {
# check is mount point "online", no printout,
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _target_folder="$GRBL_SYSTEM_MOUNT"
    [[ "$1" ]] && _target_folder="$1"

    if [[ -f "$_target_folder/.online" ]] ; then
        return 0
    else
        return 1
    fi
}

mount.mounted () {
# check is givven list name already mounted
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _mount_list_name=$1

    if ! [[ "$_mount_list_name" ]]; then
        gr.msg -c error -v2 "please give mount point name"
        return
    fi

    local _target_folder=$(eval echo '${GRBL_MOUNT_'"${_mount_list_name^^}[0]}")
    gr.debug "$FUNCNAME: target folder '$_target_folder'"

    if ! [[ $_target_folder ]] ; then
        gr.msg -c error "unable to solve target folder, check mount list name '$_mount_list_name'"
        return 2
    fi

    if [[ -f "$_target_folder/.online" ]] ; then
        gr.debug "'$_mount_list_name' mounted to '$_target_folder'"
        return 0
    else
        gr.debug "'$_mount_list_name' not mounted '$_target_folder'"
        return 1
    fi
}

mount.check () {
# check is mount point mounted, output status
# TODO stupid thing this is, re-think whole mount module

    gr.msg -N -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _target_folder=$GRBL_SYSTEM_MOUNT
    [[ "$1" ]] && _target_folder="$1"

    local color=grey
    local _online

    mount.online $_target_folder && _online=1 || _online=

    case $_target_folder in
        *.data)
            [[ $_online ]] \
                && color=sky_blue \
                || color=black
            ;;

        */.*)
            [[ $_online ]] \
                && color=black \
                || color=null
            ;;

        *)
            [[ $_online ]] \
                && color=aqua \
                || color=dark_cyan
            ;;
    esac

    if ! [[ $quiet ]] ; then
        [[ $color != null ]] && gr.msg -n -v1 -c $color "${_target_folder##*/} "
    fi

    # online comes wrong way around for this purpose
    [[ $_online ]] && return 0 || return 1

}

mount.remote () {
# mount any remote location. usage: mount_point remote_folder optional: domain port symlink_to
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    # set defaults
    local _target_folder=
    local _source_folder=
    local _source_server=$GRBL_CLOUD_DOMAIN
    local _source_port=$GRBL_CLOUD_PORT
    local _symlink=

    # temporary
    local _temp_folder="/tmp/$USER/grbl/mount"
    local _reply=
    # to avoid read function to pass without input set force mode off
    unset FORCE

    [[ "$1" ]] && _target_folder="$1" || read -r -p "local target mount point: " _target_folder
    [[ "$2" ]] && _source_folder="$2" || read -r -p "source folder at server: " _source_folder
    [[ "$3" ]] && _source_server="$3"
    [[ "$4" ]] && _source_port="$4"
    [[ "$5" ]] && _symlink="$5"

    local _mount_name=${_target_folder##*/}
    gr.msg -v1 -n "${_mount_name//./} "

    # double check is in /etc/mtab already mounted (connected) and .online file exists
    if grep -qw "$_target_folder" /etc/mtab && [[ -f $_target_folder/.online ]]; then
        gr.msg -v1 -c green "connected"
        return 0
    fi

    # check mount point exist, create if not
    if ! [[ -d "$_target_folder" ]] ; then
        mkdir -p "$_target_folder"
    fi

    echo $_target_folder | xclip -i -selection clipboard

    # check is target populated and append if is
    if ! [[ -z "$(ls -A $_target_folder)" ]] ; then
        # Check that target directory is empty
        gr.msg -e1 "target folder is not empty!"

        # Check force options
        if ! [[ $GRBL_FORCE ]] ; then
            gr.msg -v2 -c white "try '-f' to force or: '$GRBL_CALL -f mount $_source_folder $_target_folder"
            return 25
        fi

        # move found files to temp
        gr.msg -c light_blue "$(ls $_target_folder)"
        read -r -p "append above files to $_target_folder?: " _reply

        case $_reply in
            y)
                [[ -d $_temp_folder ]] && rm -rf "$_temp_folder"
                gr.debug "mv $_target_folder -> $_temp_folder"
                mkdir -p "$_temp_folder"
                mv "$_target_folder" "$_temp_folder"
                ;;
            *)  gr.msg -c red "unable to mount $_target_folder is populated"
                return 26
        esac
    fi

    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"

    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,follow_symlinks \
          -p "$_source_port" \
          "$GRBL_CLOUD_USERNAME@$_source_server:$_source_folder" \
          "$_target_folder"

    error=$?

    # copy files from temp if exist
    if [[ -d "$_temp_folder/${_target_folder##*/}" ]] ; then
        # new fucked up space dot --> if [[ -d "$_temp_folder" ]] ; then
        gr.debug "cp $_temp_folder/${_target_folder##*/} > $_target_folder"

        cp -a "$_temp_folder/${_target_folder##*/}/." "$_target_folder" \
            || gr.msg -e1 "failed to append/return files to $_target_folder, check also $_temp_folder"

        rm -rf "$_temp_folder" \
            || gr.msg -e1 "failed to remote $_temp_folder"
    fi

    # if symlink given check if exist and create if not
    if [[ $_symlink ]] ; then

        if file -h $_symlink | grep "symbolic" >/dev/null ; then
            gr.msg -n -v3 "link exist "
        else
            gr.msg -n -v2 "linking "
            ln -s $_target_folder $_symlink && error=0 \
                || gr.msg -x 25 -e1 "error creating $_symlink"
        fi
    fi

    # check sshfs error
    if ((error>0)) ; then
        gr.msg -e1 "error $error when sshf"
        gr.msg -v2 "check user configuration '$GRBL_CALL config user'"

        ## check that is not listed in /etc/mtab
        if grep -wq $_target_folder /etc/mtab ; then
            gr.msg -e1 "listed in mtab, not able to remove $_target_folder"
            return 27
        fi

        # remove folder only if empty
        [[ -d "$_target_folder" ]] && rmdir "$_target_folder"
        return $error
    else
        [[ -f "$_target_folder/.online" ]] || touch "$_target_folder/.online"
        gr.msg -v1 -c green "mounted"
        return 0
    fi
}

mount.available () {
# printout list of available mount points
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    for _mount_point in ${all_list[@]} ; do
        _target=$(eval echo '${GRBL_MOUNT_'"${_mount_point^^}[0]}")
        mount.check $_target && _online=1 || _online=
    done
    echo

    # gr.msg -c light_blue "${all_list[@]}"
    return 0
}

mount.listed () {
# mount all GRBL_MOUNT_<list_name>_LIST defined in user configuration
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _list_name="default" ; [[ $1 ]] && _list_name=$1

    # get list given of mount points specified in mount.cfg
    local _mount_list=$(eval echo '${GRBL_MOUNT_'"${_list_name^^}_LIST[@]^^}")

    [[ ${_mount_list[@]} ]] || _mount_list=(${all_list[@]})

    if [[ ${_mount_list} ]] ; then
                gr.debug "$FUNCNAME: ${_mount_list[@]}"
            else
                gr.msg -e1 "default mount list is empty, edit $GRBL_CFG/$GRBL_USER/user.cfg and then '$GRBL_CALL config export'"
            return 1
        fi

    # go trough of found variables
    for _item in ${_mount_list[@]} ; do
            _target=$(eval echo '${GRBL_MOUNT_'"${_item}[0]}")
            _source=$(eval echo '${GRBL_MOUNT_'"${_item}[1]}")
            _symlink=$(eval echo '${GRBL_MOUNT_'"${_item}[2]}")
            IFS=':' read -r _server _port _source_folder <<<"$_source"

            if ! [[ $_source_folder ]] ; then
                    _source_folder=$_source
                    _server=
                    _port=
                fi

            gr.debug "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done

    IFS="$_IFS"
    return $_error
}

mount.all () {
# mount all GRBL_CLOUD_* defined in userrc
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _error=0
    local _IFS="$IFS"
    local _symlink=
    local _mount_list=(${all_list[@]^^})

    if [[ $_mount_list ]] ; then
                gr.debug "$FUNCNAME: ${_mount_list[@]}"
            else
                gr.msg -e1 "default mount list is empty, edit $GRBL_CFG/$GRBL_USER/user.cfg and then '$GRBL_CALL config export'"
            return 1
        fi

    for _item in "${_mount_list[@]}" ; do
            # go trough of found variables
            _target=$(eval echo '${GRBL_MOUNT_'"${_item}[0]}")
            _source=$(eval echo '${GRBL_MOUNT_'"${_item}[1]}")
            _symlink=$(eval echo '${GRBL_MOUNT_'"${_item}[2]}")
            IFS=':' read -r _server _port _source_folder <<<"$_source"
            IFS="$_IFS"

            if ! [[ $_source_folder ]] ; then
                    _source_folder=$_source
                    _server=
                    _port=
                fi

            gr.debug "$FUNCNAME: $_target < $_server:$_port:$_source ($_symlink)"
            mount.remote "$_target" "$_source_folder" "$_server" "$_port" "$_symlink"
        done

    #mount.status >/dev/null
    return $_error
}

mount.known_remote () {
# mount single GRBL_CLOUD_* defined in userrc
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _target=$(eval echo '${GRBL_MOUNT_'"${1^^}[0]}")
    local _source=$(eval echo '${GRBL_MOUNT_'"${1^^}[1]}")
    local _symlink=$(eval echo '${GRBL_MOUNT_'"${1^^}[2]}")
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
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    [[ $1 == "quiet" ]] && quiet=true

    # printout header for status output
    local _target
    local _private=
    local _online=
    local _mounted=

    if ! [[ $quiet ]]; then
        gr.msg -t -v1 -n "${FUNCNAME[0]}: "
        # check is enabled
        if [[ $GRBL_MOUNT_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled " -k $GRBL_MOUNT_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled" -k $GRBL_MOUNT_INDICATOR_KEY
            return 100
        fi
    fi

    gr.end $GRBL_MOUNT_INDICATOR_KEY

    # go trough mount points
    for _mount_point in ${all_list[@]} ; do
        _target=$(eval echo '${GRBL_MOUNT_'"${_mount_point^^}[0]}")
        mount.check $_target && _online=1 || _online=

        # if some of mount points are "secret" and online
        case $_target in
            $GRBL_DATA)
                [[ $_online ]] && _system=1
            ;;
            */.*)
                [[ $_online ]] && _private=1
                [[ $_online ]] && _mounted=1
            ;;
            *)
                [[ $_online ]] && _mounted=1
            ;;
        esac
    done

    # set indicate key color
    if [[ $_private ]]; then
        if [[ $_system ]]; then
            gr.msg -n -c deep_pink -k $GRBL_MOUNT_INDICATOR_KEY
        else
            gr.blink $GRBL_MOUNT_INDICATOR_KEY secred
        fi
    elif [[ $_mounted ]]; then
        if [[ $_system ]]; then
            gr.msg -n -c aqua -k $GRBL_MOUNT_INDICATOR_KEY
        else
            gr.blink $GRBL_MOUNT_INDICATOR_KEY partly
        fi
    else
        if [[ $_system ]]; then
            gr.msg -n -c blue -k $GRBL_MOUNT_INDICATOR_KEY
        else
            gr.blink $GRBL_MOUNT_INDICATOR_KEY offline
        fi
    fi

    # serve enter
    [[ $quiet ]] || echo
    return 0
}

mount.toggle_single () {
# mount or un-mount single given mount point
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    if ! [[ $1 ]]; then
        gr.msg -e1 "please give mount point"
        return 11
    fi

    local target="$1"

    # check is in all list
    if ! gr.contain "$target" "${all_list[@]}"; then
        gr.msg -e1 "'$target' is non valid mount point"
        return 12
    fi

    local mounted=()
    local _list=($(mount.ls | grep -v '.data'))

    # clean path away
    for (( i = 0; i < ${#_list[@]}; i++ )); do
        mounted+="${_list[$i]##*/} "
    done

    gr.debug "mounted: ${mounted[@]}"

    # check is in list
    if gr.contain "$target" "${mounted[@]}"; then
        source unmount.sh
        unmount.main $target
        return $?
    else
        mount.main $target
        return $?
    fi
}

mount.toggle () {
# mount defaults vs unmount all for keyboard shortcut usage
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    source unmount.sh

    local _list=($(mount.ls | grep -v '.data'))

    # list mount/unmount
    if  [[ ${#_list[@]} -gt 1 ]] ; then
            unmount.main all
        else
            mount.listed default
        fi
    return 0
}

mount.poll () {
# daemon poll api
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    local _cmd="$1" ; shift

    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $GRBL_MOUNT_INDICATOR_KEY
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $GRBL_MOUNT_INDICATOR_KEY
            ;;
        status)
            mount.status $@
            ;;
        *)  mount.help
            ;;
        esac
}

mount.install () {
# install and remove install applications. input "install" or "remove"
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    sudo apt update
    sudo apt install rsync sshfs xclip
}

mount.uninstall () {
# install and remove install applications. input "install" or "remove"
    gr.msg -v4 -c $__mount_color "$__mount [$LINENO] $FUNCNAME '$@'" >&2

    gr.msg "wont remove 'ssh' or 'rsync', do it manually if really needed"
    return 0
}

mount.rc

if [[ ${BASH_SOURCE[0]} == ${0} ]] ; then
        #source $GRBL_RC
        gr.msg -v4 -c $__mount_color "$__mount [$LINENO] run" >&2
        mount.main $@
        exit $?
    else
        gr.msg -v4 -c $__mount_color "$__mount [$LINENO] sourced" >&2
    fi
