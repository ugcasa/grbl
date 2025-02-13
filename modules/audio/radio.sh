#!/bin/bash
# guru-cli radio functionalities for guru-cli audio module casa@ujo.guru

__radio_color="orange"
__radio=$(readlink --canonicalize --no-newline $BASH_SOURCE)

source corsair.sh
source flag.sh

declare -g radio_rc="/tmp/$USER/guru-cli_radio.rc"
declare -g radio_number_file="/tmp/$USER/guru-cli_radio.nr"
declare -g station_nro
declare -g station_name
declare -g station_url

radio.help () {
# radio help
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

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
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    gr.debug "$FUNCNAME got:$@"

    local command=$1
    shift


    case $command in

        play|listen)
                radio.parse $@ || return $?
                radio.play
                ;;

        ls|help|status)
                radio.$command $@
                ;;
        list)
                radio.list | column -s ':' 2>/dev/null
                ;;

        next|prev)
                radio.$command
                ;;

        [0-9]|[1-9][0-9])
                radio.parse $command || return $?
                radio.play
                return 0
                ;;

        player)
                radio.selector $@
                ;;

        *)
                radio.parse $command $@ || return $?
                radio.play
        esac
}

radio.next () {
# jump to next radio station
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    flag.set skip

    station_nro=$(< $radio_number_file)

    if [[ $station_nro -ge $amount_of_stations ]] ; then
        station_nro=0
    else
        station_nro=$(( $station_nro +1 ))
    fi

    echo $station_nro >$radio_number_file
    audio.stop
}

radio.prev () {
# jump to previous radio station
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    flag.set skip

    station_nro=$(< $radio_number_file)

    if [[ $station_nro -le 0 ]] ; then
        station_nro=$amount_of_stations
    else
        station_nro=$(( $station_nro -1 ))
    fi

    echo $station_nro >$radio_number_file
    audio.stop
}

radio.selector () {
# radio selector
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    audio.stop
    guru flag rm audio_stop

    local firstime=true
    if [[ $1 ]] ; then
        station_nro=$1
    else
        station_nro=$(< $radio_number_file)
    fi
    radio.parse $station_nro
    while true ; do
        clear

        guru flag get audio_stop && return 0

        radio.list $station_nro | column -s ':' 2>/dev/null
        gr.msg -v1 -n -c white "(p)rev (n)ext (c)ontinue (q)uit or station: "

        [[ $firstime ]] || read station_nro

        clear
        case $station_nro in q*) return 0 ;; esac
        radio.parse $station_nro
        radio.list $station_nro | column -s ':' 2>/dev/null
        radio.play $station_nro
        firstime=
    done
}

radio.change () {
# tune in to next or previous radio station
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    local next=
    local value="$1"
    local current=
    [[ -f $radio_number_file ]] && current=$(< $radio_number_file)

    [[ -f $GURU_AUDIO_PAUSE_FLAG ]] && return 0

    case $1 in
        next|n) next=$(( $current + 1 )) ;;
        prev|p) next=$(( $current - 1 )) ;;
        current|continue|c) next=$current ;;
    esac

    if (( $next >= ${#station_list[@]} )) ; then
        next=0
    elif (( $next < 0 )) ; then
        next=$(( ${#station_list[@]} -1 ))
    fi
    #echo "$next" >$radio_number_file

    corsair.type_end
    audio.stop
    local station_list=($(radio.ls))
    station_nro=$next
    echo $station_nro >$radio_number_file
    radio_name=${station_list[$station_nro]}

    corsair.type white "$station_nro"
    radio.play ${radio_name//_/ }
}

radio.ls () {
# gather list of radio stations, printout all stations
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    local all_channels=()
    local favorite_channels=(${GURU_RADIO_FAVORITE_STATIONS[@]})
    local commercial_stations=($(cat $GURU_CFG/radio.list | cut -d ' ' -f2-))
    local yle_channels=(${GURU_RADIO_YLE_STATIONS[@]})

    # add favorite channels (0-9)
    for (( i = 0; i <= 9; i++ )); do

        if [[ ${favorite_channels[$i]} == "" ]] ; then
                all_channels+=( "--" )
            else
                all_channels+=( "${favorite_channels[$i]}" )
            fi
    done

    # add commercial channels
    for station in ${commercial_stations[@]} ; do
            all_channels+=( "${station}" )
        done

    # add yle channels
    for station in ${yle_channels[@]} ; do
            all_channels+=( "${station}" )
        done

    echo ${all_channels[@]}
    return 0
}

radio.list () {
# human readable list own favorite and other radio stations
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    local list=($(radio.ls))

    if [[ $1 ]] ; then
        station_nro=$1
    else
        station_nro=$(< $radio_number_file)
    fi


    for (( i = 0; i < 10; i++ )); do
            gr.msg -n "$i: "
            item=${list[$i]//_/ }

             if [[ $station_nro -eq $i ]] ; then
                    gr.msg -h -c slime "$item"
                else
                    gr.msg -c aqua_marine "$item"
                fi
        done

    for (( i = 10; i < ${#list[@]}; i++ )); do
            gr.msg -n "$i: "
            item=${list[$i]//_/ }

            if [[ $station_nro -eq $i ]] ; then
                    gr.msg -h -c slime "$item"
                else
                    gr.msg -c turquoise "$item"
                fi
        done
}

radio.parse () {
# check input to ques what user needs
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    local station_str=
    local got=$1
    shift

    case $got in

        # by favorite list
        [0-9])
            gr.debug "1-9: $got"
            station_str="${GURU_RADIO_FAVORITE_STATIONS[$got]}"
            station_nro=$got
            ;;
        # by radio list file
        [1-9][0-9])
            gr.debug "10-99: $got"
            station_nro=$got

            if [[ $station_nro -gt $amount_of_stations ]] ; then
                gr.msg -e1 "station number '$station_nro' is damn too high"
                return 101
            fi

            local first_yle_station=$(( ${#GURU_RADIO_FAVORITE_STATIONS[@]} + ${#commercial_stations[@]}))

            if [[ $station_nro -ge $first_yle_station ]]; then
                yle_location=$(( $station_nro - $first_yle_station ))
                station_str=${GURU_RADIO_YLE_STATIONS[$yle_location]}
                gr.debug "station_str:$station_str, first_yle_station:$first_yle_station, yle_stations[yle_location]:${yle_stations[$yle_location]}"
            else
                station_str=$(sed -n "$(( $station_nro - 9 ))p" < "$GURU_CFG/radio.list")
                station_url=$(cut -d"_" -f1 <<<$station_str)
                station_name=$(cut -d"_" -f2- <<<$station_str)
            fi
            ;;

        # url given
        http*)
            gr.debug "http: $got"
            station_url=$got
            station_nro=0
            #radio.play $station_url
            ;;
        yle)
            gr.debug "yle: $got, $1"
            station_str="yle_$1"
            if ! [[ ${GURU_RADIO_YLE_STATIONS[@]} =~ $station_str ]] ; then
                gr.msg -e1 "station '$station_str' is not yle radio station "
                return 100
            fi

            ;;
        "")
            if [[ -f ${radio_number_file} ]] ; then
                station_nro=$(cat $radio_number_file)
            else
                station_nro=0
            fi
            station_list=($(radio.ls))
            station_str=${station_list[$station_nro]}
            ;;

        *)
            gr.debug "radio.ls: $got"
            station_list=($(radio.ls))
            for (( i = 0; i < ${#station_list[@]}; i++ )); do
                if [[ ${station_list[$i]} == *$got* ]] ; then
                    station_str=${station_list[$i]}
                    station_nro=$i
                    break
                fi
            done
            ;;
    esac

    if ! [[ $station_str ]] ; then
        gr.msg -e1 "did not able to solve radio station name '$got'"
        return 100
    fi

    if [[ $station_str == yle* ]] ; then
        gr.debug "yle station_str: $station_str, station_nro,$station_nro"

        if ! [[ $station_nro ]] ; then
            station_list=($(radio.ls))
           for (( i = 0; i < ${#station_list[@]}; i++ )); do
            if [[ ${station_list[$i]} == $station_str ]] ; then
                station_nro=$i
                break
            fi
            done
        fi

        station_str=${station_str//'_'/' '}
        station_name=$(sed -e "s/\b\(.\)/\u\1/g" <<<$station_str)
        station_str=$(sed -r 's/(^| )([a-z])/\U\2/g' <<<$station_str)
        station_url="https://icecast.live.yle.fi/radio/$station_str/icecast.audio"

    else
        gr.debug "radio.list"
        local station_tmp=$(grep -e "$station_str" "$GURU_CFG/radio.list" | head -n1 )
        station_url=$(cut -d' ' -f1 <<<$station_tmp)
        station_name=$(cut -d' ' -f2- <<<$station_tmp)
        station_name="${station_name//[_-]/ }"
        gr.debug "1:${station_name}"
        station_name="${station_name^^}"
        gr.debug "2:${station_name}"
        [[ $station_nro ]] || station_nro=$(( $i + 9 ))
    fi
}

radio.play () {
# listen radio station by number or name, list of stations
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    gr.debug "station_url: $station_url, station_name: $station_name, station_nro: $station_nro "

    # stop currently playing audio
    audio.stop

    corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY
    echo $station_nro > $radio_number_file

  while true ; do
    # indicate and inform user
    gr.msg -v1 -h "Radio #$station_nro $station_name"
    echo "Radio #$station_nro $station_name" >$GURU_AUDIO_NOW_PLAYING

    # play media
    mpv $station_url $mpv_options

    if flag.get audio_hold ; then
        while flag.get audio_hold >/dev/null; do
            sleep 5
        done
    elif flag.get skip ; then
        flag.rm skip
        station_nro=$(< $radio_number_file)
        radio.parse $station_nro
    else
        break
    fi

    done
    #gnome-terminal --hide-menubar --geometry 30x5 --zoom 0.7 --title "guru radio $station_nro ${station_name^}" -- bash -c "mpv $station_url $mpv_options --no-resume-playback"
    # remove now playing and indications
    [[ -f $GURU_AUDIO_NOW_PLAYING ]] && rm $GURU_AUDIO_NOW_PLAYING
    gr.end $GURU_AUDIO_INDICATOR_KEY

    return 0
}

radio.status() {
# reroute status requests to audio module
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    audio.status
}

radio.rc () {
# check is config changed and source configurations
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

    if [[ ! -f $radio_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $radio_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/radio.cfg) - $(stat -c %Y $radio_rc) )) -gt 0 ]]
        then
            radio.make_rc && \
                gr.msg -v1 -c dark_gray "$radio_rc updated"
        fi

    source $radio_rc
    [[ $audio_rc ]] || source audio.sh
}

radio.make_rc () {
# configure audio module
    gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME '$1'" >&2

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

gr.msg -v4 -c $__radio_color "$__radio [$LINENO] $FUNCNAME" >&2

# located here cause rc needs to see some of functions above
radio.rc

declare -ga commercial_stations=($(cat $GURU_CFG/radio.list | cut -d ' ' -f2-))
declare -g amount_of_stations=$(( ${#GURU_RADIO_FAVORITE_STATIONS[@]} + ${#commercial_stations[@]} + ${#GURU_RADIO_YLE_STATIONS[@]} -1 ))

gr.debug "amount_of_stations:$amount_of_stations "
gr.debug "GURU_RADIO_FAVORITE_STATIONS:${#GURU_RADIO_FAVORITE_STATIONS[@]} "
gr.debug "commercial_stations: ${#commercial_stations[@]}"
gr.debug "GURU_RADIO_YLE_STATIONS: ${#GURU_RADIO_YLE_STATIONS[@]}"

# variables that needs values that radio.rc provides
declare -g mpv_options="--input-ipc-server=$GURU_AUDIO_MPV_SOCKET-radio"
[[ $GURU_VERBOSE -lt 1 ]] && mpv_options="$mpv_options --really-quiet"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # if sourced it probably done by audio.sh, otherwise source here
    radio.main $@     # TBD radio.main $(radio.parse_options $@)
    exit $?
fi

