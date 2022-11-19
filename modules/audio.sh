#!/bin/bash
# guru-client audio adapter casa@ujo.guru 2020 - 2022

source common.sh
source net.sh

declare -g audio_data_folder="$GURU_SYSTEM_MOUNT/audio"
declare -g audio_playlist_folder="$audio_data_folder/playlists"
declare -g audio_temp_file="/tmp/guru/audio.playlist"
declare -g audio_blink_key="f$(gr.poll audio)"

[[ ! -d $audio_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder


audio.help () {

    gr.msg -v1 -c white "guru-cli audio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL audio play|ls|list|listen|radio|pause|resume|mute|stop|tunnel|toggle|install|remove|help"
    gr.msg -v2
    gr.msg -v2 "playing files and stream " -c white
    gr.msg -v1 "  play <song|album|artist>    play files in $GURU_MOUNT_AUDIO"
    gr.msg -v1 "  play list <playlist_name>   play a playlist set in user.cfg"
    gr.msg -v1 "  play list ls                list of available playlists "
    gr.msg -v1 "  listen yle <station>        listen yle stations"
    gr.msg -v2 "  listen ls                   list of stations"
    gr.msg -v1 "  listen <url>                listen audio stream"
    gr.msg -v2 "  radio ls                    list of finnish radio stations"
    gr.msg -v2 "  radio <station> <city>      seartch and listen station  "
    gr.msg -v1 "  mute                        mute (or unmute) main audio device"
    gr.msg -v1 "  stop                        try to stop audio sources (TBD)"
    gr.msg -v1 "  pause                       pause all audio and video"
    gr.msg -v2 "  toggle                      toggle last/default audio (for keyboard launch)"
    gr.msg -v2 "  ls                          list of local audio devices "
    gr.msg -v1 "  install                     install requirements "
    gr.msg -v1 "  remove                      remove requirements "
    gr.msg -v1 "  tunnel                      secure audio tunnel tools (rise verbose for more)" -V2
    gr.msg -v1 "  help                        printout this help "
    gr.msg -v2
    gr.msg -v2 "tunneling commands " -c white
    gr.msg -v2 "  tunnel open <host>            open audio tunnel (ssh) to host audio device "
    gr.msg -v2 "  tunnel close                  close current audio tunnel "
    gr.msg -v2 "  tunnel install                install tools to voip over ssh"
    gr.msg -v2 "  tunnel toggle <host>          build tunnel or close active tunnel "
    gr.msg -v2 "  tunnel fast [command] <host>  fast (and brutal) way to open tunnel"
    gr.msg -v2
}


audio.main () {
    # main command parser
    local _command=$1
    shift
    case "$_command" in

        play|ls|listen|pause|mute|stop|tunnel|toggle|install|update|remove|help)
            audio.$_command $@
            return $?
            ;;
        list)
            shift
            audio.playlist_play $@
            return $?
            ;;
        *)
            gr.msg -c white "audio module: unknown command '$_command'"
            return 1
            ;;
    esac
}


audio.play () {
# play playlist and song/album/artis name given as parameter

    case $1 in
            list)
                shift
                audio.playlist_play $@
                ;;

            "")
                gr.ind playing $audio_blink_key

                audio.listen yle kajaani

                gr.end $audio_blink_key
                ;;

            *)
                # if file, play it
                if [[ -f $1 ]] ; then
                        gr.ind playing $audio_blink_key

                        mpv $1

                        gr.end $audio_blink_key
                        return $?
                    fi

                # if part of name, look from folders
                if [[ $1 ]] ; then
                    ifs=$IFS
                    IFS=" "
                    got=$(find $GURU_MOUNT_MUSIC -maxdepth 3 -iname *mp3)

                    while [[ $1 ]] ; do
                        got=$(echo -e $got | grep -i $1 | grep -v 'Trash-1000')
                        shift
                    done
                    IFS=$ifs

                    # printout artist and song name
                    songs=${got//"$GURU_MOUNT_MUSIC/"/""}
                    songs=${songs//'/'/'@'}                 # to remove word before '/' later
                    songs=${songs//'_'/' '}
                    songs=${songs//'-'/': '}
                    songs=${songs//'.mp3'/''}

                    if [[ $got ]] ; then
                        gr.msg -v1 -c white "${songs}" | sed 's/.*@//'
                        gr.ind playing $audio_blink_key

                        mpv --no-video $(echo -e $got) 2>/dev/null

                        gr.end $audio_blink_key
                        return $?
                    fi
                fi

                gr.msg "nothing to play"
                ;;
        esac
}


audio.toggle () {
# start or stop to play last listened or default audio source
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


# audio.radio () {
# # listen radio stations listed in radio.list in config
#     ifs=$IFS ; IFS=$'\n'
#     local _2="http"
#     #stations=$(tr A-Z a-z < $GURU_CFG/radio.list)
#     station=$(cat $GURU_CFG/radio.list | grep $1 | grep $_2 | head -n1 )
#     url=$(echo $station |cut -d ' ' -f1 )
#     name=$(echo $station |cut -d ' ' -f2- )
#     [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"
#     IFS=$ifs
#     gr.msg -v4 -c pink "got:$station > url:$url name:'$name'"

#     gr.msg -c white "📻 ${name^h} 🔊"

#     gr.msg -v4 -c pink "mpv $options $url"
#     mpv $options $url
# }


audio.listen () {
# listen yle radio stations from icecast stream
    local options=
    [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"

    if ! net.check ; then
            gr.msg "unable to play streams, network unplugged"
            return 100
        fi

    case $1 in

        ls|list|"")
            local possible=('yle puhe' 'yle radio1' 'yle kajaani' 'yle klassinen' 'yle x' 'yle x3 m' 'yle vega' 'yle kemi' 'yle turku' \
                            'yle pohjanmaa' 'yle kokkola' 'yle pori' 'yle kuopio' 'yle mikkeli' 'yle oulu' 'yle lahti' 'yle kotka' 'yle rovaniemi' \
                            'yle hameenlinna' 'yle tampere' 'yle vega aboland' 'yle vega osterbotten' 'yle vega ostnyland' 'yle vega vastnyland' 'yle sami')

            for station in "${possible[@]}" ; do
                    gr.msg -n -c light_blue "$station, "
                done

            local _list=$(cat $GURU_CFG/radio.list | cut -d ' ' -f2- | tr '\n' ',' | sed -e 's/,/, /g')
            gr.msg -c light_blue "$_list"

            return 0
            ;;

        url)
            shift
            gr.msg -v1 "playing from $@"
            gr.ind playing -k $audio_blink_key
            mpv $options $@
            gr.end $audio_blink_key
            return 0
            ;;

        yle)
            gr.ind playing -k $audio_blink_key
            local channel=$(echo $@ | sed -r 's/(^| )([a-z])/\U\2/g' )
            local url="https://icecast.live.yle.fi/radio/$channel/icecast.audio"
            mpv $options $url
            return $?
            ;;
        *)
            # listen radio stations listed in radio.list in config
            ifs=$IFS ; IFS=$'\n'
            local _2="http"
            # stations=$(tr A-Z a-z < $GURU_CFG/radio.list)
            station=$(cat $GURU_CFG/radio.list | grep $1 | grep $_2 | head -n1 )
            url=$(echo $station |cut -d ' ' -f1 )
            name=$(echo $station |cut -d ' ' -f2- )
            [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"
            IFS=$ifs
            # debug
            gr.msg -v4 -c pink "got:$station > url:$url name:'$name'"
            gr.msg -v4 -c pink "mpv $options $url"
            # play
            gr.msg -v2 -c white "📻 ${name^h} 🔊"
            mpv $options $url

        esac
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
    gr.msg -v3 "playlist_found_name: $playlist_found_name"

    local variable="GURU_AUDIO_PLAYLIST_${playlist_found_name}[@]"
    local found_settings=($(eval echo ${!variable}))
    gr.msg -v3 "found_settings: ${found_settings[@]}"

    declare -g playlist_location=${found_settings[0]}
    gr.msg -v3 "playlist_location: $playlist_location"

    declare -g playlist_phase=${found_settings[1]}
    gr.msg -v3 "playlist_phase: $playlist_phase"

    declare -g playlist_option=${found_settings[2]}
    gr.msg -v3 "playlist_option: $playlist_option"

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
                | grep -e wav -e mp3 -e m4a -e mkv -e mp4 -e avi \
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
# play playlist file or by nicknam set in user.cfg
    local user_reguest=$1
    local _wanna_hear=
    [[ $2 ]] && _wanna_hear=$2
    # gr.msg -v3 "user_reguest: $user_reguest $_wanna_hear"

    case $user_reguest in
        list|ls)
            shift
            audio.playlist_list $@
            return $?
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

            gr.ind playing $audio_blink_key

            mpv --playlist=$user_reguest

            gr.end $audio_blink_key
            return $?

        else
            gr.msg -v3 "file '$user_reguest' not found or format mismatch"
        fi

    # be silent if asked so
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


audio.ls () {

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -c light_blue "$_device_list"
}


audio.mute() {
# mute master audio device
    amixer -q -D pulse sset Master toggle
    return $?
}


audio.stop () {
# send stop or brutal kill audio source
    gr.msg TBD
}


audio.pause () {
# pause all audio and video system wide

    local _flag="/tmp/guru/audio.pause.flag"

    [[ -d "/tmp/guru" ]] || mkdir "/tmp/guru"

    if ! [[ -f $_flag ]] ; then
        # pause
        /bin/bash -c "/usr/bin/amixer -q -D pulse sset Master mute; /usr/bin/killall -q -STOP 'pulseaudio'"
        touch $_flag
    else
        # resume
        /bin/bash -c "/usr/bin/killall -q -CONT 'pulseaudio'; /usr/bin/amixer -q -D pulse sset Master unmute"
        rm $_flag
    fi
}


audio.tunnel () {
# tunnel secure audio link to another computer
    local _cmd=$1
    shift
    case $_cmd in
            status|open|close|toggle|install)
                audio.tunnel_$_cmd $@
                ;;
            fast) # for speed testing
                $GURU_BIN/audio/fast_voipt.sh $1 \
                    -h $GURU_ACCESS_DOMAIN \
                    -p $GURU_ACCESS_PORT \
                    -u $GURU_ACCESS_USERNAME
                    return $?
                ;;
            *)
                audio.tunnel_toggle $@
                ;;
        esac
    return 0
}


audio.tunnel_status () {
    # status function is required by core

    if ps auxf | grep "ssh -L 10000:127.0.0.1:10001 " | grep -v grep >/dev/null ; then
            gr.msg -c green "audio tunnel is active"
            return 0
        else
            gr.msg -c dark_grey "no audio tunnels"
            return 1
        fi
}


audio.tunnel_open () {

    # fill defaults to point to home server
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
            return 233
        fi
}


audio.tunnel_close () {
# close audio tunnel

    gr.msg -k $audio_blink_key -c aqua

    if ! $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            gr.msg -c yellow "voip tunnel exited with code $?"
            gr.msg -k $audio_blink_key -c red
        fi

    gr.msg -k $audio_blink_key -c reset
    return $?
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


audio.update() {
    # sudo pip install -U youtube-dl
    sudo -H pip install --upgrade youtube-dl

}


audio.tunnel_install () {
    # install function is required by core
    $GURU_BIN/audio/voipt.sh install
}


audio.install () {
    # install function is required by core
    sudo apt-get install espeak mpv vlc -y
}


audio.remove () {
    # remove function is required by core
    $GURU_BIN/audio/voipt.sh remove
    gmsg "remove manually: 'sudo apt-get remove espeak mpv vlc'"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    audio.main "$@"
    exit $?
fi

