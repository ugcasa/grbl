#!/bin/bash
# guru-client calendar playground casa@ujo.guru 2022
# based on ncal and calcurse  # TBD add links to team wab pages
# primary target is to two way sync calendar data least from Google and Microsoft account for
# guru-cli platform automation needs.
# secondarily simplify and mundane terminal calendar commands

# source $GURU_BIN/common.sh # CLEAN old way to call commons

declare -g temp_file="/tmp/cal.tmp"

# placeholder for user configurations
declare -gA google

[[ -f $GURU_CFG/$GURU_USER/google.cfg ]] && source $GURU_CFG/$GURU_USER/google.cfg


cal.help () {
    gr.msg -v1 -c white "guru-client calendar help "
    gr.msg -v2
    gr.msg -v1  "printout month date numbers to std and clipboard"
    gr.msg -v0 "usage:    $GURU_CALL cal months|days|year <wide|single> <year> <month_list> <year> <month_list> "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " year         printout year full of month date numbers "
    gr.msg -v1 " months       printout day number list of given months "
    gr.msg -v1 " year-ahead   print rest of year dates"
    gr.msg -v1 " days         same but no different than upper one "
    gr.msg -v2 " upgrade      update tools "
    gr.msg -v2
    # TBD following functions
    # gr.msg -v1 -c white "output formatting options: "
    # gr.msg -v1 " --wide         wide it three on row"
    # gr.msg -v1 " --single       single just one month"
    # gr.msg -v1 " --unicode      print small as possible calendar"
    # gr.msg -v2
    gr.msg -v1 -c white "sync tools: "
    gr.msg -v1 " sync google    sync with google calendar"
    # gr.msg -v1 " sync ms        sync with Microsoft calendar"
    # gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 "   $GURU_CALL cal months 1 2 2005 2 3 1917 3 4"
    gr.msg -v1 "   $GURU_CALL cal days wide "
    gr.msg -v2
}


cal.main () {
# calendar module command parser

    local command="$1" ; shift

    case "$command" in

        upgrade|uniballs|install)
            cal.$command $@
            ;;

        days|mouth|months)
            cal.print_month $@
            ;;

        notes)
            local _month=$(date -d now +%-m)

            if [[ $1 ]] ; then
                _month=$1
                shift
            fi

            cal.print_month note $_month # $@
            ;;

        year)
            local year=$(date -d now +%Y)
            [[ $1 ]] && year=$1
            cal.print_month no-highlight $year 2 5 8 11
            ;;

        year-ahead|'+1')
            local year=$(date -d now +%Y)
            [[ $1 ]] && year=$1

            local month_list=()

            for (( i = ($(date -d now +%m) + 1) ; i < 12 ; i=$i + 3 )); do
                month_list[${#month_list[@]}]=$i
            done

            cal.print_month no-highlight $year ${month_list[@]}
            ;;

        sync)
            local service=$1
            shift
            case $service in
                google|ms)
                    cal.sync_$service $@
                    return $?
                    ;;
                setup)
                    service=$1
                    shift
                    cal.setup_$service $@ \
                        && gr.msg -c green "$service done" \
                        || gr.msg -c error "no setup for '$service'"
                    return $?
                    ;;
                *) gr.msg -c error "unknown calendar service provider '$service'"
                   return 1
               esac
            ;;

        *)
            cal.help
            ;;

        esac

    return 0
}


cal.print_month () {
# print out table of days in month
# if year/month is not given, present time is default
# example: 'cal.print_month single 2021 1 2' prints Jan and Feb of 2019.

    local year=$(date -d now +%Y)
    local month=$(date -d now +%-m)
    local list=
    local item=
    local next_item=
    local unicode=

    # limited style selection
    local style=

    case $1 in
        single)         style='-1' ; shift ;;
        wide)           style='-3' ; shift ;;
        no-highlight)   style='-h -3' ; shift ;;
        note)           style='-h -A 2 ' ; shift ;;
        unicode)        style='-h -A 2 ' ; unicode=true ; shift ;;
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
                #style=
                continue
            else
                # only year given, print whole year
                month=
                style=
            fi
        fi

        gr.msg -v3 -c dark_grey "style=$style month=$month year=$year"
        gr.msg -v3 -c dark_grey "list=(${list[@]}) item=$item"

        # # save to wait
        # if [[ $clipboard_flag ]] ; then
        #     gr.debug " ncal -s FI -w -b -M -h $style $month $year"
        #     ncal -s FI -w -b -M -h $style $month $year >> $temp_file
        # fi

        # make small unicode based calendar
        if [[ $unicode ]] ; then
            # TBD add selector terminal|editor
            gr.debug "ncal -s FI -w -b -M -h $style $month $year"
            ncal -s FI -w -b -M -h $style $month $year > $temp_file
            cal.unistrings_gnome_terminal "$(ncal -s FI -w -b -M -h $style $month $year)"
            #cal.unistrings_gnome_terminal

            continue
        fi

        # print to user
        gr.debug "ncal -s FI -w -b -M $style $month $year"
        ncal -s FI -w -b -M $style $month $year

    done

    # printout all matches and remove tracks
    if [[ -f $temp_file ]] ; then
        cat $temp_file | xclip -i -selection clipboard
        rm -f $temp_file
    fi

    return 0
}


cal.setup_google () {
# install requirements and guide trough google account, api and credential setup

    declare config_file="/home/casa/.calcurse/caldav/config"
    declare config_folder=${config_file%%/*}
    local open_fox=true

    #cal.install

    if [[ -f $config_file ]] ; then
        gr.msg -h "configuration found:"
        cat $config_file
        gr.ask "run setup an anyway, will overwrite current settings above?" || return 1
    fi

    [[ -d $config_folder ]] || mkdir -p $config_folder

    touch $config_file \
        && gr.msg -c green "ok" \
        || gr.msg -c yellow "config file creation error: $?"

    gr.msg "tip: when creating project Scope: I did give all rights, but owned files rwd, other rw is better"
    gr.msg "will open links with firefox. just print guide and exit pres 'n' "
    gr.ask "ready to go?" || open_fox=

    gr.msg -c white "1) sing in to google account"
    gr.msg -c light_blue "https://myaccount.google.com/"
    [[ $open_fox ]] && firefox "https://myaccount.google.com/"

    gr.msg -c white "2) go to google cloud-resource-manager and Create a Project"
    gr.msg -c light_blue "https://console.cloud.google.com/cloud-resource-manager"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/cloud-resource-manager"

    gr.msg -c white "3) install caldav api "
    gr.msg -c light_blue "https://console.cloud.google.com/apis/library/caldav.googleapis.com"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/apis/library/caldav.googleapis.com"

    gr.msg -c white "4) go and create credentials for OAuth 2.0 Client IDs "
    gr.msg -c light_blue "https://console.cloud.google.com/projectselector2/projectselector/apis/credentials"
    [[ $open_fox ]] && firefox "https://console.cloud.google.com/projectselector2/projectselector/apis/credentials"

    gr.msg -c white "5) get the 'OAuth 2.0 Client ID and place it to guru-cli user.cfg"
    # CALCURSE_CALDAV_PASSWORD=$(pass show calcurse) calcurse-caldav
    # TBD secrets.cfg

    if gr.ask "let guru to write config files" ; then

            read -p "your new client clientID please: " tha_id

            while ! grep ".apps.google" <<<$tha_id ; do
                gr.msg "non valid userID."
                read -p "please re enter: " tha_id
            done

            local user_conf="$GURU_CFG/$GURU_USER/user.cfg"

            cat $user_conf | grep "google[caldav_id]=" \
                && gr.msg -c yellow "already set, change manually from $user_conf" \
                || printf "google[caldav_id]==$tha_id\n" >>$user_conf

            # take configuration in use
            source config.sh
            config.export
    else

        gr.msg -c pink "config file location: $user_conf"
        gr.msg "go or add '[google]' chapter and fill variable 'caldav_id=with_your_ID'"
        gr.msg "then save and run '$GURU_CALL export config'"
    fi

    gr.msg -c white "6) ready to download stuff from server, all local data will be overwritten. (press ctrl+c if not sure)"
    read -p "ready to go?" got
    sleep 3
    calcurse-caldav --init keep-remote --authcode ${google[caldav_id]}
}


cal.sync_google () {
# two-way       - copy local objects to the CalDAV server and vice versa
# keep-remote   - remove all local calcurse items and import remote objects
# keep-local    - remove all remote objects and push local calcurse items

    local method="keep-remote" ## hmm.. google is just output? REVIEW
    [[ $1 ]] && method=$1
    #local backup_location="/tmp/calcurse-backup"
    #local local_folder="/home/casa/.calcurse"
    # local files=(apts todo)
    # local did_mount=

    # check is configuration made
    if ! [[ ${google[caldav_id]} ]] ; then
            gr.msg -c yellow "google[caldav_id] variable is empty, fill it to '$GURU_CFG/$GURU_USER/google.cfg'"
            return 111
        fi

    # if keep local method in use, why to bother to backup local? REVIEW
    # # check that mount location exist
    # if [[ -d ${GURU_BACKUP_FILES[2]} ]] ; then

    #     backup_location="${GURU_BACKUP_FILES[2]}/${GURU_BACKUP_FILES[3]}"

    # else

    #     if gio mount -d ${GURU_BACKUP_FILES[0]} ${GURU_BACKUP_FILES[2]} ; then
    #             gr.msg -c green "mounted to ${GURU_BACKUP_FILES[2]}"
    #             did_mount=true
    #             backup_location="${GURU_BACKUP_FILES[2]}/${GURU_BACKUP_FILES[3]}"
    #         else
    #             mkdir -p "$backup_location"
    #         fi
    # fi

    # # make backup folder (contains year so can be non exist)
    # [[ -d $backup_location ]] || mkdir -p $backup_location

    # backup_location="$backup_location/calcurse-$(date -d now +%s)"
    # mkdir "$backup_location"

    # for file in ${files[@]} ; do
    #         gr.msg "$file -> $backup_location"
    #         cp "$local_folder/$file" "$backup_location"
    #     done

    # to only get stuff from härvel go:

    # import authentication code to calcurse

    gr.debug "caldavid ${google[caldav_id]}"

    calcurse-caldav --init $method --authcode ${google[caldav_id]}

    # if [[ $did_mount ]] ; then
    #         gio mount -u ${GURU_BACKUP_FILES[2]}
    #     fi
    #return $?
}

cal.isint() {
# check is integer
# case is fastest https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
    case $1 in
        ''|*[!0-9]*)
            # gr.msg -c red "."
            return 1
            ;;
    esac
    # gr.msg -c green "."
}


cal.unistrings_gnome_terminal () {
# fixes gnome-terminal character length to maintain columns

   local white=('・'  '➊ ' '➋ ' '➌ ' '➍ ' '➎ ' '➏ ' '➐ ' '➑ ' '➒ ' \
                '➓ ' '⓫ ' '⓬ ' '⓭ ' '⓮ ' '⓯ ' '⓰ ' '⓱ ' '⓲ ' '⓳ ' '⓴ ')

   local  dark=('・'  '➀ ' '➁ ' '➂ ' '➃ ' '➄ ' '➅ ' '➆ ' '➇ ' '➈ ' \
                '➉ ' '⑪ ' '⑫ ' '⑬ ' '⑭ ' '⑮ ' '⑯ ' '⑰ ' '⑱ ' '⑲ ' '⑳ ' \
                '㉑' '㉒' '㉓' '㉔' '㉕' '㉖' '㉗' '㉘' '㉙' '㉚' '㉛' '㉜' '㉝' \
                '㉞' '㉟' '㊱' '㊲' '㊳' '㊴' '㊵' '㊶' '㊷' '㊸' '㊹' '㊺' '㊻' \
                '㊼' '㊽' '㊾' '㊿' '㋛' '㋡')

   local  order=(' ' a b c d e f g h i j k l m n o p q r s t u v w x y z å ä ö)
   local  alpha=('・'  '🅐 ' '🅑 ' '🅒 ' '🅓 ' '🅔 ' '🅕 ' '🅖 ' '🅗 ' '🅘 ' \
                 '🅙 ' '🅚 ' '🅛 ' '🅜 ' '🅝 ' '🅞 ' '🅟 ' '🅠 ' '🅡 ' '🅢 ' \
                 '🅣 ' '🅤 ' '🅥 ' '🅦 ' '🅧 ' '🅨 ' '🅩 ' '🅞 ' '🅐 ' '🅞 ' '㋛')

   local monthname="September 2023"
   local header=('🆅  ' '🅜 ' '🅣 ' '🅚 ' '🅣 ' '🅟 ' '🅛 ' '🅢 ')

   # for (( i = 0; i < ${#white[@]}; i++ )); do
   #      gr.kv "$i" "${white[$i]}"
   # done

   # for (( i = 0; i < ${#dark[@]}; i++ )); do
   #      gr.kv "$i" "${dark[$i]}"
   # done

   # for (( i = 0; i < ${#alpha[@]}; i++ )); do
   #      gr.kv "${pointer[$i]}" "${alpha[$i]}"
   # done


   message=($@)

    for (( i = 0; i < ${#message[@]}; i++ )); do

        part=${message[$i]}

        # numbers
        if cal.isint $part ; then
            gr.msg -c white -n "${dark[$part]}"
            continue
        fi

        chars=($(sed 's/./& /g' <<<$part))
        specials=($'\n' '|')

        for char in ${chars[@]} ; do
            # special characters
            if [[ $char =~ [${specials[@]}] ]] ; then
                printf "$char"
                continue
            fi

            # find alphabet location
            for(( a = 0; a < ${#order[@]}; a++ )); do
                # gr.msg -c light_blue "." -n
                case ${order[$a]} in ${char,,}) break ;; esac
            done

            # printf "%s%s" "${alpha[$a]}" ""
            gr.msg -c deep_pink -n "${alpha[$a]}"
        done


    done
}


cal.uniballs () {

    cat << EOL
    ➊ ➋ ➌ ➍ ➎ ➏ ➐ ➑ ➒ ➓ ⓫ ⓬ ⓭ ⓮ ⓯ ⓰ ⓱ ⓲ ⓳ ⓴
    ➀ ➁ ➂ ➃ ➄ ➅ ➆ ➇ ➈ ➉ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳
    ㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛㉜㉝㉞㉟㊱㊲㊳㊴㊵㊶㊷
    ㊸㊹㊺㊻㊼㊽㊾㊿㊡㊤🅐 🅑 🅒 🅓 🅔 🅕 🅖 🅗 🅘 🅙 🅚
    🅛 🅜 🅝 🅞 🅟 🅠 🅡 🅢 🅣 🅤 🅥 🅦 🅧 🅨 🅩 ㋛㋡・
EOL
}


cal.unical () {

    cat << EOL
  Lokakuu 2023
🆅  🅜 🅣 🅚 🅣 🅟 🅛 🅢
㉟ ・・・・➀ ➁ ➂
㊱ ➃ ➄ 🅙 🅡 ➇ ➈ ➉
㊲ 🅞 🅤 🅛 🅤 🅝 ⑯ ⑰
㊳ ⑱ ⑲ 🅡 ㉑㉒🅐 ㉔
㊴ ㉕🅑 ㉗㉘㋛㉚・
EOL
}


cal.uniclocks () {
    cat << EOL
    🕐🕜🕑🕝🕒🕞🕓🕟🕔🕠🕕🕡🕖🕢🕗🕣🕘🕤🕙
    🕥🕚🕦🕛🕧
EOL
}


cal.upgrade() {
# upgrade needed tools, ofter youtube changes shit causing weird errors

    sudo apt update && guru system upgrade
    # get new version of
    pip3 install --upgrade pip
    pip3 install --user --upgrade yt-dlp
    return 0
}


cal.install () {

    sudo apt update && sudo apt install calcurse ncal

    # install httplib2 and oauth2client for Python 3 using pip
    pip3 install --user httplib2 oauth2client
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GURU_RC"
    cal.main "$@"
    exit "$?"
fi

