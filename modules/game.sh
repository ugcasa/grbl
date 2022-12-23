#!/bin/bash
# guru-cli gaming functions casa@ujo.guru 2022
#
# change log
# - 20221222 module started, bedrock installer
#

declare -g game_rc="/tmp/guru-cli_game.rc"
declare -g game_folder="~/guru/games"
declare -g list_of_games=(duke3d bedrock doom2 minecraft)

game.rc () {
    export GURU_GAME_ENABLED=true
    export GURU_GAME_INDICATOR_KEY=
}


game.main () {
# game main command parser

    local _cmd="$1" ; shift
    local _game="$1" ; shift

    case $_cmd in
               install|remove|set|start|set)
                    game.${_game}_${_cmd} $@
                    return $?
                    ;;
                status)
                    game.${_cmd} $@
                    ;;
               *)
                    game.${_cmd}_start $@ || \
                        gr.msg -c yellow "${FUNCNAME[0]}: unknown command: '${_cmd}' or game '${_game}'"
                    return 2
        esac
    return 0
}


game.help () {
# general help

    gr.msg -v1 -c white "guru-client game help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL game install|set|start|remove|help "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " install <game>           install game and requirements "
    gr.msg -v1 " set <game> pre/post      set game environment before or after game lauch"
    gr.msg -v1 " <game>                   start game "
    gr.msg -v1 " start <game>             start game "
    gr.msg -v1 " remove <game>            remove game "
    gr.msg -v1 " status                   list of available and installed games "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "examples: "
    gr.msg -v1 "         $GURU_CALL game start minecraft"
    gr.msg -v1 "         $GURU_CALL game set minecraft pre"
    gr.msg -v2
    return 0
}


game.status () {
# check game broker is reachable.

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_GAME_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled, " #-k $GURU_GAME_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled " #-k $GURU_GAME_INDICATOR_KEY
            return 1
        fi

    if [[ ${#list_of_games[@]} -lt 1 ]]; then
            gr.msg -c dark_grey "no installed or available games"
        fi

    for _game in ${list_of_games[@]}; do
            game.${_game}_status 2>/dev/null \
                && gr.msg -n -c aqua "$_game " \
                || gr.msg -n -c dark_cyan "$_game "

        done

    echo
    return 0
}


game.poll () {
# daemon required polling functions

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GURU_GAME_INDICATOR_KEY \
                "${FUNCNAME[0]}: game status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GURU_GAME_INDICATOR_KEY \
                "${FUNCNAME[0]}: game status polling ended"
            ;;
        status )
            game.status
            ;;
        *)  game.help
            ;;
        esac
}

## Minecraft Java edition

game.minecraft_status () {
# install minecraft bedrock
    [[ $GURU_GAME_FOLDER/menicraft ]] && return 0 || return 1
}


game.minecraft_start () {
# set environment and start minecraft minecraft

    game.minecraft_set pre
    minecraft-launcher
    game.minecraft_set post
}


game.minecraft_set () {
# setup minecraft bedrock
    source corsair.sh
    pkill mpv
    guru stop

    case $1 in
        pre|"")
            gr.msg -c sky_blue "  A          Strafe Left"
            gr.msg -c sky_blue "  D          Strafe Right"
            gr.msg -c sky_blue "  S          Walk Backward"
            gr.msg -c sky_blue "  W          Walk Forward"
            gr.msg -c sky_blue "  Space      Jump"
            gr.msg -c sky_blue "  Left Shift Sneak"
            gr.msg -c sky_blue "  Left Ctrl  Sprint"

            for keys in 'shiftl' 'lctrl' a d s w 'space' ; do
                corsair.main set $keys blue
            done

            gr.msg -c green "  E          Open Inventory"
            gr.msg -c green "  1-9        Selecthotbarslotof the number youpressed"
            gr.msg -c green "  Q          Drop item"
            gr.msg -c green "  F          Swapheld item(s) to off hand"

            for keys in q f e 1 2 3 4 5 6 7 8 9 ; do
                corsair.main set $keys green
            done

            gr.msg -c orange "  L          Advancements"
            gr.msg -c orange "  F3         Toggles the debug menu"
            gr.msg -c orange "  F2         Takes screenshots and stores them in your .minecraft folder"
            gr.msg -c orange "  Scroll     Scrolls through your quick bar and the chat when opened."

            for keys in 'f2' 'f3' l 'scroll' ; do
                corsair.main set $keys orange
            done

            # unused
            for keys in 'half' 0 'plus' 'query' 'backscape' 'tab' 'f1' 'f4' 'f5' 'f6' 'f7' 'f8' 'f9' 'f10' 'f11' 'f12' r t y u i o p å c 'tilde' 'enter' 'caps' g h j k ö ä 'asterix' 'less' z x v b n m 'comma' 'perioid' 'minus' 'shiftr' 'func' 'alt' 'altgr' 'fn' 'set' 'rctrl'  ; do
                corsair.main set $keys black
            done
            ;;

        post)
            for keys in 'shiftl' 'lctrl' 'f2' 'f3' a d s w space q f e 1 2 3 4 5 6 7 8 9 l c 'scroll' 'half' 0 'plus' 'query' 'backscape' 'tab' r t y u i o p å 'tilde' 'enter' 'caps' f g h j k ö ä 'asterix' 'shiftl' 'less' z x v b n m 'comma' 'perioid' 'minus' 'shiftr' 'func' 'alt' 'altgr' 'fn' 'set' 'rctrl'  ; do
                corsair.main reset $keys
            done
            guru start
            ;;
    esac
}


## Minecraft Bedrock

game.bedrock_start () {
# set environment and start minecraft bedrock

    game.minecraft_set pre

    cd $GURU_GAME_FOLDER/bedrock
    ./Minecraft_Bedrock_Launcher.AppImage

    game.minecraft_set post
}


game.bedrock_set () {
# setup minecraft bedrock
    game.minecraft_set $@
}


game.bedrock_status () {
# install minecraft bedrock
    [[ $GURU_GAME_FOLDER/bedrock ]] && return 0 || return 1
}


game.bedrock_install () {
# install minecraft bedrock

    mkdir -p $GURU_GAME_FOLDER/bedrock
    wget https://mcpelauncher.mrarm.io/appimage/Minecraft_Bedrock_Launcher.AppImage -O $GURU_GAME_FOLDER/Minecraft_Bedrock_Launcher.AppImage
    chmod +x $GURU_GAME_FOLDER/Minecraft_Bedrock_Launcher.AppImage
    cd $GURU_GAME_FOLDER
    ./Minecraft_Bedrock_Launcher.AppImage
}


game.bedrock_remove () {
# remove minecraft bedrock

    if [[ -d $GURU_GAME_FOLDER/bedrock ]] ; then
            rm -r $GURU_GAME_FOLDER/bedrock
        fi

    if [[ $GURU_FORCE ]] && [[ -d $GURU_GAME_FOLDER/bedrock ]] ; then
        gr.ask "remove bedrock saves and configurations?" || return 0
        echo rm -r $GURU_GAME_FOLDER/bedrock
        fi
}


game.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    game.main "$@"
    exit "$?"
fi

