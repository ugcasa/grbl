#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2022

core.help () {

    source $GURU_BIN/common.sh

    core.help_usage () {
        gmsg -c white "guru-client core help "
        gmsg
        gmsg "usage:            $GURU_CALL -options module command arguments"
        gmsg "                  options are not place oriented"
    }

    core.help_flags () {
        gmsg -c white "options:"
        gmsg " -v 1..4          verbose level, adds headers and some details"
        gmsg " -u <user_name>   change guru user name temporary  "
        gmsg " -h <host_name>   change computer host name name temporary "
        gmsg " -s               speak out all output "
        gmsg " -f               set force mode on, be more aggressive "
        gmsg " -c               disable colors in terminal "
        gmsg " -q               be quiet "
        gmsg
        gmsg "to refer module help, type '$GURU_CALL <module> help'"
        gmsg
        # gmsg " -l             set logging on to file $GURU_LOG"
        # gmsg " -o '-t 1 -a'   transmit options to module TBD"
        # gmsg " --o argument   module options TBD"
    }

    core.help_system () {
        gmsg -c white  "system tools:"
        gmsg "  install         install tools "
        gmsg "  uninstall       remove guru toolkit "
        gmsg "  upgrade         upgrade guru toolkit "
        gmsg "  status          status of stuff"
        gmsg "  shell           start guru shell"
        gmsg "  --ver           printout version "
        gmsg "  --help          printout help "
    }

    core.help_examples () {
        gmsg -c white  "examples:"
        gmsg "  $GURU_CALL note yesterday           open yesterdays notes"
        gmsg "  $GURU_CALL install mqtt-server      install mqtt server"
        gmsg "  $GURU_CALL ssh key add github       add ssh keys to github server"
        gmsg "  $GURU_CALL timer start at 12:00     start work time timer"
        gmsg
    }

    core.help_newbie () {
        if [[ -f $HOME/guru/.data/.newbie ]] ; then
            gmsg -c white "if problems after installation"
            gmsg "  1) logout and login to set path by .profiles or set path:"
            gmsg '       PATH=$PATH:$HOME/bin'
            gmsg "  2) if no access to ujo.guru access point, create fake data mount"
            gmsg '      mkdir $HOME/guru/.data ; touch $HOME/guru/.data/.online'
            gmsg "  3) to edit user configurations run:"
            gmsg "      $GURU_CALL config user"
            gmsg "  4) remove newbie help view by: "
            gmsg "      rm $HOME/guru/.data/.newbie"
            gmsg
            export GURU_VERBOSE=2
        fi
    }

    core.help_usage
    core.help_flags
    core.help_examples
    core.help_newbie
    gmsg "version: $GURU_VERSION_NAME v$GURU_VERSION (2022) casa@ujo.guru"

}


core.parser () {
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
                    source $GURU_BIN/daemon.sh
                    daemon.$module
                    return $? ;;

            help|version)
                    core.$module
                    return $? ;;
            *)
                    core.run_module "$module" "$@"
                    return $? ;;
        esac
}


core.stop () {
    # ask daemon to stop. daemon should get the message after next tick (about a second)

    source $GURU_BIN/system.sh
    system.main flag set stop
    reuturn $?
}


core.pause () {
    # ask daemon to pause

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

    # check is given command in reserved words, if so change argument order
    if grep -q -w "$1" <<<${GURU_SYSTEM_RESERVED_CMD[@]} ; then
            local function=$1 ; shift
            local module=$1 ; shift
            local command=$1 ; shift
        else
            local module=$1 ; shift
            local command=$1 ; shift
            local function=$1 ; shift
        fi

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

                # speak out what ever module returns
                if [[ $GURU_SPEAK ]]  ; then
                    local module_output="$(${run_me[@]//  / })"
                    gmsg "guru replies: '$module_output'"
                    espeak -p $GURU_SPEAK_PITCH \
                           -s $GURU_SPEAK_SPEED \
                           -v $GURU_SPEAK_LANG \
                           "$module_output"
                    return $?
                fi

                # run the command and return what ever module did return
                ${run_me[@]//  / }
                return $?
            fi
        done
    done

    echo "guru recognize no module named '$module'"
    return $?

    # if gask "passing to request to operating system?" ; then
    #    $module $@
    #   fi
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


core.process_opts () {
    # process core level options

    local left_overs=
    local commands=

    # default values for global control variables
    declare -g GURU_FORCE=
    declare -g GURU_SPEAK=
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


## MAIN

# global variables
declare -x GURU_RC="$HOME/.gururc"
declare -x GURU_BIN="$HOME/bin"
declare -x GURU_VERSION=$(echo $(head -n1 $GURU_BIN/version) | tr -d '\n')
declare -x GURU_VERSION_NAME=$(echo $(tail $GURU_BIN/version -n +2 | head -n 1 ) | tr -d '\n')
# declare -x GURU_VERSION_DESCRIPTION=$(echo $(tail $GURU_BIN/version -n +3 | head -n 1 ) | tr -d '\n')

# early exits
case $1 in
    version|--version|--ver)
        echo "$GURU_VERSION $GURU_VERSION_NAME"
        exit 0
        ;;
    description|--description)
        echo "$GURU_VERSION $GURU_VERSION_NAME $(tail $GURU_BIN/version -n +3 | head -n 1 )"
        exit 0
        ;;
    help|--help)
        shift
        core.help $@
        exit 0
        ;;
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    # process arguments and return cleaned command
    core.process_opts $@

    # import needed modules
    source $GURU_BIN/common.sh

    # set up platform
    core.mount_system_base

    # export global variables for sub processes
    declare -xa GURU_COMMAND

    # TBD following not really need i stinks.. damn, this messy too
    declare -x GURU_FORCE
    declare -x GURU_COLOR
    declare -x GURU_VERBOSE
    declare -x GURU_HOSTNAME
    declare -x GURU_LOGGING


    core.parser ${GURU_COMMAND[@]}
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

