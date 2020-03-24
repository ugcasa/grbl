#!/bin/bash
# guru tool-kit - caa@ujo.guru 2020
export GURU_VERSION="0.4.8"

source $HOME/.gururc                              # user and platform settings (implement here, always up to date)
source $GURU_BIN/functions.sh                     # common functions, if no .sh, check here
source $GURU_BIN/remote.sh
source $GURU_BIN/note.sh
source $GURU_BIN/timer.sh
source $GURU_BIN/mount.sh                         # common functions, if no .sh, check here
source $GURU_BIN/lib/deco.sh                      # text decorations, functions like PASSED, ONLINE ..
source $GURU_BIN/lib/common.sh

#echo "status: $GURU_SYSTEM_STATUS $GURU_FILESERVER_STATUS"

main.parser () {
    # parse arguments and delivery variables to corresponding worker
    tool="$1"; shift                                                                 # store tool call name and shift arguments left
    export GURU_CMD="$tool"                                                          # Store tool call name to other functions
    export GURU_SYSTEM_STATUS="processing $tool"
    case "$tool" in
        check)              main.$tool "$@" ; return $? ;;                           # check and test cases
        tor|trans|upgrade|document|terminal)                                         # function tools
                            $tool "$@" ; return $? ;;
        test|unmount|mount|user|project|remote|counter|note|stamp|timer|tag|install)      # shell scrip tools
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
        *)                  printf "$GURU_CMD: command %s not found \n" "$tool"

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


main.check() {
    [ "$1" ] && tool="$1" ||read -r -p "select tool to test or all: " tool

    if [ "$tool" == "all" ] ; then
        msg "checking remote tools: " ;  remote.check
        msg "checking mount tools: "  ;   mount.check
        msg "checking timer tools: "  ;   timer.check
        msg "checking note tools: "   ;    note.check
        return 0
    fi

    if ! [ -f "$GURU_BIN/$tool.sh" ]; then
            msg "no tool'$tool' found"
            return 12
        fi

    $tool.check
    return $?
}


main.terminal() {
    # Terminal looper
    VERBOSE=true
    msg "$GURU_CALL in terminal mode (type 'help' enter for help)\n"
    while :
        do
            source $HOME/.gururc
            read -e -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd"
            [ "$cmd" == "exit" ] && return 0
            main.parser $cmd
        done
    return 123
}


main() {

    local error_code=0
    [ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG" # Remove old error messages
    export GURU_SYSTEM_PLATFORM="$(check_distro)"       # run wide platform check
    export GURU_SYSTEM_STATUS="starting.."              # needs to be "ready"
    export GURU_FILESERVER_STATUS="unknown"

    if [ "$GURU_FILESERVER_STATUS" != "online" ]; then
        mount.system                                    # mount system mount point
    fi

    if [ "$GURU_FILESERVER_STATUS" == "online" ] && [ "$GURU_SYSTEM_STATUS" != "ready" ]; then     # require track mount
        export GURU_SYSTEM_STATUS="ready"
    fi

    counter.main add guru-runned >/dev/null

    if [ "$1" ]; then
        main.parser "$@"                                                            # with arguments go to parser
        error_code=$?
    else
        main.terminal                                                               # guru without parameters starts terminal loop
        error_code=$?
    fi

    if (( error_code > 1 )); then                                                   # 1 is warning, no error output
        [ -f "$GURU_ERROR_MSG" ] && error_message=$(tail -n 1 $GURU_ERROR_MSG)      # TODO when re-write error less than 10 are warnings + list of them
        ERROR "$error_code while $GURU_SYSTEM_STATUS $error_message \n"       # print error
        [ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG"
    fi

    export GURU_SYSTEM_STATUS="done"
    return $error_code
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    export VERBOSE="$GURU_VERBOSE"                      # use verbose setting from personal config
    while getopts 'lvf' flag; do                          # if verbose flag given, overwrite personal config
        case "${flag}" in
            l)  export LOGGING="true"; shift;;
            v)  export VERBOSE="true"; shift ;;
            f)  export FORCE="true"; shift ;;
            *)  echo "invalid flag"
                exit 1
        esac
    done

    main "$@"
    exit $?

fi

