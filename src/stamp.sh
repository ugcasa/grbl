#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

command="$1"
shift

case $command in
            date)
    			[ "$1" == "-h" ] && stamp=$(date +%Y.%m.%d) || stamp=$(date +%Y%m%d)			
    			;;

    		time)
    			stamp=$(date +%H:%M:%S)
    			;;

            start)
                stamp=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
                ;;
             
            end)
                stamp=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M")          
                ;;
             
            round)
    			stamp=$(date -d @$(( (($(date +%s) + 450) / 900) * 900)) "+%H:%M")
                ;;

            transaction)
                stamp="## Transaction\n\tAccount\t\tAmount\t\tVAT\tto/frm\tDescription\n\t"            
                ;;

            signature)
    			stamp="Juha Palm, ujo.guru, +358 400 810 055, juha.palm@ujo.guru"
                ;;
             
            *)
                echo $"Usage: $0 {start|end|..|}"
                exit 1
esac

printf "$stamp\n"
printf "$stamp" | xclip -i -selection clipboard