#!/bin/bash

## guru-client place for aliases
# GURU_* environmental values are in available.

# examples:
# alias work='guru timer start'
# alias lunch='guru timer end'

alias $GURU_SYSTEM_ALIAS="$GURU_CALL"

## place for simple functions used as aliases
# freedom from 'guru' or 'gr.' prefixes

google () {
    # open google search in browser, query as argument
    local url=https://www.google.com/search?q="$(sed 's/ /%20/g' <<< ${@})"
    case $GURU_PREFERRED_BROWSER in
        firefox|chromium)
            $GURU_PREFERRED_BROWSER --new-window $url
            ;;
        lynx|curl|wget)
            $GURU_PREFERRED_BROWSER $url
            ;;
        *)
            gr.msg -c -v2 -c yellow "non supported browser, here's link: "
            gr.msg -c $url
        esac
    return $?
}


backup () {
	guru backup daily
}


radio () {
	[[ -f /tmp/audio.playlist ]] && rm /tmp/audio.guru-client
	guru audio toggle
}


play () {

    case $1 in
            perttu)
                guru audio play list perttu
            ;;
            pasila)
                guru audio play list pasila
            ;;
            "")
                guru audio play list liimatta
            ;;
            *)
                guru audio play list $@
        esac

}


listen () {

    case $1 in
            rock)
                guru audio listen rock
            ;;
            puhe)
                guru audio listen yle puhe
            ;;
            "")
                guru audio listen yle puhe
            ;;
            *)
                guru audio listen $@
        esac
}


tube() {
    gr.ind playing f8 >/dev/null 2>/dev/null
    guru youtube search $@
    gr.end f8 >/dev/null 2>/dev/null
}