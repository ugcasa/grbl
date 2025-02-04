#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2023
__core_color="black"
__core=$(readlink --canonicalize --no-newline $BASH_SOURCE)

process_list=/tmp/guru-cli_ps.list

core.parser () {
# parsing first word of user input, rest words are passed to next level parser
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local _input="$1" ; shift

    case "$_input" in

        all)
        # run command on all modules
            core.multi_module_function "$@"
            return $?
            ;;

        start|poll|stop)
        # daemon controls
            source $GURU_BIN/daemon.sh
            daemon.$_input
            return $?
            ;;

        kill|top|ps|debug|pause|version|online|list|active)
        # core control functions
            core.$_input $@
            return $?
            ;;

        uninstall)
        # use uninstaller of installed version
            bash "$GURU_BIN/$_input.sh" "$@"
            return $?
            ;;

        help)
            source help.sh
            help.main $@
            return 0
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


core.list () {
# printout lists of stuff
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local list=

    case $1 in

        core)
            gr.msg -v2 -h "list of core modules:"
            list=($(cat $GURU_CFG/installed.core ))
            ;;
        installed|modules)
            gr.msg -v2 -h "list of installed modules:"
            list=($(cat $GURU_CFG/installed.modules))
            ;;
        commands)
            gr.msg -v2 -h "list of commands:"
            list=(debug pause help version online list all)
            list=(${list[@]} start poll kill stop)
            ;;
        available|*|"")
            gr.msg -v2 -h "list of available modules:"
            list=(${GURU_MODULES[@]})
            ;;
    esac

    gr.msg -c list "${list[@]}"
}


core.debug () {
# some debug stuff, not used too often
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

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


core.active () {
# start daemon
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    # ask key for server,
    # if key is no open, popup passphase input dialog appears

    # # set colors on terminal
    # export GURU_COLOR=true
    export GURU_VERBOSE=1

    source mount.sh

    # mount guru-cli data and cache
    if ! mount.main system ; then
        gr.msg -c failed "unable to active, system data mount failed"
        return 127
    fi

    # mound defaults
    mount.main

    # copy sounds locally to be fast enough
    cp $GURU_DATA/sounds/*wav /tmp

    # start daemon
    source daemon.sh
    daemon.main start
    return 0
    gr.msg -c gold "bye!"
}

# file log

# gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'"


core.ps () {
# list of running guru-client processes
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2
    local ifs=$IFS
    local _pid _int _com _arg
    local data_string=()

    # cut by newline
    IFS=$'\n'

    # get list of processes
    # local raw_list=($(ps -eo %cpu,pid,args | grep -v grep | grep -e $GURU_BIN/$GURU_CALL))
    local raw_list=($(ps -eo %cpu,pid,args | grep -v grep | grep -v $$ | grep -e $GURU_BIN/$GURU_CALL))
    local raw_list+=($(ps -eo %cpu,pid,args | grep -v grep | grep -v $$ | grep -e "/tmp/mpvsocket-radio"))
    local raw_list+=($(ps -eo %cpu,pid,args | grep -v grep | grep -v $$ | grep -e "sshfs"))

    [[ -f $process_list ]] && rm $process_list

    gr.msg -nh -w 4 -c white "GID"
    gr.msg -n -w 5 -c white "CPU"
    gr.msg -n -w 10 -c white "PID"
    gr.msg -n -w 20 -c white "Process"
    echo

    for (( i = 0; i < ${#raw_list[@]}; i++ )); do

        # file log to keep kill on synk
        # gr.debug "[$i]: '${raw_list[$i]}'"
        echo "$i ${raw_list[$i]}" >>$process_list

        # cut by space + other
        IFS=$ifs

        data_string=(${raw_list[$i]})
        _cpu="$(cut -d'.' -f1 <<<${data_string[0]})"
        _pid="${data_string[1]}"
        _int="${data_string[2]}"
        _com="${data_string[3]}"
        _arg="${data_string[4]} ${data_string[5]} ${data_string[6]} ${data_string[7]}"

        gr.msg -n -w 4 "$i"
        gr.msg -n -w 5 -c grey "$_cpu%"
        gr.msg -n -w 10 -c dark_grey "$_pid"
        echo "$_com $_arg"

        #echo
        # return cut by newlinefor line parsing
        IFS=$'\n'
    done

    IFS=$ifs

}


core.top () {
# list of guru processes
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2
    option=1
    while true ; do

        clear
        core.ps

        #sleep 0.5
        gr.msg -n -c aqua "${option}|k,q,s,i: "
        read -t3 -n1 answer

        case $answer in
            i)
                gr.msg -n "nfo"
                ;;
            q)
                gr.msg -n "uit"
                echo
                break
            ;;
            s) # toggle cpu view
               gr.msg -n "low "
               [[ $option ]] && option=1 || option=10
            ;;

            k)
                gr.msg -n "ill "
                read killer
                case $killer in
                    [0-9]|[1-9][0-9])
                        gr.msg "core.kill $killer"
                        core.kill $killer
                        ;;
                    "")
                        core.kill 0
                        ;;
                    *)
                        continue
                        ;;
                esac
            ;;
        esac

        [[ $option ]] && sleep $option

    done
}

core.kill () {
# list of running guru-client processes
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local ifs=$IFS
    local gid=$1
    local data_string=()
    # get list of processes

    [[ -f $process_list ]] || core.ps

    [[ $gid ]] || read -p "select process: " gid

    IFS=$'\n'
    local raw_list=($(cat $process_list))
    IFS=$ifs

    if [[ $gid -ge ${#raw_list[@]} ]] ; then #|| [[ $gid -lt 0 ]]
        gr.msg -e1 "out of list [$gid/$((${#raw_list[@]} -1))]"
        return 11
    fi

    local data_string=(${raw_list[$gid]})
    local _id="${data_string[0]}"
    local _cpu="${data_string[1]}"
    local _pid="${data_string[2]}"
    local _int="${data_string[3]}"
    local _com="${data_string[4]}"
    local _arg="${data_string[5]} ${data_string[6]} ${data_string[7]}"

    if ! [[ $_id -eq $gid ]] ; then gr.msg -e1 "id mismatch" ; return 13 ; fi

    gr.msg -n "killing '$_arg' ($_pid).. "
    kill -9 $_pid && gr.msg -c green "ok" || gr.msg -e1 "failed"

    IFS=$ifs
    [[ -f $process_list ]] && rm $process_list

}

core.stop () {
# ask daemon to stop. daemon should get the message after next tick (about a second)
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    flag.set stop
    return $?
}

core.pause () {
# This function asks the daemon to pause by toggling the pause flag in the system.
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2
# The flag is stored using the system.s module.
# If the flag is already set, it will be removed. If it is not set, it will be set. (chatgpt)

    if flag.check pause ; then
        flag.rm pause
    else
        flag.set pause
    fi
    return 0
}

core.make_adapter () {
# make adapter to multi file module
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local module=$1 ; shift
    local temp_script=$GURU_BIN/$module.sh

    gr.msg -n -v2 -c dark_grey "generating adapter for $module module.. "

    cat > "$temp_script" <<EOL
#!/bin/bash
# guru-cli adapter generated by core $(date)
source "$GURU_BIN/$module/$module.sh"
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    gr.debug "\${0##*/}: adapting $module to $GURU_BIN/$module/$module.sh with variables \$@"
    $module.main "\$@"
fi
EOL

    if [[ -f $GURU_BIN/$module.sh ]] ; then
        gr.msg -v2 -c green "ok"
        chmod +x "$GURU_BIN/$module.sh"
    else
        gr.msg -v2 -c error "file not generated in right location"
        return 123
    fi
}


core.run_module () {
# check is input in module list and if so, call module main
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local type_list=(".sh" ".py" "")
    local run_me=

    # check is given command in reserved words, if so change argument order
    #if gr.contain "$1" "${GURU_SYSTEM_RESERVED_CMD[@]}" ; then
    if [[ "${GURU_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] ; then
        gr.debug "fmc"
        local function=$1 ; shift
        local module=$1 ; shift
        local command=$1 ; shift
    elif [[ "${GURU_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] && [[ "${GURU_MODULES[@]}" =~ $2 ]]; then
        gr.debug "mcf"
        local command=$1 ; shift
        local module=$1 ; shift
        local function=$1 ; shift
    else
        gr.debug "mcf"
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

            # check is module folder, create adpater if not found
            if [[ -f "$GURU_BIN/$_module/$_module.sh" ]] && ! [[ -f "$GURU_BIN/$_module.sh" ]]; then
                core.make_adapter $_module
            fi

            # module in recognized format found
            if [[ -f "$GURU_BIN/$_module$_type" ]] ; then

                # make command
                run_me="$_module$_type $command $function $@"

                # speak out what ever module returns
                if [[ $GURU_SPEAK ]] ; then
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
                gr.debug "running: ${run_me[@]//  / }"
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


core.print_description () {
# printout function description for documentation and debugging
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    local module=$1
    shift
    local command=$1
    shift
    local file=$1
    shift

    #gr.msg -n -h "$command "
    first_line=$(grep -A 2 "$module.$command " $file | grep  -e '() ' -A 1 | tail -n1)
    [[ $first_line ]] || return 100
    gr.msg -v3 -c dark_grey "$module.$command '${first_line//# /}'"
}


core.run_module_function () {
# run methods (functions) in module
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    # guru add ssh key @ -> guru ssh key add @
    if gr.contain "$1" "${GURU_SYSTEM_RESERVED_CMD[@]}" ; then
        gr.debug "change order"
        local command=$1 ; shift
        local module=$1 ; shift
        local function=$1 ; shift
     else
        gr.debug "keep order"
        local module=$1 ; shift # note: there was reason to use shift over $2, $3, may just be cleaner
        local command=$1 ; shift
        local function=$1 ; shift
    fi

    gr.varlist "debug module command function"


    for _module in ${GURU_MODULES[@]} ; do

        if [[ "$_module" == "$module" ]] ; then

            # check is module folder, create adapter if is not found
            if [[ -f "$GURU_BIN/$_module/$_module.sh" ]] && ! [[ -f "$GURU_BIN/$_module.sh" ]] ; then
                core.make_adapter $_module
            fi

            gr.msg -v3 -c white "documentation: $GURU_DOCUMENTATION:module:$_module"

            # include all module functions and run called
            if [[ -f "$GURU_BIN/$_module.sh" ]] ; then
                core.print_description $_module "$command" "$GURU_BIN/$_module.sh"
                source $GURU_BIN/$_module.sh
                $_module.main "$command" "$function" "$@"
                return $?
            fi

            # run one function in python script
            if [[ -f "$GURU_BIN/$_module.py" ]] ; then
                # TBD add environment
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
    gr.msg -v1 -V2 -c error "$GURU_CALL see no sense in your request '$module'"
    gr.msg -v2 -c error "$FUNCNAME: function '$function' in module '$module' not found"
    return 12
}


core.multi_module_function () {
# run function name of all installed modules
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2


    local function_to_run=$1 ; shift

    for (( mod_count = 0; mod_count < ${#GURU_MODULES[@]}; mod_count++ )); do
    # for _module in ${GURU_MODULES[@]} ; do
        _module=${GURU_MODULES[$mod_count]}

        gr.msg -v2 -c olive "$mod_count: $_module $function_to_run"
        gr.msg -v3 -c olive "DUCUMENT: $_module: $GURU_DOCUMENTATION:module:$_module"

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

    # gr.msg -v2 -c error "$FUNCNAME: something went wrong when tried to run '$function_to_run' in '$_module'"
    return 13
}


core.change_user () {
# change guru user temporarily
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

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
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

    declare -g offline_flag="/tmp/guru-offline.flag"
    source net.sh

    if net.check_server ; then
        if [[ -f $offline_flag ]] ; then
            gr.end caps
            flag.rm pause
            rm $offline_flag
        fi
        return 0
    else
        touch $offline_flag
        gr.msg -v1 -c white "offline mode"
        gr.end caps
        flag.set pause
        return 127
    fi
}


core.mount_system_base () {
# check is access point enabled and mount is not
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME '$@'" >&2

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
gr.msg -v4 -n -c blue "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GURU_DEBUG ]] && echo $@ >&2

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
    gr.msg -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GURU_DEBUG ]] && echo $@ >&2

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
    gr.msg -v4 -n -c blue "$__core [$LINENO] $FUNCNAME " >&2

    case ${1} in
        *.gm)
            [[ $GURU_DEBUG ]] && echo "yes $@" >&2
            core.run_macro $@
            return 0
            ;;
        *)
            [[ $GURU_DEBUG ]] && echo "nope" >&2
            return 1
    esac
}


core.process_core_opts () {
# process core level options
    gr.msg -v4 -n -c blue "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GURU_DEBUG ]] && echo $@ >&2

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
                export GURU_VERBOSE=4
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

    gr.varlist "debug GURU_DEBUG GURU_COLOR GURU_VERBOSE GURU_SPEAK GURU_COLOR GURU_FORCE GURU_HOSTNAME GURU_LOGGING "


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
    # core debug option

    debug)
        source $GURU_BIN/common.sh
        export GURU_VERBOSE=4
        export GURU_DEBUG=true
        export GURU_COLOR=true
        shift
        ;;

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
        source common.sh
        source config.sh
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

gr.msg -v4 -c $__core_color "$__core [$LINENO] 'base modules loaded'" >&2

# check is core run or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    #\\ process arguments and return cleaned command
    # import needed modules
    gr.msg -v4 -c $__core_color "$__core [$LINENO] core runned" >&2
    
    source $GURU_BIN/common.sh

    # check is core called as interrupter by macro
    core.is_macro $@ && exit $?
    gr.msg -v4 -c $__core_color "$__core [$LINENO] 'no macro'" >&2

    # core.process_opts $@
    core.process_module_opts $@
    core.process_core_opts $GURU_CORE_ARGUMENTS
    gr.msg -v4 -c $__core_color "$__core [$LINENO] 'arguments processed'" >&2

    # export global variables for sub processes
    export GURU_COMMAND=($GURU_MODULE_COMMAND $GURU_MODULE_ARGUMENTS)

    core.parser ${GURU_COMMAND[@]}
    _error_code=$?

    # all fine
    if (( _error_code < 1 )) ; then
        gr.msg -v4 -c $__core_color "$__core [$LINENO] 'no errors'" >&2
        exit 0
    fi

    if [[ $GURU_CORSAIR_ENABLED ]] ; then
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
else
    gr.msg -v4 -c $__core_color "$__core [$LINENO] 'core sourced, why?'" >&2
fi

