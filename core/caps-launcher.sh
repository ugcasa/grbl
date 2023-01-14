#!/bin/bash
#guru-cli caps-launcher.sh is not an module, not a plugin, its a macro

source common.sh
source os.sh
guru corsair set caps white

read -n1 -t1 key1
read -n1 -t1 key2
read -n1 -t1 key3
echo


[[ $key1 == $key2 ]] && [[ $key2 == $key3 ]] && all_same=true
all="$key1$key2$key3"
clear
case $all in

    # for testing this function
    kkk)    guru say 'yippee kai yay mother fuckerr' ;;

    # timer module controls
    t)      guru say "timer start"
            guru timer start
            ;;
    tt)     guru say "timer stop"
            guru timer stop
            ;;
    ttt)    guru say "timer canceled"
            guru timer cancel
            ;;

    # disable capslock
    cc|CC)  os.capslock disable ;;

    # enable caps lock
    ccc)    os.capslock enable ;;

    # audio controls kill all audio and lights
    r*)     guru audio radio $key2 $key3 ;;

    # kill all audio and lights
    as)     guru audio stop ;;
    # reserved for notes module
    no*)    guru note ;;
    ny*)    guru note yesterday;;
    nt*)    guru note tomorrow;;

    # reserved for notes module
    mm)     guru game start minecraft ;;

    # project module
    cl)     guru project close ;;

    # reserved for  module
    st)     guru project stonks ;;
     *)     guru say "no hit"
    esac

#guru say  "$key1 $key2 $key3"

guru corsair reset caps
# sleep 3

