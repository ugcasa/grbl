#!/bin/bash
# method to commonucate with mpv player for stats
# audio.rc sould be sourced before soursing this file

mpv.list () {

    mpv --list-properties
    # echo '{ "command": ["get_property", "playlist"] }' | socat - $GURU_AUDIO_MPV_SOCKET |jq '.data'
}


mpv.get() {

    local key=$1
    local player=$2
    # pass the property as the first argument

    if [[ $player ]] ; then
        gr.debug "get $player $key $GURU_AUDIO_MPV_SOCKET-$player"
        printf '{ "command": ["get_property", "%s"] }\n' "$key" | socat - "$GURU_AUDIO_MPV_SOCKET-$player" | jq -r ".data"
        return 0
    fi

    local _return
    local socket_list=($(ls $GURU_AUDIO_MPV_SOCKET*))
    for socket in ${socket_list[@]} ; do
            gr.debug "get $player $key $socket"
            _return=$(printf '{ "command": ["get_property", "%s"] }\n' "$key" | socat - "$socket" | jq -r ".data")
            gr.msg "$socket $key: $_return"
    done
}


mpv.set () {

    local key=$1
    local value=$2
    local player=$3

    if [[ $player ]] ; then
        gr.msg -v2 "set $player $key=$value "
        gr.debug "$GURU_AUDIO_MPV_SOCKET-$player"
        echo '{ "command": ["set_property", "'$key'", '$value'] }' | socat - $GURU_AUDIO_MPV_SOCKET-$player
        return 0
    fi

    local _return
    local socket_list=($(ls $GURU_AUDIO_MPV_SOCKET*))
    for socket in ${socket_list[@]} ; do
        gr.msg -v2 "set $player $key=$value $socket"
        gr.debug "$socket"
        echo '{ "command": ["set_property", "'$key'", '$value'] }' | socat - $socket
    done

}


mpv.stat() {
# get mpv player status information

    ps aufx | grep "mpv " | grep -v grep >/dev/null || return 1
    [[ -S $GURU_AUDIO_MPV_SOCKET ]] || return 0

    position="$(mpv.get percent-pos $1 | cut -d'.' -f1)%"
    file="$(mpv.get filename $1)"
    icy_title="$(mpv.get media-title $1)"

    [[ $file == "null" ]] && file=""
    [[ $icy_title ]] && file=$icy_title

    [[ $position =~ ^[0-9]+$ ]] || [[ $file ]] && printf "%s %s" "$file" "$position"

    #playlist_pos="$(( $(mpv.get 'playlist-pos') + 1 ))"
    #playlist_count="$(mpv.get "playlist-count")"
    # printf "%s %s [%s/%s]" "$file" "$position" "$playlist_pos" "$playlist_count"
}