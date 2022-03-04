#!/bin/bash
# guru-client audio adapter
# casa@ujo.guru 2020
source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh


audio.help () {

    gmsg -v1 -c white "guru-client audio help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL audio status|close|install|remove|toggle|fast|playlist help|tunnel <host|ip> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  tunnel <host>               open tunnel to host "
    gmsg -v2 "  toggle <host>               check is tunnel on them stop it, else open tunnel "
    gmsg -v1 "  playlist <playlist>         play list name configured in user.cfg or playlist file"
    gmsg -v1 "  playlist ls|list            list of playlists set in user.cfg "
    gmsg -v1 "  close                       close tunnel "
    gmsg -v1 "  ls                          list of local audio devices "
    gmsg -v1 "  ls_remote                   list of local remote audio devices "
    gmsg -v1 "  install                     install requirements "
    gmsg -v1 "  remove                      remove requirements "
    gmsg -v2 "  fast [command] <host>       quick open tunnel, does not check stuff, just brute force"
    gmsg -v1 "  fast help                   check fast tool help for more detailed instructions"
    gmsg -v2
}


audio.main () {
    # main command parser

    local _command="$1"
    shift

    case "$_command" in

            playlist)
                audio.play_playlist $@
                return $?
                ;;

            status|ls|tunnel|close|install|remove|help)
                audio.$_command $@
                return $? ;;

            fast)
                $GURU_BIN/audio/fast_voipt.sh $1 \
                -h $GURU_ACCESS_DOMAIN \
                -p $GURU_ACCESS_PORT \
                -u $GURU_ACCESS_USERNAME
                return $? ;;

            toggle)
                audio.tunnel_toggle $@
                return $? ;;

            *)
                gmsg -c red "unknown command"
                return 1 ;;
        esac
}


audio.play_playlist () {

    local temp_file='/tmp/audio.playlist'

    # in user.cfg [audio]
    # playlist_perttu=($GURU_MOUNT_AUDIO/yle *phase*)

    local user_reguest=$1
    gmsg -v3 "user_reguest: $user_reguest "

    if ! [[ $user_reguest ]] ; then
            gmsg -c yellow "please input lists name or playlist file "
            return 126
        fi

    case $user_reguest in
        list|ls)
            # local list=($(set | grep "GURU_AUDIO_PLAYLIST_" | cut -f4 -d '_' | cut -f1 -d '='))
            local list=($(set | grep "GURU_AUDIO_PLAYLIST_" | grep -v "local" | cut -f4 -d '_' | cut -f1 -d '='))
            list=(${list[@],,})
            gmsg -n -v2 "current lists: "
            gmsg -c light_blue "${list[@]}"
            return 0
        esac

    # check is input a filename and is file ascii
    if [[ -f $user_reguest ]] && file $user_reguest | grep -q "text" ; then

            # check that first itet exists
            local first_item=$(head -n 1 $user_reguest)
            if ! [[ -f $first_item ]] ; then
                    gmsg -c yellow "playlist item '$first_item' does not exist"
                    return 125
                fi

            mpv --playlist=$user_reguest

            return 0
        else
            gmsg -v3 "file '$user_reguest' not found or format mismatch"
        fi


    # check is list named as request exist
    local found_line=$(set | grep "GURU_AUDIO_PLAYLIST_${user_reguest^^}=")

    if ! [[ $found_line ]] ; then
            gmsg -c yellow "list '$user_reguest' not found"
            return 126
        fi

    gmsg -v3 "found_line: $found_line"

    local found_name=$(echo $found_line | cut -f4 -d '_' | cut -f1 -d '=')
    gmsg -v3 "found_name: $found_name"

    local variable="GURU_AUDIO_PLAYLIST_${found_name}[@]"
    local found_settings=($(eval echo ${!variable}))
    gmsg -v3 "found_settings: ${found_settings[@]}"

    local location=${found_settings[0]}
    gmsg -v3 "location: $location"

    local phase=${found_settings[1]}
    gmsg -v3 "phase: $phase"

    local option=${found_settings[2]}
    gmsg -v3 "option: $option"


    if ! [[ $found_name ]] ; then
            gmsg -c yellow "'$user_reguest' not found"
            return 127
        fi

    if [[ "$found_name" == "${user_reguest^^}" ]] ; then
            ls $location/$phase | grep -e wav -e mp3 -e m4a | sort $option > $temp_file # | head -n 5
            gmsg -v2 "$(cat $temp_file)"

            mpv --playlist="$temp_file"

            return 0
        else
            gmsg -c yellow "list name '$user_reguest' not found"
        fi
}



audio.close () {
    # close audio tunnel

    corsair.main set F8 aqua
    $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME || corsair.main set F8 red
    corsair.main reset F8
    return $?
}


audio.ls () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gmsg -v -c "audio device list (alsa card)"
    gmsg -c light_blue "$_device_list"
}


audio.ls_remote () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gmsg -c light_blue "$_device_list"
}


audio.tunnel () {
    # open tunnel adapter for voipt. input host, port, user (all optional)

    # fill default
    local _host=$GURU_ACCESS_DOMAIN
    local _port=$GURU_ACCESS_PORT
    local _user=$GURU_ACCESS_USERNAME

    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gmsg -v1 "tunneling mic to $_user@$_host:$_port"
    corsair.main set F8 aqua
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            corsair.main set F8 green
        else
            corsair.main set F8 red
        fi

    return 0
}


audio.tunnel_toggle () {
    # audio toggle for keyboard shortcut usage

    corsair.main set F8 aqua
    if audio.status ; then
            if $GURU_BIN/audio/fast_voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT ; then
                    corsair.main reset F8
                    return 0
                else
                    corsair.main set F8 red
                    return 1
                fi
        fi

    if $GURU_BIN/audio/fast_voipt.sh open -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            corsair.main set F8 green
            return 0
        else
            corsair.main set F8 red
            return 1
        fi
}


audio.install () {
    # install function is required by core

    $GURU_BIN/audio/voipt.sh install
    # TBD add mpv vlc
}


audio.remove () {
    # remove function is required by core

    $GURU_BIN/audio/voipt.sh remove
}


audio.status () {
    # status function is required by core

    if ps auxf | grep "ssh -L 10000:127.0.0.1:10001 " | grep -v grep >/dev/null ; then
            gmsg -c green "audio tunnel is active"
            return 0
        else
            gmsg -c dark_grey "no audio tunnels"
            return 1
        fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    audio.main "$@"
    exit $?
fi

