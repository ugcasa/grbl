#!/bin/bash
# grbl gaming functions casa@ujo.guru 2022
#
# change log
# - 20221222 module started, bedrock installer
#

declare -g game_rc="/tmp/$USER/grbl_game.rc"
declare -g game_folder="~/grbl/games"
declare -g list_of_games=(duke3d bedrock doom2 minecraft)

game.rc () {
    export GRBL_GAME_ENABLED=true
    export GRBL_GAME_INDICATOR_KEY=
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

    gr.msg -v1 -c white "grbl game help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL game install|set|start|remove|help "
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
    gr.msg -v1 "         $GRBL_CALL game start minecraft"
    gr.msg -v1 "         $GRBL_CALL game set minecraft pre"
    gr.msg -v2
    return 0
}


game.status () {
# check game broker is reachable.

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GRBL_GAME_ENABLED ]] ; then
            gr.msg -v1 -n -c green "enabled, " #-k $GRBL_GAME_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled " #-k $GRBL_GAME_INDICATOR_KEY
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
                -k $GRBL_GAME_INDICATOR_KEY \
                "${FUNCNAME[0]}: game status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_GAME_INDICATOR_KEY \
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
    [[ $GRBL_GAME_FOLDER/menicraft ]] && return 0 || return 1
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
    grbl stop

    case $1 in
        pre|"")
            gr.msg -v1 -c sky_blue "  A          Strafe Left"
            gr.msg -v1 -c sky_blue "  D          Strafe Right"
            gr.msg -v1 -c sky_blue "  S          Walk Backward"
            gr.msg -v1 -c sky_blue "  W          Walk Forward"
            gr.msg -v1 -c sky_blue "  Space      Jump"
            gr.msg -v1 -c sky_blue "  Left Shift Sneak"
            gr.msg -v1 -c sky_blue "  Left Ctrl  Sprint"

            for keys in a d s w 'space' 'shiftl' 'lctrl' ; do
                corsair.main set $keys blue
            done

            gr.msg -v1 -c green "  E          Open Inventory"
            gr.msg -v1 -c green "  Q          Drop item"
            gr.msg -v1 -c green "  F          Swapheld item(s) to off hand"
            gr.msg -v1 -c green "  1-9        Select tool the number you pressed"

            for keys in e q f 1 2 3 4 5 6 7 8 9 ; do
                corsair.main set $keys green
            done

            gr.msg -v1 -c orange "  L          Advancements"
            gr.msg -v1 -c orange "  F2         Takes screenshots and stores them in your .minecraft folder"
            gr.msg -v1 -c orange "  F3         Toggles the debug menu"
            gr.msg -v1 -c orange "  Scroll     Scrolls through your quick bar and the chat when opened."

            for keys in l 'f2' 'f3' 'scroll' ; do
                corsair.main set $keys orange
            done

            # unused go black
            for keys in r t y u i o p å c g h j k ö ä z x v b n m 0 'half' 'plus' 'query' 'backscape' 'tab' 'f1' 'f4' 'f5' 'f6' 'f7' 'f8' 'f9' 'f10' 'f11' 'f12' 'tilde' 'enter' 'caps' 'asterix' 'less' 'comma' 'perioid' 'minus' 'shiftr' 'func' 'alt' 'altgr' 'fn' 'set' 'rctrl'  ; do
                corsair.main set $keys black
            done
            ;;

        post)
            for keys in a d s w l c z x v b n m q f e 1 2 3 4 5 6 7 8 9 0 'shiftl' 'lctrl' 'f2' 'f3' 'space' 'scroll' 'half' 'plus' 'query' 'backscape' 'tab' r t y u i o p å 'tilde' 'enter' 'caps' f g h j k ö ä 'asterix' 'shiftl' 'less' 'comma' 'perioid' 'minus' 'shiftr' 'func' 'alt' 'altgr' 'fn' 'set' 'rctrl'  ; do
                corsair.main reset $keys
            done
            #grbl start
            ;;
    esac
}


## Minecraft Bedrock

game.bedrock_start () {
# set environment and start minecraft bedrock

    game.minecraft_set pre

    cd $GRBL_GAME_FOLDER/bedrock
    ./Minecraft_Bedrock_Launcher.AppImage

    game.minecraft_set post
}


game.bedrock_set () {
# setup minecraft bedrock
    game.minecraft_set $@
}


game.bedrock_status () {
# install minecraft bedrock
    [[ $GRBL_GAME_FOLDER/bedrock ]] && return 0 || return 1
}


game.bedrock_install () {
# install minecraft bedrock

    mkdir -p $GRBL_GAME_FOLDER/bedrock
    wget https://mcpelauncher.mrarm.io/appimage/Minecraft_Bedrock_Launcher.AppImage -O $GRBL_GAME_FOLDER/Minecraft_Bedrock_Launcher.AppImage
    chmod +x $GRBL_GAME_FOLDER/Minecraft_Bedrock_Launcher.AppImage
    cd $GRBL_GAME_FOLDER
    ./Minecraft_Bedrock_Launcher.AppImage
}


game.bedrock_remove () {
# remove minecraft bedrock

    if [[ -d $GRBL_GAME_FOLDER/bedrock ]] ; then
            rm -r $GRBL_GAME_FOLDER/bedrock
        fi

    if [[ $GRBL_FORCE ]] && [[ -d $GRBL_GAME_FOLDER/bedrock ]] ; then
        gr.ask "remove bedrock saves and configurations?" || return 0
        echo rm -r $GRBL_GAME_FOLDER/bedrock
        fi
}


game.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source $GRBL_RC
    game.main "$@"
    exit "$?"
fi



# while read -rsn1 ui; do
#     echo "ui:'$ui'"
#     case "$ui" in
#     $'\x1b')    # Handle ESC sequence.
#         # Flush read. We account for sequences for Fx keys as
#         # well. 6 should suffice far more then enough.
#         read -rsn1 -t 0.1 tmp
#         echo "tmp:'$tmp'"
#         if [[ "$tmp" == "[" ]]; then
#             read -rsn1 -t 0.1 tmp
#             case "$tmp" in
#             "A") printf "Up\n";;
#             "B") printf "Down\n";;
#             "C") printf "Right\n";;
#             "D") printf "Left\n";;
#             "E") printf "center\n";;
#             "F") printf "End\n";;

#             "H") printf "Home\n";;
#             "1") printf "Function first part\n";;
#             "2") printf "insert\n";;
#             "3") printf "delete\n";;
#             "3") printf "end\n";;
#             "5") printf "pageup\n";;
#             "6") printf "pagedown\n";;
#             esac

#         fi
#         # Flush "stdin" with 0.1  sec timeout.
#         read -rsn5 -t 0.1
#         ;;
#     # Other one byte (char) cases. Here only quit.
#     q) break;;
#     esac
# done

# flasher () { while true; do printf \\e[?5h; sleep 0.1; printf \\e[?5l; read -s -n1 -t1 && break; done; }