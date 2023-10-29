#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2023

core.help () {

    core.help_usage () {
        gr.msg -v1 "guru-cli main help $GURU_VERSION_NAME v$GURU_VERSION " -h
        gr.msg -v2
        gr.msg -v0 "usage:            $GURU_CALL -arguments module_name command --module_arguments" -c white
        gr.msg -v1 "                  $GURU_CALL -arguments core_command" -c white
        gr.msg -v2 "                  '-'' and '--'' arguments are not place oriented"
    }

    core.help_arguments () {
        gr.msg -v1 "arguments:" -c white
        # gr.msg -v2 " -a               record audio command and run it (TBD!)"
        gr.msg -v1 " -q               be quiet as possible, no audio or text output "
        gr.msg -v1 " -s               speak out command return messages and data "
        gr.msg -v1 " -v 1..4          verbose level, adds headers and some details"
        gr.msg -v1 " -u <user_name>   change guru user name temporary  "
        gr.msg -v1 " -h <host_name>   change computer host name name temporary "
        gr.msg -v1 " -f               set force mode on to be bit more aggressive "
        gr.msg -v1 " -c               disable colors in terminal "
        gr.msg -v3 " -d               run in debug mode, lot of colorful text (TBD!) "
        gr.msg -v1
        gr.msg -v1 "to refer module help, type '$GURU_CALL <module_name> help'"
        gr.msg -v2
    }

    core.help_system () {
        gr.msg -v2 "system tools:" -c white
        gr.msg -v2 "  install         install tools "
        gr.msg -v2 "  uninstall       remove guru toolkit "
        gr.msg -v2 "  upgrade         upgrade guru toolkit "
        # gr.msg -v3 "  status          status of stuff (TBD return this function) "
        # gr.msg -v3 "  shell           start guru shell (TBD return this function )"
        gr.msg -v2 "  --ver           printout version "
        gr.msg -v2 "  --help          printout help "
    }

    core.help_examples () {
        gr.msg -v2 "examples:" -c white
        gr.msg -v2 "  $GURU_CALL ssh key add github       add ssh keys to github server"
        gr.msg -v2 "  $GURU_CALL timer start at 12:00     start work time timer"
        gr.msg -v2 "  $GURU_CALL note yesterday           open yesterdays notes"
        gr.msg -v2 "  $GURU_CALL install mqtt-server      install mqtt server"
        gr.msg -v2 "  $GURU_CALL radio radiorock          listen radio station"
        gr.msg -v2 "  $GURU_CALL start                    start poller daemon"

        gr.msg
    }

    core.help_newbie () {
        if [[ -f $HOME/guru/.data/.newbie ]] ; then
            gr.msg -v0 "if problems after installation" -c white
            gr.msg -v0 "  1) logout and login to set path by .profiles or set path:"
            gr.msg -v0 '       PATH=$PATH:$HOME/bin'
            gr.msg -v0 "  2) if no access to ujo.guru access point, create fake data mount"
            gr.msg -v0 '      mkdir $HOME/guru/.data ; touch $HOME/guru/.data/.online'
            gr.msg -v0 "  3) to edit user configurations run:"
            gr.msg -v0 "      $GURU_CALL config user"
            gr.msg -v0 "  4) remove newbie help view by: "
            gr.msg -v0 "       rm $HOME/guru/.data/.newbie"
            gr.msg -v1
        fi
    }

    core.help_usage
    core.help_arguments
    core.help_examples
    core.help_newbie
}


core.parser () {
# parsing first word of user input, rest words are passed to next level parser

    local _input="$1" ; shift
    gr.debug "$FUNCNAME $@"

    case "$_input" in

        all)
        # run command on all modules
            core.multi_module_function "$@"
            return $?
            ;;

        start|poll|kill|stop)
        # daemon controls
            source $GURU_BIN/daemon.sh
            daemon.$_input
            return $?
            ;;

        debug|pause|help|version|online)
        # core control functions
            core.$_input $@
            return $?
            ;;

        uninstall)
        # use uninstaller of installed version
            bash "$GURU_BIN/$_input.sh" "$@"
            return $?
            ;;

        *)
        # otherwise try is user input one of installed modules

            core.run_module_function "$_input" "$@"
            return $?
            ;;

        "")
        # ask more
            gr.msg "$GURU_CALL need more instructions"
            ;;
    esac
}


core.debug () {
# some debug stuff, not used too often

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

    flag.set stop
    return $?
}


core.pause () {
# This function asks the daemon to pause by toggling the pause flag in the system.
# The flag is stored using the system.s module.
# If the flag is already set, it will be removed. If it is not set, it will be set. (chatgpt)

    if flag.check pause ; then
        flag.rm pause
    else
        flag.set pause
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
                    module_output="$(echo $module_output | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g'))"
                    gr.msg -v2 "$module_output"
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
    gr.debug "$FUNCNAME $@"
    # guru add ssh key @ -> guru ssh key add @
    if ! grep -q -w "$1" <<<${GURU_SYSTEM_RESERVED_CMD[@]} ; then
        local module=$1 ; shift # note: there was reason to use shift over $2, $3, may just be cleaner
        local command=$1 ; shift
        local function=$1 ; shift
     else
        local function=$1 ; shift
        local module=$1 ; shift
        local command=$1 ; shift
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
    # gr.msg -v1 -V2 -c error "there is no light in your request '$module'"
    # gr.msg -v1 -V2 -c error "$GURU_CALL see no sense in your request '$module'"
    gr.msg -v1 -V2 -c error "$GURU_CALL see no enlightenment in your question '$module'"
    gr.msg -v2 -c error "$FUNCNAME: function '$function' in module '$module' not found"
    return 12
}


core.multi_module_function () {
# run function name of all installed modules

    gr.debug "$FUNCNAME $@"

    local function_to_run=$1 ; shift

    for _module in ${GURU_MODULES[@]} ; do
        gr.msg -c dark_golden_rod "$_module $function_to_run"

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
    done

    gr.msg -v2 -c yellow "$FUNCNAME: something went wrong when tried to run "$function_to_run" in '$_module'"
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
# check is online, set pause for daemon if not

    declare -g offline_flag="/tmp/guru-offline.flag"
    source net.sh

    if net.check_server ; then
        if [[ -f $offline_flag ]] ; then
                gr.end esc
                flag.rm pause
                rm $offline_flag
        fi
        return 0
    else
        touch $offline_flag
        gr.msg -v1 -c white "offline mode"
        gr.end esc
        flag.set pause
        return 127
    fi
}


core.mount_system_base () {
# check is access point enabled and mount is not

    # is access functionality enabled?
    if ! [[ $GURU_ACCESS_ENABLED ]] ; then
        gr.msg -c error "access not enabled"
        return 12
    fi

    # is mount functionality enabled?
    if ! [[ $GURU_MOUNT_ENABLED ]] ; then
        gr.msg -c error "mount not enabled"
        return 13
    fi

    # is nets online
    if core.online ; then
        return 0
    fi

    # is it already mounted?
    if ! mount.online ; then
        # check and mount system folder mounted
        mount.main system && return 0
    fi
}


core.process_module_opts () {
# This function processes command line arguments for a module and core, making sure that each argument is
# correctly assigned to the appropriate variable. The processed arguments are then exported as environment
# variables for use in other parts of the program. Comments of this function are generated by chatGPT.

    # The function starts by initializing three variables: input_string_list, pass_to_module, and pass_to_core.
    # The input_string_list variable holds all the command line arguments passed to the function, while pass_to_module
    # and pass_to_core will hold the processed arguments that will be passed to the module and core, respectively.
    local input_string_list=($@)
    local pass_to_module=()
    local pass_to_core=()

    # The function then loops over each element of input_string_list using a for loop.
    # Inside the loop, it uses a case statement to determine what to do with each argument.
    for (( i = 0; i < ${#input_string_list[@]}; i++ )); do
        #gr.debug "$i:${input_string_list[$i]}" #$((i + 1)):${input_string_list[$((i + 1))]}

        case ${input_string_list[$i]} in

        '--'*)  # If an argument starts with --, it is considered a module argument. The function checks the
                # next argument to see if it is a flag or an argument that requires a value. If it is a flag,
                # the current argument is added to pass_to_module. If it requires a value, the current and next
                # arguments are added to pass_to_module. The let i++ statement skips over the argument's value
                # since it has already been added to pass_to_module.
                case ${input_string_list[$((i + 1))]} in
                '-'*|""|" ")
                    gr.debug "module arguments '${input_string_list[$i]}'"
                    pass_to_module="$pass_to_module ${input_string_list[$i]}"
                    ;;
                 *)
                    gr.debug "module option with arguments '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                    pass_to_module="$pass_to_module ${input_string_list[$i]}"
                    let i++
                    pass_to_module="$pass_to_module ${input_string_list[$i]}"
                    ;;
                esac
                ;;

        '-'*)   # If an argument starts with -, it is considered a core argument. Like module arguments, the function
                # checks the next argument to see if it is a flag or an argument that requires a value. If it is a flag,
                # the current argument is added to the beginning of pass_to_core. If it requires a value, the current and
                # next arguments are added to pass_to_core. The let i++ statement skips over the argument's value since it
                # has already been added to pass_to_core.
                case ${input_string_list[$((i + 1))]} in
                '-'*|""|" ")
                    gr.debug "core arguments '${input_string_list[$i]}'"
                    pass_to_core="${input_string_list[$i]} $pass_to_core"
                    ;;
                 *)
                    # echo "core option with arguments '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                    pass_to_core="$pass_to_core ${input_string_list[$i]}"
                    let i++
                    pass_to_core="$pass_to_core ${input_string_list[$i]}"
                esac
                ;;

            *)  # If the argument does not start with - or --, it is considered a module name and command,
                # and it is added to pass_to_core.
                gr.debug "command '${input_string_list[$i]}'"
                pass_to_core="$pass_to_core ${input_string_list[$i]}"
        esac
    done

    # Finally, the processed pass_to_module and pass_to_core arguments are exported to environment variables
    # GURU_MODULE_ARGUMENTS and GURU_CORE_ARGUMENTS, respectively. The tr command is used to remove any redundant
    # spaces in the processed arguments before exporting them. (tr is fastest method stack overflow 50259869)
    export GURU_MODULE_ARGUMENTS=$(echo ${pass_to_module[@]} | tr -s ' ')
    export GURU_CORE_ARGUMENTS=$(echo ${pass_to_core[@]} | tr -s ' ')
}


core.run_macro () {
# run macro

    #export GURU_VERBOSE=1
    local file_name="${1}"
    gr.msg -c dark_grey -v2 "running macro '$file_name'"
    local words_list=()
    local line_nr=0
    while IFS= read -r line; do
        line_nr=$(( line_nr + 1 ))
        # rest_words_list=$(echo ${line} | cut -d' ' -f3-)
        IFS=" " ; words_list=(${line[@]}) ; IFS=
        # remove leading spaces from command
        words_list[0]=$(sed 's/^[[:space:]]*//' <<< "${words_list[0]}")

        case ${words_list[0]} in *'#'*|"") continue ; esac

        # re place commands if found in reserved words_list list
        if [[ " ${GURU_SYSTEM_RESERVED_CMD[@]} " =~ " ${words_list[0]} " ]]; then
            core.run_module_function "${words_list[1]}"\
                                     "${words_list[2]}"\
                                     "${words_list[0]}"\
                                     "${words_list[@]:3}"
            continue
        # check is there module named as given command
        elif [[ " ${GURU_MODULES[@]} " =~ " ${words_list[0]} " ]]; then
            core.run_module_function "${words_list[@]}"
            continue
        else
            gr.msg -n -v2 -c white "in '$file_name' line $line_nr: '${words_list[@]}' "
            gr.msg -c yellow "unknown command '${words_list[0]}'"
            continue
        fi

    done < $file_name
}


core.is_macro () {
# check is core called by macro and if so, remove macro name from input string

    case ${1} in
        *.gm)
            core.run_macro $@
            return 0
            ;;
        *)
            return 1
    esac
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
    TEMP=`getopt --longoptions -o "dcsflqh:u:v:" $@`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in

            -d)
                export GURU_DEBUG=true
                shift
                ;;
            -c)
                export GURU_COLOR=
                shift
                ;;
            -s)
                export GURU_VERBOSE=2
                export GURU_SPEAK=true
                shift
                ;;
            -f)
                export GURU_FORCE=true
                shift
                ;;
            -h)
                export GURU_HOSTNAME="$2"
                shift 2 ;;
            -l)
                export GURU_LOGGING=true
                shift
                ;;
            -q)
                export GURU_VERBOSE=
                export GURU_GURU_SPEAK=
                shift
                ;;
            -u)
                core.change_user "$2"
                shift 2
                ;;
            -v)
                export GURU_VERBOSE="$2"
                shift 2
                ;;
             *) break
        esac
    done

    gr.debug "GURU_DEBUG: $GURU_DEBUG"
    gr.debug "GURU_COLOR: $GURU_COLOR"
    gr.debug "GURU_VERBOSE: $GURU_VERBOSE"
    gr.debug "GURU_SPEAK: $GURU_SPEAK"
    gr.debug "GURU_COLOR: $GURU_COLOR"
    gr.debug "GURU_FORCE: $GURU_FORCE"
    gr.debug "GURU_HOSTNAME: $GURU_HOSTNAME"
    gr.debug "GURU_LOGGING: $GURU_LOGGING"


    # clean rest of user input
    local left_overs="$@"
    if [[ "$left_overs" != "--" ]] ; then
        GURU_MODULE_COMMAND="${left_overs#* }"
    fi
}

# Do not let run guru as root
case $USER in root|admin|sudo) echo "too dangerous to run guru-cli as root!" ; return 100; esac

# global variables
declare -x GURU_RC="$HOME/.gururc"
declare -x GURU_BIN="$HOME/bin"
declare -x GURU_VERSION=$(echo $(head -n1 $GURU_BIN/version) | tr -d '\n')
declare -x GURU_VERSION_NAME=$(echo $(tail $GURU_BIN/version -n +2 | head -n 1 ) | tr -d '\n')

# early exits
case $1 in
    version|--version|--ver)
        echo "$GURU_VERSION $GURU_VERSION_NAME"
        exit 0
        ;;
    --help)
        shift
        core.help $@
        exit 0
        ;;
esac

# check that config rc file exits
if [[ -f $GURU_RC ]] ; then
        source $GURU_RC
        gr.debug "sourcing $GURU_RC.. "
    else
        # run user configuration if not exist
        config.main export $USER
        source $GURU_RC
    fi

# determinate how to call guru, I prefer 'guru' or now more often alias 'gr'
[[ $GURU_SYSTEM_NAME ]] && export GURU_CALL=$GURU_SYSTEM_NAME

# everybody have daemons
source daemon.sh
source flag.sh
source mount.sh
source config.sh

# check is core run or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    #\\ process arguments and return cleaned command
    # import needed modules
    source $GURU_BIN/common.sh

    # check is core called as interrupter by macro
    core.is_macro $@ && exit $?

    # core.process_opts $@
    core.process_module_opts $@
    core.process_core_opts $GURU_CORE_ARGUMENTS

    # export global variables for sub processes
    export GURU_COMMAND=($GURU_MODULE_COMMAND $GURU_MODULE_ARGUMENTS)

    # set up platform
    #core.mount_system_base || gr.msg -c yellow "running local mode"
    gr.debug "GURU_COMMAND: ${GURU_COMMAND[@]}"

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

    # less than 100 are warnings
    if (( _error_code < 100 )) ; then
        gr.msg -v3 -c yellow "warning: $_error_code $GURU_LAST_ERROR"
    else
        gr.msg -v2 -c red  "error: $_error_code $GURU_LAST_ERROR"
    fi

    exit $_error_code
fi

