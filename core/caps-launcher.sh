#!/bin/bash
# guru-cli caps-launcher

source common.sh
source corsair.sh
source os.sh

corsair.indicate active caps

read -n1 -t 1 key1
read -n1 -t 0.5 key2
read -n1 -t 0.5 key3

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
    tt)     guru say "timer start"
            guru timer start ;;
    to)     guru say "timer stop"
            guru timer stop ;;
    tc)     guru say "timer canceled"
            guru timer cancel ;;
    # audio controls kill all audio and lights
    r*)     guru radio $key2$key3 ;;
    # kill all audio and lights
    as)     guru audio stop ;;
    ts)     printf "%s\n" "$(gr.ts -f)" | xclip -selection clipboard ;;
    tn)     printf "%s\n" "$(gr.ts -n)" | xclip -selection clipboard ;;
    # reserved for notes module
    n)      guru note ;;
    ni)     guru note idea ;;
    nm)     guru note memo ;;
    nw)     guru note write ;;
    ny*)    guru note yesterday;;
    nt*)    guru note tomorrow;;
    # reserved for notes module
    mm)     guru game start minecraft ;;
    # project module
    clo)    guru project close ;;
    # reserved for  module
    sto)    guru project stonks ;;
      #*)    guru say "no hit"
esac

#guru say  "$key1 $key2 $key3"

guru corsair reset caps
#sleep 3

