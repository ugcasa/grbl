#!/bin/bash

## guru-client place for aliases
# GURU_* environmental values are in available.

# examples:
# alias work='guru timer start'
# alias lunch='guru timer end'

alias $GURU_SYSTEM_ALIAS="$GURU_CALL"
alias tube="$GURU_CALL youtube"
alias tubes="$GURU_CALL youtube search"
alias stopwatch="$GURU_CALL timer stopwatch"
alias countdown="$GURU_CALL timer countdown"
alias vartti="$GURU_CALL timer countdown 15 m"
alias puolituntia="$GURU_CALL timer countdown 30 m"
alias tunti="$GURU_CALL timer countdown 60 m"


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

