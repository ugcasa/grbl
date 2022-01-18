#!/bin/bash

[[ -f $GURU_BIN/keyboard.sh ]] \
    && source $GURU_BIN/keyboard.sh \
    || gmsg -c white "keboard module not found, unable to return keyboard shortcuts"

[[ -f $GURU_BIN/config.sh ]] \
    && source $GURU_BIN/config.sh \
    || gmsg -c white "config module not found, unable send config data to server"

backup_rc="$HOME/.bashrc.backup-by-guru"
guru_rc="$GURU_RC"


uninstall.main () {

    command="$1" ; shift
    case "$command" in
        config) remove_user_configs=true
                uninstall.remove            ; return $? ;;
        status) uninstall.status            ; return $? ;;
          help) uninstall.help              ; return 0 ;;
             *) uninstall.remove            ; return $? ;;
    esac
}


uninstall.status () {

    local _error=0

    gmsg -n -v2 ".bashrc.. "
    if cat $HOME/.bashrc | grep ".gururc" >/dev/null ; then
            gmsg -v2 -c green "modified"
        else
            gmsg -v2 -c red "not modified"
            _error=1
        fi

    gmsg -n -v2 "$backup_rc.. "
    if [[ -f $backup_rc ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=1
        fi

    gmsg -n -v2 "$GURU_CFG.. "
    if [[ -d $GURU_CFG ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=1
        fi


    gmsg -n -v2 "$GURU_CFG/$GURU_USER/user.cfg.. "
    if [[ -f $GURU_CFG/$GURU_USER/user.cfg ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=1
        fi


    gmsg -n -v2 "$GURU_BIN/common.sh..  "
    if [[ -f $GURU_BIN/common.sh ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=1
        fi

    gmsg -n -v2 "$GURU_CFG/installed.core.. "
    if [[ -f $GURU_CFG/installed.core ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=1
        fi

    gmsg -n -v2 "$GURU_BIN/uninstall.sh..  "
    if [[ -f $GURU_BIN/uninstall.sh ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=10
        fi

    gmsg -n -v2 "$GURU_CFG/installed.files.. "
    if [[ -f $GURU_CFG/installed.files ]] ; then
            gmsg -v2 -c green "exist"
        else
            gmsg -v2 -c red "not found"
            _error=10
        fi

    case $_error in
               0)  gmsg -v1 -c green "guru.client installed and can be uninstalled" ; return 0 ;;
           [1-9])  gmsg -v1 -c yellow "guru.client installation is not complete but can be uninstalled" ;;
          1[0-9])  gmsg -v1 -c red "guru.client uninstallation might be unstable, try to re-install, then uninstall" ;;
    esac
    return $_error
}


uninstall.help () {
    gmsg -v1 -c white "guru-client uninstaller help"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL uninstall [config|status|help]"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 " config                      remove also configurations"
    gmsg -v1 " status                      blink esc, print status and return "
    gmsg -v2 " help                        this help "
    gmsg -v2
}


uninstall.remove () {

    source system.sh

    if system.flag running ; then
            system.flag set pause
            sleep 3
        fi

    # check installation
    if [[ -f "$backup_rc" ]] ; then
        gmsg -n -v1 "removing launcher "
        if cp -f "$backup_rc" "$HOME/.bashrc" ; then
                gmsg -v1 -c green "ok"
            else
                gmsg -c yellow  "error when trying to remove launcher from $HOME/.bashrc, try manually"
            fi

        else
            echo "not installed, aborting.."
            return 1
        fi

    version_to_uninstall=$(core.sh version)
    gmsg -v1 -c white "uninstalling $version_to_uninstall"

    # remove keyboard shortcuts
    if [[ -f $GURU_BIN/keyboard.sh ]] ; then
            gmsg -v1 "removing keyboad shortcuts.. "
            keyboard.main rm all
        fi

    # remove configrations
    gmsg -v1 "removing general configurations.. "
    rm -f "$HOME/.config/guru/*" >/dev/null || gmsg -c yellow "error while removing files"

    if [[ $remove_user_configs ]] ; then
            gmsg -n -v1 "removing user configurations.. "

            if [[ -f $GURU_CFG/$GURU_USER/user.cfg ]] ; then
                    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
                        gmsg -n -v1 "sending $GURU_USER's configurations to accesspoint.. "
                        if config.main push ; then
                                gmsg -n -v1 "removing $GURU_USER configurations.. "
                                rm -fr $GURU_CFG/$GURU_USER || gmsg -c yellow "error while removing user files"
                            else
                                gmsg -c yellow "error while sending user data "
                            fi
                        else
                            gmsg -c white "personal config file $GURU_CFG/$GURU_USER/user.cfg kept"
                        fi
                fi

            # check other users configurations and do not remove if found
            if [[ $(ls $GURU_CFG) ]] ; then
                    gmsg -c yellow "$GURU_CFG contains other user configurations and cannot be removed"
                else
                    rmdir "$HOME/.config/guru" || gmsg -c yellow "error while config"
                fi
        fi


    # remove installed files
    file_list=( $(cat $GURU_CFG/installed.files) )
    gmsg -v1 -n "deleting files " ; gmsg -v2
    for _file in ${file_list[@]} ; do
        if [[ -f $_file ]] ; then
                rm -rf $_file
                gmsg -n -v1 -V2 -c gray "."
                gmsg -v2 -c gray "$_file"
            else
                gmsg -c yellow "warning: file '$_file' not found"
            fi
        done
    gmsg -v1 -V2 -c green " done"

    # remove installtion data
    gmsg -v1 "removing installer data.. "
    rm -f "$GURU_CFG/installed*" >/dev/null || gmsg -v1 -c yellow "error while removing $GURU_CFG/installed.*"
    rm -f "$GURU_CFG/modified*" >/dev/null || gmsg -v1 -c yellow "error while removing $GURU_CFG/modified.*"

    # unlink core symbolic link
    gmsg -v1 "unlinking core.. "
    unlink $GURU_BIN/$GURU_CALL || gmsg -v1 -c yellow "error while unlinking $GURU_BIN/$GURU_CALL"

    # remove module folders, should be empty already
    gmsg -v1 "removing module folders.. "
    cd $GURU_BIN ; rmdir * >/dev/null 2>&1 || gmsg -v1 -c yellow "error while removing module folders"

    # remove binary folder if it's empty
    gmsg -v1 "removing bin folder.. "
    cd ; rmdir $GURU_BIN >/dev/null 2>&1 || gmsg -v1 -c yellow "contains other stuff, $GURU_BIN kept"

    # remove .gururc file from home
    gmsg -v1 "removing rc files.. "
    rm -f "$guru_rc" || gmsg -v1 -c yellow "error while removing $guru_rc "

    # pass
    gmsg -c white "$version_to_uninstall removed"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f "$guru_rc" ]] && source "$guru_rc"
    uninstall.main "$@"
    exit $?
fi

