#!/bin/bash
# guru-client audio adapter
# casa@ujo.guru 2020 - 2022

#source $GURU_RC
source common.sh

declare -g audio_data_folder="$GURU_SYSTEM_MOUNT/audio"
declare -g audio_playlist_folder="$audio_data_folder/playlists"
declare -g audio_temp_file="/tmp/audio.playlist"
declare -g audio_blink_key="f$(gr.poll audio)"

[[ ! -d $audio_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder


audio.help () {

    gr.msg -v1 -c white "guru-cli audio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL audio play|install|remove|white|tunnel|close|ls|ls_remote|toggle|fast|help <host|ip> "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 "  play <playlist>             play list name configured in user.cfg or playlist file"
    gr.msg -v1 "  play ls|list                list of playlists set in user.cfg "
    gr.msg -v1 "  install-voip                install tools to voip over ssh"
    gr.msg -v1 "  install                     install requirements "
    gr.msg -v1 "  remove                      remove requirements "
    gr.msg -v1 "  help                        printout this help "
    gr.msg -v2
    gr.msg -v2 -c white "tunnel: "
    gr.msg -v2 "  tunnel <host>               build audio tunnel (ssh) to host audio device "
    gr.msg -v2 "  close                       close current audio tunnel "
    gr.msg -v2 "  ls                          list of local audio devices "
    gr.msg -v2 "  ls_remote                   list of local remote audio devices "
    gr.msg -v2 "  toggle <host>               check is tunnel on them stop it, else open tunnel "
    gr.msg -v2 "  fast [command] <host>       quick open tunnel, does not check stuff, just brute force"
    gr.msg -v2 "  fast help                   check fast tool help for more detailed instructions"
    gr.msg -v2
}


audio.main () {
    # main command parser
    local _command="$1"
    shift
    case "$_command" in

        status|ls|tunnel|close|install|remove|toggle|tunnel_toggle|help)
            audio.$_command $@
            return $?
            ;;
        listen)
            gr.ind playing $audio_blink_key
            audio.stream_$_command $@
            gr.end $audio_blink_key
            return $?
            ;;
        play)
            gr.ind playing $audio_blink_key
            audio.playlist_play $@
            gr.end $audio_blink_key
            return $?
            ;;
        fast) # fast tunnel move this under 'tunnel' parser
            $GURU_BIN/audio/fast_voipt.sh $1 \
            -h $GURU_ACCESS_DOMAIN \
            -p $GURU_ACCESS_PORT \
            -u $GURU_ACCESS_USERNAME
            return $?
            ;;
        *)
            gr.msg -c white "audio module: unknown command '$_command'"
            return 1
            ;;
    esac
}


audio.toggle () {

    local default_radio='yle puhe'
    [[ $GURU_RADIO_WAKEUP_STATION ]] && default_radio=$GURU_RADIO_WAKEUP_STATION

    if ps auxf | grep mpv | grep -v grep ; then
            pkill mpv && gr.end $audio_blink_key
            return 0
        fi

    if [[ -f $audio_temp_file ]] ; then
            gr.ind playing -k $audio_blink_key
            mpv --playlist=$audio_temp_file
            gr.end $audio_blink_key
        else
            audio.main listen "$default_radio"
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
                    gr.msg -c light_blue $station
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
            gr.msg -c yellow "list '$user_reguest' not found"
            return 126
        fi

    # gr.msg -v3 "found_line: $found_line"

    declare -g playlist_found_name=$(echo $found_line | cut -f4 -d '_' | cut -f1 -d '=')
    # gr.msg -v3 "playlist_found_name: $playlist_found_name"

    local variable="GURU_AUDIO_PLAYLIST_${playlist_found_name}[@]"
    local found_settings=($(eval echo ${!variable}))
    # gr.msg -v3 "found_settings: ${found_settings[@]}"

    declare -g playlist_location=${found_settings[0]}
    # gr.msg -v3 "playlist_location: $playlist_location"

    declare -g playlist_phase=${found_settings[1]}
    # gr.msg -v3 "playlist_phase: $playlist_phase"

    declare -g playlist_option=${found_settings[2]}
    # gr.msg -v3 "playlist_option: $playlist_option"

    declare -g list_description="${playlist_location##*/}"
    list_description="${list_description//_/' '}"
    list_description="${list_description//'-'/' - '}"
    # gr.msg -v3 "description: $list_description"

    if ! [[ $playlist_found_name ]] ; then
            gr.msg -c yellow "'$user_reguest' not found"
            return 127
        fi

    return 0
}


audio.playlist_list () {

    local _list=($(cat $GURU_RC | grep "GURU_AUDIO_PLAYLIST_" | grep -v "local" | cut -f4 -d '_' | cut -f1 -d '='))
    _list=(${_list[@],,})

    # if verbose is lover than 1
    gr.msg -V2 -c light_blue "${_list[@]}"

    # higher verbose
    if [[ $GURU_VERBOSE -gt 1 ]] ; then

            for _list_item in ${_list[@]} ; do
                    audio.playlist_config $_list_item
                    gr.msg -n -c light_blue "$_list_item: "
                    gr.msg "$list_description"
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
            ls $playlist_location/$playlist_phase \
                | grep -e wav -e mp3 -e m4a -e mkv -e mp4 \
                | sort $sort_option > $audio_temp_file
                #\ | head -n 5
            local test=$(cat $audio_temp_file)

            if [[ $test ]] ; then
                    gr.msg -v2 "$(cat $audio_temp_file)"
                    return 0
                else
                    gr.msg -c yellow "empty playlist, try to mount media"
                    return 123
                fi
        else
            gr.msg -c yellow "list name '$user_reguest' not found"
            return 124
        fi
}


audio.playlist_play () {

    local user_reguest=$1
    local _wanna_hear=
    [[ $2 ]] && local _wanna_hear=$2
    # gr.msg -v3 "user_reguest: $user_reguest $_wanna_hear"

    case $user_reguest in
        list|ls)
            audio.playlist_list $user_reguest
            return 0
            ;;
        "")
            gr.msg -c yellow "please input list name or playlist file "
            audio.playlist_list
            return 1
        esac

    # check is input a filename and is file ascii
    if [[ -f $user_reguest ]] && file $user_reguest | grep -q "text" ; then

            # check that first item exists
            local first_item=$(head -n 1 $user_reguest)
            if ! [[ -f $first_item ]] ; then
                    gr.msg -c yellow "playlist item '$first_item' does not exist"
                    return 125
                fi

            mpv --playlist=$user_reguest
            return $?

        else
            gr.msg -v3 "file '$user_reguest' not found or format mismatch"
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
            # gr.msg -v3 "wanted hear $_wanna_hear"
            local _list=($(cat $audio_temp_file))

            for _list_item in ${_list[@]} ; do
                # gr.msg -v3 "$_list_item:$_wanna_hear"
                grep -i $_wanna_hear <<< $_list_item && mpv $_list_item $options
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
    gr.msg -k $audio_blink_key -c aqua

    $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME || gr.msg -k $audio_blink_key -c red

    gr.msg -k $audio_blink_key -c reset
    return $?
}


audio.ls () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -v -c "audio device list (alsa card)"
    gr.msg -c light_blue "$_device_list"
}


audio.ls_remote () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -c light_blue "$_device_list"
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

    gr.msg -v1 "tunneling mic to $_user@$_host:$_port"
    gr.msg -k $audio_blink_key -c aqua
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            gr.msg -k $audio_blink_key -c green
        else
            gr.msg -k $audio_blink_key -c red
        fi

    return 0
}


audio.tunnel_toggle () {
    # audio toggle for keyboard shortcut usage
    # source $GURU_BIN/corsair.sh
    gr.msg -k $audio_blink_key -c aqua
    if audio.status ; then
            if $GURU_BIN/audio/fast_voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT ; then
                    gr.msg -k $audio_blink_key -c reset
                    return 0
                else
                    gr.msg -k $audio_blink_key -c red
                    return 1
                fi
        fi

    if $GURU_BIN/audio/fast_voipt.sh open -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            gr.msg -k $audio_blink_key -c green
            return 0
        else
            gr.msg -k $audio_blink_key -c red
            return 1
        fi
}


audio.install () {
    # install function is required by core

    case $1 in

        tunnel|voip)
            $GURU_BIN/audio/voipt.sh install
        ;;
        dev)


        ;;
        *)
            sudo apt-get install espeak mpv vlc -y
        esac
}


audio.remove () {
    # remove function is required by core

    $GURU_BIN/audio/voipt.sh remove
    gmsg "remove manually: 'sudo apt-get remove espeak mpv vlc'"

}


audio.status () {
    # status function is required by core

    if ps auxf | grep "ssh -L 10000:127.0.0.1:10001 " | grep -v grep >/dev/null ; then
            gr.msg -c green "audio tunnel is active"
            return 0
        else
            gr.msg -c dark_grey "no audio tunnels"
            return 1
        fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    audio.main "$@"
    exit $?
fi

