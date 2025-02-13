#!/bin/bash
# guru-cli caps-launcher

source common.sh
source corsair.sh
source os.sh

corsair.indicate active caps

animation=(ↀ ↂ ↈ ↂ)

printf '%s\r' ${animation[0]}
read -s -n1 -t 0.75 key1

printf '%s\r' ${animation[1]}
read -s -n1 -t 0.5 key2

printf '%s\r' ${animation[2]}
read -s -n1 -t 0.2 key3

all="$key1$key2$key3"

case $all in
    # stamps
    sdd)    guru stamp datetime | timeout 0.5 xclip ;;
    sd)     guru stamp time | timeout 0.5 xclip ;;
    ds)     guru stamp date | timeout 0.5 xclip ;;
    ws)     guru stamp weekplan | timeout 0.5 xclip ;;
    ss)     guru stamp signature | timeout 0.5 xclip ;;
    # caps lock enabler
    ca)     os.capslock toggle ;;
    # timer controls
    tt)     guru say "timer start"
            guru timer start ;;
    to)     guru say "timer stop"
            guru timer stop ;;
    tc)     guru say "timer canceled"
            guru timer cancel ;;
    # audio controls kill all audio and lights
    r*)     gnome-terminal --hide-menubar --geometry 100x26 --zoom 0.7 --hide-menubar --title \
            "radio player" -- $GURU_BIN/guru radio player $key2$key3
            ;;
    # kill all audio and lights
    as)     guru audio stop ;;
    ts)     printf "%s\n" "$(gr.ts -f)" | xclip -selection clipboard ;;
    tn)     printf "%s\n" "$(gr.ts -n)" | xclip -selection clipboard ;;
    # reserved for notes module
    po)     guru audio pause other ;;
    py)     guru audio pause yle ;;
    pt)     guru audio pause youtube ;;
    pu)     guru audio pause uutiset ;;
    pa)     guru audio pause audio ;;
    pp)     guru phone pair ;;
    upp)    guru phone unpair ;;
    pf)     guru phone find ;;
    np)     guru audio np ;;
    # note shortcuts
    n)      guru note ;;
    ni)     guru note idea ;;
    nm)     guru note memo ;;
    nw)     guru note write ;;
    ny*)    guru note yesterday;;
    nt*)    guru note tomorrow;;
    # games
    mm)     guru game start minecraft ;;
    # project module
    clo)    guru project close ;;
    sto)    guru project stonks ;;
   # general skip and confirm
    *$'\x1b'*)  guru flag rm ok ; guru flag set cancel ; mpv /tmp/$USER/cancel.wav ;;
    *§*)   guru flag rm cancel ; guru flag set ok ; mpv /tmp/$USER/ok.wav ;;
      #*)    guru say "no hit"
esac

guru corsair reset caps
