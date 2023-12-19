#!/bin/bash
# guru-cli radio functionalities for guru-cli audio module 2023 casa@ujo.guru

source corsair.sh

declare -g radio_number=
declare -g radio_rc="/tmp/guru-cli_radio.rc"
declare -g radio_prev_file="/tmp/guru-cli_radio.nr"

radio.help () {
    gr.msg -v1 -c white "guru-cli radio help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL radio url, station name or station_number"
    gr.msg -v1 "          $GURU_CALL radio url|listen|prev|next|list|ls|help"
    gr.msg -v2
    gr.msg -v1 "commands:" -c white
    gr.msg -v2 " player                simple radio channel selector"
    gr.msg -v1 " url <url>             listen web stream"
    gr.msg -v1 " listen <station>      listen radio station"
    gr.msg -v1 " listen <number>       listen station list number"
    gr.msg -v1 " next (or n)           tune in next radio station"
    gr.msg -v1 " prev (or p)           tune in to previous station "
    gr.msg -v1 " list                  numbered list of stations "
    gr.msg -v2 " ls                    list of stations"
    gr.msg -v2
}


radio.main() {
# simple radio player, number or station name
    gr.debug "$FUNCNAME: $@"
    local key1=$1
    local key2=$2
    local radio_nr=
    local station_list=($(radio.ls))
    #gr.debug "stations: ${station_list[0]} mpv_options: $mpv_options, audio rc: $audio_rc now_playing: $GURU_AUDIO_NOW_PLAYING"

    case $key1 in

        ls|listen|help|status)
                shift
                radio.$key1 $@
                ;;

        l|list)
                radio.list | column -s ':' 2>/dev/null
                ;;

        n|next|prev|p)
                radio.change $key1
                ;;

        [0-9]|[1-9][0-9])
                radio_nro="$key1$key2"
                radio_number=$radio_nro
                radio_name=${station_list[$radio_number]}
                echo $radio_number >$radio_prev_file
                radio.listen ${radio_name//_/ }
                return 0
                ;;

        s|select|selector)
                while true ; do
                    clear
                    radio.list | column -s ':' 2>/dev/null
                    audio.status
                    gr.msg -v1 -n -c white "(p)rev (n)ext (c)ontinue (q)uit or station: "
                    read -t 60 ans
                    case $ans in
                        q) break ;;
                       "") continue ;;
                        c) radio.main ;;
                        *) radio.main $ans ;;
                    esac
                done
                ;;

        o|open|player)
                radio_number=$(< $radio_prev_file)
                local _command='guru radio selector'
                gnome-terminal --hide-menubar --geometry 130x$((${#station_list[@]} / 4 + 8 )) --zoom 0.5 --title "radio player" -- bash -c "$_command"
                ;;

        "")
                if [[ -f $radio_prev_file ]]; then
                        radio_number=$(< $radio_prev_file)
                        radio_name=${station_list[$radio_number]}
                        #echo $radio_number >$radio_prev_file
                        radio.listen ${radio_name//_/ }

                    else
                        radio_number=0
                        radio_name=${station_list[$radio_number]}
                        echo $radio_number >$radio_prev_file
                        radio.listen ${radio_name//_/ }
                    fi
                ;;
        *)
                radio.listen $@
        esac
}


radio.change (){
# tune in to next or previous radio station

    local next=
    local value="$1"
    local current=
    [[ -f $radio_prev_file ]] && current=$(< $radio_prev_file)

    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] && return 0

    case $1 in
        next|n) next=$(( $current + 1 )) ;;
        prev|p) next=$(( $current - 1 )) ;;
        current|contnue|c) next=$current ;;
    esac

    if (( $next >= ${#station_list[@]} )) ; then
        next=0
    elif (( $next < 0 )) ; then
        next=$(( ${#station_list[@]} -1 ))
    fi
    #echo "$next" >$radio_prev_file

    corsair.type_end
    audio.stop
    local station_list=($(radio.ls))
    radio_number=$next
    echo $radio_number >$radio_prev_file
    radio_name=${station_list[$radio_number]}

    corsair.type white "$radio_number"
    radio.listen ${radio_name//_/ }
}


radio.ls (){
# gather list of radio stations, printout all stations

    local all_radio=()
    local favorite_channels=(${GURU_RADIO_FAVORITE_STATIONS[@]})
    local commercial_channels=($(cat $GURU_CFG/radio.list | cut -d ' ' -f2-))
    local yle_channels=(${GURU_RADIO_YLE_STATIONS[@]})

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


radio.list () {
# human readable list own favorite and other radio stations

    local i=0
    local current=0
    local list=($(radio.ls))
    [[ -f $radio_prev_file ]] && current=$(< $radio_prev_file)

    for (( i = 0; i < 10; i++ )); do
            gr.msg -n "$i: "
            item=${list[$i]//_/ }

             if [[ $current -eq $i ]] ; then
                    gr.msg -h -c slime "$item"
                else
                    gr.msg -c aqua_marine "$item"
                fi
        done

    for (( i = 10; i < ${#list[@]}; i++ )); do
            gr.msg -n "$i: "
            item=${list[$i]//_/ }

            if [[ $current -eq $i ]] ; then
                    gr.msg -h -c slime "$item"
                else
                    gr.msg -c turquoise "$item"
                fi
        done
}


radio.listen () {
# listen radio station by number or name, list of stations

    local station_nro=
    local station_name=
    local station_url=
    local station_str=

    [[ -f $radio_prev_file ]] && station_nro=$(< $radio_prev_file)

    source net.sh
    if ! net.check >/dev/null; then
            gr.msg "unable to play streams, network unplugged"
            return 100
        fi

    case $1 in

        ls|list)
            radio.$1
            ;;

        url)
        # play url streams
            shift
            station_url=$1
            station_name=$station_url
            ;;

        yle)
        # listen yleisradio channels
            station_str=$(echo $@ | sed -r 's/(^| )([a-z])/\U\2/g' )
            station_url="https://icecast.live.yle.fi/radio/$station_str/icecast.audio"
            station_name="${1^} ${2^} ${3^} ${4^}"
            ;;

        *)
        # listen radio stations listed in radio.list in config
            ifs=$IFS ; IFS=$'\n'
            station_str=$(cat $GURU_CFG/radio.list | grep $1 | grep "http" | head -n1 )
            station_url=$(echo $station_str | cut -d ' ' -f1 )
            station_name=$(echo $station_str | cut -d ' ' -f2- )
            IFS=$ifs
            station_name=${station_name/_/' '}
            station_name=${station_name^}
        esac

        # stop currently playing audio
        audio.stop

        # indicate and inform user
        gr.msg -v1 -h "playing $station_name"
        echo "$station_name" >$GURU_AUDIO_NOW_PLAYING
        corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
        echo $station_nro > $radio_prev_file

        # play media
        mpv $station_url $mpv_options --no-resume-playback
        #gnome-terminal --hide-menubar --geometry 30x5 --zoom 0.7 --title "guru radio $radio_nro ${station_name^}" -- bash -c "mpv $station_url $mpv_options --no-resume-playback"

        # remove now playing and indications
        echo $station_url > $GURU_AUDIO_LAST_PLAYED
        rm $GURU_AUDIO_NOW_PLAYING
        gr.end $GURU_AUDIO_INDICATOR_KEY

    return 0
}

radio.status() {
    audio.status
}


radio.rc () {
# check is config changed and source configurations

    if [[ ! -f $radio_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $radio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/radio.cfg) - $(stat -c %Y $radio_rc) )) -gt 0 ]]
        then
            radio.make_rc && \
                gr.msg -v1 -c dark_gray "$radio_rc updated"
        fi

    source $radio_rc
}


radio.make_rc () {
# configure audio module

    source config.sh

    # make rc out of config file and run it

    if [[ -f $radio_rc ]] ; then
            rm -f $radio_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/audio.cfg" $radio_rc
    config.make_rc "$GURU_CFG/$GURU_USER/radio.cfg" $radio_rc append
    chmod +x $radio_rc
    source $radio_rc
}

# located here cause rc needs to see some of functions above
radio.rc

# variables that needs values that radio.rc provides
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_MPV_SOCKET"
[[ $GURU_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $GURU_BIN/audio/audio.sh
    # if sourced it probably done by audio.sh, otherwise source here
    radio.main $@     # TBD radio.main $(radio.parse_options $@)
    exit $?
fi

