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
    gmsg -v1 " at <YYMMDD> <H:M>        make backup at date"
    gmsg -v1 " ls                       list of backups "
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

                ls|now|restore|status|help|install|poll|all|at)
                    backup.$command "$@"
                    return $? ;;

                "")
                    gmsg -c yellow "missing parameter"
                    return 0 ;;

                *)  gmsg -c yellow "unknown command"
                    # backup.help
                    return 0 ;;
        esac
    backup.status
    return $?
}



backup.config () {
    # get tunnel configuration an populate common variables

    declare -ga backup_name=($1)
    declare -la header=(store method from ignore)
    declare -ga active_list=(${GURU_BACKUP_ACTIVE[@]})
    declare -g backup_indicator_key="f$(daemon.poll_order backup)"


    # check is enabled
    if ! [[ $GURU_BACKUP_ENABLED ]] ; then
            gmsg -c dark_grey "backup module disabled"
            return 1
        fi

    # exit if not in list
    if ! echo "${active_list[@]}" | grep "$backup_name" >/dev/null ; then
        gmsg -c yellow "no configuration for backup $backup_name"
        return 2
        fi

    gmsg -v3 -c white "active_list: ${active_list[@]}"

    for bu_name in ${active_list[@]} ; do
            if [[ "$bu_name" == "$backup_name" ]] ; then
                local data="GURU_BACKUP_${bu_name^^}[@]" ; data=(${!data})
                gmsg -v3 -c pink "${data[@]}"
                declare -l store_device=${data[0]}
                declare -l method=${data[1]}
                declare -l from=${data[2]}
                declare -l ignore="${data[3]//:/" "}"
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

        declare -ga backup_ignore=($ignore)
        declare -g backup_method=$method
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

    if ! [[ -f $backup_data_folder/next ]] ; then
            gmsg -v1 -c green -k $backup_indicator_key \
                "no scheduled backups"
            return 0
        fi

    local epic_backup=$(cat $backup_data_folder/next)
    local diff=$(( $epic_backup - $(date '+%s') ))

    # indicate backup time
    if [[ $diff -lt 10000 ]] ; then
        # indicate that backup is close ~3h
        gmsg -n -v1 -c aqua_marine -k $backup_indicator_key \
            "scheduled backup at $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        # indicate that that backup is very soon, ~minutes
        [[ $diff -lt $GURU_DAEMON_INTERVAL ]] && gmsg -n -v1 -c deep_pink -k $backup_indicator_key \ "($diff seconds)"
        echo
    else
        # all fine, no backup for three least hours
        gmsg -n -v1 -c green -k $backup_indicator_key "on service "
        gmsg -v1 -c reset "next backup $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
    fi
    return 0
}


backup.ls () {
    # list available backups and its status

    for source in ${GURU_BACKUP_ACTIVE[@]} ; do
            gmsg -n -c light_blue "$source"
        done

    return 0
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

backup.restore () {
    echo TBD
    return 127
}


backup.wekan () {
    # take a database dump and copy it to location set in user.cfg where normal process can copy it to local
    local _domain=$1
    local _port=$2
    local _user=$3
    local _location=$4

    # stop container
    gmsg -n "stopping docker container.. "
    ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan >/dev/null \
        && gmsg -c green "ok" \
        || gmsg -c yellow "error $?"

    # delete current dump
    gmsg -n "delete last dump.. "
    ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump >/dev/null \
        && gmsg -c green "ok" \
        || gmsg -c yellow "error $?"

    # take a dump
    gmsg -n "take a dump /data/dump.. "
    ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump 2>/dev/null \
        && gmsg -c green "ok" \
        || gmsg -c yellow "error $?"

    # copy to where to rsyck it to final location
    gmsg -n "copy to ${_location}.. "
    ssh ${_user}@${_domain} -p ${_port} -- "[[ -d ${_location} ]] || mkdir -p ${_location}>/dev/null "

    ssh ${_user}@${_domain} -p ${_port} -- docker cp wekan-db:/data/dump ${_location} >/dev/null \
        && gmsg -c green "ok" \
        || gmsg -c yellow "error $?"

    # start container
    gmsg -n "starting docker container.. "
    ssh ${_user}@${_domain} -p ${_port} -- docker start wekan >/dev/null \
        && gmsg -c green "ok" \
        || gmsg -c yellow "error $?"

    return 0
}


backup.now () {
    # check things and if pass then make backup

    # get config of backup name
    backup.config $1

    #
    local from_param="$from_location"
    local store_param="$store_location"
    local command_param="-a --progress --update"

    gmsg -v3 "backup active" -c $GURU_BACKUP_COLOR -k $backup_indicator_key
    #local command_param="-avh '-e ssh -p $from_port' --progress --update"

    # if server to server copy..
    if [[ $from_domain ]] && [[ $store_domain ]] ; then
            # build server to server copy command variables
            read -p  "NEVER TESTED!! continue? "
            from_param="$from_user@$from_domain 'rsync -ave ssh $from_location $store_user@$store_domain:$from_port:$store_location'"
            store_param=

        # .. or if server to local copy..
        elif [[ $from_domain ]] ; then
            # build remote to local command variables
            command_param="-a -e 'ssh -p $from_port' --progress --update"

            if [[ $backup_ignore ]] ; then
                for _ignore in  ${backup_ignore[@]} ; do
                    command_param="$command_param --exclude '*$_ignore'"
                done
            fi

            from_param="$from_user@$from_domain:$from_location"

        # .. or if local to server copy..
        elif [[ $store_domain ]] ; then
            # build local to remote command variables
            read -p  "NEVER TESTED!! continue? "
            command_param="-a -e 'ssh -p $store_port'"
            store_param="$store_user@$store_domain:$store_location"
        # # ..else local to local
        # else
        #     command_param="-a --progress --update"
        #     store_param="$store_location"
        #     from_param="$from_location"
        fi

    # make dir if not exist (year changes)
    if ! [[ $store_domain ]] && [[ $store_location ]] ; then
            mkdir -p $store_location
        fi

    case $backup_method in

            wekan)  backup.wekan $from_domain $from_port $from_user $from_location || return $?
                    # continue
                    ;;
            wiki)   echo "wiki"
                    # continue
                    ;;
            git)    echo "wiki"
                    # continue
                    ;;
        esac

    # crypto virus checks only if from location is remote and store location is local
    if [[ $from_domain ]] && ! [[ $store_domain ]] ; then

        # wannacry test
        local list_of_files=($(ssh $from_user@$from_domain "find $from_location -type f -name '*' "))

        for file in ${list_of_files[@]} ; do

            case $file in

                *.WNCRY*)
                        gmsg -c red -k $backup_indicator_key \
                            "POTENTIAL VIRUS: wannacry tracks detected!"
                        gmsg -c light_blue "$file"
                        gmsg -c yellow "backup of $from_location canceled"
                        return 101
                        ;;

                 *WORM*)
                        echo "TBD other virus track marks here"
                        return 102
                        ;;
                esac
        done

        # check if honeypot file exists
        if ssh $from_user@$from_domain "test -e $honeypot_file" ; then
            [[ -f /tmp/honeypot.txt ]] && rm -f /tmp/honeypot.txt
            gmsg -n "getting honeypot file.. "
            # get honeypot file

            if eval rsync "$command_param" $from_user@$from_domain:$honeypot_file /tmp >/dev/null ; then
                gmsg -c green "ok"
            else
                gmsg -c yellow "cannot get honeypot file"
            fi
        fi
    fi

    # check is text in honeypot.txt file changed
    if [[ -f /tmp/honeypot.txt ]] ; then
            gmsg -n "checking honeypot file.. "
            local contain=($(cat /tmp/honeypot.txt))
            rm -f /tmp/honeypot.txt
            if ! [[ ${contain[3]} == "honeypot" ]] ; then
                gmsg -c yellow \
                     "honeypot file changed! got '${contain[3]}' when 'honeypot' expected."
                gmsg -c light_blue "${contain[@]}"
                gmsg -c red -k $backup_indicator_key \
                     "backup canceled cause of potential crypto virus action detected!"
                #export GURU_BACKUP_ENABLED=false
                return 102
            fi
        gmsg -c green "ok"
    fi

    eval rsync "$command_param" $from_param $store_param/$backup_name

    local _error=$?
    if [[ $_error -gt 0 ]] ; then
            gmsg -v1 "$from_location error: $backup_method $_error" \
                 -c red -k $backup_indicator_key
            return 12
        else
            gmsg -v3 "$from_location ok" \
                 -c green -k $backup_indicator_key
            return 0
        fi
}


backup.all () {
    # backup all in active list

    local item=1;
    local _error=0

    for source in ${GURU_BACKUP_ACTIVE[@]} ; do
            gmsg -n -c dark_golden_rod "backing up $source $item/${#GURU_BACKUP_ACTIVE[@]}.. "
            #if ! [[ $GURU_BACKUP_ENABLED ]] ; then gmsg -c yellow "canceled" ; break ; fi
            backup.now $source || (( _error++ ))
            (( item++ ))
        done

    if [[ $_error -gt 0 ]] ; then
            gmsg -v1 "$_error warnings, check log above" -c yellow -k $backup_indicator_key
            return 12
        else
            gmsg -v3 "backup done" -c reset -k $backup_indicator_key
            return 0
        fi
}

backup.scheduled () {
        # run an set scheduled backup

        local backup_data_folder=$GURU_SYSTEM_MOUNT/backup
        local epic_backup=$(cat $backup_data_folder/next)

        if ! [[ -f $backup_data_folder/next ]] ; then
            return 0
        fi

        if [[ $(date '+%s') -lt $epic_backup ]] ; then
            return 0
        fi

        backup.all
        local _error=$?

        if [[ $_error -lt 100 ]] ; then
            epic_backup=$(( $epic_backup + 86400))
            echo $epic_backup > $backup_data_folder/next
            gmsg -c white \
                "next backup scheduled to $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
            return $_error
        fi
}


backup.poll () {
    # poll functions

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
            backup.scheduled
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
    # remove stuff

    gmsg "no point ro remove so basic tools.."
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    backup.main "$@"
    exit "$?"
fi

