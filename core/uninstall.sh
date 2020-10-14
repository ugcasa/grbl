#!/bin/bash
source $GURU_BIN/keyboard.sh

backup_rc="$HOME/.bashrc.backup-by-guru"
guru_rc="$GURU_RC"    # TODO change name to '.gururc' when cleanup next time

## TODO total bullshit, rewrite all!
uninstall.main () {

    command="$1" ; shift
    case "$command" in
        #config) [[ -d $HOME/.config/guru ]] && rm -rf $HOME/.config/guru ;;
          help) echo "usage:    $GURU_CALL uninstall [config|help]" ;;
        status) gmsg -c dark_grey "nothing to report" ; return 0 ;;
             *) uninstall.remove "$@"
                exit "$?"
    esac
}

## TODO total bullshit, rewrite all! edit, slowly..
uninstall.remove () {

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
            return 127
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

    # remove .gururc file from home
    rm -f "$guru_rc"

    # remove left over folders and symbolic link
    unlink $GURU_BIN/$GURU_CALL
    cd $GURU_BIN ; rmdir * >/dev/null 2>&1
    cd ; rmdir $GURU_BIN >/dev/null 2>&1

    # leave settings untouch
    #[[ $HOME/.config/guru ]] && rm -rf "$HOME/.config/guru"

    # remove keyboard shorcuts
    keyboard.main rm all
    echo "guru-client removed"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f "$guru_rc" ]] && source "$guru_rc"
    uninstall.main "$@"
fi

