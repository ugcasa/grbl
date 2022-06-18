#!/bin/bash

# guru-cli uninstaller


[[ -f $GURU_BIN/keyboard.sh ]] \
    && source $GURU_BIN/keyboard.sh \
    || gr.msg -c white "keboard module not found, unable to return keyboard shortcuts"

[[ -f $GURU_BIN/config.sh ]] \
    && source $GURU_BIN/config.sh \
    || gr.msg -c white "config module not found, unable send config data to server"

backup_rc="$HOME/.bashrc.backup-by-guru"
guru_rc="$GURU_RC"


uninstall.main () {
    # remove mobules and applications installed by guru-cli
    command="$1" ; shift
    case "$command" in

            config)
                    remove_user_configs=true
                    uninstall.remove
                    return $?
                    ;;

            status|help)
                    uninstall.$command
                    return $?
                    ;;

            help)
                    uninstall.help
                    return 0
                    ;;

            uninstall|remove|"")
                    uninstall.remove
                    ;;

            *)
                    if [[ -f $GURU_BIN/$command.sh ]] ; then

                        # try to find uninstall method from module
                        if grep -q "$command.uninstall ()" $GURU_BIN/$command.sh ; then

                                source $GURU_BIN/$command.sh
                                $command.uninstall
                                return $?
                            else
                                gr.msg -c yellow "no unisntall method in module"
                            fi

                        # try to find uninstall method from installer
                        if grep -q "install.$command ()" $GURU_BIN/install.sh ; then

                                source $GURU_BIN/install.sh
                                install.$command uninstall
                                return $?
                            else
                                gr.msg -c yellow "no uninstall method in installer"
                            fi

                        gr.msg -c red "failed to uninstall '$command'"
                        return 100

                    else

                        # did not found module
                        gr.msg "application or module '$command' not found"
                        return 1
                    fi
                    ;;
        esac
}



uninstall.status () {

    local _error=0

    gr.msg -n -v2 ".bashrc.. "
    if cat $HOME/.bashrc | grep ".gururc" >/dev/null ; then
            gr.msg -v2 -c green "modified"
        else
            gr.msg -v2 -c red "not modified"
            _error=1
        fi

    gr.msg -n -v2 "$backup_rc.. "
    if [[ -f $backup_rc ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=1
        fi

    gr.msg -n -v2 "$GURU_CFG.. "
    if [[ -d $GURU_CFG ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=1
        fi

    gr.msg -n -v2 "$GURU_CFG/$GURU_USER/user.cfg.. "
    if [[ -f $GURU_CFG/$GURU_USER/user.cfg ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=1
        fi

    gr.msg -n -v2 "$GURU_BIN/common.sh..  "
    if [[ -f $GURU_BIN/common.sh ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=1
        fi

    gr.msg -n -v2 "$GURU_CFG/installed.core.. "
    if [[ -f $GURU_CFG/installed.core ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=1
        fi

    gr.msg -n -v2 "$GURU_BIN/uninstall.sh..  "
    if [[ -f $GURU_BIN/uninstall.sh ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=10
        fi

    gr.msg -n -v2 "$GURU_CFG/installed.files.. "
    if [[ -f $GURU_CFG/installed.files ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=10
        fi

    gr.msg -n -v2 "$GURU_CFG/installed.modules.. "
    if [[ -f $GURU_CFG/installed.files ]] ; then
            gr.msg -v2 -c green "exist"
        else
            gr.msg -v2 -c red "not found"
            _error=10
        fi

    case $_error in
               0)  gr.msg -v1 -c green "guru.client installed and can be uninstalled" ; return 0 ;;
           [1-9])  gr.msg -v1 -c yellow "guru.client installation is not complete but can be uninstalled" ;;
          1[0-9])  gr.msg -v1 -c red "guru.client uninstallation might be unstable, try to re-install, then uninstall" ;;
    esac
    return $_error
}


uninstall.help () {
    gr.msg -v1 -c white "guru-client uninstaller help"
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL uninstall [config|status|help]"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 " config                      remove also configurations"
    gr.msg -v1 " status                      check installation status "
    gr.msg -v2 " help                        this help "
    gr.msg -v2
}


uninstall.remove () {

    source system.sh

    if system.flag running ; then
            system.flag set pause
            sleep 3
        fi

    # check installation
    if [[ -f "$backup_rc" ]] ; then
        gr.msg -n -v1 "removing launcher "
        if cp -f "$backup_rc" "$HOME/.bashrc" ; then
                gr.msg -v1 -c green "ok"
            else
                gr.msg -c yellow  "error when trying to remove launcher from $HOME/.bashrc, try manually"
            fi

        else
            echo "not installed, aborting.."
            return 1
        fi

    version_to_uninstall=$(core.sh version)
    gr.msg -v1 -c white "uninstalling $version_to_uninstall"

    # remove keyboard shortcuts
    if [[ -f $GURU_BIN/keyboard.sh ]] ; then
            gr.msg -v1 "removing keyboad shortcuts.. "
            keyboard.main rm all
        fi

    # remove configrations
    gr.msg -v1 "removing general configurations.. "
    rm -f "$HOME/.config/guru/*" >/dev/null || gr.msg -c yellow "error while removing files"

    if [[ $remove_user_configs ]] ; then
            gr.msg -n -v1 "removing user configurations.. "

            if [[ -f $GURU_CFG/$GURU_USER/user.cfg ]] ; then
                    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
                        gr.msg -n -v1 "sending $GURU_USER's configurations to accesspoint.. "
                        if config.main push ; then
                                gr.msg -n -v1 "removing $GURU_USER configurations.. "
                                rm -fr $GURU_CFG/$GURU_USER || gr.msg -c yellow "error while removing user files"
                            else
                                gr.msg -c yellow "error while sending user data "
                            fi
                        else
                            gr.msg -c white "personal config file $GURU_CFG/$GURU_USER/user.cfg kept"
                        fi
                fi

            # check other users configurations and do not remove if found
            if [[ $(ls $GURU_CFG) ]] ; then
                    gr.msg -c yellow "$GURU_CFG contains other user configurations and cannot be removed"
                else
                    rmdir "$HOME/.config/guru" || gr.msg -c yellow "error while config"
                fi
        fi


    # remove installed files
    file_list=( $(cat $GURU_CFG/installed.files) )
    gr.msg -v1 -n "deleting files " ; gr.msg -v2
    for _file in ${file_list[@]} ; do
        if [[ -f $_file ]] ; then
                rm -rf $_file
                gr.msg -n -v1 -V2 -c gray "."
                gr.msg -v2 -c gray "$_file"
            else
                gr.msg -c yellow "warning: file '$_file' not found"
            fi
        done
    gr.msg -v1 -V2 -c green " done"

    # remove installtion data
    gr.msg -v1 "removing installer data.. "
    rm -f "$GURU_CFG/installed*" >/dev/null || gr.msg -v1 -c yellow "error while removing $GURU_CFG/installed.*"
    rm -f "$GURU_CFG/modified*" >/dev/null || gr.msg -v1 -c yellow "error while removing $GURU_CFG/modified.*"

    # unlink core symbolic link
    gr.msg -v1 "unlinking core.. "
    unlink $GURU_BIN/$GURU_CALL || gr.msg -v1 -c yellow "error while unlinking $GURU_BIN/$GURU_CALL"

    # remove module folders, should be empty already
    gr.msg -v1 "removing module folders.. "
    cd $GURU_BIN ; rmdir * >/dev/null 2>&1 || gr.msg -v1 -c yellow "error while removing module folders"

    # remove binary folder if it's empty
    gr.msg -v1 "removing bin folder.. "
    cd ; rmdir $GURU_BIN >/dev/null 2>&1 || gr.msg -v1 -c yellow "contains other stuff, $GURU_BIN kept"

    # remove .gururc file from home
    gr.msg -v1 "removing rc files.. "
    rm -f "$guru_rc" || gr.msg -v1 -c yellow "error while removing $guru_rc "

    # pass
    gr.msg -c white "guru-cli v$version_to_uninstall removed"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f "$guru_rc" ]] && source "$guru_rc"
    uninstall.main "$@"
    exit $?
fi

