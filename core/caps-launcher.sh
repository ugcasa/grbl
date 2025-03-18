#!/bin/bash
# grbl caps-launcher

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
    sdd)    grbl stamp datetime | timeout 0.5 xclip ;;
    sd)     grbl stamp time | timeout 0.5 xclip ;;
    ds)     grbl stamp date | timeout 0.5 xclip ;;
    ws)     grbl stamp weekplan | timeout 0.5 xclip ;;
    ss)     grbl stamp signature | timeout 0.5 xclip ;;
    # caps lock enabler
    ca)     os.capslock toggle ;;
    # timer controls
    tt)     grbl say "timer start"
            grbl timer start ;;
    to)     grbl say "timer stop"
            grbl timer stop ;;
    tc)     grbl say "timer canceled"
            grbl timer cancel ;;
    # audio controls kill all audio and lights
    r*)     gnome-terminal --hide-menubar --geometry 100x26 --zoom 0.7 --hide-menubar --title \
            "radio player" -- $GRBL_BIN/grbl radio player $key2$key3
            ;;
    # kill all audio and lights
    as)     grbl audio stop ;;
    ts)     printf "%s\n" "$(gr.ts -f)" | xclip -selection clipboard ;;
    tn)     printf "%s\n" "$(gr.ts -n)" | xclip -selection clipboard ;;
    # reserved for notes module
    po)     grbl audio pause other ;;
    py)     grbl audio pause yle ;;
    pt)     grbl audio pause youtube ;;
    pu)     grbl audio pause uutiset ;;
    pa)     grbl audio pause audio ;;
    pp)     grbl phone pair ;;
    upp)    grbl phone unpair ;;
    pf)     grbl phone find ;;
    np)     grbl audio np ;;
    # note shortcuts
    n)      grbl note ;;
    ni)     grbl note idea ;;
    nm)     grbl note memo ;;
    nw)     grbl note write ;;
    ny*)    grbl note yesterday;;
    nt*)    grbl note tomorrow;;
    # games
    mm)     grbl game start minecraft ;;
    # project module
    clo)    grbl project close ;;
    sto)    grbl project stonks ;;
   # general skip and confirm
    *$'\x1b'*)  grbl flag rm ok ; grbl flag set cancel ; mpv /tmp/$USER/cancel.wav ;;
    *§*)   grbl flag rm cancel ; grbl flag set ok ; mpv /tmp/$USER/ok.wav ;;
      #*)    grbl say "no hit"
esac

grbl corsair reset caps
