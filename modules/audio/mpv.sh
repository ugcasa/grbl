#!/bin/bash
# method to commonucate with mpv player for stats
# audio.rc sould be sourced before soursing this file

mpv.communicate() {
# pass the property as the first argument
    printf '{ "command": ["get_property", "%s"] }\n' "$1" |\
        socat - "$GURU_AUDIO_MPV_SOCKET" |\
        jq -r ".data"
}


mpv.stat() {
# get mpv player status information

    ps aufx | grep "mpv " | grep -v grep >/dev/null || return 1
    [[ -S $GURU_AUDIO_MPV_SOCKET ]] || return 0

    position="$(mpv.communicate "percent-pos" | cut -d'.' -f1)%"
    file="$(mpv.communicate "filename")"
    printf "%s %s " "$file" "$position"

    #playlist_pos="$(( $(mpv.communicate 'playlist-pos') + 1 ))"
    #playlist_count="$(mpv.communicate "playlist-count")"
    # printf "%s %s [%s/%s]" "$file" "$position" "$playlist_pos" "$playlist_count"
}