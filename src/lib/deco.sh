#!/bin/bash
unset RED GRN YEL WHT BLU BRN NC

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
export MOUNTED="${GRN}MOUNTED${NC}\n"
export UNMOUNTED="${GRN}UNMOUNTED${NC}\n"
export IGNORED="${BRN}IGNORED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export ERROR="${YEL}ERROR${NC}"
export WARNING="${WHT}WARNING${NC}"
export ONLINE="${WHT}ONLINE${NC}\n"
export OFFLINE="${BRN}OFFLINE${NC}\n"
export UNKNOWN="${WHT}UNKNOWN${NC}\n"
export OK="${WHT}OK!${NC}\n"


PASSED() 	{
	msg "$PASSED"
}

READY()		{
	msg "$READY"
}

IGNORED()		{
	msg "$IGNORED"
}

MOUNTED() 	{
	msg "$MOUNTED"
}

UNMOUNTED() 	{
	[ "$1" ] && msg "$1 $UNMOUNTED" || msg "$UNMOUNTED"
}

FAILED() 	{
	msg "$FAILED"
}

TEST_FAILED() 	{
	[ "$1" ] && msg "${WHT}$1 test result is:${NC} $FAILED" || msg "${WHT}test resul is:${NC} $FAILED"
}

TEST_PASSED() 	{
	[ "$1" ] && msg "${WHT}$1 test result is:${NC} $PASSED" || msg "${WHT}test resul is:${NC} $PASSED"
}

ERROR() 	{
	[ "$1" ] && msg "$ERROR ${WHT}$1${NC}" || msg "$ERROR"
}

WARNING() 	{
	[ "$1" ] && msg "$WARNING ${WHT}$1${NC}" || msg "$WARNING"
}

ONLINE() 	{
	msg "$ONLINE"
}

OFFLINE() 	{
	msg "$OFFLINE"
}

UNKNOWN() 	{
	msg "$UNKNOWN"
}

OK() 		{
	msg "$OK"
}
