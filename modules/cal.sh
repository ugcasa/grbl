#!/bin/bash
# guru-client calender playground casa@ujo.guru 2022

source $GURU_BIN/common.sh

cal.help () {
    # general help
    gmsg -v1 -c white "guru-client calender help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL cal mounth(s) year mounth(s) ..."
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " mounths  printout  "
    gmsg -v2 "          varies typos are accepted"
    gmsg -v3 "          mouths, mouths, moutht, mouths, mounts, mounth"
    gmsg -v2 " help     printout this help "
    # TBD gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "   $GURU_CALL cal 4 5 2020 4 5 2100 4 5"
    gmsg -v2
}


cal.main () {
    # command parser

    local command="$1" ; shift

    case "$command" in

        days|mouth|moutht|mounth)
            cal.months $@
            ;;

        months|mouths|mouths|mouths|mounts)
            cal.months $@
            ;;

        year)
            local year=$(date -d now +%Y)
            [[ $1 ]] && year=$1
            cal.months wide $year 2 6 9 12
            ;;

        *)
            cal.help
            ;;
        esac
    return 0
}



cal.months () {
    # mouth caleder printout

    local year=$(date -d now +%Y)
    local list=$(date -d now +%m)
    local item=
    local month=
    local _style=
    case $1 in
        single) _style='-1' ; shift ;;
        wide)   _style='-3' ; shift ;;
    esac


    [[ $@ ]] && list=($@)

    for (( i = 0; i < ${#list[@]}; i++ )); do

        item=${list[$i]}
        next_item=${list[$i+1]}

        if (( item > 12 )) ; then

            year=$item

            if [[ ${list[$i+1]} ]] && (( next_item < 13 ))  ; then
                month=
                continue
            else
                month=
            fi

        else

            month=$item
        fi

        ncal -s FI -w -b -M -h $_style $month $year  >> /tmp/cal.tmp
        echo
        ncal -s FI -w -b -M $_style $month $year

    done

    cat /tmp/cal.tmp | xclip -i -selection clipboard
    rm -f /tmp/cal.tmp

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    cal.main "$@"
    exit "$?"
fi

