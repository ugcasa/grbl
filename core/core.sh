#!/bin/bash
# guru-client - main command parser
# caa@ujo.guru 2020

export GURU_VERSION="0.6.4"
# minimal process command
case "$1" in
    ver|version|--ver|--version) echo "guru-client v.$GURU_VERSION" ; exit 0 ;;
esac

# include configuration tools
source $GURU_BIN/config.sh
# source common variable
GURU_RC="$HOME/.gururc"
[[ -f $GURU_RC ]] && source $GURU_RC || config.main export $GURU_USER

# import common functions
source $GURU_BIN/common.sh
# include mount tools
source $GURU_BIN/mount.sh
# include client sytem tools
source $GURU_BIN/system.sh
# include daemon tools
source $GURU_BIN/daemon.sh
# export configuration

# user configuration overwrites
[[ $GURU_SYSTEM_NAME ]] && export GURU_CALL=$GURU_SYSTEM_NAME
[[ $GURU_FLAG_VERBOSE ]] && export GURU_VERBOSE=$GURU_FLAG_VERBOSE


## core functions

core.main () {
    # main function

    #counter.main add guru-runned >/dev/null

    # with arguments go to parser
    if [[ "$1" ]] ; then
            core.parser "$@"
            _error_code=$?
        else
            # guru without parameters starts terminal loop
            core.shell "$@"
            _error_code=$?
        fi

    # less than 100 are warnings, no error output
    if (( _error_code > 99 )); then
            gmsg -v2 -c dark_grey  "retuning error code $_error_code"
        fi

    return $_error_code
}


## code.help moved to common.sh


core.parser () {
    # main command parser
    tool="$1" ; shift
    export GURU_CMD="$tool"
    case "$tool" in
                           all)  core.multi_module_function "$@"        ; return $? ;;
                        status)  gmsg -c green "installed"              ; return 0 ;;
               start|poll|kill)  daemon.$tool                           ; return $? ;;
                          stop)  touch "$HOME/.guru-stop"               ;;
                      document)  $tool "$@"                             ; return $? ;;
                       unmount)  mount.main unmount "$@"                ; return $? ;;
                         radio)  DISPLAY=0; $tool.py "$@"               ; return $? ;;
                         shell)  core.shell "$@"                        ; return $? ;;
                     uninstall)  bash "$GURU_BIN/$tool.sh" "$@"         ; return $? ;;
                          test)  bash "$GURU_BIN/test/test.sh" "$@"     ; return $? ;;
       help|"?"|"-?"|--help|-h)  core.help $@ ; exit 0 ;;
                            "")  core.shell ;;
                             *)  core.run_module "$tool" "$@"           ; return $? ;;
    esac
    return 0
}


core.process_opts () {                                                  # argument parser

    TEMP=`getopt --long -o "vVWflu:h:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -v ) export GURU_VERBOSE=1      ; shift     ;;
            -V ) export GURU_VERBOSE=2      ; shift     ;;
            -W ) export GURU_VERBOSE=3      ; shift     ;;
            -f ) export GURU_FORCE=true     ; shift     ;;
            -l ) export GURU_LOGGING=true   ; shift     ;;
            -u ) core.change_user "$2"      ; shift 2   ;;
            -h ) export GURU_HOSTNAME=$2    ; shift 2   ;;
             * ) break                  ;;
        esac
    done;
    _arg="$@"
    [[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"
}


core.change_user () {
    # change user to unput ans
    local _input_user=$1
    if [[ "$_input_user" == "$GURU_USER" ]] ; then
            gmsg -c "user is already $_input_user"
            return 0
        fi

    export GURU_USER=$_input_user

    if [[ -d "$GURU_CFG/$GURU_USER" ]] ; then
            gmsg -c white "changing user to $_input_user"
            config.main export $_input_user
        else
            gmsg -c yellow "user configuration not exits"
        fi
}


core.run_module () {
    # check is given tool in module list and lauch first hit
    local tool=$1 ; shift
    local type_list=(".sh" ".py" "")

    for _module in ${GURU_MODULES[@]} ; do
        if [[ "$_module" == "$tool" ]] ; then
            for _type in ${type_list[@]} ; do
                if [[ -f "$GURU_BIN/$_module$_type" ]] ; then $_module$_type "$@" ; return $? ; fi
            done
        fi
    done

    gmsg -v1 "passing request to os.."
    $tool $@
    return $?
}


core.run_module_function () {
    # run module functions
    local tool=$1 ; shift
    local function_to_run=$1 ; shift

    for _module in ${GURU_MODULES[@]} ; do
                if [[ "$_module" == "$tool" ]] ; then
                    # fun shell script module functions
                    if [[ -f "$GURU_BIN/$_module.sh" ]] ; then
                            source $GURU_BIN/$_module.sh
                            $_module.main "$function_to_run" "$@"
                            return $?
                        fi
                    # run python module functions
                    if [[ -f "$GURU_BIN/$_module.py" ]] ; then
                            $_module.py "$function_to_run" "$@"
                            return $?
                        fi
                    # run binary module functions
                    if [[ -f "$GURU_BIN/$_module" ]] ; then
                            $_module "$function_to_run" "$@"
                            return $?
                        fi
                    fi
    done
    return 1
}


core.multi_module_function () {
    # run function name of all installed modules
    local function_to_run=$1 ; shift
    for _module in ${GURU_MODULES[@]} ; do
                gmsg -c $GURU_COLOR_HEADER2 "## $_module $function_to_run"

                # fun shell script module functions
                if [[ -f "$GURU_BIN/$_module.sh" ]] ; then
                        source $GURU_BIN/$_module.sh
                        $_module.main "$function_to_run" "$@"
                    fi
                # run python module functions
                if [[ -f "$GURU_BIN/$_module.py" ]] ; then
                        $_module.py "$function_to_run" "$@"
                    fi
                # run binary module functions
                if [[ -f "$GURU_BIN/$_module" ]] ; then
                        $_module "$function_to_run" "$@"
                    fi
    done
    return 1
}


core.shell () {                                                      # terminal loop
    # Terminal looper

        render_path () {
            # todo this is broken
            local _path="$(pwd)"
            if [[ "$_path" == "$HOME" ]] ; then _path='~' ; fi
            local _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
            local c_user=$(eval echo '$C_'"${GURU_COLOR_PATH_USER^^}")
            local c_at=$(eval echo '$C_'"${GURU_COLOR_PATH_AT^^}")
            local c_call=$(eval echo '$C_'"${GURU_COLOR_PATH_CALL^^}")
            local c_sepa=$(eval echo '$C_'"${GURU_COLOR_PATH_SEPA^^}")
            local c_dir=$(eval echo '$C_'"${GURU_COLOR_PATH_DIR^^}")
            local c_input=$(eval echo '$C_'"${GURU_COLOR_PATH_INPUT^^}")

            printf "$c_user$GURU_USER$c_at@$c_call$_GURU_CALL$c_sepa:$c_dir$_path$ $c_input"
            gmsg -n -c normal
        }

        inc_verbose () {
            (( _verbose<2 )) && let _verbose++
            cmd=
        }

        dec_verbose () {
            (( _verbose>0 )) && let _verbose--
            cmd=
        }


    gmsg "$GURU_CALL in shell mode (type 'help' enter for help)"

    local _verbose=1
    while : ; do
            #config.export "$GURU_CFG/$GURU_USER/user.cfg" >/dev/null
            source $GURU_RC
            GURU_VERBOSE=$_verbose
            # set call name off, affects help print out
            _GURU_CALL="$GURU_CALL" ; GURU_CALL=
            read -e -p "$(render_path)" "cmd"
            case "$cmd" in exit|q|quit)  break ;;
                                     -V)  inc_verbose ;;
                                     -v)  dec_verbose ;;
                esac
            [[ $cmd ]] && core.parser $cmd
        done
    gmsg -v2 "take care!"
    return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        core.process_opts $@
        core.main $ARGUMENTS
        exit $?
    fi
