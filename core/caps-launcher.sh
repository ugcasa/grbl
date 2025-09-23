#!/bin/bash
# grbl caps-launcher

source common.sh
source corsair.sh
source os.sh

check_escape () {
# escape keys: esc, arrows, enter, backskape
    if [[ $1 == $'\e' ]] ||\
       [[ $1 == $'\n' ]] ||\
       [[ $1 == $'\x0a' ]] ||\
       [[ $1 == $'\177' ]] then 
        grbl corsair reset caps
        exit 0 
    fi
}

corsair.indicate active caps

animation=(ↀ ↂ ↈ ↂ)

printf '%s\r' ${animation[0]}
read -s -n1 -t 0.75 key1

check_escape $key1

printf '%s\r' ${animation[1]}
read -s -n1 -t 0.75 key2

check_escape $key2

printf '%s\r' ${animation[2]}
read -s -n1 -t 0.75 key3

check_escape $key3

all="$key1$key2$key3"

case $all in
    # stamps
    sdd)    say="date time"
            grbl stamp datetime | timeout 0.5 xclip ;;
    sd)     say="time"
            grbl stamp time | timeout 0.5 xclip ;;
    ds)     say="date"
            grbl stamp date | timeout 0.5 xclip ;;
    ws)     say="week plan"
            grbl stamp weekplan | timeout 0.5 xclip ;;
    ss)     say="signature"
            grbl stamp signature | timeout 0.5 xclip ;;
    # caps lock enabler
    ca)     say="signature"
            os.capslock toggle ;;
    # timer controls
    tt)     say="timer start"
            grbl timer start ;;
    to)     say="timer stop"
            grbl timer stop ;;
    tc)     say="timer canceled"
            grbl timer cancel ;;
    # audio controls kill all audio and lights
    r*)     gnome-terminal --hide-menubar --geometry 100x26 --zoom 0.7 --hide-menubar --title \
            "radio player" -- $GRBL_BIN/grbl radio player $key2$key3
            ;;
    # kill all audio and lights
    as)     grbl audio stop ;;
    ts)     say="file stamp"
            printf "%s\n" "$(gr.ts -f)" | xclip -selection clipboard ;;
    tn)     say="nice stamp"
            printf "%s\n" "$(gr.ts -n)" | xclip -selection clipboard ;;
    # reserved for notes module
    po)     grbl audio pause other ;;
    py)     grbl audio pause yle ;;
    pt)     grbl audio pause youtube ;;
    pu)     grbl audio pause uutiset ;;
    pa)     grbl audio pause audio ;;
    pp)     say="pair phone"    
            grbl phone pair ;;
    pb)     say="page break"
            printf "%s\n" "<div style="page-break-after: always"></div>" | xclip -selection clipboard ;;
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
clear
if [[ $say ]] && [[ $GRBL_SPEECH_ENABLED ]]; then 
    source say.sh
    say.string "$say"
fi

grbl corsair reset caps
