#!/bin/bash
# guru tool-kit decorations for terminal

unset RED GRN YEL WHT BLU BRN NC

ansi()          { echo -e "\e[${1}m${*:2}\e[0m"; }
bold()          { ansi 1 "$@"; }
italic()        { ansi 3 "$@"; }
underline()     { ansi 4 "$@"; }
strikethrough() { ansi 9 "$@"; }
red()           { ansi 31 "$@"; }


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
export UNKNOWN="${WHT}UNKNOWN${NC}\n"
export OK="${WHT}OK!${NC}\n"




PASSED() {
	[ "$1" ] && msg "$1: $PASSED" || msg "$PASSED"
}

READY() {
	[ "$1" ] && msg "$1 $READY" || msg "$READY"
}

UPTODATE() {
	[ "$1" ] && msg "$1 $UPTODATE" || msg "$UPTODATE"
}

UPDATED() {
	[ "$1" ] && msg "$1 $UPDATED" || msg "$UPDATED"
}

IGNORED() {
	[ "$1" ] && msg "$1 $IGNORED" || msg "$IGNORED"
}

SUCCESS() {
	[ "$1" ] && msg "$1$ $SUCCESS" || msg "$SUCCESS"
}

MOUNTED() {
	[ "$1" ] && msg "$1 $MOUNTED" || msg "$MOUNTED"
}

UNMOUNTED() {
	[ "$1" ] && msg "$1 $UNMOUNTED" || msg "$UNMOUNTED"
}

FAILED() {
	[ "$1" ] && msg "${WHT}$1:${NC} $FAILED" || msg "$FAILED"
}

TEST_FAILED() {
	[ "$1" ] && msg "${WHT}$1 test result is:${NC} $FAILED" || msg "${WHT}test resul is:${NC} $FAILED"
}

TEST_PASSED() {
	[ "$1" ] && msg "${WHT}$1 test result is:${NC} $PASSED" || msg "${WHT}test resul is:${NC} $PASSED"
}

TEST_IGNORED() {
	[ "$1" ] && msg "${WHT}$1 test is${NC} $IGNORED" || msg "${WHT}test resul is${NC} $IGNORED"
}

ERROR() {
	[ "$1" ] && msg "$ERROR ${WHT}$1${NC}" || msg "$ERROR"
}

WARNING() {
	[ "$1" ] && msg "$WARNING ${WHT}$1${NC}" || msg "$WARNING"
}

ONLINE() {
	[ "$1" ] && msg "$1 $ONLINE" || msg "$ONLINE"
}

OFFLINE() {
	[ "$1" ] && msg "$1 $OFFLINE" || msg "$OFFLINE"
}

UNKNOWN() {
	[ "$1" ] && msg "$1 $UNKNOWN" || msg "$UNKNOWN"
}

OK() {
	[ "$1" ] && msg "$1 $OK" || msg "$OK"
}
