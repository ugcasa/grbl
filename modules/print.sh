#!/bin/bash
# sshfs mount functions for guru-client
source $GURU_BIN/common.sh

print.main() {
    [[ "$GURU_INSTALL" == "server" ]] && print.warning

    command="$1"; shift
    case "$command" in
             label|help)    print.$command "$@"                           ; return $? ;;
                   test)    source $GURU_BIN/test.sh; print.test "$@"     ; return $? ;;
                 status)    gr.msg -c black "printer not connected" ;;
                      *)    print.help ;;
    esac
    return 0
}


print.help () {
    gr.msg -v1 -c white "guru-client print help "
    gr.msg -v0  "usage:    $GURU_CALL print [label] "
    gr.msg -v1 -c white "commands:"
    gr.msg -v1  " label                     print label "
    gr.msg -v2
}


print.label () {
    echo "printing label"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    print.main "$@"
    exit 0
fi

