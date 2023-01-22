#!/bin/bash
# guru-cli audio module 2020 - 2022 casa@ujo.guru

# todo:
# - [ ] move functionalities to own files and place them to ./audio folder
# - [ ] change this file to act as an adapter
# - [ ] audio tunneling, move to audio folder (most interesting)
# - [ ] fix file search and play

source corsair.sh

declare -g audio_rc="/tmp/guru-cli_audio.rc"
declare -g audio_playlist_folder="$GURU_SYSTEM_MOUNT/audio/playlists"
declare -g audio_temp_file="/tmp/guru-cli_audio.playlist"
declare -g audio_playing_pid=$(ps x | grep mpv| grep -v grep | cut -f1 -d" ")
# more global variables downstairs (after sourcing rc file)

audio.help () {

    gr.msg -v1 -c white "guru-cli audio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL audio play|ls|list|listen|radio|pause|resume|mute|stop|tunnel|toggle|install|remove|help"
    gr.msg -v2
    gr.msg -v1 "  play <song|album|artist>    play files in $GURU_MOUNT_AUDIO"
    gr.msg -v1 "  play list <playlist_name>   play a playlist set in user.cfg"
    gr.msg -v1 "  play list ls                list of available playlists "
    gr.msg -v1 "  listen yle <station>        listen yle stations"
    gr.msg -v2 "  listen ls                   list of stations"
    gr.msg -v1 "  listen <url>                listen audio stream"
    gr.msg -v2 "  radio ls                    list of finnish radio stations"
    gr.msg -v2 "  radio <station> <city>      search and listen station  "
    gr.msg -v1 "  mute                        mute (or un-mute) main audio device"
    gr.msg -v1 "  stop                        try to stop audio sources (TBD)"
    gr.msg -v1 "  pause                       pause all audio and video"
    gr.msg -v2 "  toggle                      toggle last/default audio (for keyboard launch)"
    gr.msg -v2 "  ls                          list of local audio devices "
    gr.msg -v1 "  install                     install requirements "
    gr.msg -v1 "  remove                      remove requirements "
    gr.msg -v1 "  tunnel                      secure audio tunnel tools (rise verbose for more)" -V2
    gr.msg -v1 "  help                        printout this help "
    gr.msg -v2
    gr.msg -v1  "options:"
    gr.msg -v1   " --loop                     loop forever (not fully implemented)"
    gr.msg -v2
    gr.msg -v2 "playing files and stream " -c white
    gr.msg -v2 "tunneling commands " -c white
    gr.msg -v2 "  tunnel open <host>            open audio tunnel (ssh) to host audio device "
    gr.msg -v2 "  tunnel close                  close current audio tunnel "
    gr.msg -v2 "  tunnel install                install tools to voip over ssh"
    gr.msg -v2 "  tunnel toggle <host>          build tunnel or close active tunnel "
    gr.msg -v2 "  tunnel fast [command] <host>  fast (and brutal) way to open tunnel"
    gr.msg -v2
}


# audio.parse_options () {

#     local got_args=($@)
#     for (( i = 0; i < ${#got_args[@]}; i++ )); do
#         case ${got_args[$i]} in

#             --repeat|--l|--loop)
#                 mpv_options="$mpv_options --loop"
#                 ;;
#             *)
#                 pass_forward+=("${got_args[$i]}")
#                 ;;
#             esac
#         done
#     echo ${pass_forward[@]}
# }


audio.main () {
# main command parser
    local _command=$1
    shift

    case "$_command" in

        continue)
            if [[ -f $audio_temp_file ]] ; then
                [[ $audio_playing_pid ]] && kill $audio_playing_pid
                mpv $mpv_options --playlist=$audio_temp_file --save-position-on-quit
            else
                gr.msg -c yellow "no saved position"
                return 0
            fi
            ;;

        radio|play|ls|listen|pause|mute|stop|tunnel|toggle|install|update|remove|help|poll|status)
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
   # rm $audio_rc
}


audio.play () {
# play playlist and song/album/artist name given as parameter
    local _error=

    corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

    case $1 in
            find)
                shift
                audio.find_and_play $1
                _error=$?
                ;;
            list)
                shift
                audio.playlist_play $@
                _error=$?
                ;;
            "")
                audio.listen yle kajaani
                _error=$?
                ;;
            *)
                audio.find_and_play $@
                _error=$?
                ;;
        esac

    gr.end $GURU_AUDIO_INDICATOR_KEY
    # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
    return $_error
}


audio.stop () {
# send stop or brutal kill audio source

    pkill mpv
    pkill mpv
    gr.end $GURU_AUDIO_INDICATOR_KEY
    # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
}


audio.pause () {
# pause all audio and video system wide

    [[ -d "/tmp/guru" ]] || mkdir "/tmp/guru"

    if ! [[ -f $GURU_AUDIO_PAUSE_FLAG ]] ; then
        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/amixer -q -D pulse sset Master mute; /usr/bin/killall -q -STOP 'pulseaudio'"
        touch $GURU_AUDIO_PAUSE_FLAG
        corsair.indicate pause $GURU_AUDIO_INDICATOR_KEY
    else
        # resume
        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        /bin/bash -c "/usr/bin/killall -q -CONT 'pulseaudio'; /usr/bin/amixer -q -D pulse sset Master unmute"
        rm $GURU_AUDIO_PAUSE_FLAG
        audio.status
    fi
}


audio.mute () {
# mute master audio device

    amixer -q -D pulse sset Master toggle
    return $?
}


## status checks ----------------------------------------------------------------------------------


audio.ls () {
# list audio devices TBD rename audio.device_list()

    local _device_list=$(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq)
    gr.msg -c light_blue "$_device_list"
}


audio.is_paused () {
# check is module set to pause

    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] && return 0 || return 1
}


audio.is_playing () {
# check is something playing

    audio.mpv_stat || return 1
    [[ -f $GURU_AUDIO_NOW_PLAYING ]] || return 1
    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] || return 1
    return 0
}


audio.toggle () {
# start or stop to play last listened or default audio source

    local default_radio='yle puhe'
    [[ $GURU_RADIO_WAKEUP_STATION ]] && default_radio=$GURU_RADIO_WAKEUP_STATION

    if ps auxf | grep "mpv " | grep -v grep ; then
            gr.end $GURU_AUDIO_INDICATOR_KEY
            # pkill mpv && corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            return 0
        fi

    if [[ -f $audio_temp_file ]] ; then
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            [[ $audio_playing_pid ]] && kill $audio_playing_pid
            mpv --playlist=$audio_temp_file $mpv_options --save-position-on-quit
            gr.end $GURU_AUDIO_INDICATOR_KEY
            # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        else
            audio.main listen "$default_radio"
        fi

    return 0
}


audio.mpv_stat() {
# get mpv player status information

    mpv_communicate() {
    # pass the property as the first argument
        printf '{ "command": ["get_property", "%s"] }\n' "$1" |\
            socat - "$GURU_AUDIO_SOCKET" |\
            jq -r ".data"
    }

    ps aufx | grep "mpv " | grep -v grep >/dev/null || return 1
    [[ -S $GURU_AUDIO_SOCKET ]] || return 0

    position="$(mpv_communicate "percent-pos" | cut -d'.' -f1)%"
    file="$(mpv_communicate "filename")"
    playlist_pos="$(( $(mpv_communicate 'playlist-pos') + 1 ))"
    playlist_count="$(mpv_communicate "playlist-count")"

    printf "%s %s [%s/%s]" "$file" "$position" "$playlist_pos" "$playlist_count"
}


## special playing functions ----------------------------------------------------------------------------


audio.find_and_play () {
# find from known audio locations and play
# jeesus mitä paskaa.. TBD review! a) tää ei toimi b) metodi todella anaalista c) ei saa mitään selvää!
# miten sienissä tämä on kirjoitettu?

        if [[ -f $1 ]] ; then
                        corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
                        [[ $audio_playing_pid ]] && kill $audio_playing_pid
                        mpv $1 $mpv_options --save-position-on-quit
                        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
                        return $?
                    fi

        # if part of name, look from folders
        if [[ $1 ]] ; then
            local to_find=$1
            to_find=${to_find//'ä'/'a'}
            to_find=${to_find//'å'/'a'}
            to_find=${to_find//'ö'/'o'}

            source mount.sh
            mount.main audio music
            mount.main music
            ifs=$IFS
            IFS=" "
            # luoja mitä paskaa.. TBD review!
            _got="$(find $GURU_MOUNT_MUSIC -maxdepth 5 -iname *mp3)"
            _got="$_got $(find $GURU_MOUNT_AUDIO -maxdepth 5 -iname *mp3)"
            while [[ $1 ]] ; do
                got=$(echo -e $_got | grep -i $to_find | grep -v 'Trash-1000')
                shift
            done
            #gr.msg -c light_blue "${got[@]}"

            IFS=$ifs

            # printout artist and song name
            songs=${got//"$GURU_MOUNT_MUSIC/"/""}
            songs=${songs//'/'/'@'}                 # to remove word before '/' later
            songs=${songs//'_'/' '}
            songs=${songs//'-'/': '}
            songs=${songs//'.mp3'/''}

            if [[ $got ]] ; then
                gr.msg -v1 -c light_blue "${songs}" | sed 's/.*@//'
                corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

                # TBD why here?? remove from here and add move to audio.parse_options
                case $GURU_MODULE_ARGUMENTS in

                    --repeat|--loop)
                        local key
                        gr.msg -h "loop forever, hit double 'q' to end"
                        corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
                        while true ; do
                                [[ $audio_playing_pid ]] && kill $audio_playing_pid
                                gr.msg -h "$got"
                                mpv $(echo -e $got) $mpv_options --no-resume-playback --no-video #>/dev/null
                                read -t 1 -n 1 -p "hit 'q' to end loop: " key
                                case $key in q) echo ; break ; esac
                            done
                        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
                        ;;
                    *)
                        [[ $audio_playing_pid ]] && kill $audio_playing_pid

                        corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
                        gr.msg -h "$got"
                        mpv $(echo -e $got) $mpv_options --no-resume-playback --no-video #>/dev/null
                        gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
                        ;;
                    esac

                gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
                return $?
            fi
        fi

        gr.msg -c yellow "nothing found"
        return 1
}


audio.radio_list (){

    local all_radio=()
    local commercial_channels=($(cat $GURU_CFG/radio.list | cut -d ' ' -f2-))

    local yle_channels=(yle_puhe yle_radio1 yle_kajaani yle_klassinen yle_x yle_x3_m yle_vega yle_kemi yle_turku \
                    yle_pohjanmaa yle_kokkola yle_pori yle_kuopio yle_mikkeli yle_oulu yle_lahti yle_kotka yle_rovaniemi \
                    yle_hameenlinna yle_tampere yle_vega_aboland yle_vega_osterbotten yle_vega_ostnyland yle_vega_vastnyland yle_sami)

    local favorite_channels=(${GURU_RADIO_FAVORITE_STATIONS[@]})
    local station

    # add favorite channels (0-9)
    for (( i = 0; i <= 9; i++ )); do

        if [[ ${favorite_channels[$i]} == "" ]] ; then
                all_radio+=( "--" )
            else
                all_radio+=( "${favorite_channels[$i]}" )
            fi
    done

    # add commercial channels
    for station in ${commercial_channels[@]} ; do
            all_radio+=( "${station}" )
        done

    # add yle channels
    for station in ${yle_channels[@]} ; do
            all_radio+=( "${station}" )
        done

    echo ${all_radio[@]}
    return 0
}


audio.radio_next (){

    local next=
    local value="$1"
    local current=
    [[ -f /tmp/guru_cli-radio.nr ]] && current=$(cat /tmp/guru_cli-radio.nr)

    case $1 in
        next|n) next=$(( $current + 1 )) ;;
        prev|p) next=$(( $current - 1 )) ;;
    esac
    echo "$next" >/tmp/guru_cli-radio.nr

    audio.stop
    local station_list=($(audio.radio_list))
    echo $next >/tmp/guru_cli-radio.nr
    radio_name=${station_list[$next]}
    audio.listen ${radio_name//_/ }
}


audio.radio() {
# simple radio player, number or
    local key1=$1
    local key2=$2
    local station_list=($(audio.radio_list))
    #gr.msg -v4 "${station_list[0]} $GURU_RADIO_WAKEUP_STATION"

    case $key1 in
        l|list)
                local _command='guru audio listen list ; read -n 1'
                gnome-terminal --hide-menubar --geometry 30x$((${#station_list[@]} + 2)) --zoom 0.7 --title "radio list" -- bash -c "$_command"
                ;;

        n|next|prev|p)
                audio.radio_next $key1
                ;;

        [0-9]|[1-9][0-9])
                audio.stop
                radio_number="$key1$key2"
                radio_name=${station_list[$radio_number]}
                audio.listen ${radio_name//_/ }
                echo "$radio_number" >"/tmp/guru_cli-radio.nr"
                return 0
                ;;
        *)
                audio.stop
                audio.listen $@
                [[ -f /tmp/guru_cli-radio.nr ]] && rm /tmp/guru_cli-radio.nr

        esac
}


audio.listen () {
# listen radio stations

    source net.sh
    local current=
    [[ -f "/tmp/guru_cli-radio.nr" ]] && current=$(cat "/tmp/guru_cli-radio.nr")

    if ! net.check >/dev/null; then
            gr.msg "unable to play streams, network unplugged"
            return 100
        fi

    case $1 in

        ls) # for other functions TBD trying to get list return work.. pain in the ass.
            audio.radio_list
            ;;

        list|"")
            # human readable list
            local list=($(audio.radio_list))
            local i=0

            for (( i = 0; i < 10; i++ )); do
                    gr.msg -n "$i "
                    item=${list[$i]//_/ }

                     if [[ $current -eq $i ]] ; then
                            gr.msg -h -c slime "$item"
                        else
                            gr.msg -c aqua_marine "$item"
                        fi

                done

            for (( i = 10; i < ${#list[@]}; i++ )); do
                    gr.msg -n "$i "
                    item=${list[$i]//_/ }

                    if [[ $current -eq $i ]] ; then
                            gr.msg -h -c slime "$item"
                        else
                            gr.msg -c turquoise "$item"
                        fi
                done
            ;;

        url)
            shift
            gr.msg -v1 -h "playing from $1"
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            [[ $audio_playing_pid ]] && kill $audio_playing_pid 2>/dev/null
            echo "stream $1" >$GURU_AUDIO_NOW_PLAYING

            mpv $1 $mpv_options --no-resume-playback >/dev/null

            rm $GURU_AUDIO_NOW_PLAYING
            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            ;;

        yle)
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            local channel=$(echo $@ | sed -r 's/(^| )([a-z])/\U\2/g' )
            local url="https://icecast.live.yle.fi/radio/$channel/icecast.audio"
            [[ $audio_playing_pid ]] && kill $audio_playing_pid 2>/dev/null

            echo "radio #$current ${1^} ${2^}" >$GURU_AUDIO_NOW_PLAYING
            gr.msg -v1 -h "radio ${1^} ${2^}"

            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

            # play media
            mpv $url $mpv_options --no-resume-playback >/dev/null

            # remove indications and
            rm $GURU_AUDIO_NOW_PLAYING
            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            ;;
        *)
            # listen radio stations listed in radio.list in config
            ifs=$IFS ; IFS=$'\n'
            local _2="http"
            # stations=$(tr A-Z a-z < $GURU_CFG/radio.list)
            station=$(cat $GURU_CFG/radio.list | grep "$1" | grep $_2 | head -n1 )
            url=$(echo $station | cut -d ' ' -f1 )
            # name=$(echo $station |cut -d ' ' -f2- )
            name="$@"

            IFS=$ifs

            # play
            gr.msg -v1 -h "radio #$current ${name^}"
            [[ $audio_playing_pid ]] && kill $audio_playing_pid 2>/dev/null
            echo "radio #$current ${name^}" >$GURU_AUDIO_NOW_PLAYING
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

            mpv $url $mpv_options --no-resume-playback >/dev/null

            rm $GURU_AUDIO_NOW_PLAYING
            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
        esac
    return 0
}


audio.playlist_play () {
# play playlist file

    local audio_last_played_pointer="/tmp/guru-cli_audio.last"
    local user_reguest=$1
    local _wanna_hear=
    [[ $2 ]] && _wanna_hear=$2

    case $user_reguest in
        list|ls)
            shift
            audio.playlist_list $@
            return 0
            ;;
        "")
            audio.playlist_list
            return 0
        esac

    # check is input a filename and is file ascii
    if [[ -f $user_reguest ]] && file $user_reguest | grep -q "text" ; then

            # check that first item exists
            local first_item=$(head -n 1 $user_reguest)
            if ! [[ -f $first_item ]] ; then
                    gr.msg -c yellow "playlist item '$first_item' does not exist"
                    return 125
                fi

            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            [[ $audio_playing_pid ]] && kill $audio_playing_pid
            mpv --playlist=$user_reguest  $mpv_options --save-position-on-quit
            gr.end $GURU_AUDIO_INDICATOR_KEY # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            return 0

        else
            gr.msg -v3 "file '$user_reguest' not found or format mismatch"
        fi

    # check is there saved playlists on that name
    if [[ -f "$audio_playlist_folder/$user_reguest.list" ]] && file $user_reguest | grep -q "text" ; then
            [[ $audio_playing_pid ]] && kill $audio_playing_pid
            mpv --playlist="$audio_playlist_folder/$user_reguest.list" $mpv_options --save-position-on-quit
            return 0
        fi

    # if not file check is it configured in user.cfg
    audio.playlist_compose $user_reguest || return 123

    # play requests from list
    if [[ $_wanna_hear ]] ; then
            # gr.msg -v3 "wanted hear $_wanna_hear"
            local _list=($(cat $audio_temp_file))

            for _list_item in ${_list[@]} ; do
                # gr.msg -v3 "$_list_item:$_wanna_hear"
                grep -i $_wanna_hear <<< $_list_item && mpv $_list_item $mpv_options
            done

            return 0
        fi

    # play whole list
    [[ $audio_playing_pid ]] && kill $audio_playing_pid
    mpv --playlist="$audio_temp_file" $mpv_options --no-resume-playback --save-position-on-quit
    return 0
}



### playlist stuff TBD >audio/playlist.sh ------------------------------------------------------------------------


audio.playlist_config () {
# configure playlist

    local user_reguest=$1
    local found_line=$(grep "GURU_AUDIO_PLAYLIST_${user_reguest^^}=" $audio_rc)

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
                    gr.msg -c yellow "got empty playlist"
                    gr.msg "try to 'gr mount audio', 'audiobooks' or 'video'"
                    return 123
                fi
        else
            gr.msg -c yellow "list name '$user_reguest' not found"
            return 124
        fi
}


audio.playlist_list () {
# list of playlists

    local _list=($(cat $audio_rc | grep "GURU_AUDIO_PLAYLIST_" | grep -v "local" | cut -f4 -d '_' | cut -f1 -d '='))
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


## tunnel shit TBD > audio/tunnel.sh -------------------------------------------------------------------------

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
# open audio ssh tunnel

    # fill defaults to point to home server
    local _host=$GURU_ACCESS_DOMAIN
    local _port=$GURU_ACCESS_PORT
    local _user=$GURU_ACCESS_USERNAME

    # fill user input
    if [[ $1 ]] ; then _host=$1 ; shift ; fi
    if [[ $1 ]] ; then _port=$1 ; shift ; fi
    if [[ $1 ]] ; then _user=$1 ; shift ; fi

    gr.msg -v1 "tunneling mic to $_user@$_host:$_port"
    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c aqua
    if $GURU_BIN/audio/voipt.sh open -h $_host -p $_port -u $_user ; then
            gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c green
        else
            gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c red
            return 233
        fi
}


audio.tunnel_close () {
# close audio tunnel

    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c aqua

    if ! $GURU_BIN/audio/voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            gr.msg -c yellow "voip tunnel exited with code $?"
            gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c red
        fi

    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c reset
    return $?
}


audio.tunnel_toggle () {
# audio toggle for keyboard shortcut usage

    # source $GURU_BIN/corsair.sh
    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c aqua
    if audio.status ; then

            if $GURU_BIN/audio/fast_voipt.sh close -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT ; then
                    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c reset
                    return 0
                else
                    gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c red
                    return 1
            fi
    fi

    if $GURU_BIN/audio/fast_voipt.sh open -h $GURU_ACCESS_DOMAIN -p $GURU_ACCESS_PORT -u $GURU_ACCESS_USERNAME ; then
            gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c green
            return 0
        else
            gr.msg -k $GURU_AUDIO_INDICATOR_KEY -c red
            return 1
        fi
}


## install and remove stuff -----------------------------------------------------------------


audio.update() {
# update needed tools

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


## module shit --------------------------------------------------------------------

audio.status () {
# printout module status

    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    # for playing files
    local now_playing=$(audio.mpv_stat)

    # for playing radios
    if [[ -f $GURU_AUDIO_NOW_PLAYING ]] ; then
            local station=$(cat $GURU_AUDIO_NOW_PLAYING)
            now_playing="$station $now_playing"
        fi

    if [[ $GURU_AUDIO_ENABLED ]] ; then
            gr.msg -n -v1 -c green "enabled "

        else
            gr.end $GURU_AUDIO_INDICATOR_KEY
            # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            gr.msg -c black "disabled" -k $GURU_AUDIO_INDICATOR_KEY
            return 0
        fi

    if [[ $now_playing ]] ; then
            corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
            gr.msg -v1 -n -c aqua "playing: $now_playing"
            audio.is_paused && gr.msg -v1 -h "[paused]" \
                            || gr.msg -v1
        else
            gr.end $GURU_AUDIO_INDICATOR_KEY
            # corsair.blink_stop $GURU_AUDIO_INDICATOR_KEY
            gr.msg -v1 -c dark_grey "stopped"

        fi
}


audio.poll () {
# daemon poll can access functions start, stop and status trough this

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: polling started" -k $GURU_AUDIO_INDICATOR_KEY
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: polling ended" -k $GURU_AUDIO_INDICATOR_KEY
            ;;
        status )
           audio.status $@
            ;;
        *) audio.help
            ;;
        esac

}


audio.rc () {
# source configurations (to be faster)

    if [[ ! -f $audio_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mount.cfg) - $(stat -c %Y $audio_rc) )) -gt 0 ]]
        then
            audio.make_rc && \
                gr.msg -v1 -c dark_gray "$audio_rc updated"
        fi

    [[ ! -d $audio_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $audio_playlist_folder
    source $audio_rc
}

audio.make_rc () {
# configure audio module

    source config.sh

    # make rc out of foncig file and run it

    if [[ -f $audio_rc ]] ; then
            rm -f $audio_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $audio_rc
    config.make_rc "$GURU_CFG/$GURU_USER/audio.cfg" $audio_rc append
    chmod +x $audio_rc
    source $audio_rc
}

# located here cause rc needs to see some of functions above
audio.rc

# variables that needs values that audio.rc provides
declare -g audio_data_folder="$GURU_SYSTEM_MOUNT/audio"
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_SOCKET"
[[ $GURU_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_RC
    source common.sh
    audio.main $@ # $(audio.parse_options $@)
    exit $?
fi

