#!/bin/bash
# sshfs mount functions for grbl
source $GRBL_BIN/common.sh

print.main() {
    [[ "$GRBL_INSTALL" == "server" ]] && print.warning

    command="$1"; shift
    case "$command" in
             label|help)    print.$command "$@"                           ; return $? ;;
                   test)    source $GRBL_BIN/test.sh; print.test "$@"     ; return $? ;;
                 status)    gr.msg -c black "printer not connected" ;;
                      *)    print.help ;;
    esac
    return 0
}


print.help () {
    gr.msg -v1 -c white "grbl print help "
    gr.msg -v0  "usage:    $GRBL_CALL print [label] "
    gr.msg -v1 -c white "commands:"
    gr.msg -v1  " label                     print label "
    gr.msg -v2
}


print.label () {
    echo "printing label"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GRBL_RC"
    print.main "$@"
    exit 0
fi

