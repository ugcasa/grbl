#!/bin/bash
# grbl aliases, run commands without need to grbl or gr

## TODO: from alias.cfg
## [alias]
# stopwatch="timer stopwatch"
# clean=( "convert webp -f"
#         "convert webm -f"
#         "place memes -f"
#         "place mime move -f")
# echo ${clean[2]}
## TODO main,add, del, status, list, help

alias active="$GRBL_CALL active"
alias backup="$GRBL_CALL backup"
alias countdown="$GRBL_CALL timer countdown"
alias mqtt="$GRBL_CALL mqtt"
alias notes="$GRBL_CALL note"
alias radio="$GRBL_CALL audio radio"
alias kb="$GRBL_CALL corsair"
alias speak="$GRBL_CALL say"
alias stopwatch="$GRBL_CALL timer stopwatch"
alias tube="$GRBL_CALL youtube"
alias tubes="$GRBL_CALL youtube search"
alias tunel="$GRBL_CALL tunnel"
alias status="$GRBL_CALL status"
alias spy="$GRBL_CALL spy monitor firefox"

# variables
alias $GRBL_SYSTEM_ALIAS="$GRBL_CALL"
$GRBL_ANDROID_NAME >/dev/null 2>/dev/null || alias $GRBL_ANDROID_NAME="gr phone"

# shorts
alias con="connect"
alias discon="disconnect"
alias rel="release"

play () {
    local media=$(xclip -o -selection clipboard)
    [[ -f $media ]]

    # mediafile
    if file $media | grep -q -e mp4 -e mp3 -e webm -e avi; then
        mpv $media
    fi

    # TODOadd rest of playables here
}

connect () {
    $GRBL_CALL mount $@
    #$GRBL_CALL tunnel
}

release () {
    $GRBL_CALL unmount $@
}

cloud () {
    $GRBL_CALL onedrive mount
    #$GRBL_CALL dropbox start
    $GRBL_CALL mount
}

clean () {
    $GRBL_CALL convert webp -f
    $GRBL_CALL convert webm -f
    $GRBL_CALL place memes -f
    $GRBL_CALL place mime move -f
}

disconnect () {
# connect to mountpoint
    $GRBL_CALL daemon stop
    $GRBL_CALL tunnel close all
    $GRBL_CALL unmount all
    $GRBL_CALL status
}

google () {
# open google search in browser, query as argument
    local url=https://www.google.com/search?q="$(sed 's/ /%20/g' <<< ${@})"
    case $GRBL_PREFERRED_BROWSER in
        firefox|chromium)
            $GRBL_PREFERRED_BROWSER --new-window $url
            ;;
        lynx|curl|wget)
            $GRBL_PREFERRED_BROWSER $url
            ;;
        *)
            gr.msg -c -v2 -c yellow "non supported browser, here's link: "
            gr.msg -c $url
        esac
    return $?
}


