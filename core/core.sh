#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2022

#source $GURU_BIN/common.sh


core.help () {

    core.help_usage () {
        gr.msg -c white "guru-client core help "
        gr.msg
        gr.msg "usage:            $GURU_CALL -options module command arguments"
        gr.msg "                  options are not place oriented"
    }

    core.help_flags () {
        gr.msg -c white "options:"
        gr.msg " -v 1..4          verbose level, adds headers and some details"
        gr.msg " -u <user_name>   change guru user name temporary  "
        gr.msg " -h <host_name>   change computer host name name temporary "
        gr.msg " -s               speak out all output "
        gr.msg " -f               set force mode on, be more aggressive "
        gr.msg " -c               disable colors in terminal "
        gr.msg " -q               be quiet "
        gr.msg
        gr.msg "to refer module help, type '$GURU_CALL <module> help'"
        gr.msg
        # gr.msg " -l             set logging on to file $GURU_LOG"
        # gr.msg " -o '-t 1 -a'   transmit options to module TBD"
        # gr.msg " --o argument   module options TBD"
    }

    core.help_system () {
        gr.msg -c white  "system tools:"
        gr.msg "  install         install tools "
        gr.msg "  uninstall       remove guru toolkit "
        gr.msg "  upgrade         upgrade guru toolkit "
        gr.msg "  status          status of stuff"
        gr.msg "  shell           start guru shell"
        gr.msg "  --ver           printout version "
        gr.msg "  --help          printout help "
    }

    core.help_examples () {
        gr.msg -c white  "examples:"
        gr.msg "  $GURU_CALL note yesterday           open yesterdays notes"
        gr.msg "  $GURU_CALL install mqtt-server      install mqtt server"
        gr.msg "  $GURU_CALL ssh key add github       add ssh keys to github server"
        gr.msg "  $GURU_CALL timer start at 12:00     start work time timer"
        gr.msg
    }

    core.help_newbie () {
        if [[ -f $HOME/guru/.data/.newbie ]] ; then
            gr.msg -c white "if problems after installation"
            gr.msg "  1) logout and login to set path by .profiles or set path:"
            gr.msg '       PATH=$PATH:$HOME/bin'
            gr.msg "  2) if no access to ujo.guru access point, create fake data mount"
            gr.msg '      mkdir $HOME/guru/.data ; touch $HOME/guru/.data/.online'
            gr.msg "  3) to edit user configurations run:"
            gr.msg "      $GURU_CALL config user"
            gr.msg "  4) remove newbie help view by: "
            gr.msg "      rm $HOME/guru/.data/.newbie"
            gr.msg
            export GURU_VERBOSE=2
        fi
    }

    core.help_usage
    core.help_flags
    core.help_examples
    core.help_newbie
    gr.msg "version: $GURU_VERSION_NAME v$GURU_VERSION (2022) casa@ujo.guru"

}


core.parser () {
# parsing the commands

    local module="$1"
    shift

    case "$module" in

            all)
                    core.multi_module_function "$@"
                    return $?
                    ;;

            uninstall)
                    bash "$GURU_BIN/$module.sh" "$@"
                    return $?
                    ;;

            start|poll|kill|stop)
                    source $GURU_BIN/daemon.sh
                    daemon.$module
                    return $?
                    ;;
            silent)
                    pkill espeak
                    ;;

            debug|pause)
            # access to core functions
                    core.$module
                    return $?
                    ;;

            help|version)
                    core.$module $@
                    return $?
                    ;;
            *)
                    core.run_module "$module" "$@"
                    return $?
                    ;;
            "")     gr.msg "$GURU_CALL need more instructions"
                    ;;
        esac
}


core.debug () {

    local wanted=$1
    # local available=($(cat "$GURU_CFG/variable.list"))
    # local available=($(set | grep 'GURU_' | grep -v '$'))
    local available=$(cat $GURU_RC| grep "export GURU_" | cut -d "=" -f1 | cut -d' ' -f2)
    local i=0
    local empty=0

    for variable in ${available[@]} ; do
        gr.msg -n -c light_blue "$variable "
        #printf "${variable}="

        # TBD now prints only first part of list variables
        if [[ ${!variable} ]] ; then
            gr.msg -c light_green "${!variable}"
            #printf "${!variable}\n"
            let i++
        else

            [[ $GURU_COLOR ]] \
                && gr.msg -c yellow "false (empty)" \
                || echo "   <-------------------------------------- empty or false"

            let empty++
        fi

        done
    gr.msg -N "$i variables where $empty empty one"
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
                    local module_output="$(${run_me[@]//  / } | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g')"
                    gr.msg -v2 "${module_output[@]}"
                    espeak -p $GURU_SPEAK_PITCH \
                           -s $GURU_SPEAK_SPEED \
                           -v $GURU_SPEAK_LANG \
                           "${module_output[@]}" &

                    return $?
                fi

                # run the command and return what ever module did return
                ${run_me[@]//  / }
                return $?
            fi
        done
    done

    gr.msg -v1 "guru recognize no module named '$module'"
    return $?


    # if gr.ask "passing to request to operating system?" ; then
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
        gr.msg -v4 "non reserved word: $command"
     else
        local function=$1 ; shift
        local module=$1 ; shift
        local command=$1 ; shift
        gr.msg -v4 "reserved word: $command"
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
    gr.msg -v2 -c yellow "in core.run_module_function something went wrong when tried to run "$function" in '$module'"
    return 12
}


core.multi_module_function () {
    # run function name of all installed modules

    local function_to_run=$1 ; shift

    for _module in ${GURU_MODULES[@]} ; do
        gr.msg -c dark_golden_rod "$_module $function_to_run"

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

    gr.msg -v2 -c yellow "in core.multi_module_function something went wrong when tried to run "$function_to_run" in '$_module'"
    return 13
}


core.change_user () {
    # change guru user temporarily

    local _input_user=$1
    if [[ "$_input_user" == "$GURU_USER" ]] ; then
        gr.msg -c yellow "user is already $_input_user"
        return 0
    fi

    export GURU_USER=$_input_user
    source $GURU_BIN/config.sh

    if [[ -d "$GURU_CFG/$GURU_USER" ]] ; then
        gr.msg -c white "changing user to $_input_user"
        config.main export $_input_user
    else
        gr.msg -c yellow "user configuration not exits"
    fi
}


core.online () {

    source system.sh
    source net.sh

    declare -g offline_flag="/tmp/guru-offline.flag"

    if net.check_server ; then
            if [[ -f $offline_flag ]] ; then
                    gr.end esc
                    system.flag rm pause
                    rm $offline_flag
                fi
            return 0
        else
            touch $offline_flag
            gr.msg -v1 -c white "offline mode"
            gr.end esc
            system.flag set pause
            return 127
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

    # is nets online
    if ! core.online ; then
            return 3
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


tester () {
    echo "GURU_CORE_ARGUMENTS: '$GURU_CORE_ARGUMENTS' "
    echo "GURU_MODULE_COMMAND: '$GURU_MODULE_COMMAND'"
    echo "GURU_MODULE_ARGUMENTS: '$GURU_MODULE_ARGUMENTS'"
}


core.process_module_opts () {
# bash < 4.2 compatible method to pass long arguments to module

    declare -l input_string_list=($@)
    declare -l pass_to_module=
    declare -l pass_to_core=

   for (( i = 0; i < ${#input_string_list[@]}; i++ )); do
            # echo "$i:${input_string_list[$i]}, (next ${input_string_list[$((i + 1))]})"

            case ${input_string_list[$i]} in
                '--'*)  # module arguments
                         case ${input_string_list[$((i + 1))]} in
                            '-'*|""|" ")
                                # echo "module flag '${input_string_list[$i]}'"
                                pass_to_module="$pass_to_module ${input_string_list[$i]}"
                                ;;
                             *)
                                # echo "module option with arguments '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                                pass_to_module="$pass_to_module ${input_string_list[$i]}"
                                let i++
                                pass_to_module="$pass_to_module ${input_string_list[$i]}"
                                ;;
                            esac
                        ;;
                '-'*)   # core arguments
                        case ${input_string_list[$((i + 1))]} in
                        '-'*|""|" ")
                            # echo "core flag '${input_string_list[$i]}'"
                            pass_to_core="${input_string_list[$i]} $pass_to_core"
                            ;;
                         *)
                            # echo "core option with arguments '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                            pass_to_core="$pass_to_core ${input_string_list[$i]}"
                            let i++
                            pass_to_core="$pass_to_core ${input_string_list[$i]}"
                        esac
                        ;;
                    *)  # module name and command
                        # echo "command '${input_string_list[$i]}'"
                        pass_to_core="$pass_to_core ${input_string_list[$i]}"
                esac
        done

    # clean up and export (tr is fastest method stackoverflow 50259869)
    declare -xg GURU_MODULE_ARGUMENTS=$(echo ${pass_to_module[@]} | tr -s ' ')
    declare -xg GURU_CORE_ARGUMENTS=$(echo ${pass_to_core[@]} | tr -s ' ')
}


core.process_core_opts () {
    # process core level options

    # default values for global control variables
    declare -gx GURU_FORCE=
    declare -gx GURU_SPEAK=
    declare -gx GURU_LOGGING=
    declare -gx GURU_HOSTNAME=$(hostname)
    declare -gx GURU_VERBOSE=$GURU_FLAG_VERBOSE
    declare -gx GURU_COLOR=$GURU_FLAG_COLOR

    # go trough core arguments, long options should be on cause passing command trough this too
    TEMP=`getopt --longoptions -o "csflqh:u:v:" $@`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -c)
                export GURU_COLOR=
                shift
                ;;
            -s)
                export GURU_VERBOSE=1
                export GURU_SPEAK=true
                export GURU_COLOR=
                shift
                ;;
            -f)
                export GURU_FORCE=true
                shift
                ;;
            -h)
                export GURU_HOSTNAME=$2
                shift 2 ;;
            -l)
                export GURU_LOGGING=true
                shift
                ;;
            -q)
                export GURU_VERBOSE=
                shift
                ;;
            -u)
                core.change_user "$2"
                shift 2
                ;;
            -v)
                export GURU_VERBOSE=$2
                shift 2
                ;;
             *) break
        esac
    done


    declare -xg GURU_MODULE_COMMAND

    # clean rest of user input
    declare -l left_overs="$@"
    if [[ "$left_overs" != "--" ]] ; then
        GURU_MODULE_COMMAND="${left_overs#* }"
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
        source $GURU_RC
        gr.msg -v4 "sourcing config $GURU_RC.. "
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
    # core.process_opts $@
    core.process_module_opts $@
    core.process_core_opts $GURU_CORE_ARGUMENTS

    # import needed modules
    source $GURU_BIN/common.sh

    # set up platform
    core.mount_system_base

    # export global variables for sub processes
    declare -xa GURU_COMMAND=($GURU_MODULE_COMMAND $GURU_MODULE_ARGUMENTS)

    core.parser ${GURU_COMMAND[@]}
    _error_code=$?

    # all fine
    if (( _error_code < 1 )) ; then
        exit 0
    fi

    if [[ GURU_CORSAIR_ENABLED ]] ; then
        source corsair.sh
        corsair.indicate error
        corsair.main type "er$_error_code" >/dev/null
    fi

    # less than 10 are warnings
    if (( _error_code < 100 )) ; then
        gr.msg -v2 -c yellow "warning: $_error_code $GURU_LAST_ERROR" # TBD for hard exits
    else
        gr.msg -v2 -c red  "error: $_error_code $GURU_LAST_ERROR" # TBD for hard exits
    fi

    exit $_error_code
fi

