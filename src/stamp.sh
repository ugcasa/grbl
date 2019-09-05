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
             
            picture-md)
                file="$GURU_NOTES/$GURU_USER/$(date +%Y)/$(date +%m)/pictures/$(xclip -o)"
                [[ -f $file ]] || exit 234
                stamp="![]($file){ width=500px }" 
                ;;

            *)
                printf "usage: guru stamp [COMMAND] \ncommands: \n"                
                printf "date              datestamp \n"
                printf "time              timestamp \n"
                printf "start             start time stamp in format HH:MM \n"                
                printf "end               end time stamp in format HH:MM \n"
                printf "round             rounded up time stamp \n"    #>TODO poisko?
                printf "signature         user signature \n"   
                printf "transaction       stansaction stamp for notes r\n"   
                printf "all stamps will also be to copied to clipboard\n"  
                exit 1
esac

printf "$stamp\n"
printf "$stamp" | xclip -i -selection clipboard