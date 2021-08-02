#!/bin/bash
# tmux controller
# casa@ujo.guru 2020 - 2021
# thanks samoshkin! https://github.com/samoshkin/tmux-config
# [vim + tmux - OMG!Code](https://www.youtube.com/watch?v=5r6yzFEXajQ)
# [Complete tmux Tutorial](https://www.youtube.com/watch?v=Yl7NFenTgIo)
# config location: ~/.tmux.conf (overrides defaults)

source $GURU_BIN/common.sh
tmux_indicator_key="f$(daemon.poll_order tmux)"
GURU_VERBOSE=1

tmux.help () {
    gmsg -v1 -c white "guru-client tmux help "
    gmsg -v2
    gmsg -V2 -v0 "usage:    $GURU_CALL tmux ls|attach|config "
    gmsg -v2     "usage:    $GURU_CALL tmux ls|attach|config|help|status|start|end|install|remove "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " ls                       list on running sessions "
    gmsg -v1 " attach <session>         attach to exist session "
    gmsg -v1 " config                   open configuration in dialog "
    gmsg -v1 " config edit              open configuration in $GURU_PREFERRED_EDITOR "
    gmsg -v1 " config undo              undo last config changes "
    gmsg -v1 " status                   show status of default tmux server "
    gmsg -v1 " install                  install client requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2 " help                     printout this help "
    gmsg -v2
    gmsg -v1 -c white "examples: "
    gmsg -v1 "         $GURU_CALL tmux config "
    gmsg -v2
}


tmux.main () {
    # tmux main command parser
    local _cmd="$1" ; shift

    case "$_cmd" in
               help|ls|attach|install|remove|poll|status|config)
                    tmux.$_cmd "$@"
                    return $?
                    ;;
               *)   gmsg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 2
        esac
}


tmux.ls () {
    tmux ls | cut -d ':'
    return $?
}


tmux.config () {
    # tmux configuration manager
    local editor='dialog'
    [[ $1 ]] && editor='$1'
    config_file="$HOME/.tmux.conf"

    if ! [[ -f $config_file ]] ; then
        if gask "user configuration fur user did not found, create from template?" ; then
                [[ -f /usr/share/doc/tmux/example_tmux.conf ]] \
                    && cp /usr/share/doc/tmux/example_tmux.conf $config_file \
                    || gmsg -c yellow "tmux default file not found try to install '$GURU_CALL tmux install'"
            else
                gmsg -v1 "nothing changed, using tmux default config"
                return 0
            fi
        fi

    case $1 in

                edit)
                    $GURU_PREFERRED_EDITOR $config_file
                    return 0
                    ;;
                undo|return)
                    tmux.config_undo $config_file
                    ;;
                dialog|*)
                    tmux.config_dialog $config_file
                    ;;
       esac
}



tmux.config_dialog () {
    # open dialog to make changes to tmux config file

    # gmsg -v3 "checking dialog installation.."
    dialog --version >>/dev/null || sudo apt install dialog
    local config_file="$HOME/fuckedup.conf"
    [[ $1 ]] && config_file="$1"

    # open temporary file handle and redirect it to stdout
    exec 3>&1
    new_file="$(dialog --editbox "$config_file" "0" "0" 2>&1 1>&3)"
    return_code=$?
    # close new file handle
    exec 3>&-
    clear

    if (( return_code > 0 )) ; then
            gmsg -v1 "nothing changed.."
            return 0
        fi

    if gask "overwrite settings" ; then
            cp -f "$config_file" "$config_file.old"
            gmsg -v1 "backup saved $config_file.old"
            echo "$new_file" >"$config_file"
            gmsg -v1 -c white "configure saved"
            gmsg -v2 "to get previous configurations from sever type: '$GURU_CALL config undo'"
        else
            gmsg -v1 -c dark_golden_rod "nothing changed"
        fi
    return 0
}


tmux.config_undo () {

    if [[ $1 ]] ; then
            local config_file="$1"
        else
            gmsg -c yellow "config file '$1' does not exist"
            return 0
        fi

    if gask "undo changes?" ; then
            mv -f "$config_file" "$config_file.tmp"
            cp -f "$config_file.old" "$config_file"
            mv -f "$config_file.tmp" "$config_file.old"
            gmsg -v1 -c white "previous configure returned"
        else
            gmsg -v1 -c dark_golden_rod "nothing changed"
        fi
}


tmux.open () {
    # open tmux session
    local session="0"
    [[ $1 ]] && session="$1"
    tmux attach -s $session
    return 0
}



tmux.status () {
    # check tmux broker is reachable.
    # printout and signal by corsair keyboard indicator led - if available
    tmux_indicator_key="f$(daemon.poll_order tmux)"

    gmsg -n -t "${FUNCNAME[0]}: "

    if [[ $GURU_TMUX_ENABLED ]] ; then
            gmsg -n -c green "enabled, "
        else
            gmsg -c reset "disabled " -k $tmux_indicator_key
            return 1
        fi

    local sessions=($(tmux ls |cut -f 1 -d ':'))
    local active=$(tmux ls | grep '(attached)' | cut -f 1 -d ':')
    local _id=""

    gmsg -n "${#sessions[@]} sessions: "
    for _id in ${sessions[@]} ; do
            if [[ $_id == $active ]] ; then
                    gmsg -n -c aqua_marine "$_id "
                else
                    gmsg -n -c light_blue "$_id "
                fi
            #gmsg -c pink "$_id : $active"
        done
    echo
}


tmux.attach () {
    # attach to tmux session if exist
    local session="0"
    [[ $1 ]] && session="$1"

    if [[ $TMUX ]] ; then
            gmsg -c white "working inside of tmux session"
            gmsg -v1 "open new terminal or close current session"
            return 2
        fi

    if ! tmux ls | grep $session ; then
            gmsg -c yellow "session '$session' does not exist"
            return 1
        fi

    if [[ $DISPLAY ]] ; then
            gnome-terminal  --geometry 180x50 -- /usr/bin/tmux attach -t $session
        else
            /usr/bin/tmux attach -t $session
        fi
    return $?

}


tmux.poll () {
    # daemon required polling functions
    local _cmd="$1" ; shift
    local tmux_indicator_key="f$(daemon.poll_order tmux)"

    case $_cmd in
        start )
            gmsg -v1 -t -c black \
                -k $tmux_indicator_key \
                "${FUNCNAME[0]}: tmux status polling started"
            ;;
        end )
            gmsg -v1 -t -c reset \
                -k $tmux_indicator_key \
                "${FUNCNAME[0]}: tmux status polling ended"
            ;;
        status )
            tmux.status
            ;;
        *)  tmux.help
            ;;
        esac
}


tmux.install () {
    # install tmux
    sudo apt update
    sudo apt install tmux \
        && gmsg -c green "guru is now ready to tmux" \
        || gmsg -c yellow "error $? during install tmux"
    return 0

}


tmux.remove () {
    # remove tmux
    sudo apt remove tmux && return 0
    return 1
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tmux.main "$@"
    exit "$?"
fi

