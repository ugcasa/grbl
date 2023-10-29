#!/bin/bash
# tmux controller
# casa@ujo.guru 2020
# thanks samoshkin! https://github.com/samoshkin/tmux-config
# [vim + tmux - OMG!Code](https://www.youtube.com/watch?v=5r6yzFEXajQ)
# [Complete tmux Tutorial](https://www.youtube.com/watch?v=Yl7NFenTgIo)
# config location: ~/.tmux.conf (overrides defaults)
# https://stackoverflow.com/questions/60335872/start-tmux-with-specific-layout
# https://gist.github.com/sdondley/b01cc5bb1169c8c83401e438a652b84e
# https://gist.github.com/Muzietto/325344c2b1b3b723985a85800cafef4f

source $GURU_BIN/common.sh
tmux_indicator_key="f$(gr.poll tmux)"


tmux.help () {
    # general help

    gr.msg -v1 -c white "guru-client tmux help "
    gr.msg -v2
    gr.msg -V2 -v0 "usage:    $GURU_CALL tmux ls|attach|config "
    gr.msg -v2     "usage:    $GURU_CALL tmux ls|attach|config|help|status|start|end|install|remove "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " ls                       list on running sessions "
    gr.msg -v1 " attach <session>         attach to exist session "
    gr.msg -v1 " config                   open configuration in dialog "
    gr.msg -v1 " config edit              open configuration in $GURU_PREFERRED_EDITOR "
    gr.msg -v1 " config undo              undo last config changes "
    gr.msg -v1 " status                   show status of default tmux server "
    gr.msg -v1 " install                  install client requirements "
    gr.msg -v1 " remove                   remove installed requirements "
    gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "examples: "
    gr.msg -v1 "         $GURU_CALL tmux config "
    gr.msg -v2
}


tmux.main () {
    # tmux main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in
               help|ls|attach|install|remove|poll|status|config)
                # TBD rm/deattach session
                    tmux.$_cmd "$@"
                    return $?
                    ;;
               *)   gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 2
        esac
}


tmux.ls () {
    # list of sessions

    tmux ls | cut -d ':'
    return $?
}


tmux.config () {
    # tmux configuration manager

    local editor='dialog'
    [[ $1 ]] && editor='$1'
    config_file="$HOME/.tmux.conf"

    if ! [[ -f $config_file ]] ; then
        if gr.ask "user configuration fur user did not found, create from template?" ; then
                [[ -f /usr/share/doc/tmux/example_tmux.conf ]] \
                    && cp /usr/share/doc/tmux/example_tmux.conf $config_file \
                    || gr.msg -c yellow "tmux default file not found try to install '$GURU_CALL tmux install'"
            else
                gr.msg -v1 "nothing changed, using tmux default config"
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

    # gr.msg -v3 "checking dialog installation.."
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
            gr.msg -v1 "nothing changed.."
            return 0
        fi

    if gr.ask "overwrite settings" ; then
            cp -f "$config_file" "$config_file.old"
            gr.msg -v1 "backup saved $config_file.old"
            echo "$new_file" >"$config_file"
            gr.msg -v1 -c white "configure saved"
            gr.msg -v2 "to get previous configurations from sever type: '$GURU_CALL config undo'"
        else
            gr.msg -v1 -c dark_golden_rod "nothing changed"
        fi
    return 0
}


tmux.config_undo () {
    # return previous config

    if [[ $1 ]] ; then
            local config_file="$1"
        else
            gr.msg -c yellow "config file '$1' does not exist"
            return 0
        fi

    if gr.ask "undo changes?" ; then
            mv -f "$config_file" "$config_file.tmp"
            cp -f "$config_file.old" "$config_file"
            mv -f "$config_file.tmp" "$config_file.old"
            gr.msg -v1 -c white "previous configure returned"
        else
            gr.msg -v1 -c error "nothing changed"
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
    # check tmux broker is reachable. printout and signal by corsair keyboard indicator led - if available

    #tmux_indicator_key="f$(gr.poll tmux)"

    gr.msg -n -t "${FUNCNAME[0]}: "

    if [[ $GURU_TMUX_ENABLED ]] ; then
            gr.msg -n -c green "enabled, "
        else
            gr.msg -c reset "disabled " -k $tmux_indicator_key
            return 1
        fi

    local sessions=($(tmux ls |cut -f 1 -d ':'))
    local active=$(tmux ls | grep '(attached)' | cut -f 1 -d ':')
    local _id=""

    gr.msg -n "${#sessions[@]} sessions: "
    for _id in ${sessions[@]} ; do
            if [[ $_id == $active ]] ; then
                    gr.msg -n -c aqua_marine "$_id "
                else
                    gr.msg -n -c light_blue "$_id "
                fi
            #gr.msg -c pink "$_id : $active"
        done
    echo
}


tmux.attach () {
    # attach to tmux session if exist

    local session="0"
    [[ $1 ]] && session="$1"

    if [[ $TMUX ]] ; then
            gr.msg -c white "working inside of tmux session"
            gr.msg -v1 "open new terminal or close current session"
            return 2
        fi

    if ! tmux ls | grep $session ; then
            gr.msg -c yellow "session '$session' does not exist"
            return 1
        fi

    if [[ $DISPLAY ]] ; then
            gnome-terminal --geometry 180x50 -- /usr/bin/tmux attach -t $session
        else
            /usr/bin/tmux attach -t $session
        fi
    return $?

}


tmux.poll () {
    # daemon required polling functions

    local _cmd="$1" ; shift
    local tmux_indicator_key="f$(gr.poll tmux)"

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $tmux_indicator_key \
                "${FUNCNAME[0]}: tmux status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
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
        && gr.msg -c green "guru is now ready to tmux" \
        || gr.msg -c yellow "error $? during install tmux"
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

