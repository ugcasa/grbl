# guru tool-kit common functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"

source "$(dirname "${BASH_SOURCE[0]}")/os.sh"       # folder by caller bubblecum cause 'source "lib/counter.sh"' not worky
source "counter.sh"                                 # TODO how to dirname brewious folder


msg() {
    #function for ouput messages and make log notifications
    # input -[flag] "message string"
    [ "$1" ] || return 0

    case "$1" in
        -l|--log)   [ "$GURU_SYSTEM_STATUS"=="online" ]  && shift; printf "$@" >>"$GURU_LOG" ;;
        *)          [ "$VERBOSE" ]                       && printf "$@" ;;
    esac
}

export -f msg
