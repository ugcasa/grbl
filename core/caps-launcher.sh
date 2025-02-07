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
    # parental scripts THESE DOES NOT WORK on other systems than mine computer. Quick implementation, sorry -casa@ujo.guru
    sf)     gnome-terminal --hide-menubar --geometry 80x20 --zoom 1 --hide-menubar --title \
            "firefox parental" -- ssh santeri -t '~/.parental/firefox.sh'
            ;;
    sk)     ssh santeri -t pkill firefox
            ;;
    sq)     ssh santeri -t systemctl suspend
            ;;
    st)     gnome-terminal --hide-menubar --geometry 80x20 --zoom 1 --hide-menubar --title \
            "santeri's computer" -- ssh santeri
            ;;
    # hosts changes
    da)     gnome-terminal --hide-menubar --geometry 40x1 --zoom 0.7 --hide-menubar --title \
            "connection tests" -- \
            $GURU_BIN/guru net host direct -v2
            ;;
    ta)     gnome-terminal --hide-menubar --geometry 40x1 --zoom 0.7 --hide-menubar --title \
            "connection tests" -- $GURU_BIN/guru net host tunnel -v2
            ;;
    ba)     gnome-terminal --hide-menubar --geometry 40x1 --zoom 0.7 --hide-menubar --title \
            "connection tests" -- $GURU_BIN/guru net host basic -v2
            ;;
    # mqtt controls
    qq)     gnome-terminal --hide-menubar --geometry 50x10 --zoom 0.7 --hide-menubar --title \
            "mqtt server feed" -- $GURU_BIN/guru mqtt sub all
            ;;
    # net tests
    nn)     gnome-terminal --hide-menubar --geometry 50x10 --zoom 0.7 --hide-menubar --title \
            "connection tests" -- $GURU_BIN/guru net status loop
            ;;
    # stamps
    sdd)    guru stamp datetime | timeout 0.5 xclip ;;
    sd)     guru stamp time | timeout 0.5 xclip ;;
    ds)     guru stamp date | timeout 0.5 xclip ;;
    ws)     guru stamp weekplan | timeout 0.5 xclip ;;
    ss)     guru stamp signature | timeout 0.5 xclip ;;
    # caps lock enabler
    ca)     os.capslock toggle ;;
    # cheatsheets
    cs)     gnome-terminal --hide-menubar --geometry 200x60 --zoom 0.7 --hide-menubar --title \
            "guru-cli cheatsheet" -- $GURU_BIN/guru cheatsheet
            ;;
    cc)     gnome-terminal --hide-menubar --geometry 50x35 --zoom 1.2 --hide-menubar --title \
            "guru-cli cheatsheet" -- $GURU_BIN/guru help capslauncher
            ;;
    t)      gnome-terminal --hide-menubar --geometry 60x20 --zoom 1.0 --hide-menubar --title \
            "google translator" -- $GURU_BIN/guru trans
            ;;
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
    *$'\x1b'*)  guru flag rm ok ; guru flag set cancel ; mpv /tmp/cancel.wav ;;
    *§*)   guru flag rm cancel ; guru flag set ok ; mpv /tmp/ok.wav ;;
      #*)    guru say "no hit"
esac

guru corsair reset caps
