#!/bin/bash
# sshfs mount functions for guru-client
source $GURU_BIN/common.sh

print.main() {
    [[ "$GURU_INSTALL" == "server" ]] && print.warning

    command="$1"; shift
    case "$command" in
             label|help)    print.$command "$@"                           ; return $? ;;
                   test)    source $GURU_BIN/test.sh; print.test "$@"     ; return $? ;;
                 status)    gmsg -c black "printer not connected" ;;
                      *)    print.help ;;
    esac
    return 0
}


print.help () {
    gmsg -v1 -c white "guru-client print help "
    gmsg -v0  "usage:    $GURU_CALL print [label] "
    gmsg -v1 -c white "commands:"
    gmsg -v1  " label                     print label "
    gmsg -v2
}


print.label () {
    echo "printing label"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc2"
    print.main "$@"
    exit 0
fi

