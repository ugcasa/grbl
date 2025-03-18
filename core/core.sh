#!/bin/bash
# grbl core
# casa@ujo.guru 2020-2025

# Do not let run grbl as root
case $USER in root|admin|sudo) echo "too dangerous to run grbl as root!" ; return 100; esac

## BUGFIX
[[ -d /tmp/$USER/ ]] || mkdir -p "/tmp/$USER/"

# debug visualiser variables
__core_color="black"
__core=$(readlink --canonicalize --no-newline $BASH_SOURCE)

# global variables for core
process_list=/tmp/$USER/grbl_ps.list
core_command=
pass_to_core=()
pass_to_module=()
module_options=()

# export variables for modules
declare -x GRBL_RC="$HOME/.grblrc"
declare -x GRBL_BIN="$HOME/bin"
declare -x GRBL_VERSION=$(echo $(head -n1 $GRBL_BIN/version) | tr -d '\n')
declare -x GRBL_VERSION_NAME=$(echo $(tail $GRBL_BIN/version -n +2 | head -n 1 ) | tr -d '\n')

# early exits
case $1 in

    # active core debug messages
    ## option '-d' debug is not covering whole code.sh run
    ## cheap trick and also make debug faster
    debug)
        source $GRBL_BIN/common.sh
        export GRBL_VERBOSE=4
        export GRBL_DEBUG=true
        export GRBL_COLOR=true
        shift
        ;;

    # quick version output makes
    version|--version|--ver)
        echo "$GRBL_VERSION $GRBL_VERSION_NAME"
        exit 0
        ;;
    --help)
        shift
        core.help $@
        exit 0
        ;;
esac


# TODO vertaile kaikk
# if [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/system.cfg) - $(stat -c %Y $GRBL_RC) )) -gt 0 ]]
# # if module needs more than one config file here it can be done here
# #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/lab.cfg) - $(stat -c %Y $GRBL_RC) )) -gt 0 ]] \
# #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $GRBL_RC) )) -gt 0 ]]
# then
#     lab.make_rc && \
#         gr.msg -v2 -c dark_gray "$GRBL_RC updated"
# fi



# check that config rc file exits
if [[ -f $GRBL_RC ]] ; then
    source $GRBL_RC
    gr.debug "sourcing $GRBL_RC.. "
else
    # run user configuration if not exist
    # assume that grbl environment is not present
    source common.sh
    source config.sh
    config.main export $USER

    if [[ -f $GRBL_RC ]]; then
        source $GRBL_RC
        gr.msg -c dark_grey "main rc updated"
    else
        echo "fatal: empty RC file '$GRBL_RC'"
        return 127
    fi
fi

# call name for grbl system is set in system.cfg
[[ $GRBL_SYSTEM_NAME ]] && export GRBL_CALL=$GRBL_SYSTEM_NAME


core.main () {
# parsing first word of user input, rest words are passed to next level parser
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _input="$1" ; shift

    case "$_input" in

        all)
        # run command on all modules
            core.multi_module_function "$@"
            return $?
            ;;

        start|poll|stop)
        # daemon controls
            source $GRBL_BIN/daemon.sh
            daemon.$_input
            return $?
            ;;

        status|kill|top|ps|debug|pause|version|online|list|active)
        # core control functions
            core.$_input $@
            return $?
            ;;

        uninstall)
        # use uninstaller of installed version
            bash "$GRBL_BIN/$_input.sh" "$@"
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
            gr.msg "$GRBL_CALL need more instructions"
            ;;
    esac
}


core.list () {
# printout lists of stuff
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local list=

    case $1 in

        core)
            gr.msg -v2 -h "list of core modules:"
            list=($(cat $GRBL_CFG/installed.core ))
            ;;
        installed|modules)
            gr.msg -v2 -h "list of installed modules:"
            list=($(cat $GRBL_CFG/installed.modules))
            ;;
        commands)
            gr.msg -v2 -h "list of commands:"
            list=(debug pause help version online list all)
            list=(${list[@]} start poll kill stop)
            ;;
        available|*|"")
            gr.msg -v2 -h "list of available modules:"
            list=(${GRBL_MODULES[@]})
            ;;
    esac

    gr.msg -c list "${list[@]}"
}


core.debug () {
# some debug stuff, not used too often
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local wanted=$1
    # local available=($(cat "$GRBL_CFG/variable.list"))
    # local available=($(set | grep 'GRBL_' | grep -v '$'))
    local available=$(cat $GRBL_RC| grep "export GRBL_" | cut -d "=" -f1 | cut -d' ' -f2)
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

            [[ $GRBL_COLOR ]] \
                && gr.msg -c yellow "false (empty)" \
                || echo "   <-------------------------------------- empty or false"

            let empty++
        fi

        done
    gr.msg -N "$i variables where $empty empty one"
}


core.active () {
# start daemon
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # ask key for server,
    # if key is no open, popup passphase input dialog appears

    # # set colors on terminal
    # export GRBL_COLOR=true
    export GRBL_VERBOSE=1

    source mount.sh

    # mount grbl data and cache
    if ! mount.main system ; then
        gr.msg -c failed "unable to active, system data mount failed"
        return 127
    fi

    # mound defaults
    mount.main

    # copy sounds locally to be fast enough
    cp $GRBL_DATA/sounds/*wav /tmp

    # start daemon
    source daemon.sh
    daemon.main start
    return 0
    gr.msg -c gold "bye!"
}


core.status () {
# simple status check


    local modules=($@)

    # get module status
    if [[ ${modules[0]} ]]; then

        for module in ${modules[@]}; do
            # get module status for all
            if [[ $module == "all" ]]; then
                for mod in ${GRBL_MODULES[@]}; do
                    source $mod.sh
                    $mod.status
                done
                return 0
            fi

            # for given modulename
            if [[ "${GRBL_MODULES[@]}" =~ " $module " ]]; then
                source $module.sh
                $module.status
                continue
            else
                gr.msg -e1 "no sutch module '$module'"
                continue
            fi

        done
        return 0
    fi

    # else core status
    gr.msg -t -n "${FUNCNAME[0]}: "
    gr.msg -n -c white "v$GRBL_VERSION $GRBL_VERSION_NAME installed "

    if gr.msg -c dark_gold -k 'g' >/dev/null ; then
        gr.msg -n -v1 -c dark_gold "responsive " -k 'g'
    fi
    gr.msg -c dark_gold -k 'r' >/dev/null

    if core.online ; then
        gr.msg -c aqua "connected " -k caps
    else
        gr.msg -v1 -c black "offline " -k caps
    fi
}

core.ps () {
# list of running grbl processes
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    local ifs=$IFS
    local _pid _int _com _arg
    local data_string=()

    # cut by newline
    IFS=$'\n'

    # get list of processes
    # local raw_list=($(ps -eo %cpu,pid,args | grep -v grep | grep -e $GRBL_BIN/$GRBL_CALL))
    local raw_list=($(ps -eo %cpu,pid,args | grep -v grep | grep -v $$ | grep -e $GRBL_BIN/$GRBL_CALL))
    local raw_list+=($(ps -eo %cpu,pid,args | grep -v grep | grep -v $$ | grep -e "/tmp/$USER/mpvsocket-radio"))
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
# list of grbl processes
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
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
# list of running grbl processes
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

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
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    source flag.sh
    flag.set stop
    return $?
}

core.pause () {
# This function asks the daemon to pause by toggling the pause flag in the system.
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
# The flag is stored using the system.s module.
# If the flag is already set, it will be removed. If it is not set, it will be set. (chatgpt)
    source flag.sh
    if flag.check pause ; then
        flag.rm pause
    else
        flag.set pause
    fi
    return 0
}

core.make_adapter () {
# make adapter to multi file module
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local module=$1 ; shift
    local temp_script=$GRBL_BIN/$module.sh

    gr.msg -n -v2 -c dark_grey "generating adapter for $module module.. "

    cat > "$temp_script" <<EOL
#!/bin/bash
# grbl adapter generated by core $(date)
source "$GRBL_BIN/$module/$module.sh"
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    gr.debug "\${0##*/}: adapting $module to $GRBL_BIN/$module/$module.sh with variables \$@"
    $module.main "\$@"
fi
EOL

    if [[ -f $GRBL_BIN/$module.sh ]] ; then
        gr.msg -v2 -c green "ok"
        chmod +x "$GRBL_BIN/$module.sh"
    else
        gr.msg -v2 -c error "file not generated in right location"
        return 123
    fi
}


core.run_module () {
# check is input in module list and if so, call module main
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local type_list=(".sh" ".py" "")
    local run_me=

    # check is given command in reserved words, if so change argument order
     if gr.contain "$1" "${GRBL_SYSTEM_RESERVED_CMD[@]}" ; then
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

    #if gr.contain "$1" "${GRBL_SYSTEM_RESERVED_CMD[@]}" ; then
    # if [[ "${GRBL_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] ; then
    #     gr.debug "fmc"
    #     local function=$1 ; shift
    #     local module=$1 ; shift
    #     local command=$1 ; shift
    # elif [[ "${GRBL_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] && [[ "${GRBL_MODULES[@]}" =~ $2 ]]; then
    #     gr.debug "cmf"
    #     local command=$1 ; shift
    #     local module=$1 ; shift
    #     local function=$1 ; shift
    # else
    #     gr.debug "mcf"
    #     local module=$1 ; shift
    #     local command=$1 ; shift
    #     local function=$1 ; shift
    # fi

    # go trough $modules if match do the $command and pas $function ans rest
    for _module in ${GRBL_MODULES[@]} ; do

        # not match
        if ! [[ "$_module" == "$module" ]] ; then
                continue
        fi

        # match, go trough possible filenames
        for _type in ${type_list[@]} ; do

            # check is module folder, create adpater if not found
            if [[ -f "$GRBL_BIN/$_module/$_module.sh" ]] && ! [[ -f "$GRBL_BIN/$_module.sh" ]]; then
                core.make_adapter $_module
            fi

            # module in recognized format found
            if [[ -f "$GRBL_BIN/$_module$_type" ]] ; then

                # make command
                run_me="$_module$_type $command $function $@"

                # speak out what ever module returns
                if [[ $GRBL_SPEAK ]] ; then
                    local module_output="$(${run_me[@]//  / })"
                    module_output="$(echo $module_output | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g'))"
                    gr.msg -v2 "$module_output"
                    espeak -p $GRBL_SPEAK_PITCH \
                           -s $GRBL_SPEAK_SPEED \
                           -v $GRBL_SPEAK_LANG \
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

    gr.msg -v1 "grbl recognize no module named '$module'"
    return $?

    # if gr.ask "passing to request to operating system?" ; then
    #    $module $@
    #   fi
}


core.print_description () {
# printout function description for documentation and debugging
    #gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

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
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # grbl add ssh key @ -> grbl ssh key add @
    if gr.contain "$1" "${GRBL_SYSTEM_RESERVED_CMD[@]}" ; then
        gr.debug "order: cmf"
        local command=$1 ; shift
        local module=$1 ; shift
        local function=$1 ; shift
     else
        gr.debug "order: mcf"
        local module=$1 ; shift # note: there was reason to use shift over $2, $3, may just be cleaner
        local command=$1 ; shift
        local function=$1 ; shift
    fi

    # ei jaksa testailla on yö ja huomenna koulua
    # if [[ "${GRBL_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] ; then
    #     gr.debug "fmc"
    #     local function=$1 ; shift
    #     local module=$1 ; shift
    #     local command=$1 ; shift
    # elif [[ "${GRBL_SYSTEM_RESERVED_CMD[@]}" =~ $1 ]] && [[ "${GRBL_MODULES[@]}" =~ $2 ]]; then
    #     gr.debug "cmf"
    #     local command=$1 ; shift
    #     local module=$1 ; shift
    #     local function=$1 ; shift
    # else
    #     gr.debug "mcf"
    #     local module=$1 ; shift
    #     local command=$1 ; shift
    #     local function=$1 ; shift
    # fi

    gr.varlist "debug module command function module_options"

        # check is module on that name installed
        if [[ "${GRBL_MODULES[@]}" =~ "$module" ]] ; then
            # check is module folder, create adapter if is not found
            if [[ -f "$GRBL_BIN/$module/$module.sh" ]] && ! [[ -f "$GRBL_BIN/$module.sh" ]] ; then
                core.make_adapter $module
            fi

            # printout module documentation link
            gr.msg -v3 -c white "documentation: $GRBL_DOCUMENTATION:module:$module"

            # check if module is shell script
            if [[ -f "$GRBL_BIN/$module.sh" ]] ; then

                # printout function description
                core.print_description $module "$command" "$GRBL_BIN/$module.sh"

                # source module as function collection
                source $GRBL_BIN/$module.sh
                # check if module contains options function
                if grep $GRBL_BIN/$module.sh -e "$module.option" -q; then
                    # if module do parse it's onw options, it needs to be done here
                    $module.option "$function" "$@"
                fi
                # call main function of module
                $module.main "$command" "$function" "$@"
                return $?
            fi

            # run one function in python script
            if [[ -f "$GRBL_BIN/$module.py" ]] ; then
                # TBD add environment
                $module.py "$command" "$function" "$@"
                return $?
            fi

            # run binaries
            if [[ -f "$GRBL_BIN/$module" ]] ; then
                $module "$command" "$function" "$@"
                return $?
            fi
        fi

    # if here something went wrong, raise warning
    gr.msg -v1 -V2 -c error "$GRBL_CALL see no sense in your request '$module'"
    gr.msg -v2 -c error "$FUNCNAME: function '$function' in module '$module' not found"
    return 12
}


core.multi_module_function () {
# run function name of all installed modules
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2


    local function_to_run=$1
    shift

    for (( mod_count = 0; mod_count < ${#GRBL_MODULES[@]}; mod_count++ )); do
    # for _module in ${GRBL_MODULES[@]} ; do
        _module=${GRBL_MODULES[$mod_count]}

        gr.msg -v2 -c olive "$mod_count: $_module $function_to_run"
        gr.msg -v3 -c olive "DUCUMENT: $_module: $GRBL_DOCUMENTATION:module:$_module"

        # fun shell script module functions
        if [[ -f "$GRBL_BIN/$_module.sh" ]] ; then
            source $GRBL_BIN/$_module.sh
            $_module.main "$function_to_run" "$@"
        fi

        # run python module functions
        if [[ -f "$GRBL_BIN/$_module.py" ]] ; then
            $_module.py "$function_to_run" "$@"
        fi

        # run binary module functions
        if [[ -f "$GRBL_BIN/$_module" ]] ; then
            $_module "$function_to_run" "$@"
        fi
    done

    # gr.msg -v2 -c error "$FUNCNAME: something went wrong when tried to run '$function_to_run' in '$_module'"
    return 13
}


core.change_user () {
# change grbl user temporarily
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _input_user=$1
    if [[ "$_input_user" == "$GRBL_USER" ]] ; then
        gr.msg -c yellow "user is already $_input_user"
        return 0
    fi

    export GRBL_USER=$_input_user
    source $GRBL_BIN/config.sh

    if [[ -d "$GRBL_CFG/$GRBL_USER" ]] ; then
        gr.msg -c white "changing user to $_input_user"
        config.main export $_input_user
    else
        gr.msg -c yellow "user configuration not exits"
    fi
}


core.online () {
# check is online, set pause for daemon if not
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    declare -g offline_flag="/tmp/$USER/grbl-offline.flag"
    source net.sh
    source flag.sh

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
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    source mount.sh
    # is access functionality enabled?
    if ! [[ $GRBL_ACCESS_ENABLED ]] ; then
        gr.msg -c error "access not enabled"
        return 12
    fi

    # is mount functionality enabled?
    if ! [[ $GRBL_MOUNT_ENABLED ]] ; then
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

core.run_macro () {
# run macro
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

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
        if [[ " ${GRBL_SYSTEM_RESERVED_CMD[@]} " =~ " ${words_list[0]} " ]]; then
            core.run_module_function "${words_list[1]}"\
                                     "${words_list[2]}"\
                                     "${words_list[0]}"\
                                     "${words_list[@]:3}"
            continue
        # check is there module named as given command
        elif [[ " ${GRBL_MODULES[@]} " =~ " ${words_list[0]} " ]]; then
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
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    case ${1} in
        *.gm)
            [[ $GRBL_DEBUG ]] && echo "yes $@" >&2
            core.run_macro $@
            return 0
            ;;
        *)
            [[ $GRBL_DEBUG ]] && echo "nope" >&2
            return 1
    esac
}



core.process_module_opts () {
# This function processes command line arguments for a module and core, making sure that each argument is
# correctly assigned to the appropriate variable. The processed arguments are then exported as environment
# variables for use in other parts of the program. Comments of this function are generated by chatGPT.
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # The function starts by initializing three variables: input_string_list, pass_to_module, and pass_to_core.
    # The input_string_list variable holds all the command line arguments passed to the function, while pass_to_module
    # and pass_to_core will hold the processed arguments that will be passed to the module and core, respectively.
    local input_string_list=($@)
    # local pass_to_module=()
    # local pass_to_core=()

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

                        pass_to_module+=("${input_string_list[$i]/'-'}")
                        gr.debug "module options: '${input_string_list[$i]}'"
                        ;;
                    *)
                        gr.debug "module option with arguments: '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                        # remove another hyphen
                        pass_to_module+=("${input_string_list[$i]/'-'}")
                        let i++
                        pass_to_module+=("${input_string_list[$i]}")
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
                        gr.debug "core options: '${input_string_list[$i]}'"
                        pass_to_core+=("${input_string_list[$i]}")
                        ;;
                    *)
                        # echo "core option with arguments '${input_string_list[$i]}=${input_string_list[$((i + 1))]}'"
                        pass_to_core+=("${input_string_list[$i]}")
                        let i++
                        pass_to_core+=("${input_string_list[$i]}")
                esac
                ;;

            *)  # If the argument does not start with - or --, it is considered a module name and command,
                # and it is added to pass_to_core.
                gr.debug "module command: '${input_string_list[$i]}'"
                pass_to_core="$pass_to_core ${input_string_list[$i]}"
        esac
    done

    gr.debug "pass_to_core: '${pass_to_core[@]}'"
    gr.debug "pass_to_module: '${pass_to_module[@]}'"
    # Finally, the processed pass_to_module and pass_to_core arguments are exported to environment variables
    # ${pass_to_module[@]} and ${pass_to_core[@]}, respectively. The tr command is used to remove any redundant
    # spaces in the processed arguments before exporting them. (tr is fastest method stack overflow 50259869)
}


core.process_core_opts () {
# process core level options
    gr.msg -n -v4 -c $__core_color "$__core [$LINENO] $FUNCNAME " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # default values for global control variables
    declare -gx GRBL_FORCE=
    declare -gx GRBL_SPEAK=
    declare -gx GRBL_LOGGING=
    declare -gx GRBL_HOSTNAME=$(hostname)
    declare -gx GRBL_VERBOSE=$GRBL_FLAG_VERBOSE
    declare -gx GRBL_COLOR=$GRBL_FLAG_COLOR

    # go trough core arguments, long options should be on cause passing command trough this too
    TEMP=`getopt --longoptions -o "dcsflqh:u:v:" $@`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in

            -d)
                export GRBL_DEBUG=true
                export GRBL_VERBOSE=4
                shift
                ;;
            -c)
                export GRBL_COLOR=
                shift
                ;;
            -s)
                export GRBL_VERBOSE=2
                export GRBL_SPEAK=true
                shift
                ;;
            -f)
                export GRBL_FORCE=true
                shift
                ;;
            -h)
                export GRBL_HOSTNAME="$2"
                shift 2 ;;
            -l)
                export GRBL_LOGGING=true
                shift
                ;;
            -q)
                export GRBL_VERBOSE=
                export GRBL_GRBL_SPEAK=
                shift
                ;;
            -u)
                core.change_user "$2"
                shift 2
                ;;
            -v)
                export GRBL_VERBOSE="$2"
                shift 2
                ;;
             *) break
        esac
    done

    gr.varlist "debug GRBL_DEBUG GRBL_COLOR GRBL_VERBOSE GRBL_SPEAK GRBL_COLOR GRBL_FORCE GRBL_HOSTNAME GRBL_LOGGING "

    # clean rest of user input
    local left_overs="$@"
    if [[ "$left_overs" != "--" ]] ; then
        core_command="${left_overs#* }"
    fi
    gr.varlist "debug core_command"
}

# check is core run or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    # import needed modules
    source $GRBL_BIN/common.sh

    # check is core called as interrupter by macro
    core.is_macro $@ && exit $?

    # process mmodule options first, return to pass_to* list variables
    core.process_module_opts $@
    # process core options separated by previos function
    core.process_core_opts ${pass_to_core[@]}

    # core main command parser
    core.main $core_command ${pass_to_module[@]}
    # collect return code
    _error_code=$?
    # check errors, exit if none
    if (( _error_code < 1 )) ; then
        gr.msg -v4 -c $__core_color "$__core [$LINENO] 'no errors'" >&2
        exit 0
    fi

    # error handler
    if (( _error_code < 100 )) ; then
    # # less than 100 are warnings
        gr.msg -v3 -c yellow "warning: $_error_code $GRBL_LAST_ERROR"
    else
    # real errors
        gr.msg -v2 -c red  "error: $_error_code $GRBL_LAST_ERROR"
    fi

    # corsair indication
    GRBL_VERBOSE=0
    source corsair.sh
    if [[ $GRBL_CORSAIR_ENABLED ]] && corsair.check; then
        corsair.indicate error
        corsair.main type "er$_error_code" >/dev/null
    fi

    # return error code
    exit $_error_code

fi

