#!/bin/bash
source $GURU_BIN/keyboard.sh

backup_rc="$HOME/.bashrc.backup-by-guru"
core_rc="$HOME/.gururc2"    # TODO change name to '.gururc' when cleanup next time

## TODO total bullshit, rewrite all!
uninstall.main () {

    command="$1" ; shift
    case "$command" in
        config) uninstall.remove "$@" ; [[ $HOME/.config/guru ]] && rm -rf $HOME/.config/guru ;;
          help) echo "usage:    $GURU_CALL uninstall [config|help]" ;;
        status) echo TBD ;;
             *) uninstall.remove "$@"
                exit "$?"
    esac
}

## TODO total bullshit, rewrite all! edit, slowly..
uninstall.remove () {

    if [ -f "$backup_rc" ]; then
        gmsg -n -v1 "removing launcher "

        if cp -f "$backup_rc" "$HOME/.bashrc" ; then
                gmsg -v1 -c green "ok"
            else
                gmsg -v1 -c yellow  "error when trying to remove launcher from $HOME/.bashrc, try manually"
            fi
        else
            echo "not installed, aborting.."
            return 127
        fi

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

    rm -f "$core_rc"
    rm -fr "$HOME/bin"
    #[[ $HOME/.config/guru ]] && rm -rf "$HOME/.config/guru"
    keyboard.main rm all
    echo "guru-client removed"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f "$core_rc" ]] && source "$core_rc"
    uninstall.main "$@"
fi

