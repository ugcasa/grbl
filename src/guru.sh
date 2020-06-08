#!/bin/bash
# guru tool-kit - main command parser
# caa@ujo.guru 2020

export GURU_VERSION="0.5.2.9"
export GURU_HOSTNAME="$(hostname)"


source ~/.gururc
source ~/.gururc2
#  [[ -f $GURU_USER_RC ]] && source $GURU_USER_RC || source ~/.gururc2
   [[ $GURU_USER_NAME ]] && export GURU_USER=$GURU_USER_NAME
  [[ $GURU_FLAG_COLOR ]] && export GURU_TERMINAL_COLOR=true
[[ $GURU_FLAG_VERBOSE ]] && export GURU_VERBOSE=$GURU_FLAG_VERBOSE


source $GURU_BIN/system.sh                  # guru toolkit upgrade etc.
source $GURU_BIN/config.sh
source $GURU_BIN/functions.sh               # quick try outs TODO remove need of this
source $GURU_BIN/mount.sh                   # needed to keep track tiles up to date
source $GURU_BIN/lib/common.sh              # TODO remove need of this


main.parser () {                                                                        # main command parser
    tool="$1"; shift                                                                    # store tool call name and shift arguments left
    export GURU_CMD="$tool"                                                             # Store tool call name to other functions
    export GURU_SYSTEM_STATUS="processing $tool"                                        # system status can use as part of error exit message

    case "$tool" in
                      document)  $tool "$@"                             ; return $? ;;  # one function prototypes are in 'function.sh'
                trans|tor|user)  $tool "$@"                             ; return $? ;;  # function.sh prototypes
              clear|ls|cd|echo)  $tool "$@"                             ; return $? ;;  # os command pass trough
      conda|phone|play|vol|yle)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
       stamp|timer|tag|install)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
           system|mount|remote)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
       scan|input|counter|note)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
           project|mqtt|config)  $tool.sh "$@"                          ; return $? ;;  # configuration tools
              keyboard|uutiset)  $tool.py "$@"                          ; return $? ;;  # python scripts
                         radio)  DISPLAY=0; $tool.py "$@"               ; return $? ;;  # leave background + set display
                   help|--help)  main.help "$@"                         ; return 0  ;;  # help printout
                       unmount)  mount.main unmount "$1"                ; return $? ;;  # alias for un-mounting
                terminal|shell)  main.terminal "$@"                     ; return $? ;;  # guru in terminal mode
             ssh|os|common|tme)  $GURU_BIN/lib/$tool.sh "$@"            ; return $? ;;  # direct lib calls
                   input|hosts)  $GURU_BIN/trial/$tool.sh "$@"          ; return $? ;;  # place for shell script prototypes and experiments
         tme|fmradio|datestamp)  $GURU_BIN/trial/$tool.py "$@"          ; return $? ;;  # place for python script prototypes and experiments
                     uninstall)  bash "$GURU_BIN/$tool.sh" "$@"         ; return $? ;;  # Get rid of this shit
                          test)  bash "$GURU_BIN/test/test.sh" "$@"     ; return $? ;;  # tester
                 version|--ver)  printf "guru tool-kit v.%s\n" "$GURU_VERSION"  ;;                      # version output
                             *)  printf "%s confused: phrase '%s' unknown. you may try '%s help'\n" \
                                        "$GURU_CALL" "$tool" "$GURU_CALL"                               # false user input
        esac
    return 0
}

main.help () {                                                          # help prinout TODO: re-write
    # TODO re-organize by function category
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
    printf "\t %s -v mount notes" "$GURU_CALL"
    echo

    # FORCE=$temp_force                                        # return FORCE status
    # echo "invalid flag '$1' "
    # echo " -v   set verbose, headers and success are printed out"
    # echo " -V   more deep verbose"
    # echo " -l   set logging on to file $GURU_LOG"
    # echo " -f   set force mode on, be more aggressive"
    # echo " -u   run as user"
}

main.terminal () {                                                      # terminal loop
    # Terminal looper
    GURU_VERBOSE=true
    msg "$GURU_CALL in terminal mode (type 'help' enter for help)\n"
    while : ; do
            config.load "$GURU_CFG/$GURU_USER/user.cfg" # source $HOME/.gururc
            read -e -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd"
            case "$cmd" in  exit|q) return 0 ;; esac
            main.parser $cmd
        done
    return $?
}


main.process_opts () {                                                  # argument parser

    TEMP=`getopt --long -o "vVflu:h:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -v ) export GURU_VERBOSE=1      ; shift     ;;
            -V ) export GURU_VERBOSE=2      ; shift     ;;
            -f ) export GURU_FORCE=true     ; shift     ;;
            -l ) export GURU_LOGGING=true   ; shift     ;;
            -u ) export GURU_USER_NAME=$2   ; shift 2   ;;
            -h ) export GURU_HOSTNAME=$2    ; shift 2   ;;

             * ) break                  ;;
        esac
    done;
    _arg="$@"
    [[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"
}

main.main () {                                                          # main run trough

    local _error_code=0
    [ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG"                                 # Remove old error messages

    export GURU_SYSTEM_PLATFORM="$(check_distro)"                                       # run wide platform check
    export GURU_SYSTEM_STATUS="starting.."                                              # needs to be "ready"
    export GURU_CLOUD_STATUS="unknown"

    if [ "$GURU_CLOUD_STATUS" != "online" ]; then
            mount.system                                                                # mount system mount point
        fi

    if [ "$GURU_CLOUD_STATUS" == "online" ] && [ "$GURU_SYSTEM_STATUS" != "ready" ]; then
            export GURU_SYSTEM_STATUS="ready"                                           # require track mount
        fi

    counter.main add guru-runned                                                        # add counter

    if [ "$1" ]; then
            main.parser "$@"                                                            # with arguments go to parser
            _error_code=$?
        else
            main.terminal                                                               # guru without parameters starts terminal loop
            _error_code=$?
        fi

    if (( _error_code > 1 )); then                                                      # 1 is warning, no error output
            [ -f "$GURU_ERROR_MSG" ] && error_message=$(tail -n 1 $GURU_ERROR_MSG)      # TODO when re-write error less than 10 are warnings + list of them
            ERROR "$_error_code while $GURU_SYSTEM_STATUS $error_message \n"            # print error
            [ -f "$GURU_ERROR_MSG" ] && rm -f "$GURU_ERROR_MSG"
        fi

    export GURU_SYSTEM_STATUS="done"
    return $_error_code
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then                            # user and platform settings (implement here, always up to date)

        main.process_opts $@
        main.main $ARGUMENTS
        exit $?
    fi
