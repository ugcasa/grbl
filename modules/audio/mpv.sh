#!/bin/bash
# method to commonucate with mpv player for stats
# audio.rc sould be sourced before soursing this file

__mpv_color="dark_grey"
__mpv=$(readlink --canonicalize --no-newline $BASH_SOURCE)

mpv.list () {
# list variables of mpv
    gr.msg -v4 -c $__mpv_color "$__mpv [$LINENO] $FUNCNAME '$1'" >&2
    mpv --list-properties
    # echo '{ "command": ["get_property", "playlist"] }' | socat - $GURU_AUDIO_MPV_SOCKET |jq '.data'
}


mpv.get() {
# get information from mpv process
    gr.msg -v4 -c $__mpv_color "$__mpv [$LINENO] $FUNCNAME '$1'" >&2
    local key=$1
    local player=$2
    # pass the property as the first argument

    if [[ $player ]] ; then
        gr.varlist "debug player key GURU_AUDIO_MPV_SOCKET-$player"
        printf '{ "command": ["get_property", "%s"] }\n' "$key" | socat - "$GURU_AUDIO_MPV_SOCKET-$player" | jq -r ".data"
        return 0
    fi

    local _return
    local socket_list=($(ls $GURU_AUDIO_MPV_SOCKET*))
    for socket in ${socket_list[@]} ; do
            gr.varlist "debug get player key socket"
            _return=$(printf '{ "command": ["get_property", "%s"] }\n' "$key" | socat - "$socket" | jq -r ".data")
            gr.msg "$socket $key: $_return"
    done
}


mpv.set () {
# set variables of mpv process
    gr.msg -v4 -c $__mpv_color "$__mpv [$LINENO] $FUNCNAME '$1'" >&2
    local key=$1
    local value=$2
    local player=$3

    if [[ $player ]] ; then
        gr.msg -v2 "set $player $key=$value "
        gr.varlist "debug GURU_AUDIO_MPV_SOCKET-$player"
        echo '{ "command": ["set_property", "'$key'", '$value'] }' | socat - $GURU_AUDIO_MPV_SOCKET-$player
        return 0
    fi

    local _return
    local socket_list=($(ls $GURU_AUDIO_MPV_SOCKET*))
    for socket in ${socket_list[@]} ; do
        gr.msg -v2 "set player key value socket"
        gr.varlist "debug $socket"
        echo '{ "command": ["set_property", "'$key'", '$value'] }' | socat - $socket
    done

}


mpv.stat() {
# get mpv player status information
    gr.msg -v4 -c $__mpv_color "$__mpv [$LINENO] $FUNCNAME '$1'" >&2
    ps aufx | grep "mpv " | grep -v grep -q || return 1
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

gr.msg -v4 -c $__mpv_color "$__mpv [$LINENO] $FUNCNAME" >&2