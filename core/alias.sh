#!/bin/bash

## grbl place for aliases
# GRBL_* environmental values are in available.

# examples:
# alias work='grbl timer start'
# alias lunch='grbl timer end'

alias $GRBL_SYSTEM_ALIAS="$GRBL_CALL"
alias tube="$GRBL_CALL youtube"
alias tubes="$GRBL_CALL youtube search"
alias stopwatch="$GRBL_CALL timer stopwatch"
alias countdown="$GRBL_CALL timer countdown"
alias vartti="$GRBL_CALL timer countdown 15 m"
alias puolituntia="$GRBL_CALL timer countdown 30 m"
alias tunti="$GRBL_CALL timer countdown 60 m"


## place for simple functions used as aliases
# freedom from 'grbl' or 'gr.' prefixes

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


backup () {
	grbl backup daily
}


play () {

    case $1 in
            perttu)
                grbl audio play list perttu
            ;;
            pasila)
                grbl audio play list pasila
            ;;
            "")
                grbl audio play list liimatta
            ;;
            *)
                grbl audio play list $@
        esac

}


listen () {

    case $1 in
            rock)
                grbl audio listen rock
            ;;
            puhe)
                grbl audio listen yle puhe
            ;;
            "")
                grbl audio listen yle puhe
            ;;
            *)
                grbl audio listen $@
        esac
}

