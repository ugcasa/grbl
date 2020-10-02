#!/bin/bash
# guru-client - main command parser
# caa@ujo.guru 2020

export GURU_VERSION="0.6.0"
export GURU_HOSTNAME="$(hostname)"

## configurations

# export old configurations - TODO remove need of this
# edit should be removed already, but not tested
#source ~/.gururc

# export current configuration - TODO fully implement finally, you lazy hippy!
source ~/.gururc2

# user configuration overwrites
[[ $GURU_USER_NAME ]] && export GURU_USER=$GURU_USER_NAME
[[ $GURU_FLAG_COLOR ]] && export GURU_TERMINAL_COLOR=true
[[ $GURU_FLAG_VERBOSE ]] && export GURU_VERBOSE=$GURU_FLAG_VERBOSE

### include core modules

# include client sytem tools
source $GURU_BIN/system.sh
# include configuration tools
source $GURU_BIN/config.sh
# include mount tools
source $GURU_BIN/mount.sh
# import common functions
source $GURU_BIN/common.sh
# include daemon tools
source $GURU_BIN/daemon.sh


core.parser () {                                                                        # main command parser

    tool="$1" ; shift                                                                   # store tool call name and shift arguments left
    export GURU_CMD="$tool"                                                             # Store tool call name to other functions
    export GURU_SYSTEM_STATUS="processing $tool"                                        # system status can use as part of error exit message
    case "$tool" in
        # Core commands                                                                 # core and module scripts are combined to one folder during installation
                        status)  core.$tool                             ; return $? ;;  # core controls
               start|poll|kill)  daemon.$tool                           ; return $? ;;  # daemon controls
                          stop)  touch "$HOME/.guru-stop"               ;;              # request daemon to stop ít self, use kill if need reltime
                      document)  $tool "$@"                             ; return $? ;;  # one function prototypes are in 'function.sh'
                         radio)  DISPLAY=0; $tool.py "$@"               ; return $? ;;  # leave background + set display
                   help|--help)  core.help "$@"                         ; return 0  ;;  # help printout
                       unmount)  mount.main unmount "$1"                ; return $? ;;  # alias for un-mounting
                         shell)  core.shell "$@"                        ; return $? ;;  # guru in terminal mode
                     uninstall)  bash "$GURU_BIN/$tool.sh" "$@"         ; return $? ;;  # Get rid of this shit
                          test)  bash "$GURU_BIN/test/test.sh" "$@"     ; return $? ;;  # tester
                 version|--ver)  printf "guru-client v.%s\n" "$GURU_VERSION"        ;;  # version output
                            "")  core.shell ;;
                             *)  core.select_module "$tool" "$@"          ; return $? ;;
        esac
    return 0
}


core.select_module () {
    local tool=$1 ; shift
    for _module in ${GURU_MODULES[@]} ; do
        if [[ "$_module" == "$tool" ]] ; then
            gmsg -v2 -c green "$tool:$_module"
            [[ -f $GURU_BIN/$_module.sh ]] && $_module.sh "$@"  || gmsg -v2 -c black "no match: $_module.sh"
            [[ -f $GURU_BIN/$_module.py ]] && $_module.py "$@"  || gmsg -v2 -c black "no match: $_module.py"
            [[ -f $GURU_BIN/$_module ]] && $_module "$@"        || gmsg -v2 -c black "no match: $_module"
            return $?
         else
             gmsg -v3 -c red "$tool:$_module"
        fi
    done
    gmsg -v1 "passing request to os.."
    $tool "$@"
}


core.help () {                                                          # help prinout TODO: re-write
    # TODO re-organize by function category
    gmsg -v1 -c white "guru-client help ------------------------------------------"
    gmsg -v2
    gmsg -v0  "usage:   $GURU_CALL [-flags] [tool] [argument] [variables]"
    gmsg -v1
    gmsg -v0 -c white  "Flags"
    gmsg -v0 " -v   set verbose, headers and success are printed out"
    gmsg -v0 " -V   more deep verbose"
    gmsg -v0 " -l   set logging on to file $GURU_LOG"
    gmsg -v0 " -f   set force mode on, be more aggressive"
    gmsg -v0 " -u   run as user"
    gmsg -v2
    gmsg -v0 -c white  "connection tools"
    gmsg -v0 "  remote          accesspoint access tools"
    gmsg -v0 "  ssh             ssh key'and connection tools"
    gmsg -v0 "  mount|umount    mount remote locations"
    gmsg -v0 "  phone           get data from android phone"
    gmsg -v2
    gmsg -v0 -c white  "work track and documentation"
    gmsg -v0 "  note            greate and edit daily notes"
    gmsg -v0 "  timer           work track tools"
    gmsg -v0 "  translate       google translator in terminal"
    gmsg -v0 "  document        compile markdown to .odt format"
    gmsg -v0 "  scan            sane scanner tools"
    gmsg -v2
    gmsg -v1 -c white  "clipboard tools"
    gmsg -v1 "  stamp           time stamp to clipboard and terminal"
    gmsg -v2
    gmsg -v0 -c white  "entertainment"
    gmsg -v0 "  news|uutiset    text tv type reader for rss news feeds"
    gmsg -v0 "  play            play videos and music"
    gmsg -v0 "  silence         kill all audio and lights "
    gmsg -v2
    gmsg -v1 -c white  "hardware and io devices"
    gmsg -v1 "  input           to control varies input devices (keyboard etc)"
    gmsg -v1 "  keyboard        to setup keyboard shortcuts"
    gmsg -v1 "  radio           listen FM- radio (HW required)"
    gmsg -v2
    gmsg -v0 -c white  "system tools"
    gmsg -v0 "  install         install tools "
    gmsg -v0 "  uninstall       remove guru toolkit "
    gmsg -v1 "  set             set options "
    gmsg -v1 "  counter         to count things"
    gmsg -v0 "  status          status of stuff"
    gmsg -v0 "  upgrade         upgrade guru toolkit "
    gmsg -v1 "  shell           start guru shell"
    gmsg -v0 "  version         printout version "
    gmsg -v2 "  os              basic operating system library"
    gmsg -v2
    gmsg -v0 -c white  "examples"
    gmsg -v0 "  $GURU_CALL note yesterday           open yesterdays notes"
    gmsg -v2 "  $GURU_CALL install mqtt-server      isntall mqtt server"
    gmsg -v1 "  $GURU_CALL ssh key add github       addssh keys to github server"
    gmsg -v0 "  $GURU_CALL timer start at 12:00     start work time timer"
    gmsg -v0
    gmsg -v1 "More detailed help, try '$GURU_CALL <tool> help'"
    gmsg -v0 "Use verbose mode -v to get more information in help printout. Even more detailed, try -V"
    gmsg -v1
}


core.shell () {                                                      # terminal loop
    # Terminal looper

        render_path () {
            local _path="$(pwd)"
            if [[ "$_path" == "$HOME" ]] ; then _path='~' ; fi
            local _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            local c_user=$(eval echo '$C_'"${GURU_COLOR_PATH_USER^^}")
            local c_at=$(eval echo '$C_'"${GURU_COLOR_PATH_AT^^}")
            local c_call=$(eval echo '$C_'"${GURU_COLOR_PATH_CALL^^}")
            local c_dir=$(eval echo '$C_'"${GURU_COLOR_PATH_DIR^^}")

            printf "$c_user$GURU_USER$c_at@$c_call$_GURU_CALL$c_dir:$C_BLACK$_path$ $C_NORMAL"
        }
    gmsg "$GURU_CALL in shell mode (type 'help' enter for help)"

    while : ; do
            config.load "$GURU_CFG/$GURU_USER/user.cfg" >/dev/null
            source ~/.gururc2
            GURU_VERBOSE=2
            _GURU_CALL="$GURU_CALL"
            GURU_CALL='$'
            read -e -p "$(render_path)" "cmd"
            case "$cmd" in  exit|q) return 0 ;; esac
            core.parser $cmd
        done
    return $?
}


core.process_opts () {                                                  # argument parser

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

core.main () {                                                          # main run trough

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
            core.parser "$@"                                                            # with arguments go to parser
            _error_code=$?
        else
            core.shell                                                               # guru without parameters starts terminal loop
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

        core.process_opts $@
        core.main $ARGUMENTS
        exit $?
    fi
