#!/bin/bash
# guru-client decorations for terminal

if [[ "$GURU_FLAG_COLOR" ]] ; then  #TODO remove this ..

    # TODO make futile, then remove
    export RED=$(printf '\033[0;31m')
    export GRN=$(printf '\033[0;32m')
    export YEL=$(printf '\033[1;33m')
    export WHT=$(printf '\033[1;37m')
    export CRY=$(printf '\033[0;37m')
    export CYA=$(printf '\033[0;96m')
    export BLU=$(printf '\033[0;34m')
    export BRN=$(printf '\033[0;33m')
    export BLK=$(printf '\033[0;90m')
    export LMAG=$(printf '\033[0;95m')
    export NC=$(printf '\033[0m')

fi


#TODO remove this ..
export OK=$(printf "${GRN}OK${NC}\n")
export PASSED=$(printf "${GRN}PASSED${NC}\n")
export READY=$(printf "${GRN}READY${NC}\n")
export DONE=$(printf "${GRN}DONE${NC}\n")
export UPTODATE=$(printf "${GRN}UPTODATE${NC}\n")
export EXIST=$(printf "${GRN}EXIST${NC}\n")
export NOTEXIST=$(printf "${RED}DOES NOT EXIST${NC}\n")
export UPDATED=$(printf "${GRN}UPDATED${NC}\n")
export MOUNTED=$(printf "${GRN}MOUNTED${NC}\n")
export SUCCESS=$(printf "${GRN}SUCCEEDED${NC}\n")
export UNMOUNTED=$(printf "${BLU}UN-MOUNTED${NC}\n")
export IGNORED=$(printf "${BRN}IGNORED${NC}\n")
export FAILED=$(printf "${RED}FAILED${NC}\n")
export ERROR=$(printf "${YEL}ERROR${NC}")
export WARNING=$(printf "${YEL}WARNING${NC}")
export ONLINE=$(printf "${GRN}ONLINE${NC}\n")
export OFFLINE=$(printf "${BLU}OFFLINE${NC}\n")
export NOTFOUND=$(printf "${BLU}NOT FOUND${NC}\n")
export REMOVED=$(printf "${BLU}REMOVED${NC}\n")
export UNKNOWN=$(printf "${WHT}UNKNOWN${NC}\n")


#TODO remove this ..
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
UNMOUNTED() {       [[ "$1" ]] && gmsg "$1 $(printf $UNMOUNTED)" || gmsg "$(printf $UNMOUNTED)" ; }
ERROR() {           [[ "$1" ]] && gmsg "$(printf $ERROR ${WHT} $1)"      || gmsg "$(printf $ERROR)" ; }
WARNING() {         [[ "$1" ]] && gmsg "$(printf $WARNING ${WHT} $1)"    || gmsg "$(printf $WARNING)" ; }
FAILED() {          [[ "$1" ]] && gmsg "$(printf ${WHT})$1: $(printf $FAILED)"    || gmsg "$(printf $FAILED)" ; }
TEST_IGNORED() {    [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test is $(printf $IGNORED)" || gmsg "$(printf ${WHT}test resul is $IGNORED)" ; return 1 ; }
TEST_FAILED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $FAILED)" || gmsg "$(printf ${WHT}test resul is: $FAILED)" ; return 100 ; }
TEST_PASSED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $PASSED)" || gmsg "$(printf ${WHT}test resul is: $PASSED)" ; return 0 ; }

