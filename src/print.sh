#!/bin/bash
# sshfs mount functions for guru-client

source $GURU_BIN/common.sh

print.main() {
    [[ "$GURU_INSTALL" == "server" ]] && print.warning

    command="$1"; shift
    case "$command" in
             label|help)    print.$command "$@"                           ; return $? ;;
                   test)    source $GURU_BIN/test.sh; print.test "$@"     ; return $? ;;
                      *)    print.help ;;
    esac
    return 0
}

print.help () {
    echo "-- guru-client print help -----------------------------------------------"
    printf "usage:\t %s print [command] [arguments] \n\t $0 print [source] [target] \n" "$GURU_CALL"
    printf "\ncommands:\n"
    printf " label                     print label \n"
    printf "\nexample:"
    printf "    %s print mount /home/%s/share /home/%s/mount/%s/\n" "$GURU_CALL" "$GURU_ACCESS_POINT_USER" "$USER" "$GURU_ACCESS_POINT"
}

print.label () {
    echo "printing label"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    print.main "$@"
    exit 0
fi

