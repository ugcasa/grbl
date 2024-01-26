#!/bin/bash
# guru-cli caps-launcher

source common.sh
source corsair.sh
source os.sh

corsair.indicate active caps

read -rs -n1 -t 1 key1
gr.msg -n "."
read -rs -n1 -t 0.5 key2
gr.msg -n "."
read -rs -n1 -t 0.2 key3
gr.msg -n "."

#[[ $key1 == $key2 ]] && [[ $key2 == $key3 ]] && all_same=true
all="$key1$key2$key3"

case $all in

    # timer module controls
    sdd)    guru stamp datetime | timeout 0.5 xclip ;;
    sd)     guru stamp time | timeout 0.5 xclip ;;
    ds)     guru stamp date | timeout 0.5 xclip ;;
    ws)     guru stamp weekplan | timeout 0.5 xclip ;;
    ss)     guru stamp signature | timeout 0.5 xclip ;;
    ca)     os.capslock toggle ;;
    cs)     gnome-terminal --hide-menubar --geometry 200x60 --zoom 0.7 --hide-menubar --title "guru-cli cheatsheet"  -- $GURU_BIN/guru cheatsheet ;;
    cc)     gnome-terminal --hide-menubar --geometry 50x35 --zoom 1.2 --hide-menubar --title "guru-cli cheatsheet"  -- $GURU_BIN/guru help capslauncher ;;
    tt)     guru say "timer start"
            guru timer start ;;
    to)     guru say "timer stop"
            guru timer stop ;;
    tc)     guru say "timer canceled"
            guru timer cancel ;;
    # audio controls kill all audio and lights
    r*)     gnome-terminal --hide-menubar --geometry 100x26 --zoom 0.7 --hide-menubar --title "radio player" -- $GURU_BIN/guru radio player $key2$key3 ;;
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
    n)      guru note ;;
    ni)     guru note idea ;;
    nm)     guru note memo ;;
    nw)     guru note write ;;
    ny*)    guru note yesterday;;
    nt*)    guru note tomorrow;;
    np)     guru audio np ;;
    # reserved for notes module
    mm)     guru game start minecraft ;;
    # project module
    clo)    guru project close ;;
    # reserved for  module
    sto)    guru project stonks ;;
    *$'\x1b'*)  guru flag rm ok ; guru flag set cancel ; mpv /tmp/cancel.wav ;;
    *§*)   guru flag rm cancel ; guru flag set ok ; mpv /tmp/ok.wav ;;
      #*)    guru say "no hit"
esac

#guru say  "$key1 $key2 $key3"

guru corsair reset caps
#sleep 3
