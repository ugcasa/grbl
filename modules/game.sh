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
               install|remove|set|start)
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
    gr.msg -v1 " set <game>               set game environment "
    gr.msg -v1 " <game>                   start game "
    gr.msg -v1 " start <game>             start game "
    gr.msg -v1 " remove <game>            remove game "
    gr.msg -v1 " status                   list of available and installed games "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "examples: "
    gr.msg -v1 "         $GURU_CALL game start minecraft"
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

    case $1 in

        pre|"")
            for keys in e s d f ; do
                corsair.main set $keys blue
            done

            for keys in w r ; do
                corsair.main set $keys green
            done

            for keys in 'shiftl' 'space' 'tab' ; do
                corsair.main set $keys white
            done
            ;;

        post)
            for keys in e s d f w r 'shiftl' 'space' 'tab' ; do
                corsair.main reset $keys
            done
            ;;
    esac
}


## Minecraft Bedrock

game.bedrock_start () {
# set environment and start minecraft bedrock

    game.minecraft_set pre
    ./Minecraft_Bedrock_Launcher.AppImage
    sleep 3
    game.minecraft_set post
}


# game.bedrock_set () {
# # setup minecraft bedrock

#     source corsair.sh

#     case $1 in

#         pre|"")
#             for keys in e s d f ; do
#                 corsair.main set $keys blue
#             done

#             for keys in w r ; do
#                 corsair.main set $keys green
#             done

#             for keys in 'shiftl' 'space' 'tab' ; do
#                 corsair.main set $keys white
#             done
#             ;;

#         post)
#             for keys in e s d f w r 'shiftl' 'space' 'tab' ; do
#                 corsair.main reset $keys
#             done
#             ;;
#     esac
# }


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

