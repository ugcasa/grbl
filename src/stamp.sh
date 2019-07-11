#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

command="$1"
shift

case $command in
            date)
    			[ "$1" == "-h" ] && stamp=$(date +%-d.%-m.%Y) || stamp=$(date +%Y%m%d)			
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
                echo $"Usage: guru stamp [COMMAND]"
                echo "Commands:"
                printf "date        \t datestamp \n"
                printf "time        \t timestamp \n"
                printf "start       \t start time stamp in format HH:MM \n"                
                printf "end         \t end time stamp in format HH:MM \n"
                printf "round       \t rounded up time stamp \n"    #>TODO poisko?
                printf "signature   \t user signature \n"   
                printf "transaction \t stansaction stamp for notes r\n"   
                printf "all stamps will also be to copied to clipboard\n"  
                exit 1
esac

printf "$stamp\n"
printf "$stamp" | xclip -i -selection clipboard