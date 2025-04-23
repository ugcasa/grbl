#!/bin/bash
# alias tools for GRBL casa@ujo.guru 2025

GRBL_COLOR=true # DEBUG
#GRBL_VERBOSE=2 # DEBUG
#GRBL_DEBUG=true # DEBUG
declare -g __alias=$(readlink --canonicalize --no-newline $BASH_SOURCE) # DEBUG
declare -g __alias_color="light_blue" # DEBUG
declare -g alias_rc=/tmp/$USER/gtbl_alias.rc
declare -g alias_config="$GRBL_CFG/$GRBL_USER/alias.cfg"
declare -g alias_require=()

source $alias_config

alias.help () {
# alias help printout

    gr.msg -v1 "GRBL alias help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL alias check|status|help|poll|start|end|install|uninstall" -c white
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v1 " check <something>  check stuff "
    gr.msg -v1 " status             one line status information of module "
    gr.msg -v1 " help               get more detailed help by increasing verbose level '$GRBL_CALL alias -v2' "
    gr.msg -v2
    gr.msg -v2 "Options:" -c white
    gr.msg -v2 "  o                 say 'ooo-o'"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    gr.msg -v3 "Internal functions: " -c white
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source alias.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'alias.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " alias.main         main command parser "
    gr.msg -v3 " alias.check        check all is fine, return 0 or error number "
    gr.msg -v3 " alias.status       printout one line module status output "
    # gr.msg -v3 " alias.rc           lift environmental variables for module functions "
    # gr.msg -v3 "                    check changes in user config and update RC file if needed "
    # gr.msg -v3 "                    this enables fast user configuration and keep everything up to date "
    # gr.msg -v3 " alias.make_rc      generate RC file to /tmp out of $GRBL_CFG/$GRBL_USER/alias.cfg "
    # gr.msg -v3 "                    or if not exist $GRBL_CFG/alias.cfg"
    # gr.msg -v3 " alias.install      install all needed software"
    # gr.msg -v3 "                    stuff that can be installed by apt-get package manager are listed in  "
    # gr.msg -v3 "                    'alias_require' list variable, add them there. Other software that is not "
    # gr.msg -v3 "                    available in package manager, or is too old can be installed by this function. "
    # gr.msg -v3 "                    Note that install.sh can proceed multi_module call for this function "
    # gr.msg -v3 "                    therefore what to install (and uninstall) should be described clearly enough. "
    # gr.msg -v3 " alias.uninstall    remove installed software. Do not uninstall software that may be needed "
    # gr.msg -v3 "                    by other modules or user. Uninstaller asks user every software that it  "
    # gr.msg -v3 "                    going to uninstall  "
    gr.msg -v3 " alias.poll         daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " alias.start        daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " alias.stop         daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v2
    gr.msg -v2 "Examples:" -c white
    gr.msg -v2 "  $GRBL_CALL alias install   # install required software "
    gr.msg -v2 "  $GRBL_CALL alias status    # print status of this module  "
    gr.msg -v3 "  alias.main status    # print status of alias  "
    gr.msg -v2
}

alias.main () {
# alias main command parser
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__alias_color "$__alias [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _first="$1"
    shift

    gr.debug "option a: $_op_a"
    gr.debug "option o: $_op_o"

    case "$_first" in
            check|status|help|poll|start|end|install|uninstall)
                alias.$_first "$@"
                return $?
                ;;

           *)   gr.msg -e1 "${FUNCNAME[0]}: unknown command: '$_first'"
                return 2
    esac
}


# alias.make_alias.sh () {
# }


alias.status () {
# module status one liner
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__alias_color "$__alias [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check alias is enabled and printout status
    if [[ $GRBL_ALIAS_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GRBL_ALIAS_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GRBL_ALIAS_INDICATOR_KEY
        return 1
    fi

    gr.msg -c green "ok"
}


alias.option() {
    # process module options
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__alias_color "$__alias [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

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

    alias_command_str=($@)
}

alias.poll () {
# daemon required polling functions
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__alias_color "$__alias [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_ALIAS_INDICATOR_KEY \
                "${FUNCNAME[0]}: alias status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_ALIAS_INDICATOR_KEY \
                "${FUNCNAME[0]}: alias status polling ended"
            ;;
        status )
            alias.status
            ;;
        esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    alias.option $@
    alias.main ${alias_command_str[@]}
    exit "$?"
else
    [[ $GRBL_DEBUG ]] && gr.msg -c $__alias_color "$__alias [$LINENO] sourced " >&2
fi

