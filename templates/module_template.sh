#!/bin/bash
# modulename tools for GRBL EMAIL YEAR

#: To make your own module run 'gr make module <name>' or make copy of this file
#: - if you copied this template file do following:
#:   - [ ] select all 'MODULENAME' and rename to your module's name written in capital letters, example 'MQTT'
#:   - [ ] select all 'modulename' and rename with module's written in down case
#:
#: Things to do in:
#:
#: modulename.help()
#:   - [ ] add instructions of all written command functions and options
#:   - [ ] add instructions of all internal functions
#:   - [ ] fix postions of lines where modulename are mentioned
#:   - [ ] add examples to modulename.help()
#:
#: Start editing this file
#: - [ ] go though this file, there is instructive comments '#:' that might help
#: - [ ] to run GRBL in debug mode try '-d' option
#:
#: At the end
#: - [ ] select all lines that contains '#:' and remove them
#: - [ ] you might like to remove lines with '# DEBUG' comment
#:
#: if you run 'modulename.sh' alone without GRBL (code.sh), following variables will active coloring and set high level (remove comment #)
GURU_COLOR=true # DEBUG
#GURU_VERBOSE=2 # DEBUG
#GURU_DEBUG=true # DEBUG
#: if like to highlight module debug output change '__modulename_color' variable to "deep_pink" or color you like
#: list of colors can be listed by function call 'gr.colors' (if not working 'source common.sh' first)
#:
declare -g __modulename=$(readlink --canonicalize --no-newline $BASH_SOURCE) # DEBUG
declare -g __modulename_color="light_blue" # DEBUG
declare -g modulename_rc=/tmp/$USER/gtbl_modulename.rc
declare -g modulename_config="$GURU_CFG/$GURU_USER/modulename.cfg"
declare -g modulename_require=()

modulename.help () {
# modulename help printout

#: Verbose level usage in help()
#: -v0 list of external commands (no colors)
#: -v1 most important command descriptions + header
#: -v2 for options and examples + add space to be more readable
#: -v3 for internal functions and more detailed instructions
#: -v4 for debug instructions
#: basic structure below
#:
    #: header and usage section
    gr.msg -v1 "GRBL modulename help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GURU_CALL modulename check|status|help|poll|start|end|install|uninstall" -c white
    #: command section (mostly -v1)
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v1 " check <something>  check stuff "
    gr.msg -v1 " status             one line status information of module "
    gr.msg -v1 " install            install required software: ${modulename_require[@]}"
    gr.msg -v1 " uninstall          remove required software: ${modulename_require[@]}"
    gr.msg -v1 " help               get more detailed help by increasing verbose level '$GURU_CALL modulename -v2' "
    gr.msg -v2
    #: options section
    #: avoid using '-' character in first letter with gr.msg, otherwise it is read as gr.msg option'
    gr.msg -v2 "Options:" -c white
    gr.msg -v2 "  o                 say 'ooo-o'"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    #: mainly for people who writes GRBL modules
    gr.msg -v3 "Internal functions: " -c white
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source modulename.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'modulename.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " modulename.main         main command parser "
    gr.msg -v3 " modulename.check        check all is fine, return 0 or error number "
    gr.msg -v3 " modulename.status       printout one line module status output "
    gr.msg -v3 " modulename.rc           lift environmental variables for module functions "
    gr.msg -v3 "                    check changes in user config and update RC file if needed "
    gr.msg -v3 "                    this enables fast user configuration and keep everything up to date "
    gr.msg -v3 " modulename.make_rc      generate RC file to /tmp out of $GURU_CFG/$GURU_USER/modulename.cfg "
    gr.msg -v3 "                    or if not exist $GURU_CFG/modulename.cfg"
    gr.msg -v3 " modulename.install      install all needed software"
    gr.msg -v3 "                    stuff that can be installed by apt-get package manager are listed in  "
    gr.msg -v3 "                    'modulename_require' list variable, add them there. Other software that is not "
    gr.msg -v3 "                    available in package manager, or is too old can be installed by this function. "
    gr.msg -v3 "                    Note that install.sh can proceed multi_module call for this function "
    gr.msg -v3 "                    therefore what to install (and uninstall) should be described clearly enough. "
    gr.msg -v3 " modulename.uninstall    remove installed software. Do not uninstall software that may be needed "
    gr.msg -v3 "                    by other modules or user. Uninstaller asks user every software that it  "
    gr.msg -v3 "                    going to uninstall  "
    gr.msg -v3 " modulename.poll         daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " modulename.start        daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " modulename.stop         daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v3 " modulename.status       one line status printout "
    gr.msg -v2
    #: some examples of usage
    gr.msg -v2 "Examples:" -c white
    gr.msg -v2 "  $GURU_CALL modulename install   # install required software "
    gr.msg -v2 "  $GURU_CALL modulename status    # print status of this module  "
    gr.msg -v3 "  modulename.main status    # print status of modulename  "
    gr.msg -v2
}

modulename.main () {
# modulename main command parser
    #:
    #: it indicated file and function name, line number and bypassed arguments function gets
    #: by default this line is included to first line of all module functions
    #: following line is only for debug use and are often removed from published version
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    #: remember to shift command out of argument list '$@' after reading it to variable
    local _first="$1"
    shift

    gr.debug "option -a: $_op_a"
    gr.debug "option -o: $_op_o"

    #: process first command given by user.
    #: to add other level of commands make another command parser function named by first command
    case "$_first" in
            check|status|help|poll|start|end|install|uninstall)
                modulename.$_first "$@"
                return $?
                #: remember to return last error to core.sh error handler
                ;;

           *)   gr.msg -e1 "${FUNCNAME[0]}: unknown command: '$_first'"
                return 2
    #: errors below 100 are warnings and will not prompted to user, 1 is reserved to indicate "false"
    esac
}

modulename.rc () {
# source configurations (to be faster)
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # check is user config changed
    if [[ ! -f $modulename_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/modulename.cfg) - $(stat -c %Y $modulename_rc) )) -gt 0 ]]
    # if module needs more than one config file here it can be done here
    #     || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/modulename.cfg) - $(stat -c %Y $modulename_rc) )) -gt 0 ]] \
    #     || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mount.cfg) - $(stat -c %Y $modulename_rc) )) -gt 0 ]]
    then
        modulename.make_rc && \
            gr.msg -v2 -c dark_gray "$modulename_rc updated"
    fi

    #: user configuration variable names are generated following
    #: GURU_ <- old name of environment variable og RGBL
    #: MODULE_ that comes from modulename.cfg ḥeader '[modulename]' therefore module variables should be below it
    #: VARIABLE_NAME name of variable given in cfg 'variable_name=' under [modulename]
    #: value follows bash ways, use '' or "" for strings and () for lists
    #: example: 'GURU_MQTT_ENABLED=true' tells mqtt module to be active, in config it is given in following way
    #: [mqtt]
    #: enabled=true

    # source current RC file to lift user configurations to environment
    source $modulename_rc
}

modulename.make_rc () {
# make RC file out of config file
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # remove old RC file
    if [[ -f $modulename_rc ]] ; then
            rm -f $modulename_rc
        fi

    #: code module 'config.sh' is made to handle configurations
    source config.sh
    config.make_rc "$GURU_CFG/$GURU_USER/modulename.cfg" $modulename_rc

    #: to add another module configuration to modulename RC change to following
    # config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $modulename_rc
    # config.make_rc "$GURU_CFG/$GURU_USER/modulename.cfg" $modulename_rc append

    # make RC executable
    chmod +x $modulename_rc
}

modulename.status () {
# module status one liner
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check modulename is enabled and printout status
    if [[ $GURU_MODULENAME_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GURU_MODULENAME_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GURU_MODULENAME_INDICATOR_KEY
        return 1
    fi

    #: add some status indication functionalities
    #: Keep output in one line max ~80 character and add newline to end
    #: example: 10:11:47 'modulename.status: enabled, device id: 124AMCD, on service '
    gr.msg -c green "ok"
    #: bash returns '0' if not specified
}

modulename.install() {
# install required software
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    #: list of errors
    local _errors=()

    # install software that is available distro's package manager repository
    for install in ${modulename_require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "install $install" || continue
        sudo apt-get -y install $install || _errors+=($?)
    done

    #: add here if need something else than is available (or is too old) in distro's package manager repository

    #: installer error handler
    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        #: return first one
        return $_error_count
    fi
    #: bash returns '0' if not specified
}

modulename.uninstall() {
# uninstall required software
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    #: list of errors
    local _errors=()

    # remove software that is needed ONLY of this module
    for remove in ${modulename_require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove || _errors+=($?)
    done

    #: add here if need something else than is available (or is too old) in distro's package manager repository

    #: uninstaller error handler
    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        #: return first one
        return $_error_count
    fi
    #: bash returns '0' if not specified
}

modulename.option() {
    # process module options
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local options=$(getopt -l "open;auto:;debug;verbose:" -o "doa:v:" -a -- "$@")

    if [[ $? -ne 0 ]]; then
        echo "option error"
        return 101
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            -d|debug)
                GURU_DEBUG=true
                shift
                ;;
            -v|verbose)
                GURU_VERBOSE=$2
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

    modulename_command_str=($@)
}

modulename.poll () {
# daemon required polling functions
    [[ $GURU_DEBUG ]] && gr.msg -n -c $__modulename_color "$__modulename [$LINENO] $FUNCNAME: ">&2; [[ $GURU_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GURU_MODULENAME_INDICATOR_KEY \
                "${FUNCNAME[0]}: modulename status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GURU_MODULENAME_INDICATOR_KEY \
                "${FUNCNAME[0]}: modulename status polling ended"
            ;;
        status )
            modulename.status
            ;;
        esac
}

# update rc and get variables to environment
modulename.rc

#:i check is module sourced or run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    modulename.option $@
    modulename.main ${modulename_command_str[@]}
    #: return caused errors to code.sh error handler
    exit "$?"
else
    #: indicated that this file is sourced, not run
    [[ $GURU_DEBUG ]] && gr.msg -c $__modulename_color "$__modulename [$LINENO] sourced " >&2
fi

