#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2022

# global variables
declare -x GURU_RC="$HOME/.gururc"
declare -x GURU_BIN="$HOME/bin"


declare -x GURU_VERSION=$(echo $(head -n1 $GURU_BIN/version) | tr -d '\n')
declare -x GURU_VERSION_NAME=$(echo $(tail $GURU_BIN/version -n +2 | head -n 1 ) | tr -d '\n')

# early exits
case $1 in version)
        echo "$GURU_VERSION $GURU_VERSION_NAME"
        exit 0
    esac

# check that config rc file exits
if [[ -f $GURU_RC ]] ; then
        gmsg -v3 -c deep_pink "sourcing configs.. "
        source $GURU_RC
    else
        # run user configuration if not exist
        source $HOME/bin/config.sh
        config.main export $USER
        source $GURU_RC
    fi

# determinate how to call guru, I prefer 'guru' or now more often alias 'gr'
[[ $GURU_SYSTEM_NAME ]] && export GURU_CALL=$GURU_SYSTEM_NAME

# everybody have daemons
source $GURU_BIN/daemon.sh


core.main () {
    # parsing the commands aka. module names

    local module="$1" ; shift

    case "$module" in

            all)
                    core.multi_module_function "$@"
                    return $? ;;

            uninstall)
                    bash "$GURU_BIN/$module.sh" "$@"
                    return $? ;;

            start|poll|kill)
                    #source $GURU_BIN/daemon.sh
                    daemon.$module
                    return $? ;;

            help|version)
                    core.$module
                    return $? ;;
            # "")
            #         core.shell
            #         return $? ;;

            *)
                    core.run_module "$module" "$@"
                    return $? ;;
        esac
}


core.stop () {
    # ask daemon to stop
    # daemon should get the message after next tick (about a second)

    source $GURU_BIN/system.sh

    system.main flag set stop
    reuturn $?
}


core.pause () {
    # ask daemon to pause
    # daemon should get the message after next tick (about a second)

    source $GURU_BIN/system.sh

    # toggle
    if system.flag pause ; then
            system.flag rm pause
        else
            system.flag set pause
        fi
    return 0
}


core.run_module () {
    # check is input in module list and if so, call module main

    local type_list=(".sh" ".py" "")
    local run_me=
    # echo "core.run_module got: $@" # debug shit

    # check is given command in reserved words, if so change argument order
    if grep -q -w "$1" <<<${GURU_SYSTEM_RESERVED_CMD[@]} ; then
            local function=$1 ; shift
            local module=$1 ; shift
            local command=$1 ; shift
            # echo "reserved word: $command" # debug shit
         else
            local module=$1 ; shift
            local command=$1 ; shift
            local function=$1 ; shift
            # echo "non reserved word: $command" # debug shit
        fi

    # echo "module:'$module' command:'$command' function:'$function' list:'$@'" # debug shit

    # go trough $modules if match do the $command and pas $function ans rest
    for _module in ${GURU_MODULES[@]} ; do
            # not match
            if ! [[ "$_module" == "$module" ]] ; then
                    continue
                fi

            # match, go trough possible filenames
            for _type in ${type_list[@]} ; do
                    # module in recognized format found
                    if [[ -f "$GURU_BIN/$_module$_type" ]] ; then
                            # make command
                            run_me="$_module$_type $command $function $@"

                            # run the command and return what ever module did return

                            # speak out what ever module returns
                            if [[ $GURU_SPEAK ]]  ; then
                                    local module_output="$(${run_me[@]//  / })"
                                    gmsg "guru replies: '$module_output'"
                                    espeak -p $GURU_SPEAK_PITCH -s $GURU_SPEAK_SPEED -v $GURU_SPEAK_LANG "$module_output"
                                    return $?
                                fi

                            ${run_me[@]//  / }
                            # echo "running module: ${run_me[@]//  / }" # debug shit
                            return $?
                        fi
                done
        done

    echo "guru recognize no module named '$module'"
    return $?

    # if gask "passing to request to operating system?" ; then
    #    $module $@
    #   fi

    #
}


core.run_module_function () {
    # run methods (functions) in module

    # guru add ssh key @ -> guru ssh key add @
    if ! grep -q -w "$1" <<<${GURU_SYSTEM_RESERVED_CMD[@]} ; then
            local module=$1 ; shift # note: there was reason to use shift over $2, $3, may just be cleaner
            local command=$1 ; shift
            local function=$1 ; shift
            gmsg -v4 "non reserved word: $command"
         else
            local function=$1 ; shift
            local module=$1 ; shift
            local command=$1 ; shift
            gmsg -v4 "reserved word: $command"
        fi

    # echo "module:'$module' command:'$command' function:'$function' '$@'" # debug shit

    for _module in ${GURU_MODULES[@]} ; do
            if [[ "$_module" == "$module" ]] ; then

                # include all module functions and run called
                if [[ -f "$GURU_BIN/$_module.sh" ]] ; then
                        source $GURU_BIN/$_module.sh
                        $_module.main "$command" "$function" "$@"
                        return $?
                    fi
                # run one function in python script
                if [[ -f "$GURU_BIN/$_module.py" ]] ; then
                        $_module.py "$command" "$function" "$@"
                        return $?
                    fi
                # run binaries
                if [[ -f "$GURU_BIN/$_module" ]] ; then
                        $_module "$command" "$function" "$@"
                        return $?
                    fi
                fi
        done
    # if here something went wrong, raise warning
    gmsg -v2 -c yellow "in core.run_module_function something went wrong when tried to run "$function" in '$module'"
    return 12
}


core.multi_module_function () {
    # run function name of all installed modules

    local function_to_run=$1 ; shift

    for _module in ${GURU_MODULES[@]} ; do
            gmsg -c dark_golden_rod "$_module $function_to_run"

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

    gmsg -v2 -c yellow "in core.multi_module_function something went wrong when tried to run "$function_to_run" in '$_module'"
    return 13
}


core.change_user () {
    # change guru user temporarily

    local _input_user=$1
    if [[ "$_input_user" == "$GURU_USER" ]] ; then
            gmsg -c yellow "user is already $_input_user"
            return 0
        fi

    export GURU_USER=$_input_user
    source $GURU_BIN/config.sh

    if [[ -d "$GURU_CFG/$GURU_USER" ]] ; then
            gmsg -c white "changing user to $_input_user"
            config.main export $_input_user
        else
            gmsg -c yellow "user configuration not exits"
        fi
}


core.help () {
    # functional core help

    core.help_flags () {
            gmsg -v2
            gmsg -v1 -c white "option flags:"
            gmsg -v2
            gmsg -v1 " -v 1..4          verbose level, adds headers and some details"
            gmsg -v1 " -u <user_name>   change guru user name temporary  "
            gmsg -v1 " -h <host_name>   change computer host name name temporary "
            gmsg -v1 " -l               set logging on to file $GURU_LOG"
            gmsg -v1 " -q               be quiet"
            gmsg -v1 " -s               speak out output"
            gmsg -v1 " -f               set force mode on, be more aggressive"
            gmsg -v1 " -c               disable colors in terminal"
            gmsg -v1 " --option         module options TBD"
            gmsg -v2
            return 0
        }


    core.help_system () {
            gmsg -v2
            gmsg -v1 -c white  "system tools"
            gmsg -v1 "  install         install tools "
            gmsg -v1 "  uninstall       remove guru toolkit "
            gmsg -v1 "  upgrade         upgrade guru toolkit "
            gmsg -v1 "  status          status of stuff"
            gmsg -v1 "  shell           start guru shell"
            gmsg -v1 "  version         printout version "
            gmsg -v2
            gmsg -v2 "to refer detailed tool help, type '$GURU_CALL <module> help'"
            return 0
        }


    core.help_newbie () {
        if [[ -f $HOME/.data/.newbie ]] ; then
            gmsg
            gmsg -c white "if problems after installation"
            gmsg
            gmsg "1) logout and login to set path by .profiles or set path:"
            gmsg
            gmsg '   PATH=$PATH:$HOME/bin'
            gmsg
            gmsg "2) if no access to ujo.guru access point, create fake data mount"
            gmsg
            gmsg '   mkdir $HOME/.data ; touch $HOME/.data/.online'
            gmsg
            gmsg "3) to edit user configurations run:"
            gmsg
            gmsg "   $GURU_CALL config user"
            gmsg
            gmsg "4) remove newbie help view by: "
            gmsg
            gmsg "   rm $HOME/.data/.newbie"
            gmsg
            export GURU_VERBOSE=1
        fi
    }


    local _arg="$1"
    if [[ "$_arg" ]] ; then

            case "$_arg" in
                    all) core.multi_module_function help        ; return 0 ;;
                    flags) core.help_flags                      ; return 0 ;;
                      *) core.run_module_function "$_arg" help  ; return 0 ;;
                    esac
        fi

    core.help_newbie
    gmsg -v1 -c white "guru-client help "
    gmsg -v2
    gmsg -v0  "usage:    $GURU_CALL [-flags] [tool] [argument] [variables]"
    core.help_flags
    gmsg -v2
    gmsg -v1 -c white  "examples"
    gmsg -v1 "  $GURU_CALL note yesterday           open yesterdays notes"
    gmsg -v2 "  $GURU_CALL install mqtt-server      install mqtt server"
    gmsg -v1 "  $GURU_CALL ssh key add github       add ssh keys to github server"
    gmsg -v1 "  $GURU_CALL timer start at 12:00     start work time timer"
    gmsg -v1
    gmsg -v1 -c white  "More detailed help, type '$GURU_CALL <tool> help'"
    gmsg -v1 "Use verbose mode '-v2' to get more information in help printout. "
    gmsg -v1

}


core.process_opts () {
    # process first level options (given with one '-')

    local left_overs=
    local commands=

    # default values of (to be as) global control variables
    declare -g GURU_FORCE=
    declare -g GURU_LOGGING=
    declare -g GURU_HOSTNAME=$(hostname)
    declare -g GURU_VERBOSE=$GURU_FLAG_VERBOSE
    declare -g GURU_COLOR=true

    # go trough possible arguments if set or value is given, other vice use default
    TEMP=`getopt --long -o "cCsflqh:u:v:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -c) export GURU_COLOR=true
                shift ;;
            -C) export GURU_COLOR=
                shift ;;
            -s) export GURU_SPEAK=true
                export GURU_COLOR=
                #export GURU_VERBOSE=2
                shift ;;
            -f) export GURU_FORCE=true
                shift ;;
            -h) export GURU_HOSTNAME=$2
                shift 2 ;;
            -l) export GURU_LOGGING=true
                shift ;;
            -q) export GURU_VERBOSE=
                shift ;;
            -u) core.change_user "$2"
                shift 2 ;;
            -v) export GURU_VERBOSE=$2
                shift 2 ;;
             *) break
        esac
    done

    # place module name and commands to leftovers before cleaning it up
    left_overs="$@"

    # clean rest of user input
    if [[ "$left_overs" != "--" ]] ; then
            module_commands="${left_overs#* }"
        fi

    # compose command
    GURU_COMMAND=${module_commands[@]}

    # check if colors possible, and overwrite user input and user.cfg
    if [[ $TERM != "xterm-256color" ]] || [[ $COLORTERM != "truecolor" ]]; then
            declare -x GURU_COLOR=
        fi

}


core.mount_system_base () {
    # check is access point enabled and mount is not

    # is access functionality enabled?
    if ! [[ $GURU_ACCESS_ENABLED ]] ; then
        return 1
    fi

    # is mount functionality enabled?
    if ! [[ $GURU_MOUNT_ENABLED ]] ; then
        return 2
    fi

    source mount.sh
    # is it already mounted?
    if ! mount.online ; then
        # get tools for mounting
        source $GURU_BIN/mount.sh
        # check and mount system folder mounted
        mount.main system
    fi
}

# if launched as a script, not as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    # process arguments and return cleaned command
    core.process_opts $@

    # import needed modules
    source $GURU_BIN/common.sh

    # set up platform
    core.mount_system_base

    # do the hassle
    declare -x GURU_FORCE
    declare -x GURU_COLOR
    declare -x GURU_VERBOSE
    declare -x GURU_HOSTNAME
    declare -x GURU_LOGGING
    declare -xa GURU_COMMAND

    core.main ${GURU_COMMAND[@]}
    _error_code=$?

    # all fine
    if (( _error_code < 1 )) ; then
            exit 0
        fi

    # less than 10 are warnings
    if (( _error_code < 100 )) ; then
            gmsg -v2 -c yellow "warning: $_error_code $GURU_LAST_ERROR" # TBD for hard exits
        else
            gmsg -v1 -c red  "error: $_error_code $GURU_LAST_ERROR" # TBD for hard exits
        fi

    exit $_error_code

fi


# removed functions

# core.shell () {
#     # terminal loop
#     # TBD remove but save somewhere vote +1?

#     render_path () {
#             # TBD: path location shit is broken when long input, hard to solve. vote for remove +1?
#             local _path="$(pwd)"
#             if [[ "$_path" == "$HOME" ]] ; then _path='~' ; fi
#             local _source=$(eval echo '${GURU_MOUNT_'"${_item}[1]}")
#             local c_user=$(eval echo '$C_'"${GURU_COLOR_PATH_USER^^}")
#             local c_at=$(eval echo '$C_'"${GURU_COLOR_PATH_AT^^}")
#             local c_call=$(eval echo '$C_'"${GURU_COLOR_PATH_CALL^^}")
#             local c_sepa=$(eval echo '$C_'"${GURU_COLOR_PATH_SEPA^^}")
#             local c_dir=$(eval echo '$C_'"${GURU_COLOR_PATH_DIR^^}")
#             local c_input=$(eval echo '$C_'"${GURU_COLOR_PATH_INPUT^^}")

#             printf "$c_user$GURU_USER$c_at@$c_call$_GURU_CALL$c_sepa:$c_dir$_path$ $c_input"
#             gmsg -n -c normal
#         }

#     inc_verbose () {

#             (( _verbose<2 )) && let _verbose++
#             cmd=
#         }

#     dec_verbose () {
#             (( _verbose>0 )) && let _verbose--
#             cmd=
#         }


#     gmsg "$GURU_CALL in shell mode (type 'help' enter for help)"

#     local _verbose=1

#     while true ; do

#             # TBD config.hs: to update every time
#             # TBD faster method to apply config needed before this is possible
#             # config.export "$GURU_CFG/$GURU_USER/user.cfg" >/dev/null

#             # source current configuration
#             source $GURU_RC
#             GURU_VERBOSE=$_verbose

#             # set call name off for sub processes, affects some help content
#             local _GURU_CALL="$GURU_CALL"
#             GURU_CALL=

#             read -e -p "$(render_path)" "cmd"

#             case "$cmd" in exit|q|quit)  break ;;
#                                      '+')  inc_verbose ;;
#                                      '-')  dec_verbose ;;
#                 esac
#             [[ $cmd ]] && core.parser $cmd
#         done

#     gmsg -v2 "take care!"
#     return $?
# }