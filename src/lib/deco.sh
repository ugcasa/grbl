#!/bin/bash
# guru tool-kit decorations for terminal

msg() {         # function for ouput messages and make log notifications.

    if ! [[ "$1" ]] ; then return 0 ; fi                            # no message, just return
    # print to stdout
    if [[ $GURU_VERBOSE ]] ; then printf "$@" ; fi                  # print out if verbose set

    # logging (and error messages)
    #printf "$@" >"$GURU_ERROR_MSG" ;                               # keep last message to las error
    if ! [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] ; then return 0 ; fi  # check that system mount is online before logging
    if ! [[ -f "$GURU_LOG" ]] ; then return 0 ; fi                  # log inly is log exist (hmm.. this not really neede)
    if [[ "$LOGGING" ]] ; then                                      # log without colorcodes ets.
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}

export -f msg


gmsg() {  # function for ouput messages and make log notifications - revisited

    # default
    local _verbose_trigger=0                        # prinout if verbose trigger is not set in options
    local _timestamp=                               # timestamp is disabled by default
    local _message=                                 # message container
    local _logging=                                 # logging is disabled by default
    local _newline="\n"

    TEMP=`getopt --long -o "tlnv:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
            -l ) _logging=true                              ; shift ;;
            -n ) _newline=                                  ; shift ;;
            -v ) _verbose_trigger=$2                        ; shift 2 ;;
            -c ) _color=$2                                  ; shift 2 ;;
             * ) break
        esac
    done
    # printf  "\ntrigger: $_verbose_trigger \nlogging: $_logging \ntimestamp: $_timestamp \nVERBOSE: $GURU_VERBOSE \n"

    # check message
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"       # there were reason for this
    [[ "$_message" ]] || return 0                        # no message; return

    # print to stdout
    if  [[ $GURU_VERBOSE -ge $_verbose_trigger ]] ; then printf "%s%s$_newline" "$_timestamp" "$_message" ; fi                  # print out if verbose set

    # logging
    if [[ "$LOGGING" ]] || [[ "$_logging" ]] ; then                          # log without colorcodes ets.
        [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] || return 0                        # check that system mount is online before logging
        [[ -f "$GURU_LOG" ]] || return 0                                     # log inly is log exist (hmm.. this not really neede)
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}

export -f gmsg



if [[ "$GURU_TERMINAL_COLOR" ]] ; then
    export RED='\033[0;31m'
    export GRN='\033[0;32m'
    export YEL='\033[1;33m'
    export WHT='\033[1;37m'
    export CRY='\033[0;37m'
    export CYA='\033[0;96m'
    export BLU='\033[0;34m'
    export BRN='\033[0;33m'
    export BLK='\033[0;90m'
    export NC='\033[0m'
fi


export OK="${GRN}OK${NC}\n"
export PASSED="${GRN}PASSED${NC}\n"
export READY="${GRN}READY${NC}\n"
export DONE="${GRN}DONE${NC}\n"
export UPTODATE="${GRN}UPTODATE${NC}\n"
export EXIST="${GRN}EXIST${NC}\n"
export NOTEXIST="${RED}DOES NOT EXIST${NC}\n"
export UPDATED="${GRN}UPDATED${NC}\n"
export MOUNTED="${GRN}MOUNTED${NC}\n"
export SUCCESS="${GRN}SUCCEEDED${NC}\n"
export UNMOUNTED="${BLU}UN-MOUNTED${NC}\n"
export IGNORED="${BRN}IGNORED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export ERROR="${YEL}ERROR${NC}"
export WARNING="${YEL}WARNING${NC}"
export ONLINE="${GRN}ONLINE${NC}\n"
export OFFLINE="${BLU}OFFLINE${NC}\n"
export NOTFOUND="${BLU}NOT FOUND${NC}\n"
export REMOVED="${BLU}REMOVED${NC}\n"
export UNKNOWN="${WHT}UNKNOWN${NC}\n"


HEADER() {          gmsg "$(printf ${WHT})$1$(printf ${NC})" ; }
OK() {              [[ "$1" ]] && gmsg "$(printf ${WHT}$1 $OK)"  || gmsg "$(printf $OK)" ; }
DONE() {            [[ "$1" ]] && gmsg "$1 $(printf $DONE)"      || gmsg "$(printf $DONE)" ; }
READY() {           [[ "$1" ]] && gmsg "$1 $(printf $READY)"     || gmsg "$(printf $READY)" ; }
PASSED() {          [[ "$1" ]] && gmsg "$1 $(printf $PASSED)"    || gmsg "$(printf $PASSED)" ; }
ONLINE() {          [[ "$1" ]] && gmsg "$1 $(printf $ONLINE)"    || gmsg "$(printf $ONLINE)" ; }
UPDATED() {         [[ "$1" ]] && gmsg "$1 $(printf $UPDATED)"   || gmsg "$(printf $UPDATED)" ; }
SUCCESS() {         [[ "$1" ]] && gmsg "$1 $(printf $SUCCESS)"   || gmsg "$(printf $SUCCESS)" ; }
IGNORED() {         [[ "$1" ]] && gmsg "$1 $(printf $IGNORED)"   || gmsg "$(printf $IGNORED)" ; }
EXIST() {           [[ "$1" ]] && gmsg "$1 $(printf $EXIST)"     || gmsg "$(printf $EXIST)" ; }
NOTEXIST() {        [[ "$1" ]] && gmsg "$1 $(printf $NOTEXIST)"  || gmsg "$(printf $NOTEXIST)" ; }
MOUNTED() {         [[ "$1" ]] && gmsg "$1 $(printf $MOUNTED)"   || gmsg "$(printf $MOUNTED)" ; }
OFFLINE() {         [[ "$1" ]] && gmsg "$1 $(printf $OFFLINE)"   || gmsg "$(printf $OFFLINE)" ; }
UNKNOWN() {         [[ "$1" ]] && gmsg "$1 $(printf $UNKNOWN)"   || gmsg "$(printf $UNKNOWN)" ; }
REMOVED() {         [[ "$1" ]] && gmsg "$1 $(printf $REMOVED)"   || gmsg "$(printf $REMOVED)" ; }
UPTODATE() {        [[ "$1" ]] && gmsg "$1 $(printf $UPTODATE)"  || gmsg "$(printf $UPTODATE)" ; }
NOTFOUND() {        [[ "$1" ]] && gmsg "$1 $(printf $NOTFOUND)"  || gmsg "$(printf $NOTFOUND)" ; }
UNMOUNTED() {       [[ "$1" ]] && gmsg "$1 $(printf $UNMOUNTED)" || gmsg "$(printf $UNMOUNTED)" ; }
ERROR() {           [[ "$1" ]] && gmsg "$(printf $ERROR ${WHT})$1"      || gmsg "$(printf $ERROR)" ; }
WARNING() {         [[ "$1" ]] && gmsg "$(printf $WARNING ${WHT})$1"    || gmsg "$(printf $WARNING)" ; }
FAILED() {          [[ "$1" ]] && gmsg "$(printf ${WHT})$1: $(printf $FAILED)"    || gmsg "$(printf $FAILED)" ; }
TEST_IGNORED() {    [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test is $(printf $IGNORED)" || gmsg "$(printf ${WHT}test resul is $IGNORED)" ; return 1 ; }
TEST_FAILED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $FAILED)" || gmsg "$(printf ${WHT}test resul is: $FAILED)" ; return 100 ; }
TEST_PASSED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $PASSED)" || gmsg "$(printf ${WHT}test resul is: $PASSED)" ; return 0 ; }

