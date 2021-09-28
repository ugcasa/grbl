#!/bin/bash
# guru-client backup system casa@ujo.guru 2021

source $GURU_BIN/common.sh

backup.help () {
    # general help

    gmsg -v1 -c white "guru-client backup help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL backup status|list|poll|install|remove  "
    gmsg -v0 "          $GURU_CALL backup <category> now|at <YYYYMMDD> <HH:MM> "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " now                      make backup now "
    gmsg -v1 " at <H:M>                 make backup at time, 24h time only "
    gmsg -v1 " at <YYYYMMDD> <H:M>      make backup at date, 'tomorrow 12:00' is valid "
    gmsg -v1 " list|ls                  list of backups "
    gmsg -v1 " restore                  not clear hot to be done  "
    gmsg -v1 " install                  install client requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 " $GURU_CALL backup status           # printout current backup status"
    gmsg -v1 " $GURU_CALL backup work now         # backup category 'work'"
    gmsg -v1 " $GURU_CALL backup family at 21:00  # backup family stuff at evening "
    gmsg -v1 " $GURU_CALL backup photos at Monday # backup family stuff next Monday"
    gmsg -v2
}


backup.main () {
    # command parser

    local command="$1" ; shift
    case "$command" in

                ls|list|now|status|help|install|poll|all|at)
                    backup.$command  "$@"
                    return $? ;;

                "")
                    gmsg -c yellow "missing parameter"
                    return 0 ;;

                *)  gmsg -c yellow "unknown command"
                    # backup.help
                    return 0 ;;
        esac

    return 0
}



backup.config () {
    # get tunnel configuration an populate common variables

    declare -la backup_name=($1)
    declare -la header=(store method from)
    declare -ga active_list=(${GURU_BACKUP_ACTIVE[@]})
    declare -g backup_indicator_key="f$(daemon.poll_order backup)"


    # check is enabled
    if ! [[ $GURU_BACKUP_ENABLED ]] ; then
            gmsg -c dark_grey "backup module disabled"
            return 0
        fi

    # exit if not in list
    if ! echo "${active_list[@]}" | grep "$backup_name" >/dev/null ; then
        gmsg -c yellow "no configuration for backup $backup_name"
        return 1
        fi

    gmsg -v3 -c white "active_list: ${active_list[@]}"

    for bu_name in ${active_list[@]} ; do
            if [[ "$bu_name" == "$backup_name" ]] ; then
                local data="GURU_BACKUP_${bu_name^^}[@]" ; data=(${!data})
                gmsg -v3 -c pink "${data[@]}"
                declare -l store_device=${data[0]}
                declare -l method=${data[1]}
                declare -l from=${data[2]}
                local store="GURU_BACKUP_${store_device^^}" ; store=${!store}
                gmsg -v3 -c deep_pink "|$store_device|$store|$method|$from|"
                break
            fi
        done

        if echo $from | grep ":" >/dev/null ; then
            declare -g from_user=$(echo $from | cut -d ":" -f1)
            declare -g from_domain=$(echo $from | cut -d ":" -f2)
            declare -g from_port=$(echo $from | cut -d ":" -f3)
            declare -g from_location=$(echo $from | cut -d ":" -f4)
        else
            declare -g from_location=$from
        fi

        if echo $store | grep ":" >/dev/null ; then
            declare -g store_user=$(echo $store | cut -d ":" -f1)
            declare -g store_domain=$(echo $store | cut -d ":" -f2)
            declare -g store_port=$(echo $store | cut -d ":" -f3)
            declare -g store_location=$(echo $store | cut -d ":" -f4)
        else
            declare -g store_location=$store
        fi

        declare -g storing_method=$method
        declare -g honeypot_file="$from_location/honeypot.txt"

        return 1

    return 0
}



backup.status () {
    # check latest backup is reachable and returnable.


    local backup_indicator_key="f$(daemon.poll_order backup)"
    local backup_data_folder=$GURU_SYSTEM_MOUNT/backup

    gmsg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_BACKUP_ENABLED ]] ; then
            gmsg -n -v1 -c green -k $backup_indicator_key \
                "enabled, "
        else
            gmsg -v1 -c reset -k $backup_indicator_key \
                "disabled"
            return 1
        fi

    if [[ -f $backup_data_folder/next ]] ; then
            local epic_backup=$(cat $backup_data_folder/next)
            gmsg -v1 -c aqua -k $backup_indicator_key \
                "scheduled backup at $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        else
            gmsg -v1 -c reset -k $backup_indicator_key \
                "no scheduled backups"
            return 0

        fi

    if [[ $(date '+%s') -ge $epic_backup ]] ; then

        if backup.all ; then
            epic_backup=$(( $epic_backup + 86400))
            echo $epic_backup > $backup_data_folder/next
            gmsg -c white \
                "next backup scheduled to $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        fi
    fi

    return 0
}


backup.list () {
    # list available backups and its status

    local ifs=$IFS
    local tall=0

    return 0
}


backup.ls () {
    # alias for list

    backup.list $@
    return $?
}


backup.at () {
    # set date and time for next backup

    [[ $1 ]] && local backup_date=$1 || read -p "backup date (YYMMDD): " backup_date
    shift
    [[ $1 ]] && local backup_time=$1 || read -p "backup time (H:M): " backup_time
    shift

    local backup_data_folder=$GURU_SYSTEM_MOUNT/backup

    [[ -d $backup_data_folder ]] || mkdir -p $backup_data_folder

    # TBD all kind of checks for user input

    local epic_now=$(date '+%s')
    local epic_backup=$(date -d "$backup_date $backup_time" '+%s')

    if [[ $epic_now -ge $epic_backup ]] ; then
        gmsg "that is past, try again"
        return 1
    fi

    echo $epic_backup > "$backup_data_folder/next"

    # if daemon is not running (computer sleeping) backup is not run
    # overdue backups shall be run at next start
    return 0
}


backup.now () {
    # make backup now

    backup.config $1
    local from_param="$from_location"
    local store_param="$store_location"

    gmsg -v3 "backup active" -c $GURU_BACKUP_COLOR -k $backup_indicator_key
    #local command_param="-avh '-e ssh -p $from_port' --progress --update"

    if [[ $from_domain ]] && [[ $store_domain ]] ; then
            from_param="$from_user@$from_domain 'rsync -ave ssh $from_location $store_user@$store_domain:$from_port:$store_location'"
            store_param=
    elif [[ $from_domain ]] ; then
            command_param="-a -e 'ssh -p $from_port' --progress --update"
            from_param="$from_user@$from_domain:$from_location"
    elif [[ $store_domain ]] ; then
            command_param="-a -e 'ssh -p $store_port' --progress --update"
            store_param="$store_user@$store_domain:$store_location"
        fi

    if ! [[ $store_domain ]] && ! [[ $store_param ]] ; then
            mkdir -p $store_param
        fi

    # crypto virus honeypot file
    # if crypted or copied to another file ending cancel backup

    #echo $honeypot_file
    if [[ $from_domain ]] ; then
       gmsg -n "getting honeypot file.. "
       eval $storing_method $command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null && gmsg -c green "ok"
    fi

    if [[ -f /tmp/honeypot.txt ]] ; then
            gmsg -n "checking honeypot file.. "
            local contain=($(cat /tmp/honeypot.txt))
            if ! [[ ${contain[3]} == "honeypot" ]] ; then
                gmsg -c yellow \
                     "honeypot file changed! got '${contain[3]}' when 'honeypot' expected."
                gmsg -c light_blue "${contain[@]}"
                gmsg -c red -k $backup_indicator_key \
                     "backup canceled cause of potential crypto virus action detected!"
                return 100

                fi
        gmsg -c green "ok"
        #rm -f /tmp/honeypot.txt
        fi

    eval $storing_method $command_param $from_param $store_param

    if [[ $? -gt 0 ]] ; then
            gmsg -v1 "$from_location error: $storing_method $?" \
                 -c red -k $backup_indicator_key
            return 12
        else
            gmsg -v3 "$from_location ok" \
                 -c green -k $backup_indicator_key
            return 0
        fi
}

backup.all () {
    # backup all in activelist

    local item=1;
    local error=0

    for source in ${GURU_BACKUP_ACTIVE[@]} ; do
        gmsg -c dark_golden_rod "backing up $item/${#GURU_BACKUP_ACTIVE[@]}.."
        backup.now $source || (( _error++ ))
        (( item++ ))
        done


    if [[ $_error -gt 0 ]] ; then
        gmsg -v1 "$_error errors, check log above" -c yellow -k $backup_indicator_key
        return 12
    else
        gmsg -v3 "backup done" -c reset -k $backup_indicator_key
        return 0
    fi


}



backup.poll () {
    # poll functions

    # TBD: write cooperative standard function for timed processes
    local backup_indicator_key="f$(daemon.poll_order backup)"
    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: backup status polling started" -k $backup_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: backup status polling ended" -k $backup_indicator_key
            ;;
        status )
            backup.status
            # check is backup is overdue, launch here if so
            ;;
        *)  gmsg -c dark_grey "function not written"
            return 0
        esac
}


backup.install () {
    # install needed tools

    sudo apt update && \
    sudo apt install ssh scp rsync sshfs pv
    return $?
}


backup.remove () {
    #sudo apt remove xxx

    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    backup.main "$@"
    exit "$?"
fi

