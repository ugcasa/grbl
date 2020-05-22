#!/bin/bash
# guru tool-kit decorations for terminal

msg() {
    # function for ouput messages and make log notifications.
    if ! [[ "$1" ]] ; then return 0 ; fi                            # if no message, just return
    printf "$@" >"$GURU_ERROR_MSG" ;                                # keep last message to las error
    if [[ "$GURU_VERBOSE" ]] ; then printf "$@" ; fi                # print out if verbose set
    if ! [[ -f "$GURU_LOCAL_TRACK/.online" ]] ; then return 0 ; fi  # check that system mount is online before logging
    if ! [[ -f "$GURU_LOG" ]] ; then return 0 ; fi                  # log inly is log exist (hmm.. this not really neede)
    if [[ "$LOGGING" ]] ; then                                      # log without colorcodes ets.
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}
export -f msg


if [ "$GURU_TERMINAL_COLOR" ]; then
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


OK() {              [ "$1" ] && msg "${WHT}$1 $OK"  || msg "$OK" ; }
DONE() {            [ "$1" ] && msg "$1 $DONE"      || msg "$DONE" ; }
READY() {           [ "$1" ] && msg "$1 $READY"     || msg "$READY" ; }
PASSED() {          [ "$1" ] && msg "$1 $PASSED"    || msg "$PASSED" ; }
ONLINE() {          [ "$1" ] && msg "$1 $ONLINE"    || msg "$ONLINE" ; }
UPDATED() {         [ "$1" ] && msg "$1 $UPDATED"   || msg "$UPDATED" ; }
SUCCESS() {         [ "$1" ] && msg "$1 $SUCCESS"   || msg "$SUCCESS" ; }
IGNORED() {         [ "$1" ] && msg "$1 $IGNORED"   || msg "$IGNORED" ; }
EXIST() {           [ "$1" ] && msg "$1 $EXIST"   || msg "$EXIST" ; }
NOTEXIST() {        [ "$1" ] && msg "$1 $NOTEXIST"   || msg "$NOTEXIST" ; }
MOUNTED() {         [ "$1" ] && msg "$1 $MOUNTED"   || msg "$MOUNTED" ; }
OFFLINE() {         [ "$1" ] && msg "$1 $OFFLINE"   || msg "$OFFLINE" ; }
UNKNOWN() {         [ "$1" ] && msg "$1 $UNKNOWN"   || msg "$UNKNOWN" ; }
REMOVED() {         [ "$1" ] && msg "$1 $REMOVED"   || msg "$REMOVED" ; }
UPTODATE() {        [ "$1" ] && msg "$1 $UPTODATE"  || msg "$UPTODATE" ; }
NOTFOUND() {        [ "$1" ] && msg "$1 $NOTFOUND"  || msg "$NOTFOUND" ; }
UNMOUNTED() {       [ "$1" ] && msg "$1 $UNMOUNTED" || msg "$UNMOUNTED" ; }
ERROR() {           [ "$1" ] && msg "$ERROR ${WHT}$1"      || msg "$ERROR" ; }
WARNING() {         [ "$1" ] && msg "$WARNING ${WHT}$1"    || msg "$WARNING" ; }
FAILED() {          [ "$1" ] && msg "${WHT}$1: $FAILED"    || msg "$FAILED" ; }
TEST_IGNORED() {    [ "$1" ] && msg "${WHT}$1 test is $IGNORED" || msg "${WHT}test resul is $IGNORED" ; }
TEST_FAILED() {     [ "$1" ] && msg "${WHT}$1 test result is: $FAILED" || msg "${WHT}test resul is: $FAILED" ; }
TEST_PASSED() {     [ "$1" ] && msg "${WHT}$1 test result is: $PASSED" || msg "${WHT}test resul is: $PASSED" ; }

