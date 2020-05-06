#!/bin/bash
# guru tool-kit decorations for terminal

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


export PASSED="${GRN}PASSED${NC}\n"
export READY="${GRN}READY${NC}\n"
export DONE="${GRN}DONE${NC}\n"
export UPTODATE="${GRN}UPTODATE${NC}\n"
export UPDATED="${GRN}UPDATED${NC}\n"
export MOUNTED="${GRN}MOUNTED${NC}\n"
export SUCCESS="${GRN}SUCCESS${NC}\n"
export UNMOUNTED="${BLU}UNMOUNTED${NC}\n"
export IGNORED="${BRN}IGNORED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export ERROR="${YEL}ERROR${NC}"
export WARNING="${WHT}WARNING${NC}"
export ONLINE="${GRN}ONLINE${NC}\n"
export OFFLINE="${BLU}OFFLINE${NC}\n"
export REMOVED="${BLU}REMOVED${NC}\n"
export UNKNOWN="${WHT}UNKNOWN${NC}\n"
export OK="${WHT}OK!${NC}\n"


OK() {              [ "$1" ] && msg "$1 $OK"        || msg "$OK" ; }
DONE() {            [ "$1" ] && msg "$1 $DONE"      || msg "$DONE" ; }
READY() {           [ "$1" ] && msg "$1 $READY"     || msg "$READY" ; }
PASSED() {          [ "$1" ] && msg "$1 $PASSED"    || msg "$PASSED" ; }
ONLINE() {          [ "$1" ] && msg "$1 $ONLINE"    || msg "$ONLINE" ; }
UPDATED() {         [ "$1" ] && msg "$1 $UPDATED"   || msg "$UPDATED" ; }
SUCCESS() {         [ "$1" ] && msg "$1 $SUCCESS"   || msg "$SUCCESS" ; }
IGNORED() {         [ "$1" ] && msg "$1 $IGNORED"   || msg "$IGNORED" ; }
MOUNTED() {         [ "$1" ] && msg "$1 $MOUNTED"   || msg "$MOUNTED" ; }
OFFLINE() {         [ "$1" ] && msg "$1 $OFFLINE"   || msg "$OFFLINE" ; }
UNKNOWN() {         [ "$1" ] && msg "$1 $UNKNOWN"   || msg "$UNKNOWN" ; }
REMOVED() {         [ "$1" ] && msg "$1 $REMOVED"   || msg "$REMOVED" ; }
UPTODATE() {        [ "$1" ] && msg "$1 $UPTODATE"  || msg "$UPTODATE" ; }
UNMOUNTED() {       [ "$1" ] && msg "$1 $UNMOUNTED" || msg "$UNMOUNTED" ; }
ERROR() {           [ "$1" ] && msg "$ERROR ${WHT}$1${NC}"      || msg "$ERROR" ; }
FAILED() {          [ "$1" ] && msg "${WHT}$1:${NC} $FAILED"    || msg "$FAILED" ; }
WARNING() {         [ "$1" ] && msg "$WARNING ${WHT}$1${NC}"    || msg "$WARNING" ; }
TEST_IGNORED() {    [ "$1" ] && msg "${WHT}$1 test is $IGNORED" || msg "${WHT}test resul is $IGNORED" ; }
TEST_FAILED() {     [ "$1" ] && msg "${WHT}$1 test result is: $FAILED" || msg "${WHT}test resul is: $FAILED" ; }
TEST_PASSED() {     [ "$1" ] && msg "${WHT}$1 test result is: $PASSED" || msg "${WHT}test resul is: $PASSED" ; }
