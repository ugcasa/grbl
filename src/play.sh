#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

command="$1"
shift

case $command in

            by|band|artist)
                command="mpsyt set show_video True, set search_music True, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            backroung|--bg)
                command="for i in {1..3}; do mpsyt set show_video False, set search_music True, //$@, "'$i'", 1-, q; done"  
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "     
                ;;

            video|youtube)
                command="mpsyt set show_video True, set search_music False, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            upgrade)
                sudo -H pip3 install --upgrade youtube_dl    			
    			;;

            stop|end)
                pkill mpsyt
                ;;

            help|*)           
                echo $"Usage: $0 {start|end|..|}"
                exit 1             
esac
