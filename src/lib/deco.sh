#!/bin/bash
# guru tool-kit decorations for terminal

if [[ "$GURU_TERMINAL_COLOR" ]] ; then  #TODO remove this ..
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
    export NC=$(printf '\033[0m')
fi

if [[ "$GURU_TERMINAL_COLOR" ]] ; then # ..replace with this

    export C_NORMAL='\033[0m'
    export C_HEADER='\033[1;37m'
    #light colors
    export C_LRED='\033[0;91m'
    export C_LGREEN='\033[0;92m'
    export C_LYELLOW='\033[0;93m'
    export C_LMAGENTA='\033[1;35m'
    export C_LCRAY='\033[0;37m'
    export C_LCYAN='\033[0;96m'
    export C_LBLUE='\033[1;94m'
    export C_WHITE='\033[1;37m'
    #dark colors
    export C_RED='\033[0;31m'
    export C_BROWN='\033[0;33m'
    export C_BLACK='\033[0;90m'
    export C_GREEN='\033[0;32m'
    export C_YELLOW='\033[1;33m'
    export C_BLUE='\033[0;34m'
    export C_MAGENTA='\033[0;95m'
    export C_CYAN='\033[0;36m'
    export C_CRAY='\033[0;90m'
fi


msg() {         # function for ouput messages and make log notifications. TODO remove this..

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
    local _newline="\n"                             # newline is on by default
    local _pre_newline=
    local _color=

    TEMP=`getopt --long -o "tlnNv:c:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -t ) _timestamp="$(date +$GURU_FORMAT_TIME) "   ; shift ;;
            -l ) _logging=true                              ; shift ;;
            -n ) _newline=                                  ; shift ;;  # no newline
            -N ) _pre_newline="\n"                          ; shift ;;  # newline before printout
            -v ) _verbose_trigger=$2                        ; shift 2 ;;
            -c ) _c_var="C_${2^^}" ; _color=${!_c_var}      ; shift 2 ;;
             * ) break
        esac
    done

    # check message
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"

    if [[ $GURU_VERBOSE -ge $_verbose_trigger ]] ; then
            if [[ $_color ]] ; then
                    printf "$_pre_newline$_color%s%s$_newline$C_NORMAL" "$_timestamp" "$_message"
                else
                    printf "$_pre_newline%s%s$_newline" "$_timestamp" "$_message"
                fi
        fi

    # logging
    if [[ "$LOGGING" ]] || [[ "$_logging" ]] ; then                          # log without colorcodes ets.
        [[ -f "$GURU_SYSTEM_MOUNT/.online" ]] || return 0                        # check that system mount is online before logging
        [[ -f "$GURU_LOG" ]] || return 0                                     # log inly is log exist (hmm.. this not really neede)
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}

export -f gmsg

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
ERROR() {           [[ "$1" ]] && gmsg "$(printf $ERROR ${WHT} $1)"      || gmsg "$(printf $ERROR)" ; }
WARNING() {         [[ "$1" ]] && gmsg "$(printf $WARNING ${WHT} $1)"    || gmsg "$(printf $WARNING)" ; }
FAILED() {          [[ "$1" ]] && gmsg "$(printf ${WHT})$1: $(printf $FAILED)"    || gmsg "$(printf $FAILED)" ; }
TEST_IGNORED() {    [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test is $(printf $IGNORED)" || gmsg "$(printf ${WHT}test resul is $IGNORED)" ; return 1 ; }
TEST_FAILED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $FAILED)" || gmsg "$(printf ${WHT}test resul is: $FAILED)" ; return 100 ; }
TEST_PASSED() {     [[ "$1" ]] && gmsg "$(printf ${WHT})$1 test result is: $(printf $PASSED)" || gmsg "$(printf ${WHT}test resul is: $PASSED)" ; return 0 ; }

