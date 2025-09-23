################# corsair config functions ######################
# relies on corsair variables, source only from corsair module

corsair.rc () {
# source configurations
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    # check is corsair configuration changed lately, update rc if so
    if [[ ! -f $corsair_rc ]] \
        || [[ $(( $(stat -c %Y $corsair_config) - $(stat -c %Y $corsair_rc) )) -gt 0 ]]; then
            corsair.make_rc && gr.msg -v1 -c dark_gray "$corsair_rc updated"
        fi

    if [[ -f $corsair_rc ]] ; then
        source $corsair_rc
        return 0
    else
        gr.msg -v2 -c dark_gray "no configuration"
        return 100
    fi
}

corsair.make_rc () {
# construct corsair configuration rc
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    source config.sh

    # try to find user configuration
    if ! [[ -f $corsair_config ]] ; then
        gr.debug "$corsair_config does not exist"
        corsair_config="$GRBL_CFG/corsair.cfg"

        # try to find default configuration
        if ! [[ -f $corsair_config ]] ; then
            gr.debug "$corsair_config not exist, skipping"
            return 0
        fi
    fi

    # remove existing rc file
    if [[ -f $corsair_rc ]] ; then
        rm -f $corsair_rc
    fi

    config.make_rc $corsair_config $corsair_rc
    chmod +x $corsair_rc
}

corsair.status () {
# get status for daemon (or user)
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -n -v1 -V3 -t "${FUNCNAME[0]}: "
    if corsair.check ; then
        gr.msg -n -v3 -t "${FUNCNAME[0]}: "

        gr.msg -n -c aqua "on service"
        [[ $kb_available ]] || gr.msg -V2 -n -c black " keyboard disconnected"
        [[ $ms_available ]] || gr.msg -V2 -n -c black  " mouse disconnected "
        gr.msg
        return 0
    else
        gr.msg -n -v3 -t "${FUNCNAME[0]}: "
        gr.msg -c black "offline"
        return 5
    fi
}

corsair.poll () {
# grbl daemon api functions
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started"
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended"
            ;;
        status )
            corsair.status $@
            ;;
        *)  corsair.help
            ;;
    esac
}

