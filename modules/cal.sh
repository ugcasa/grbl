#!/bin/bash
# guru-client calendar playground casa@ujo.guru 2022

source $GURU_BIN/common.sh

declare -g clipboard_flag=true
declare -g temp_file="/tmp/cal.tmp"

cal.help () {
    # general help
    gmsg -v1 -c white "guru-client calendar help "
    gmsg -v2
    gmsg -v1  "printout month date numbers to std and clipboard"
    gmsg -v0 "usage:    $GURU_CALL cal months|days|year <wide|single> <year> <month_list> <year> <month_list> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " year         printout year full of month date numbers "
    gmsg -v1 " months       printout day number list of given months "
    gmsg -v2 "    wide|single     wide it three on row, single just one month"
    gmsg -v1 " year-ahead   print rest of year dates"
    gmsg -v1 " days         same but no different than upper one "
    gmsg -v2 " help         printout this help "
    # TBD gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "   $GURU_CALL cal months 1 2 2005 2 3 1917 3 4"
    gmsg -v1 "   $GURU_CALL cal days wide "
    gmsg -v2
}


cal.main () {
    # command parser

    local command="$1" ; shift

    case "$command" in

        days|mouth|months)
            cal.print_month $@
            ;;

        notes)
            local _month=
            if [[ $1 ]] ; then
                    _month=$1
                    shift
                else
                    _month=$(date -d now +%m)
            fi
            [[ $GURU_FORCE ]] || clipboard_flag=
            cal.print_month note $_month $@

            ;;

        year)
            local year=$(date -d now +%Y)
            [[ $1 ]] && year=$1
            cal.print_month no-highlight $year 2 5 8 11
            ;;

        year-ahead)
            local year=$(date -d now +%Y)
            [[ $1 ]] && year=$1

            local month_list=()

            for (( i = ($(date -d now +%m) + 1) ; i < 12 ; i=$i + 3 )); do
                month_list[${#month_list[@]}]=$i
            done

            cal.print_month no-highlight $year ${month_list[@]}
            ;;

        *)
            cal.help
            ;;

        esac

    return 0
}



cal.print_month () {
    # calendar table of month days
    # wide/single (optional)
    # and a list of month numbers and years

    local year=$(date -d now +%Y)
    local month=$(date -d now +%m)
    local list=
    local item=
    local next_item=

    # limited style selection
    local _style=

    case $1 in
        single)         _style='-1' ; shift ;;
        wide)           _style='-3' ; shift ;;
        no-highlight)   _style='-h -3' ; shift ;;
        note)           _style='-h -A 2 ' ; shift ;;
    esac

    # take given list of years and months
    [[ $@ ]] && list=($@)

    # go that trough
    for (( i = 0 ; i < ${#list[@]} ; i++ )) ; do

        item=${list[$i]}

        if (( item < 13 )) ; then

            # item is a month
            month=$item

        else
            # item is a year
            year=$item
            next_item=${list[$i+1]}

            if (( next_item > 0 )) && (( next_item < 13 )) ; then
                # just change year, skip printout
                month=
                #_style=

                continue
            else
                # only year given, print whole year
                month=
                _style=
            fi
        fi

        gmsg -v3 -c dark_grey "style=$_style month=$month year=$year"
        gmsg -v3 -c dark_grey "list=(${list[@]}) item=$item"

        # save to wait
        if [[ $clipboard_flag ]] ; then
            ncal -s FI -w -b -M -h $_style $month $year >> $temp_file
        fi

        # print to user
        gmsg -v2
        ncal -s FI -w -b -M $_style $month $year

    done

    # printout all matches and remove tracks
    if [[ -f $temp_file ]] ; then
        cat $temp_file | xclip -i -selection clipboard || return 100
        rm -f $temp_file && return 0
    fi

    return 0
}


cal.install () {

    sudo apt update && sudo apt install calcurse
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    cal.main "$@"
    exit "$?"
fi

