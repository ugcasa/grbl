#!/bin/bash
# mem tools for GRBL casa@ujo.guru 2025

GRBL_COLOR=true # DEBUG
#GRBL_VERBOSE=2 # DEBUG
#GRBL_DEBUG=true # DEBUG
declare -g __mem=$(readlink --canonicalize --no-newline $BASH_SOURCE) # DEBUG
declare -g __mem_color="light_blue" # DEBUG
declare -g mem_rc=/tmp/$USER/gtbl_mem.rc
declare -g mem_config="$GRBL_CFG/$GRBL_USER/mem.cfg"
declare -g mem_require=()

mem.help () {
# mem help printout

    gr.msg -v1 "GRBL mem help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL mem check|status|help|poll|start|end|install|uninstall" -c white
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v1 " check <something>  check stuff "
    gr.msg -v1 " status             one line status information of module "
    gr.msg -v1 " install            install required software: ${mem_require[@]}"
    gr.msg -v1 " uninstall          remove required software: ${mem_require[@]}"
    gr.msg -v1 " help               get more detailed help by increasing verbose level '$GRBL_CALL mem -v2' "
    gr.msg -v2
    gr.msg -v2 "Options:" -c white
    gr.msg -v2 "  o                 say 'ooo-o'"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    gr.msg -v3 "Internal functions: " -c white
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source mem.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'mem.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " mem.main         main command parser "
    gr.msg -v3 " mem.check        check all is fine, return 0 or error number "
    gr.msg -v3 " mem.status       printout one line module status output "
    gr.msg -v3 " mem.rc           lift environmental variables for module functions "
    gr.msg -v3 "                    check changes in user config and update RC file if needed "
    gr.msg -v3 "                    this enables fast user configuration and keep everything up to date "
    gr.msg -v3 " mem.make_rc      generate RC file to /tmp out of $GRBL_CFG/$GRBL_USER/mem.cfg "
    gr.msg -v3 "                    or if not exist $GRBL_CFG/mem.cfg"
    gr.msg -v3 " mem.install      install all needed software"
    gr.msg -v3 "                    stuff that can be installed by apt-get package manager are listed in  "
    gr.msg -v3 "                    'mem_require' list variable, add them there. Other software that is not "
    gr.msg -v3 "                    available in package manager, or is too old can be installed by this function. "
    gr.msg -v3 "                    Note that install.sh can proceed multi_module call for this function "
    gr.msg -v3 "                    therefore what to install (and uninstall) should be described clearly enough. "
    gr.msg -v3 " mem.uninstall    remove installed software. Do not uninstall software that may be needed "
    gr.msg -v3 "                    by other modules or user. Uninstaller asks user every software that it  "
    gr.msg -v3 "                    going to uninstall  "
    gr.msg -v3 " mem.poll         daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " mem.start        daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " mem.stop         daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v3 " mem.status       one line status printout "
    gr.msg -v2
    gr.msg -v2 "Examples:" -c white
    gr.msg -v2 "  $GRBL_CALL mem install   # install required software "
    gr.msg -v2 "  $GRBL_CALL mem status    # print status of this module  "
    gr.msg -v3 "  mem.main status    # print status of mem  "
    gr.msg -v2
}

mem.main () {
# mem main command parser
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _first="$1"
    shift

    gr.debug "option -a: $_op_a"
    gr.debug "option -o: $_op_o"

    case "$_first" in
            check|status|help|poll|start|end|install|uninstall)
                mem.$_first "$@"
                return $?
                ;;

           *)   gr.msg -e1 "${FUNCNAME[0]}: unknown command: '$_first'"
                return 2
    esac
}

mem.rc () {
# source configurations (to be faster)
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # check is user config changed
    if [[ ! -f $mem_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mem.cfg) - $(stat -c %Y $mem_rc) )) -gt 0 ]]
    # if module needs more than one config file here it can be done here
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mem.cfg) - $(stat -c %Y $mem_rc) )) -gt 0 ]] \
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $mem_rc) )) -gt 0 ]]
    then
        mem.make_rc && \
            gr.msg -v2 -c dark_gray "$mem_rc updated"
    fi


    # source current RC file to lift user configurations to environment
    source $mem_rc
}

mem.make_rc () {
# make RC file out of config file
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # remove old RC file
    if [[ -f $mem_rc ]] ; then
            rm -f $mem_rc
        fi

    source config.sh
    config.make_rc "$GRBL_CFG/$GRBL_USER/mem.cfg" $mem_rc

    # config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $mem_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/mem.cfg" $mem_rc append

    # make RC executable
    chmod +x $mem_rc
}

mem.status () {
# module status one liner
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check mem is enabled and printout status
    if [[ $GRBL_MEM_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GRBL_MEM_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GRBL_MEM_INDICATOR_KEY
        return 1
    fi

    gr.msg -c green "ok"
}

mem.install() {
# install required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()

    # install software that is available distro's package manager repository
    for install in ${mem_require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "install $install" || continue
        sudo apt-get -y install $install || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

mem.uninstall() {
# uninstall required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()

    # remove software that is needed ONLY of this module
    for remove in ${mem_require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

mem.option() {
    # process module options
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local options=$(getopt -l "open;auto:;debug;verbose:" -o "doa:v:" -a -- "$@")

    if [[ $? -ne 0 ]]; then
        echo "option error"
        return 101
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            -d|debug)
                GRBL_DEBUG=true
                shift
                ;;
            -v|verbose)
                GRBL_VERBOSE=$2
                shift 2
                ;;
            -o|open)
                _op_o=true
                shift
                ;;
            -a|auto)
                _op_a="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    mem_command_str=($@)
}

mem.poll () {
# daemon required polling functions
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__mem_color "$__mem [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_MEM_INDICATOR_KEY \
                "${FUNCNAME[0]}: mem status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_MEM_INDICATOR_KEY \
                "${FUNCNAME[0]}: mem status polling ended"
            ;;
        status )
            mem.status
            ;;
        esac
}

# update rc and get variables to environment
mem.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mem.option $@
    mem.main ${mem_command_str[@]}
    exit "$?"
else
    [[ $GRBL_DEBUG ]] && gr.msg -c $__mem_color "$__mem [$LINENO] sourced " >&2
fi

