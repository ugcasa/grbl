#!/bin/bash
# guru-client audio adapter
# casa@ujo.guru 2020 - 2022

source $GURU_RC
source common.sh

declare -g audio_data_folder="$GURU_SYSTEM_MOUNT/audio"
declare -g audio_playlist_folder="$audio_data_folder/playlists"
declare -g audio_temp_file="/tmp/audio.playlist"
declare -g audio_blink_key="f$(daemon.poll_order audio)"

[[ ! -d $audio_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder


audio.help () {

    gmsg -v1 -c white "guru-cli audio help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL audio play|install|remove|white|tunnel|close|ls|ls_remote|toggle|fast|help <host|ip> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  play <playlist>             play list name configured in user.cfg or playlist file"
    gmsg -v1 "  play ls|list                list of playlists set in user.cfg "
    gmsg -v1 "  install                     install requirements "
    gmsg -v1 "  remove                      remove requirements "
    gmsg -v1 "  help                        printout this help "
    gmsg -v2
    gmsg -v2 -c white "tunnel: "
    gmsg -v2 "  tunnel <host>               build audio tunnel (ssh) to host audio device "
    gmsg -v2 "  close                       close current audio tunnel "
    gmsg -v2 "  ls                          list of local audio devices "
    gmsg -v2 "  ls_remote                   list of local remote audio devices "
    gmsg -v2 "  toggle <host>               check is tunnel on them stop it, else open tunnel "
    gmsg -v2 "  fast [command] <host>       quick open tunnel, does not check stuff, just brute force"
    gmsg -v2 "  fast help                   check fast tool help for more detailed instructions"
    gmsg -v2
}


audio.main () {
    # main command parser

    # [[ -d $audio_data_folder ]] ||

    local _command="$1"
    shift

    case "$_command" in

            listen)

                gindicate playing $audio_blink_key
                audio.stream_$_command $@
                gend_blink $audio_blink_key

                return $?
                ;;

            play)
                gindicate playing $audio_blink_key
                audio.playlist_play $@
                gend_blink $audio_blink_key
                return $?
                ;;

            status|ls|tunnel|close|install|remove|help)
                audio.$_command $@
                return $?
                ;;

            fast)
                $GURU_BIN/audio/fast_voipt.sh $1 \
                -h $GURU_ACCESS_DOMAIN \
                -p $GURU_ACCESS_PORT \
                -u $GURU_ACCESS_USERNAME
                return $?
                ;;

            toggle|tunnel_toggle)
                audio.$_command $@
                return $?
            ;;


            *)
                gmsg -c white "audio module: unknown command '$_command'"
                return 1 ;;
        esac
}


audio.toggle () {

    if ps auxf | grep mpv | grep -v grep ; then
            pkill mpv && gend_blink $audio_blink_key
            return 0
        fi

    if [[ -f $audio_temp_file ]] ; then
            gindicate playing -k $audio_blink_key
            mpv --playlist=$audio_temp_file
            gend_blink $audio_blink_key
        else
            audio.main listen "yle puhe"
        fi

    return 0
}


audio.stream_listen () {

    case $1 in
        ls|list|"")
            local possible=('yle puhe' 'yle radio1' 'yle kajaani' 'yle klassinen' 'yle x' 'yle x3 m' 'yle vega' 'yle kemi' 'yle turku' \
                            'yle pohjanmaa' 'yle kokkola' 'yle pori' 'yle kuopio' 'yle mikkeli' 'yle oulu' 'yle lahti' 'yle kotka' 'yle rovaniemi' \
                            'yle hameenlinna' 'yle tampere' 'yle vega aboland' 'yle vega osterbotten' 'yle vega ostnyland' 'yle vega vastnyland' 'yle sami')

            for station in "${possible[@]}" ; do
                    gmsg -c light_blue $station
                done
            ;;
        esac

    local channel=$@
    local options=
    [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"

    if [[ ${1,,} == "yle" ]] ; then
            channel=$(echo $channel | sed -r 's/(^| )([a-z])/\U\2/g' )
            local url="https://icecast.live.yle.fi/radio/$channel/icecast.audio"
            mpv $options $url
        fi
}


audio.playlist_config () {

    local user_reguest=$1
    local found_line=$(grep "GURU_AUDIO_PLAYLIST_${user_reguest^^}=" $GURU_RC)

    found_line="${found_line//'export '/''}"

    if ! [[ $found_line ]] ; then
            gmsg -c yellow "list '$user_reguest' not found"
            return 126
        fi

    gmsg -v3 "found_line: $found_line"

    declare -g playlist_found_name=$(echo $found_line | cut -f4 -d '_' | cut -f1 -d '=')
    gmsg -v3 "playlist_found_name: $playlist_found_name"

    local variable="GURU_AUDIO_PLAYLIST_${playlist_found_name}[@]"
    local found_settings=($(eval echo ${!variable}))
    gmsg -v3 "found_settings: ${found_settings[@]}"

    declare -g playlist_location=${found_settings[0]}
    gmsg -v3 "playlist_location: $playlist_location"

    declare -g playlist_phase=${found_settings[1]}
    gmsg -v3 "playlist_phase: $playlist_phase"

    declare -g playlist_option=${found_settings[2]}
    gmsg -v3 "playlist_option: $playlist_option"

    declare -g list_description="${playlist_location##*/}"
    list_description="${list_description//_/' '}"
    list_description="${list_description//'-'/' - '}"
    gmsg -v3 "description: $list_description"


    if ! [[ $playlist_found_name ]] ; then
            gmsg -c yellow "'$user_reguest' not found"
            return 127
        fi

    return 0
}


audio.playlist_list () {

    local _list=($(cat $GURU_RC | grep "GURU_AUDIO_PLAYLIST_" | grep -v "local" | cut -f4 -d '_' | cut -f1 -d '='))
    _list=(${_list[@],,})

    # if verbose is lover than 1
    gmsg -V2 -c light_blue "${_list[@]}"

    # higher verbose
    if [[ $GURU_VERBOSE -gt 1 ]] ; then

            for _list_item in ${_list[@]} ; do
                    audio.playlist_config $_list_item
                    gmsg -n -c light_blue "$_list_item: "
                    gmsg "$list_description"
                 done

         fi

    return 0
}


audio.playlist_compose () {
    # check is list named as request exist

    local user_reguest=$1
    audio.playlist_config $user_reguest

    local sort_option=
    [[ $playlist_option ]] && sort_option="-$playlist_option"

    if [[ "$playlist_found_name" == "${user_reguest^^}" ]] ; then
            ls $playlist_location/$playlist_phase | grep -e wav -e mp3 -e m4a -e mkv -e mp4 | sort $sort_option > $audio_temp_file # | head -n 5
            gmsg -v2 "$(cat $audio_temp_file)"
            return 0
        else
            gmsg -c yellow "list name '$user_reguest' not found"
            return 124
        fi
}


audio.playlist_play () {

    local user_reguest=$1
    local _wanna_hear=
    [[ $2 ]] && local _wanna_hear=$2
    gmsg -v3 "user_reguest: $user_reguest $_wanna_hear"

    case $user_reguest in
        list|ls)
            audio.playlist_list $user_reguest
            return 0
            ;;
        "")
            gmsg -c yellow "please input list name or playlist file "
            audio.playlist_list
            return 1
        esac

    # check is input a filename and is file ascii
    if [[ -f $user_reguest ]] && file $user_reguest | grep -q "text" ; then

            # check that first item exists
            local first_item=$(head -n 1 $user_reguest)
            if ! [[ -f $first_item ]] ; then
                    gmsg -c yellow "playlist item '$first_item' does not exist"
                    return 125
                fi

            mpv --playlist=$user_reguest
            return $?

        else
            gmsg -v3 "file '$user_reguest' not found or format mismatch"
        fi

    # be silent is asked
    local options=
    [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet $options "

    # check is there saved playlists on that name
    if [[ -f "$audio_playlist_folder/$user_reguest.list" ]] && file $user_reguest | grep -q "text" ; then
            mpv $options --playlist="$audio_playlist_folder/$user_reguest.list"
            return $?
        fi

    # if not file check is it configured in user.cfg
    audio.playlist_compose $user_reguest || return 123

    # play requests from list
    if [[ $_wanna_hear ]] ; then
            gmsg -v3 "wanted hear $_wanna_hear"
            local _list=($(cat $audio_temp_file))

            for _list_item in ${_list[@]} ; do
                gmsg -v3 "$_list_item:$_wanna_hear"
                grep  $_wanna_hear <<< $_list_item && mpv $_list_item $options
            done

            return 0
        fi

    # play whole list
    mpv --playlist="$audio_temp_file" $options

    return $?

}


audio.close () {
    # close audio tunnel

    # source $GURU_BIN/corsair.sh
    gmsg -k $audio_blink_key -c aqua

    $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME || gmsg -k $audio_blink_key -c red

    gmsg -k $audio_blink_key -c reset
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
    # source $GURU_BIN/corsair.sh
    # fill default
    local _host=$GURU_ACCESS_DOMAIN
    local _port=$GURU_ACCESS_PORT
    local _user=$GURU_ACCESS_USERNAME

    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gmsg -v1 "tunneling mic to $_user@$_host:$_port"
    gmsg -k $audio_blink_key -c aqua
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            gmsg -k $audio_blink_key -c green
        else
            gmsg -k $audio_blink_key -c red
        fi

    return 0
}


audio.tunnel_toggle () {
    # audio toggle for keyboard shortcut usage
    # source $GURU_BIN/corsair.sh
    gmsg -k $audio_blink_key -c aqua
    if audio.status ; then
            if $GURU_BIN/audio/fast_voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT ; then
                    gmsg -k $audio_blink_key -c reset
                    return 0
                else
                    gmsg -k $audio_blink_key -c red
                    return 1
                fi
        fi

    if $GURU_BIN/audio/fast_voipt.sh open -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            gmsg -k $audio_blink_key -c green
            return 0
        else
            gmsg -k $audio_blink_key -c red
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
    audio.main "$@"
    exit $?
fi

