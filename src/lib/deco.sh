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
export IGNORED="${BRN}IGNORED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export ERROR="${YEL}ERROR${NC}:"
export ONLINE="${GRN}ONLINE${NC}\n"
export OFFLINE="${RED}OFFLINE${NC}\n"
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

FAILED() 	{
	msg "$FAILED"
}

ERROR() 	{
	msg "$ERROR"
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
