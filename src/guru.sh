#!/bin/bash
# guru tool-kit - caa@ujo.guru 2020


source "$HOME/.gururc"                              # user and platform settings (implement here, always up to date)
source "$GURU_BIN/functions.sh"                     # common functions, if no ".sh", check here
source "$GURU_BIN/remote.sh"
source "$GURU_BIN/note.sh"
source "$GURU_BIN/timer.sh"
source "$GURU_BIN/mount.sh"                         # common functions, if no ".sh", check here
source "$GURU_BIN/lib/deco.sh"                      # text decorations, functions like PASSED, ONLINE ..
source "$GURU_BIN/lib/common.sh"


[ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG" # Remove old error messages
export GURU_VERSION="0.4.8"
export GURU_SYSTEM_PLATFORM="$(check_distro)"       # run wide platform check
export GURU_SYSTEM_STATUS="starting.."              # needs to be "ready"
export GURU_FILESERVER_STATUS="unknown"

export VERBOSE="$GURU_VERBOSE"                      # use verbose setting from personal config
while getopts 'v' flag; do                          # if verbose flag given, overwrite personal config
  case "${flag}" in
    v)  export VERBOSE=true; shift ;;
    *)  echo "invalid flag"
        main.help
        ;;
  esac
done

mount.check_system >/dev/null

if ! [ "$GURU_FILESERVER_STATUS" == "online" ]; then
    msg "mounting system folders $GURU_TRACK.. "
    mount.remote "$GURU_CLOUD_TRACK" "$GURU_TRACK"
fi

if [ "$GURU_FILESERVER_STATUS" == "online" ] && [ "$GURU_SYSTEM_STATUS" != "ready" ]; then     # require track mount
    export GURU_SYSTEM_STATUS="ready"
fi

counter.main add guru-runned >/dev/null

#echo "status: $GURU_SYSTEM_STATUS $GURU_FILESERVER_STATUS"

main.parser () {
    # parse arguments and delivery variables to corresponding worker
    tool="$1"; shift                                                                 # store tool call name and shift arguments left
    export GURU_CMD="$tool"                                                          # Store tool call name to other functions
    export GURU_SYSTEM_STATUS="processing $tool"
    case "$tool" in
        check|test)         main.$tool "$@" ; return $? ;;                           # check and test cases
        tor|trans|upgrade|document|terminal)                                         # function tools
                            $tool "$@" ; return $? ;;
        unmount|mount|user|project|remote|counter|note|stamp|timer|tag|install)      # shell scrip tools
                            $tool.sh "$@" ; return $? ;;
        clear|ls|cd|echo)   $tool "$@" ; return $? ;;                                # os command pass trough
        ssh|os|common|tme)  lib/$tool.sh "$@"; return $? ;;                          # direct lib calls
        uutiset)            $tool.py "$@" ; return $? ;;                             # python scripts
        radio)              DISPLAY=:0 ; $tool.py "$@" & ;;                          # leave background + set display
        slack|set)          $tool "$@" ; return $? ;;                                # function prototypes
        keyboard|scan|input|phone|play|vol|yle)                                      # shell scipt prototypes
                            $tool.sh "$@" ; return $? ;;
        uninstall)          bash $GURU_BIN/uninstall.sh "$@" ; return $? ;;          # Get rid of this shit
        version|--ver)      printf "guru tool-kit v.$GURU_VERSION \n" ; return 0 ;;
        help|-h|--help)     main.help "$@" ; return 0 ;;                             # hardly never updated help printout
        *)                  printf "$GURU_CMD: command not found\n"
                            $tool
    esac
}


main.test() {

    export VERBOSE="true"                                                           # dev test verbose is always on

    case "$1" in

        1|2|3|4|5|all )
            main.test_tool mount "$1"
            main.test_tool remote "$1"
            main.test_tool note "$1"
            return 0
            ;;

        help|-h )
            main.test_help
            return 0
            ;;
        *)
            main.test_tool "$@"
            return $?
    esac
}


main.help () {
    echo "-- guru tool-kit main help ------------------------------------------"
    printf "usage:\t %s [tool] [argument] [variables]\n" "$GURU_CALL"
    printf "\nfile control:\n"
    echo "  mount|umount    mount remote locations"
    echo "  remote          remote file pulls and pushes"
    echo "  phone           get data from android phone"

    printf "\nwork track and documentation:\n"
    echo "  notes           open daily notes"
    echo "  timer           work track tools"
    echo "  translate       google translator in terminal"
    echo "  document        compile markdown to .odt format"
    echo "  scan            sane scanner tools"
    echo "  stamp           time stamp to clipboard and terminal"

    printf "\nrelax:\n"
    echo "  news|uutiset    text tv type reader for rss news feeds"
    echo "  play            play videos and music"
    echo "  silence         kill all audio and lights "

    printf "\nhardware and io devices:\n"
    echo "  input           to control varies input devices (keyboard etc)"
    echo "  keyboard        to setup keyboard shortcuts"
    echo "  radio           fm-radio (hackrone rf)"

    printf "\nsystem tools:\n"
    echo "  install         install tools "
    echo "  set             set options "
    echo "  counter         to count things"
    echo "  status          status of stuff"
    echo "  upgrade         upgrade guru toolkit "
    echo "  uninstall       remove guru toolkit "
    echo "  terminal        start guru toolkit in terminal mode"
    echo "  version         printout version "

    printf "\nlibraries:\n"
    echo "  ssh             basic ssh library"
    echo "  os              basic operating system library"
    echo "  common          some common function library"

    printf "\nexamples:\n"
    printf "\t %s note yesterday ('%s note help' m morehelp)\n" "$GURU_CALL"
    printf "\t %s install mqtt-server \n" "$GURU_CALL"
    printf "\t %s ssh key add github \n" "$GURU_CALL"
    printf "\t %s timer start at 12:00 \n" "$GURU_CALL"
    printf "\t %s keyboard add-shortcut terminal %s F1\n" "$GURU_CALL" "$GURU_TERMINAL"
    printf "\t %s mount /home/%s/share /home/%s/mount/%s/ \n"\
           "$GURU_CALL" "$GURU_REMOTE_FILE_SERVER_USER" "$USER" "$GURU_REMOTE_FILE_SERVER"
    echo
}


main.test_help () {
    echo "-- guru tool-kit main test help -------------------------------------"
    printf "Usage:\t %s test [<tool>|all] <level> \n" "$GURU_CALL"
    printf "\nCommands:\n"
    printf " all          test all tools on level all\n"
    printf " <level>      numeral level of test detail where: \n"
    printf "              1 = mainly checks \n"
    printf "              2 = more tetailed tests \n"
    printf "              3 = hot locations \n"
    printf "Example:\n"
    printf "\t %s test remote 1 \n" "$GURU_CALL"
    printf "\t %s test mount 2 \n"  "$GURU_CALL"
    printf "\t %s test all \n"      "$GURU_CALL"
}


main.check() {
    [ "$1" ] && tool="$1" ||read -r -p "select tool to test or all: " tool

    if [ "$tool" == "all" ] ; then
        msg "checking remote tools: " ;  remote.check
        msg "checking mount tools: "  ;   mount.check
        msg "checking timer tools: "  ;   timer.check
        msg "checking note tools: "   ;    note.check
        return 0
    fi

    echo "no tool'$tool' found" >"$GURU_ERROR_MSG"
    [ -f "$GURU_BIN/$tool.sh" ] || return 12
    $tool.check
}


main.terminal() {
    # Terminal looper
    printf "$GURU_CALL in terminal mode (type 'help' enter for help)\n"
    while :
        do
            source $HOME/.gururc
            read -e -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd"
            [ "$cmd" == "exit" ] && return 0
            main.parser $cmd
        done
    return 123
}


main.test_tool() {
    # Tool to test tools. Simply call sourced tool main function and parse normal commands
    mount.main check "$GURU_TRACK" || mount_sshfs "$GURU_CLOUD_TRACK" "$GURU_TRACK"
    [ "$2" ] && level="$2" || level="all"
    [ -f "$GURU_BIN/$1.sh" ] && source "$1.sh" || return 123
    local test_id=$(counter.main add guru-ui_test_id)
    printf "\nTEST $test_id: guru-ui $1 $(date) \n" | tee -a "$GURU_LOG"
    $1.main test "$level"
    return $?
}


main() {

    if [ "$1" ]; then
        main.parser "$@"                                                            # with arguments go to parser
        error_code=$?
    else
        main.terminal                                                               # guru without parameters starts terminal loop
        error_code=$?
    fi

    if (( error_code > 1 )); then                                                   # 1 is warning, no error output
        [ -f "$GURU_ERROR_MSG" ] && error_message=$(tail -n 1 $GURU_ERROR_MSG)      # TODO when re-write error less than 10 are warnings + list of them
        logger "[ERROR] $0 $GURU_CMD: $error_code: $error_message"                  # log errors
        printf "$ERROR $error: $error_message. status: $GURU_SYSTEM_STATUS\n"       # print error
        [ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG"
    fi

    export GURU_SYSTEM_STATUS="done"
    return $error_code
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi

