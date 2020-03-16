#!/bin/bash
unset RED GNR YEL NC

if [ "$GURU_TERMINAL_COLOR" ]; then
	export RED='\033[0;31m'
	export GRN='\033[0;32m'
	export YEL='\033[1;33m'
	export WHT='\033[1;37m'
	export BLU='\033[0;34m'
	export BRN='\033[0;33m'
	export NC='\033[0m'
fi

export PASSED="${GRN}PASSED${NC}\n"
export READY="${GRN}READY${NC}\n"
export MOUNTED="${GRN}READY${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export ERROR="${YEL}ERROR${NC}:"
export ONLINE="${GRN}ONLINE${NC}\n"
export OFFLINE="${RED}OFFLINE${NC}\n"
export UNKNOWN="${WHT}UNKNOWN${NC}\n"
export OK="${WHT}OK!${NC}\n"


PASSED(){
    msg "$PASSED"
    # [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[PASSED]\n" >>"$GURU_LOG"
}


READY(){
    msg "$READY"
    # [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[READY]\n" >>"$GURU_LOG"
}


MOUNTED(){
    msg "$MOUNTED"
    # [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[MOUNTED]\n" >>"$GURU_LOG"
}

FAILED() {
    msg "$FAILED"
    # [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[FAILED]\n" >>"$GURU_LOG"
}


ERROR() {
    msg "$ERROR"
    # [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[ERROR]\n" >>"$GURU_LOG"
}


ONLINE() {
	msg "$ONLINE"
	# [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[ONLINE]\n" >>"$GURU_LOG"
}


OFFLINE() {
	msg "$OFFLINE"
	# [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[OFFLINE]\n" >>"$GURU_LOG"
}


UNKNOWN() {
	msg "$UNKNOWN"
	# [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[UNKNOWN]\n" >>"$GURU_LOG"
}


OK() {
	msg "$OK"
	# [ "$GURU_FILESERVER_STATUS"="online" ] && msg "[OK]\n" >>"$GURU_LOG"
}
