#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019



stamp_main () {
    # main command parser

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

                weekplan)
                    weekplan $@
                    exit 0
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
                    printf "transaction       stansaction stamp for notes \n"   
                    printf "weekplan          generates week plan (<from> <to> numeral week day) \n"   
                    printf "all stamps will also be to copied to clipboard\n"  
                    exit 1
    esac

    printf "$stamp\n"
    printf "$stamp" | xclip -i -selection clipboard


}


weekplan () {

    declare -a day_dates day_names
    date_format='%d.%-m.%Y'
    time_format='%H:%M:%S'
    day_names=("Week" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")

    # Purkka
    noteDir=$GURU_NOTES/$GURU_USER/$(date +%Y/%m)
    noteFile=$GURU_USER"_notes_"$(date +%Y%m%d).md      
    GURU_DAILY_NOTE="$noteDir/$noteFile"

    get_dates() {
        for i in {1..7} ; do    
            day_dates[$i]=$(date --date="this ${day_names[$i]}" +$date_format)              #;echo "day_dates[$i] : $i"
        done
    }

    md_chapter () {     
        depth=$(eval $(echo printf '"#%0.s"' {1..$1}))
        printf "\n $depth $2\n\n"
    }

    note_change() {
        printf " $(date +$date_format)-$(date +$time_format) | $GURU_USER | $1\n" >>$GURU_DAILY_NOTE
    }

    week_plan () {
        get_dates 
        md_chapter 2 "Week plan"    

        [ $1 ] && _from=$1 || _from=1 
        [ $2 ] && _to=$2 || _to=5 
        
        for ((i = $_from ; i <= $_to ; i++)); do  
            md_chapter 3 "${day_names[$i]} ${day_dates[$i]}"
            #echo "- task:"                                                                         # Tähän myöhemmin taskit todo listalta jotka tägätty ko. päivämäärällä
        done
    }

    week_plan $1 $2 | xclip -i -selection clipboard
    note_change "week plan added"
}



me=${BASH_SOURCE[0]}
if [[ "$me" == "${0}" ]]; then
    command=$1
    shift
    stamp_main $@
    exit $?
fi



