#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

stamp_main () {    # main command parser

    case $command in
                date)
        			[ "$1" == "-h" ] && stamp=$(date +$GURU_DATE_FORMAT) || stamp=$(date +$GURU_FILE_DATE_FORMAT)
        			;;

        		time)
        			stamp=$(date +$GURU_TIME_FORMAT)
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
        			stamp="$GURU_REAL_NAME, $GURU_TEAM_NAME, $GURU_USER_PHONE, $GURU_USER_EMAIL"
                    ;;

                weekplan)
                    weekplan $@
                    exit 0
                    ;;

                picture-md)
                    [ "$1" ] && file="$GURU_LOCAL_NOTES/$GURU_USER/$(date +%Y)/$(date +%m)/pictures/$1" || file="$GURU_LOCAL_NOTES/$GURU_USER/$(date +%Y)/$(date +%m)/pictures/$(xclip -o)"
                    [[ -f "$file" ]] || exit 234
                    stamp="![]($file){ width=500px }"
                    ;;

                *)
                    echo "-- guru-client stamp help -----------------------------------------------"
                    printf "usage: guru stamp [COMMAND] \n\ncommands: \n"
                    printf "date              datestamp \n"
                    printf "time              timestamp \n"
                    printf "start             start time stamp in format HH:MM \n"
                    printf "end               end time stamp in format HH:MM \n"
                    printf "round             rounded up time stamp \n"
                    printf "signature         user signature \n"
                    printf "transaction       stansaction stamp for notes \n"
                    printf "weekplan          generates week plan (<from> <to> numeral week day) \n"
                    printf "all stamps is copied to the clipboard\n"
    esac

    printf "$stamp\n"
    printf "$stamp" | xclip -i -selection clipboard

}


weekplan () {

    declare -a day_dates day_names_en day_names_fi
    day_names_en=("Week" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
    day_names_fi=("Viikko" "Maanantai" "Tiistai" "Keskiviikko" "Torstai" "Perjantai" "Lauvantai" "Sunnuntai")
    target_file=$(guru note location $(date +$GURU_FILE_DATE_FORMAT))                                               #;echo "notefile $target_file"
    # [ "$1" ] && target_file="$1" || target_file=$(guru note location $(date +$GURU_FILE_DATE_FORMAT))                                               #;echo "notefile $target_file"
    # [ -f "$target_file" ] || exit 123

    get_dates() {
        for i in {1..7} ; do
            day_dates[$i]=$(date --date="this ${day_names_en[$i]}" +$GURU_FILE_DATE_FORMAT)                 #;echo "day_dates[$i] : $i"
        done
    }

    md_chapter () {
        depth=$(eval $(echo printf '"#%0.s"' {1..$1}))
        printf "\n$depth $2\n\n"
    }

    note_change() {
        printf " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | $1\n" >>$target_file
    }

    week_plan () {
        get_dates
        md_chapter 2 "Week plan"

        [ $1 ] && _from=$1 || _from=1
        [ $2 ] && _to=$2 || _to=5

        for ((i = $_from ; i <= $_to ; i++)); do
            md_chapter 3 "${day_names_en[$i]} ${day_dates[$i]}"
            #echo "- task:"                                                                         # Tähän myöhemmin taskit todo listalta jotka tägätty ko. päivämäärällä
        done
    }

    week_plan $1 $2 | xclip -i -selection clipboard
    note_change "week plan added"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command=$1
    shift
    stamp_main $@
    exit $?
fi



