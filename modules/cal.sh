#!/bin/bash
# guru-client calendar playground casa@ujo.guru 2022

source $GURU_BIN/common.sh

declare -g clipboard_flag=true
declare -g temp_file="/tmp/cal.tmp"

cal.help () {
    # general help
    gr.msg -v1 -c white "guru-client calendar help "
    gr.msg -v2
    gr.msg -v1  "printout month date numbers to std and clipboard"
    gr.msg -v0 "usage:    $GURU_CALL cal months|days|year <wide|single> <year> <month_list> <year> <month_list> "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " year         printout year full of month date numbers "
    gr.msg -v1 " months       printout day number list of given months "
    gr.msg -v2 "    wide|single     wide it three on row, single just one month"
    gr.msg -v1 " year-ahead   print rest of year dates"
    gr.msg -v1 " days         same but no different than upper one "
    gr.msg -v2 " help         printout this help "
    # TBD gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 "   $GURU_CALL cal months 1 2 2005 2 3 1917 3 4"
    gr.msg -v1 "   $GURU_CALL cal days wide "
    gr.msg -v2
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
                    _month=$(date -d now +%-m)
            fi
            [[ $GURU_FORCE ]] || clipboard_flag=
            cal.print_month note $_month # $@

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
    local month=$(date -d now +%-m)
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
    [[ $1 ]] && list=($@)

    # go that trough
    for (( i = 0 ; i < ${#list[@]} ; i++ )) ; do

        item=${list[$i]}
        # remove leading zeros from ncal argument
        item="${item#"${item%%[!0]*}"}"

        if (( item < 13 )) ; then

            # item is a month
            month=$item


        else
            # item is a year
            year=$item
            next_item=${list[$i+1]}

            if (( next_item > 0 )) && (( next_item < 13 )) ; then
                # just change year, skip printout
                # month=
                #_style=
                continue
            else
                # only year given, print whole year
                month=
                _style=
            fi
        fi

        gr.msg -v3 -c dark_grey "style=$_style month=$month year=$year"
        gr.msg -v3 -c dark_grey "list=(${list[@]}) item=$item"

        # save to wait
        if [[ $clipboard_flag ]] ; then
            ncal -s FI -w -b -M -h $_style $month $year >> $temp_file
        fi

        # print to user
        gr.msg -v2
        ncal -s FI -w -b -M $_style $month $year

    done

    # printout all matches and remove tracks
    if [[ -f $temp_file ]] ; then
        cat $temp_file | xclip -i -selection clipboard || return 100
        rm -f $temp_file
    fi

    return 0
}


cal.setup_caldav () {
    #
    declare config_file="/home/casa/.calcurse/caldav/config"
    declare config_folder=${config_file%%/*}
    local open_fox=true

    # install httplib2 and oauth2client for Python 3 using pip
    # pip3 install --user httplib2 oauth2client
    cal.install

    [[ -d $config_folder ]] || mkdir -p $config_folder

    touch $config_file \
        && gr.msg -c green "ok" \
        || gr.msg -c yellow "config file creation error: $?"

    gr.msg "tip: when creating project Scope: I did give all rights, but owned files rwd, other rw is better"
    gr.msg "will open links with firefox. to see links use verbose level 2 '-v2'"
    gr.msg "just print guide and exit pres 'q' "

    read -p "ready to go?" got

    case got in
            q|Q|quit|exit) open_fox= ;;
        esac

    gr.msg -c white "1) sing in to google account wanna use"
    gr.msg -v2 -c light_blue "https://myaccount.google.com/"
    [[ $open_fox ]] && firefox "https://myaccount.google.com/"

    gr.msg -c white "2) go to google cloud-resource-manager and Create a Project"
    gr.msg -v2 -c light_blue "https://console.cloud.google.com/cloud-resource-manager"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/cloud-resource-manager"

    gr.msg -c white "3) install caldav api "
    gr.msg -v2 -c light_blue "https://console.cloud.google.com/apis/library/caldav.googleapis.com"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/apis/library/caldav.googleapis.com"

    gr.msg -c white "4) go and create credentials for OAuth 2.0 Client IDs "
    gr.msg -v2 -c light_blue "https://console.cloud.google.com/projectselector2/projectselector/apis/credentials"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/projectselector2/projectselector/apis/credentials"

    gr.msg -c white "5) get the 'OAuth 2.0 Client ID and place it to guru-cli user.cfg"
    # CALCURSE_CALDAV_PASSWORD=$(pass show calcurse) calcurse-caldav
    # TBD secrets.cfg
    read -p "let me do it?" yes_man

    case yes_man in
            y|Y|Yes|yes|yep|YES)

            read -p "gimmy your ID: " tha_id
            local user_conf="$GURU_CFG/$GURU_USER/user.cfg"

            cat $user_conf | grep google] \
                || printf "\n[google]\n" >>$user_conf

            cat $user_conf | grep caldav_id= \
                && gr.msg -c yellow "already set, change manually from $user_conf" \
                || printf "caldav_id=$tha_id\n" >>$user_conf

            # take configuration in use
            source config.sh
            config.export

            ;;
            *) gr.msg -c pink "no bad man, add your self, it fine, here's file: $user_conf"
               gr.msg "go or add '[google]' chapter and fill variable 'caldav_id=with_your_ID'"
               gr.msg "then save and run '$GURU_CALL export config'"
        esac

    gr.msg -c white "6) ready to download stuff from server, all local data will be overwritten. press crtl+c if not sure"
    read -p "ready to go?" got
    sleep 3
    calcurse-caldav --init keep-remote --authcode $GURU_GOOGLE_CALDAV_ID
}


cal.sync_remote () {
    # two-way       - Copy local objects to the CalDAV server and vice versa
    # keep-remote   - Remove all local calcurse items and import remote objects
    # keep-local    - Remove all remote objects and push local calcurse items

    local method="keep-local"
    [[ $1 ]] && method=$1
    local backup_location="/tmp/calcurse-backup"
    local local_folder="/home/casa/.calcurse"
    local files=(apts todo)
    local did_mount=

    # check that mount location exist
    if [[ -d ${GURU_BACKUP_FILES[2]} ]] ; then

        backup_location="${GURU_BACKUP_FILES[2]}/${GURU_BACKUP_FILES[3]}"

    else

        if gio mount -d ${GURU_BACKUP_FILES[0]} ${GURU_BACKUP_FILES[2]} ; then
                gr.msg -c green "mounted to ${GURU_BACKUP_FILES[2]}"
                did_mount=true
                backup_location="${GURU_BACKUP_FILES[2]}/${GURU_BACKUP_FILES[3]}"
            else
                mkdir -p "$backup_location"
            fi
    fi

    # make backup folder (contains year so can be non exist)
    [[ -d $backup_location ]] || mkdir -p $backup_location

    backup_location="$backup_location/calcurse-$(date -d now +%s)"
    mkdir "$backup_location"

    for file in ${files[@]} ; do
            gr.msg "$file -> $backup_location"
            cp "$local_folder/$file" "$backup_location"
        done

    # to only get stuff from härvel go:

    calcurse-caldav --authcode $GURU_GOOGLE_CALDAV_ID

    if [[ $did_mount ]] ; then
            gio mount -u ${GURU_BACKUP_FILES[2]}
        fi
    #return $?
}


cal.install () {

    sudo apt update && sudo apt install calcurse

    # install httplib2 and oauth2client for Python 3 using pip
    pip3 install --user httplib2 oauth2client
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    cal.main "$@"
    exit "$?"
fi

