#!/bin/bash
# guru-client backup system module
# automated backups from server to local, local to local or server to server based on rsync archiving functionalities.
# launching is based on guru daemon.sh poll request, not on crond mainly to avoid permission issues and shit.
# can be run individually but needs specific set of environment variables (~/.gururc).
# more of bash shit github.com/ugcasa/guru-client casa@ujo.guru 2021

source common.sh


backup.help () {
    # general help

    gmsg -v1 -c white "guru-cli backup help "
    gmsg -v2
    gmsg -v0 "usage:  $GURU_CALL backup <entry_name> at <YYYYMMDD> <HH:MM> "
    gmsg -v1 "        $GURU_CALL backup status|ls|restore|poll|install|remove  "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " <empty>                  make daily backup now "
    gmsg -v1 " <entry_name>             run <entry_name> backup right away "
    gmsg -v2 "     at <YYMMDD> <H:M>    make backup at date and time    "
    gmsg -v1 " ls                       list of backups "
    gmsg -v1 " status                   printout status string"
    gmsg -v2 " restore                  not clear hot to be done  "
    gmsg -v2 " install                  install client requirements "
    gmsg -v2 " remove                   remove installed requirements "
    gmsg -v1 " help                     printout this help "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 " $GURU_CALL backup status           # printout current backup status"
    gmsg -v1 " $GURU_CALL backup git              # backup entry_name 'git' now"
    gmsg -v2 " $GURU_CALL backup family at 21:00  # backup family stuff at evening "
    gmsg -v2 " $GURU_CALL backup photos at Monday # backup family stuff next Monday"
    gmsg -v2
}


backup.main () {
    # command parser

    local command=$1 ; shift

    case $command in

        ls|restore|status|help|install|poll|at|debug)
            backup.$command "$@"
            return $? ;;

        plan)
            backup.plan $@
            return $? ;;

        all|daily|weekly|monthly)
            backup.plan $command
            return $? ;;
        "")

            backup.plan daily
            return $? ;;
        *)
            # go trough given items
            local given_entrys=("$command" "$@")

            #gmsg -c pink "given_entrys: ${given_entrys[@]}"
            # go trough given entries..
            for given_entry in ${given_entrys[@]} ; do

                #gmsg -c pink "given_entry: $given_entry"
                # .. then trough active entry name list..
                for enabled_entry in ${GURU_BACKUP_ACTIVE[@]} ; do

                    #gmsg -c pink "enabled_entry: $enabled_entry"
                    # ..and check that given item is the requested item
                    if [[ $given_entry == $enabled_entry ]]; then

                        gmsg -n -c dark_golden_rod "backing up $given_entry.. "

                        backup.now $given_entry \
                            && gmsg -v2 -c green "$given_entry backup done" \
                            || gmsg -c yellow "$given_entry backup failed"

                        break
                    fi

                done

            done
            # gmsg -v3 "$given_entry not found"
            ;;
        esac

    return 0
}

backup.variables () {

        gmsg -N -v3 -c white "backup_name: $backup_name"

        gmsg -v3 -n -c white "active_list: "
        gmsg -v3 -c light_blue " ${active_list[@]}"

        gmsg -v3 -n -c white "from_config (can be empty):"
        gmsg -v3 -c light_blue " ${from_config[@]}"

        gmsg -v3 -n -c white "store_config (can be empty):"
        gmsg -v3 -c light_blue " ${store_config[@]}"

        gmsg -v3 -c light_pink "from_user: $from_user"
        gmsg -v3 -c light_pink "from_domain: $from_domain"
        gmsg -v3 -c light_pink "from_port: $from_port"
        gmsg -v3 -c light_pink "from_location: $from_location"
        gmsg -v3 -c light_pink "store_device: $store_device"

        gmsg -v3 -c light_green "store_device_file: $store_device_file"
        gmsg -v3 -c light_green "store_file_system: $store_file_system"
        gmsg -v3 -c light_green "store_folder: $store_folder"
        gmsg -v3 -c light_green "store_location: $store_location"
        gmsg -v3 -c light_green "store_user: $store_user"
        gmsg -v3 -c light_green "store_domain: $store_domain"
        gmsg -v3 -c light_green "store_port: $store_port"
        gmsg -v3 -c light_green "store_mount_point: $store_mount_point"

        gmsg -v3 -c grey "backup_ignore: $backup_ignore"
        gmsg -v3 -c grey "backup_method: $backup_method"
        gmsg -v3 -c grey "honeypot_file: $honeypot_file"
        gmsg -v3 -c grey "backup_indicator_key: $backup_indicator_key"
        gmsg -v3 -c grey "backup_stat_file: $backup_stat_file"
}


backup.debug () {

    export GURU_VERBOSE=3

}


backup.config () {
    # get tunnel configuration an populate common variables

    # check is enabled
    if ! [[ $GURU_BACKUP_ENABLED ]] ; then
            gmsg -c dark_grey "backup module disabled"
            return 1
        fi

    # declare of global variables
    declare -ga backup_name=$1
    declare -ga active_list=(${GURU_BACKUP_ACTIVE[@]})
    declare -la header=(store method from ignore)
    declare -g backup_indicator_key="f$(daemon.poll_order backup)"
    # TBD declare -g backup_stat_file=$GURU_SYSTEM_MOUNT/backup/$backup_name.stat
    declare -g backup_stat_file=$GURU_SYSTEM_MOUNT/backup/next
    # exit if not in list
    if ! echo "${active_list[@]}" | grep $backup_name >/dev/null; then
            gmsg -c yellow "no '$backup_name' in active backup list"
            return 2
        fi

    for bu_name in ${active_list[@]} ; do
            if [[ "$bu_name" == "$backup_name" ]] ; then
                    local from_config="GURU_BACKUP_${bu_name^^}[@]"

                    from_config=(${!from_config})
                    declare -g store_device=${from_config[0]}
                    declare -l method=${from_config[1]}
                    declare -l from_string=${from_config[2]}
                    declare -l ignore="${from_config[3]//:/" "}"

                    local store_config="GURU_BACKUP_${store_device^^}[@]"
                    store_config=(${!store_config})
                    break
                fi
        done

        # fill parameters if from seems to be a remote location
        if echo $from_string | grep -q ":" ; then
                declare -g from_user=$(echo $from_string | cut -d ":" -f1)
                declare -g from_domain=$(echo $from_string | cut -d ":" -f2)
                declare -g from_port=$(echo $from_string | cut -d ":" -f3)
                declare -g from_location=$(echo $from_string | cut -d ":" -f4)
            else
                # fill only one parameter if from is local drive
                declare -g from_location=$from
            fi

        # if store is remote drive
        if echo ${store[@]} | grep -q ":" ; then
                declare -g store_user=$(echo ${store_config[1]} | cut -d ":" -f1)
                declare -g store_domain=$(echo ${store_config[1]} | cut -d ":" -f2)
                declare -g store_port=$(echo ${store_config[1]} | cut -d ":" -f3)
                declare -g store_location=$(echo ${store_config[1]} | cut -d ":" -f4)
            else
                # fill parameters if store is local drive
                declare -g store_device_file=${store_config[0]}
                declare -g store_file_system=${store_config[1]}
                declare -g store_mount_point=${store_config[2]}
                declare -g store_folder=${store_config[3]}
                # [[ ${store_mount_point: -1} == '/' ]] \
                #     && declare -g store_location="$store_mount_point$store_folder" \
                #     || declare -g store_location="$store_mount_point/$store_folder"
            fi

        declare -ga backup_ignore=($ignore)
        declare -g backup_method=$method
        [[ ${from_location: -1} == '/' ]] \
                && declare -g honeypot_file=$from_location"honeypot.txt" \
                || declare -g honeypot_file="$from_location/honeypot.txt"

        backup.variables

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
    if [[ $diff -lt 7200 ]] ; then
        # indicate that backup will be done soon
        gmsg -n -v1 -c aqua_marine -k $backup_indicator_key \
            "scheduled backup at $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        # indicate that that backup is very soon, ~minutes
        [[ $diff -lt $GURU_DAEMON_INTERVAL ]] && gmsg -n -v1 -c deep_pink -k $backup_indicator_key \ "($diff seconds)"
        echo
        return 0
    else
        # all fine, no scheduled backup in few hours
        gmsg -n -v1 -c green -k $backup_indicator_key "on service "
        gmsg -v1 "next backup $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        return 0
    fi

}


backup.ls () {
    # list available backups and its status

    gmsg -v2 "last run time"
    gmsg -v3 -c todo "TBD last time backed up per entry table"

    gmsg -v2 "schedule"
    gmsg -n -c white "daily: "
    gmsg -c light_blue "${GURU_BACKUP_SCHEDULE_DAILY[@]}"

    gmsg -n -c white "weekly: "
    gmsg -c light_blue "${GURU_BACKUP_SCHEDULE_WEEKLY[@]}"

    gmsg -n -c white "monthly: "
    gmsg -c light_blue "${GURU_BACKUP_SCHEDULE_MONTHLY[@]}"

    return 0
}


backup.at () {
    # set date and time for next backup

    [[ $1 ]] && local backup_date=$1 || read -p "backup date (YYMMDD): " backup_date
    shift
    [[ $1 ]] && local backup_time=$1 || read -p "backup time (H:M): " backup_time
    shift

    local backup_data_folder="$GURU_SYSTEM_MOUNT/backup"

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


backup.restore_wekan () {
    # TBD

    gmsg -c light_blue "docker stop wekan"
    gmsg -c light_blue "docker exec wekan-db rm -rf /data/dump"
    gmsg -c light_blue "docker cp dump wekan-db:/data/"
    gmsg -c light_blue "docker exec wekan-db mongorestore --drop --dir=/data/dump"
    gmsg -c light_blue "docker start wekan"
    return 127
}


backup.restore () {
    # TBD

    backup_method=$1

    case $backup_method in

        wekan)  backup.restore_wekan $from_domain $from_port $from_user $from_location || return $?
                ;;
        mediawiki)
                echo "TBD mediawiki backup restore"
                ;;
        git|gitea)
                echo "TBD git server backup restore"
                ;;
        *)      gmsg -c yellow "unknown method '$backup_method'"
                return 127
    esac

}


backup.wekan () {
    # take a database dump and copy it to location set in user.cfg where normal process can copy it to local

    local _domain=$1
    local _port=$2
    local _user=$3
    local _location=$4

    # stop container
    gmsg -v2 -n "stopping docker container.. "
    gmsg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan"

    if ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c yellow "error $?"
            return 128
        fi

    # delete current dump
    gmsg -v2 -n "delete last dump.. "
    gmsg -v3 -N -c deep_pink "${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump"
    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c yellow "error $?"
            return 129
        fi

    # take a dump
    gmsg -v2 -n "take a dump /data/dump.. "
    gmsg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump"
    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump 2>/dev/null ; then
            gmsg -c green "ok"
        else
            gmsg -c yellow "error $?"
            return 130
        fi

    # copy to where to rsyck it to final location
    gmsg -v2 -n "copy to ${_location}.. "
    gmsg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- [[ -d ${_location} ]] || mkdir -p ${_location}"

    if ssh ${_user}@${_domain} -p ${_port} -- docker cp wekan-db:/data/dump ${_location} >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c yellow "error $?"
            return 131
        fi

    # start container
    gmsg -v2 -n "starting docker container.. "
    gmsg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker start wekan"
    if ssh ${_user}@${_domain} -p ${_port} -- docker start wekan >/dev/null ; then
            gmsg -v2 -c green "ok"
        else
            gmsg -c yellow "error $?"
            return 132
        fi

    return 0
}


backup.now () {
    # check things and if pass then make backup
    # 1) get config for backup name
    # 2) check and place variables for rsynck
    # 3) check backup method get files out of service containers
    # 4) file checks to avoid broken/infected copy over good files
    # 5) perform copy
    # TBD make functions out of these parts

### 1) get config for backup name

    backup.config $1

    local from_param="$from_location"
    local store_param="$store_location"
    local command_param="-a --progress --update"

    gmsg -v3 "backup active" -c aqua_marine -k $backup_indicator_key
    #local command_param="-avh '-e ssh -p $from_port' --progress --update"

### 2) check and plase variables for rsynck based on user.cfg

    # if server to server copy..
    if [[ $from_domain ]] && [[ $store_domain ]] ; then
            # build server to server copy command variables
            gmsg -c deep_pink "$from_domain:$store_domain"
            gask "server to server NEVER TESTED!! continue? " || return 1
            from_param="$from_user@$from_domain 'rsync -ave ssh $from_location $store_user@$store_domain:$from_port:$store_location'"
            store_param=

        # .. or if server to local copy..
        elif [[ $from_domain ]] ; then
            # build remote to local command variables
            command_param="-a -e 'ssh -p $from_port' --progress --update"

            # check is target location mounted and try to mount if not
            if ! mount | grep $store_mount_point >/dev/null ; then

                if [[ $DISPLAY ]] ; then
                        gmsg -v2 -n "mounting store media $store_device_file.. "
                        gmsg -v3 -N -c deep_pink "gio mount -d $store_device_file"
                        gio mount -d $store_device_file \
                            && gmsg -v1 -c green "ok" \
                            || gmsg -v1 -c yellow "error: $?" -k $backup_indicator_key

                    else
                        gmsg -c white "to mount -t $store_file_system $store_device_file $store_mount_point sudo needed"

                        [[ -d $store_mount_point ]] || sudo mkdir -p $store_mount_point

                        # if [[ $store_file_system == "luks" ]] ; then
                        #         sudo mount -t $store_file_system "/dev/mapper/dev/luks_$store_device_file" $store_mount_point
                        #     else

                        #     fi

                        gmsg -v3 -N -c deep_pink "sudo mount -t $store_file_system $store_device_file $store_mount_point"
                        if sudo mount -t $store_file_system $store_device_file $store_mount_point ; then
                                gmsg -v1 -c green "ok"
                            else
                                gmsg -v1 -c yellow "error: $?" -k $backup_indicator_key
                                return 32
                            fi

                    fi
                    # no rush, my friend
                    sleep 3
                fi

            # if ignores set add arguments
            if [[ $backup_ignore ]] ; then
                for _ignore in  ${backup_ignore[@]} ; do
                    command_param="$command_param --exclude '*$_ignore'"
                done
            fi

            # TBD remove these local variables and use global store_location
            [[ ${store_mount_point: -1} == '/' ]] \
                && store_location="$store_mount_point$store_folder" \
                || store_location="$store_mount_point/$store_folder"

            from_param="$from_user@$from_domain:$from_location"

        # .. or if local to server copy..
        elif [[ $store_domain ]] ; then
            # build local to remote command variables
            gask "local to server NEVER TESTED!! continue? " || return 1
            command_param="-a -e 'ssh -p $store_port'"
            store_param="$store_user@$store_domain:$store_location"
        # # ..else local to local
        # else
        #     command_param="-a --progress --update"
        #     store_param="$store_location"
        #     from_param="$from_location"
        fi

    # make dir if not exist (like when year changes)
    if ! [[ $store_domain ]] && [[ $store_location ]] ; then
            gmsg -v3 -c deep_pink "mkdir -p $store_location"
            [[ -d $store_location ]] || mkdir -p $store_location
        fi

### 3) check backup method get files out of service containers based settings in user.cfg

    case $backup_method in

            wekan)
                    backup.wekan $from_domain $from_port $from_user $from_location || return $?
                    ;;
            mediawiki)
                    echo "TBD mediawiki backup"
                    ;;
            git|gitea)
                    echo "TBD git server backup"
                    ;;
        esac

### 4) file checks to avoid broken/infected copy over good files

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
                        gmsg -c tbd "TBD other virus track marks here"
                        return 102
                        ;;
                esac
        done

        # check if honeypot file exists
        if ssh $from_user@$from_domain "test -e $honeypot_file" ; then
            [[ -f /tmp/honeypot.txt ]] && rm -f /tmp/honeypot.txt
            gmsg -v2 -n "getting honeypot file.. "
            # get honeypot file

            gmsg -v3 -N -c deep_pink "eval rsync $command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null"
            if eval rsync "$command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null" ; then
                gmsg -v2 -c green "ok"
            else
                gmsg -c yellow "cannot get honeypot file "
            fi
        fi
    fi

    # check is text in honeypot.txt file changed
    if [[ -f /tmp/honeypot.txt ]] ; then
            gmsg -v2 -n "checking honeypot file.. "
            local contain=($(cat /tmp/honeypot.txt))
            rm -f /tmp/honeypot.txt

            gmsg -n -v3 "expecting 'honeypot' got '${contain[3]}' "

            if ! [[ ${contain[3]} == "honeypot" ]] ; then
                gmsg -c yellow \
                     "honeypot file changed! got '${contain[3]}' when 'honeypot' expected."
                gmsg -c light_blue "${contain[@]}"
                gmsg -c red -k $backup_indicator_key \
                     "backup canceled cause of potential crypto virus action detected!"
                export GURU_BACKUP_ENABLED=
                return 102
            fi
        gmsg -v2 -c green "ok"
    fi

### 5) perform copy

    # TBD remove these local variables and use global store_location
    [[ ${store_param: -1} == '/' ]] \
        && store_param="$store_mount_point$backup_name" \
        || store_param="$store_mount_point/$backup_name"

    gmsg -v3 -c deep_pink "eval rsync $command_param $from_param $store_param"
    eval rsync $command_param $from_param $store_param

    local _error=$?

    if [[ $_error -gt 0 ]] ; then
            gmsg "$from_location error: $backup_method $_error" \
                 -c red -k $backup_indicator_key

            return 12
        else

            gmsg -v3 "$from_location ok" \
                 -c green -k $backup_indicator_key
            return 0
        fi
}


backup.plan () {
    # backup all in active list

    local schedule='daily'
    [[ $1 ]] && schedule=$1
    local _item=1;
    local _error=
    local entries=()
    local backup_indicator_key="f$(daemon.poll_order backup)"

    gmsg -v3 -c pink "schedule: $schedule"

    case $schedule in
        daily)      entries=(${GURU_BACKUP_SCHEDULE_DAILY[@]}) ;;
        weekly)     entries=(${GURU_BACKUP_SCHEDULE_WEEKLY[@]}) ;;
        monthly)    entries=(${GURU_BACKUP_SCHEDULE_MONTHLY[@]}) ;;
        all)        entries=(${GURU_BACKUP_ACTIVE[@]}) ;;
        *)          variable="GURU_BACKUP_SCHEDULE_${schedule^^}[@]"
                    entries=($(eval echo ${!variable}))
                    ;;

    esac

    if ! [[ $entries ]] ; then
        gmsg "no entries"
        return 0
    fi

    gmsg -v3 -c pink "entries: ${entries[@]}"

    for entry in ${entries[@]} ; do
        gmsg -n -c dark_golden_rod "backing up $entry $_item/${#entries[@]}.. "
        #if ! [[ $GURU_BACKUP_ENABLED ]] ; then gmsg -c yellow "canceled" ; break ; fi
        backup.now $entry || (( _error++ ))
        (( _item++ ))
    done

    if [[ $_error -gt 0 ]] ; then
        gmsg "$_error warnings, check log above" -c yellow -k $backup_indicator_key
        gindicate say -m "$_error warnings during $schedule backup"
        return 12
    else
        #gmsg -v3 -c green "$schedule done"
        gindicate done -m "$schedule backup" -k $backup_indicator_key
        return 0
    fi
}


backup.scheduled () {
        # run an set scheduled backup

    local schedule='daily'
    [[ $1 ]] && schedule=$1

    local backup_data_folder=$GURU_SYSTEM_MOUNT/backup
    local epic_backup=$(cat $backup_data_folder/next)

    if [[ $(date '+%s') -lt $epic_backup ]] ; then
        return 0
    fi

    # run given schedule list
    backup.plan $schedule
    local _error=$?

    # schedule next backup
    if [[ $_error -lt 100 ]] ; then
        local now=$(date -d now +%s)

        # konepelti näemmä aika auki jääny
        # case ${schedule} in
        #     hourly) till_next=3600 ;;
        #     daily) till_next=86400 ;;
        #     weekly) till_next=604800 ;;
        #     monthly) till_next=2629743 ;;
        #     yearly) till_next=31556926 ;;
        #     *) till_next=99999999 ;;
        # esac

        #epic_backup=$(( $epic_backup + 86400))
        #echo $epic_backup > $backup_data_folder/next
        echo $(( $now + 86400 )) > $backup_data_folder/next
        #next_time=$(( now + till_next ))

        # $GURU_SYSTEM_MOUNT/<entry_name>.stat
        # $next_time > $backup_data_folder/next
        #echo "next_time=$next_time" > $backup_stat_file
        #last_time=1645715582
        # last_note="last time got $_error"

        local rechedule="next backup scheduled to $(date -d @$(cat $backup_data_folder/next) '+%d.%m.%Y %H:%M')"
        gmsg -c white $rechedule
        gindicate say -m "next backup scheduled for tomorrow"

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
            backup.scheduled daily
            ;;
        *)  gmsg -c dark_grey "function not written"
            return 0
        esac
}



backup.stand-alone () {
    # this just a test is it even possible

    # to get this running
    declare -g GURU_VERBOSE=1
    declare -g GURU_COLOR=true
    declare -g GURU_CALL=guru
    declare -g PATH="$PATH;$(pwd)/modules;$(pwd)/core"
    declare -g GURU_SYSTEM_MOUNT=/tmp/guru

    declare -g GURU_BACKUP_ENABLED=true
    #declare -g GURU_BACKUP_COLOR=aqua
    declare -g GURU_BACKUP_ACTIVE=(git Pictures)
    declare -g GURU_BACKUP_SCHEDULE_DAILY=(git)
    declare -g GURU_BACKUP_SCHEDULE_WEEKLY=(Pictures)
    declare -g GURU_BACKUP_SCHEDULE_MONTHLY=()

    # example
    declare -g GURU_BACKUP_REPOSITORY=(/dev/sda1 ext4 $USER/backup/$(date +%Y)/git)
    declare -g GURU_BACKUP_GIT=(repository rsync $HOME/git/)
    declare -g GURU_DAEMON_INTERVAL=300

}

backup.install () {
    # install needed tools

    sudo apt update && \
    sudo apt install ssh scp rsync sshfs pv
    return $?
}


backup.remove () {
    # remove stuff

    gmsg "no point to remove so basic tools.."
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    # backup.debug

    [[ -f ~/.gururc ]] && source ~/.gururc \
                       || backup.stand-alone

    backup.main "$@"
    exit "$?"
fi

