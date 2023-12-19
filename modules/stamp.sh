#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019
source common.sh

stamp.main () {
# main command parser

    local command=$1 ; shift
    local stamp=""

    case $command in
            date)       stamp=$(date +$GURU_FORMAT_FILE_DATE) ;;
            time)       stamp=$(date +$GURU_FORMAT_TIME) ;;
            nicedate)   stamp=$(date +$GURU_FORMAT_NICE_DATE) ;;
            datetime)   stamp=$(date +$GURU_FORMAT_FILE_DATE-$GURU_FORMAT_TIME) ;;
            start)      stamp=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") ;;
            end)        stamp=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M") ;;
            round)      stamp=$(date -d @$(( (($(date +%s) + 450) / 900) * 900)) "+%H:%M") ;;
            transaction)
                    stamp="## Transaction\n\tAccount\t\tAmount\t\tVAT\tto/frm\tDescription\n\t" ;;
            signature)
                    stamp="$GURU_USER_FULL_NAME/$GURU_USER_TEAM $GURU_USER_PHONE $GURU_USER_EMAIL" ;;
            weekplan)
                    stamp.weekplan $@ ; return 0 ;;
            picture-md)
                [ "$1" ] && file="$GURU_LOCAL_NOTES/$GURU_USER/$(date +%Y)/$(date +%m)/pictures/$1" || file="$GURU_LOCAL_NOTES/$GURU_USER/$(date +%Y)/$(date +%m)/pictures/$(xclip -o)"
                [[ -f "$file" ]] || exit 234
                stamp="![]($file){ width=500px }"
                ;;

            status)  gr.msg -v1 -t "${FUNCNAME[0]}: no status information" ; return 0 ;;
            help|*) stamp.help ; return 0 ;;
        esac

    gr.msg "$stamp"
    # copy output to all clipbards
    printf "$stamp" | timeout 0.5 xclip -selection primary
    printf "$stamp" | timeout 0.5 xclip -selection secondary
    printf "$stamp" | timeout 0.5 xclip -selection clipboard
}


stamp.help () {
    gr.msg -v1 -c white "guru-client stamp help "
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL stamp [date|time|start|end|round|transaction|signature|picture-md] "
    gr.msg -v2
    gr.msg -v1 -c white  "commands: "
    gr.msg -v1  "date              datestamp "
    gr.msg -v1  "time              timestamp "
    gr.msg -v1  "start             start time stamp in format HH:MM "
    gr.msg -v1  "end               end time stamp in format HH:MM "
    gr.msg -v1  "round             rounded up time stamp "
    gr.msg -v1  "signature         user signature "
    gr.msg -v1  "transaction       stansaction stamp for notes "
    gr.msg -v1  "weekplan          generates week plan (<from> <to> numeral week day) "
    gr.msg -v1  "all stamps is copied to the clipboard"
    gr.msg -v2
}


stamp.weekplan () {

    declare -a day_dates day_names_en day_names_fi
    day_names_en=("Week" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
    day_names_fi=("Viikko" "Maanantai" "Tiistai" "Keskiviikko" "Torstai" "Perjantai" "Lauvantai" "Sunnuntai")
    target_file=$(guru note location $(date +$GURU_FORMAT_FILE_DATE))                                               #;echo "notefile $target_file"
    # [ "$1" ] && target_file="$1" || target_file=$(guru note location $(date +$GURU_FORMAT_FILE_DATE))                                               #;echo "notefile $target_file"
    # [ -f "$target_file" ] || exit 123

    get_dates() {
        for i in {1..7} ; do
            day_dates[$i]=$(date --date="this ${day_names_en[$i]}" +$GURU_FORMAT_FILE_DATE)                 #;echo "day_dates[$i] : $i"
        done
    }

    md_chapter () {
        depth=$(eval $(echo printf '"#%0.s"' {1..$1}))
        printf "\n$depth $2\n\n"
    }

    note_change() {
        printf " $(date +$GURU_FORMAT_FILE_DATE)-$(date +$GURU_FORMAT_TIME) | $GURU_USER | $1\n" >>$target_file
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
    source note.sh
    note.change "week plan added"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GURU_RC"
    #command=$1 ; shift
    stamp.main $@
    exit $?
fi



