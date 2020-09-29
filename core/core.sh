#!/bin/bash
# guru-client - main command parser
# caa@ujo.guru 2020

export GURU_VERSION="0.6.0"
export GURU_HOSTNAME="$(hostname)"

# daemon pollers:
# while true ; do ps auxf |grep "guru" |grep "start" |grep -v "color=auto" ; sleep 1 ; clear ; done
# while true ; do ls .guru-stop ; sleep 1 ; clear ; done
# while true ; do cat $GURU_SYSTEM_MOUNT/.daemon-pid ; sleep 2 ; clear ; done

### configurations

# export old configurations - TODO remove need of this
source ~/.gururc
# export current configuration - TODO fully implement!
source ~/.gururc2
[[ $GURU_USER_NAME ]] && export GURU_USER=$GURU_USER_NAME
[[ $GURU_FLAG_COLOR ]] && export GURU_TERMINAL_COLOR=true
[[ $GURU_FLAG_VERBOSE ]] && export GURU_VERBOSE=$GURU_FLAG_VERBOSE

### core modules

# include client sytem tools
source $GURU_BIN/system.sh
# include configuration tools
source $GURU_BIN/config.sh
# include quick try outs - TODO remove need of this
source $GURU_BIN/functions.sh
# include mount tools
source $GURU_BIN/mount.sh
# import common functions - TODO remove need of this
source $GURU_BIN/common.sh
# include daemon tools
source $GURU_BIN/daemon.sh


main.parser () {                                                                        # main command parser

    tool="$1"; shift                                                                    # store tool call name and shift arguments left
    export GURU_CMD="$tool"                                                             # Store tool call name to other functions
    export GURU_SYSTEM_STATUS="processing $tool"                                        # system status can use as part of error exit message

    case "$tool" in
                         start)  daemon.main start guru-daemon          ; return $? ;;  # second parameter is a name for process
                          stop)  touch "$HOME/.guru-stop"               ;;              # stop guru daemon
                      document)  $tool "$@"                             ; return $? ;;  # one function prototypes are in 'function.sh'
                    trans|user)  $tool "$@"                             ; return $? ;;  # function.sh prototypes
              clear|ls|cd|echo)  $tool "$@"                             ; return $? ;;  # os command pass trough
  tor|conda|phone|play|vol|yle)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
       stamp|timer|tag|install)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
           system|mount|remote)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
       scan|input|counter|note)  $tool.sh "$@"                          ; return $? ;;  # shell script tools
           project|mqtt|config)  $tool.sh "$@"                          ; return $? ;;  # configuration tools
              keyboard|uutiset)  $tool.py "$@"                          ; return $? ;;  # python scripts
                         radio)  DISPLAY=0; $tool.py "$@"               ; return $? ;;  # leave background + set display
                   help|--help)  main.help "$@"                         ; return 0  ;;  # help printout
                       unmount)  mount.main unmount "$1"                ; return $? ;;  # alias for un-mounting
                      terminal)  main.terminal "$@"                     ; return $? ;;  # guru in terminal mode
             ssh|os|common|tme)  $GURU_BIN/$tool.sh "$@"                ; return $? ;;  # direct lib calls
                   input|hosts)  $GURU_BIN/trial/$tool.sh "$@"          ; return $? ;;  # place for shell script prototypes and experiments
         tme|fmradio|datestamp)  $GURU_BIN/trial/$tool.py "$@"          ; return $? ;;  # place for python script prototypes and experiments
                     uninstall)  bash "$GURU_BIN/$tool.sh" "$@"         ; return $? ;;  # Get rid of this shit
                          test)  bash "$GURU_BIN/test/test.sh" "$@"     ; return $? ;;  # tester
                          gmsg)  $tool "$@"                             ; return $? ;;  # direct access to core functions
                 version|--ver)  printf "guru-client v.%s\n" "$GURU_VERSION"  ;;                      # version output
                            "")  return 0 ;;
                             *)  gmsg -v "passing request to os.."
                                 $tool $@                               ; return $? ;;
        esac
    return 0
}

main.help () {                                                          # help prinout TODO: re-write
    # TODO re-organize by function category
    gmsg -v1 -c white "-- guru-client main help ------------------------------------------"
    gmsg -v0  "usage:\t $GURU_CALL [tool] [argument] [variables]"
    gmsg -v0 -c white  "file control:"
    gmsg -v0 "  mount|umount    mount remote locations"
    gmsg -v0 "  remote          remote file pulls and pushes"
    gmsg -v0 "  phone           get data from android phone"
    gmsg -v2
    gmsg -v0 -c white  "work track and documentation:"
    gmsg -v0 "  notes           open daily notes"
    gmsg -v0 "  timer           work track tools"
    gmsg -v0 "  translate       google translator in terminal"
    gmsg -v0 "  document        compile markdown to .odt format"
    gmsg -v0 "  scan            sane scanner tools"
    gmsg -v0 "  stamp           time stamp to clipboard and terminal"
    gmsg -v2
    gmsg -v0 -c white  "relax:"
    gmsg -v0 "  news|uutiset    text tv type reader for rss news feeds"
    gmsg -v0 "  play            play videos and music"
    gmsg -v0 "  silence         kill all audio and lights "
    gmsg -v2
    gmsg -v0 -c white  "hardware and io devices:"
    gmsg -v0 "  input           to control varies input devices (keyboard etc)"
    gmsg -v0 "  keyboard        to setup keyboard shortcuts"
    gmsg -v0 "  radio           fm-radio (hackrone rf)"
    gmsg -v2
    gmsg -v0 -c white  "system tools:"
    gmsg -v0 "  install         install tools "
    gmsg -v0 "  set             set options "
    gmsg -v0 "  counter         to count things"
    gmsg -v0 "  status          status of stuff"
    gmsg -v0 "  upgrade         upgrade guru toolkit "
    gmsg -v0 "  uninstall       remove guru toolkit "
    gmsg -v0 "  terminal        start guru toolkit in terminal mode"
    gmsg -v0 "  version         printout version "
    gmsg -v2
    gmsg -v0 -c white  "libraries:"
    gmsg -v0 "  ssh             basic ssh library"
    gmsg -v0 "  os              basic operating system library"
    gmsg -v0 "  common          some common function library"
    gmsg -v2
    gmsg -v0 -c white  "examples:"
    gmsg -v0 "  $GURU_CALL note yesterday ('%s note help' m morehelp)"
    gmsg -v0 "  $GURU_CALL install mqtt-server "
    gmsg -v0 "  $GURU_CALL ssh key add github "
    gmsg -v0 "  $GURU_CALL timer start at 12:00 "
    gmsg -v0 "  $GURU_CALL keyboard add-shortcut terminal $GURU_TERMINAL F1"
    gmsg -v0 "  $GURU_CALL -v mount not"
    gmsg -v0

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

        render_path () {
            local _path="$(pwd)"
            if [[ "$_path" == "$HOME" ]] ; then _path='~' ; fi
            local _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            local c_user=$(eval echo '$C_'"${GURU_COLOR_PATH_USER^^}")
            local c_at=$(eval echo '$C_'"${GURU_COLOR_PATH_AT^^}")
            local c_call=$(eval echo '$C_'"${GURU_COLOR_PATH_CALL^^}")
            local c_dir=$(eval echo '$C_'"${GURU_COLOR_PATH_DIR^^}")

            printf "$c_user$GURU_USER$c_at@$c_call$GURU_CALL$c_dir:$_path> $C_NORMAL"
        }

    GURU_VERBOSE=1
    msg "$GURU_CALL in terminal mode (type 'help' enter for help)\n"

    while : ; do
            config.load "$GURU_CFG/$GURU_USER/user.cfg" >/dev/null
            source ~/.gururc2
            read -e -p "$(render_path)" "cmd"
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
    [[ -f "$GURU_ERROR_MSG" ]] && rm -f "$GURU_ERROR_MSG"                                 # Remove old error messages

    export GURU_SYSTEM_PLATFORM="$(check_distro)"                                       # run wide platform check
    export GURU_SYSTEM_STATUS="starting.."                                              # needs to be "ready"
    export GURU_CLOUD_STATUS="unknown"

    if [[ "$GURU_CLOUD_STATUS" != "online" ]] ; then
            mount.system                                                                # mount system mount point
        fi

    if [[ "$GURU_CLOUD_STATUS" == "online" ]] && [[ "$GURU_SYSTEM_STATUS" != "ready" ]] ; then
            export GURU_SYSTEM_STATUS="ready"                                           # require track mount
        fi

    counter.main add guru-runned >/dev/null                                             # add counter

    if [[ "$1" ]] ; then
            main.parser "$@"                                                            # with arguments go to parser
            _error_code=$?
        else
            main.terminal                                                               # guru without parameters starts terminal loop
            _error_code=$?
        fi

    if (( _error_code > 1 )); then                                                      # 1 is warning, no error output
            [[ -f "$GURU_ERROR_MSG" ]] && error_message=$(tail -n 1 $GURU_ERROR_MSG)      # TODO when re-write error less than 10 are warnings + list of them
            ERROR "$_error_code while $GURU_SYSTEM_STATUS $error_message"            # print error
            [[ -f "$GURU_ERROR_MSG" ]] && rm -f "$GURU_ERROR_MSG"
        fi

    export GURU_SYSTEM_STATUS="done"
    return $_error_code
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then                            # user and platform settings (implement here, always up to date)

        main.process_opts $@
        main.main $ARGUMENTS
        exit $?
    fi
