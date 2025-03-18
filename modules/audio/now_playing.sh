#!/bin/bash

source common.sh

mpv_stat() {

    local _socket="/tmp/$USER/mpvsocket"

    mpv_communicate() {
    # pass the property as the first argument
      printf '{ "command": ["get_property", "%s"] }\n' "$1" | socat - "${_socket}" | jq -r ".data"
    }

    [[ -f "/tmp/$USER/mpvsocket" ]] || return 0

    position="$(mpv_communicate "percent-pos" | cut -d'.' -f1)%"
    file="$(mpv_communicate "filename")"
    # title="$(mpv_communicate "filename" | sed 's/-/ /g')"
    playlist_pos="$(mpv_communicate "playlist-pos")"
    playlist_count="$(mpv_communicate "playlist-count")"
    volume="$(mpv_communicate "volume")%"

printf "%s %s [%s/%s] %s" "$file" "$position" "$playlist_pos" "$playlist_count" "vol:$volume"
}

mpv_stat
