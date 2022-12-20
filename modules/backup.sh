#!/bin/bash
# guru-client backup system module
# automated backups from server to local, local to local or server to server based on rsync archiving functionalities.
# launching is based on guru daemon.sh poll request, not on crond mainly to avoid permission issues and shit.
# can be run individually but needs specific set of environment variables (~/.gururc).
# more of bash shit github.com/ugcasa/guru-client casa@ujo.guru 2021


declare -g backup_data_folder="$GURU_SYSTEM_MOUNT/backup"
declare -g backup_rc="/tmp/guru-cli_backup.rc"
! [[ -d $backup_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $backup_data_folder


backup.rc () {
# source configurations

    if ! [[ -f $backup_rc ]] || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/backup.cfg) - $(stat -c %Y $backup_rc) )) -gt 0 ]] ; then
            backup.make_rc && \
            gr.msg -v1 -c dark_gray "$backup_rc updated"
        fi

    source $backup_rc
}


backup.make_rc () {
# make core module rc file out of configuration file

    if ! source config.sh ; then
            gr.msg -c yellow "unable to load configuration module"
            return 100
        fi

    if [[ -f $backup_rc ]] ; then
            rm -f $backup_rc
        fi

    if ! config.make_rc "$GURU_CFG/$GURU_USER/backup.cfg" $backup_rc ; then
            gr.msg -c yellow "configuration failed"
            return 101
        fi

    chmod +x $backup_rc

    if ! source $backup_rc ; then
            gr.msg -c red "unable to source configuration"
            return 202
        fi
}


backup.help () {
    # general help

    gr.msg -v1 -c white "guru-cli backup help "
    gr.msg -v2
    gr.msg -v0 "usage:  $GURU_CALL backup <entry_name> at <YYYYMMDD> <HH:MM> "
    gr.msg -v1 "        $GURU_CALL backup status|ls|restore|poll|install|remove  "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " <empty>                  make daily backup now "
    gr.msg -v1 " <entry_name>             run <entry_name> backup right away "
    gr.msg -v2 "     at <YYMMDD> <H:M>    make backup at date and time    "
    gr.msg -v1 " ls                       list of backups "
    gr.msg -v1 " status                   printout status string"
    gr.msg -v2 " restore                  not clear hot to be done  "
    gr.msg -v2 " install                  install client requirements "
    gr.msg -v2 " remove                   remove installed requirements "
    gr.msg -v1 " help                     printout this help "
    gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 " $GURU_CALL backup status           # printout current backup status"
    gr.msg -v1 " $GURU_CALL backup git              # backup entry_name 'git' now"
    gr.msg -v2 " $GURU_CALL backup family at 21:00  # backup family stuff at evening "
    gr.msg -v2 " $GURU_CALL backup photos at Monday # backup family stuff next Monday"
    gr.msg -v2
}


backup.main () {
    # command parser

    local command=$1 ; shift

    case $command in

        ls|restore|status|help|install|poll|at|debug|config)
            backup.$command "$@"
            return $? ;;

        hourly|daily|weekly|monthly|yearly|all)
            backup.plan $command
            return $? ;;
        "")

            backup.plan daily
            return $? ;;
        *)
            # go trough given items
            local given_entrys=("$command" "$@")

            # go trough given entries..
            for given_entry in ${given_entrys[@]} ; do

                    # .. then trough active entry name list..
                    for enabled_entry in ${GURU_BACKUP_ACTIVE[@]} ; do

                            # ..and check that given item is the requested item
                            if [[ $given_entry == $enabled_entry ]]; then
                                    gr.msg -n -c dark_golden_rod "backing up $given_entry.. "

                                    backup.now $given_entry \
                                        && gr.msg -v2 -c green "$given_entry backup done" \
                                        || gr.msg -c yellow "$given_entry backup failed"
                                    break
                                fi
                        done
                done
            ;;
        esac
    return 0
}

backup.variables () {

        gr.msg -N -v3 -c white "backup_name: '$backup_name'"

        gr.msg -v3 -c light_blue "from_config: '${from_config[@]}'"
        gr.msg -v3 -c light_green "store_device: '$store_device'"
        gr.msg -v3 -c light_pink "from_location: '$from_location'"
        gr.msg -v3 -c light_pink "from_user (o): '$from_user'"
        gr.msg -v3 -c light_pink "from_domain (o): '$from_domain'"
        gr.msg -v3 -c light_pink "from_port (o): '$from_port'"

        gr.msg -v3 -c light_blue "store_config: '${store_config[@]}'"
        gr.msg -v3 -c light_green "store_device_file: '$store_device_file'"
        gr.msg -v3 -c light_green "store_mount_point: '$store_mount_point'"
        gr.msg -v3 -c light_green "store_file_system: '$store_file_system'"
        gr.msg -v3 -c light_green "store_folder: '$store_folder'"
        gr.msg -v3 -c light_green "store_location (o): '$store_location'"
        gr.msg -v3 -c light_green "store_user (o): '$store_user'"
        gr.msg -v3 -c light_green "store_domain (o): '$store_domain'"
        gr.msg -v3 -c light_green "store_port (o): '$store_port'"

        gr.msg -v3 -c grey "backup_ignore: '$backup_ignore'"
        gr.msg -v3 -c grey "backup_method: '$backup_method'"
        gr.msg -v3 -c grey "honeypot_file: '$honeypot_file'"
        gr.msg -v3 -c grey "GURU_BACKUP_INDICATOR_KEY: '$GURU_BACKUP_INDICATOR_KEY'"

        gr.msg -v3 -c grey "backup_stat_file: '$backup_stat_file'"
        [[ -f $backup_stat_file ]] && source $backup_stat_file
        gr.msg -v3 -c grey "last_backup_name: '$last_backup_type'"
        gr.msg -v3 -c grey "last_backup_time: '$last_backup_time'"
        gr.msg -v3 -c grey "last_backup_version: '$last_backup_version'"
        gr.msg -v3 -c grey "last_backup_error: '$last_backup_error'"

        gr.msg -v3 -c light_blue "active_list: '${active_list[@]}'"
}


backup.debug () {

    export GURU_VERBOSE=3
    local name=${GURU_BACKUP_ACTIVE[0]}
    [[ $1 ]] && name=$1
    backup.config $name
}


backup.config () {
    # get tunnel configuration an populate common variables

    # check is enabled
    if ! [[ $GURU_BACKUP_ENABLED ]] ; then
            gr.msg -c black "backup module disabled"
            return 1
        fi

    # declare of global variables
    local store_is_local=
    declare -ga backup_name=$1
    declare -ga active_list=(${GURU_BACKUP_ACTIVE[@]})
    locala header=(store method from ignore)

    # exit if not in active list
    if ! echo "${active_list[@]}" | grep -q $backup_name ; then
            gr.msg -c yellow "no '$backup_name' in active backup list"
            return 2
        fi

    # go trough active backups and find match
    for bu_name in ${active_list[@]} ; do
            if [[ "$bu_name" == "$backup_name" ]] ; then
                    local from_config="GURU_BACKUP_${bu_name^^}[@]"

                    from_config=(${!from_config})
                    declare -g store_device=${from_config[0]}
                    local method=${from_config[1]}
                    local from_string=${from_config[2]}
                    local ignore="${from_config[3]//:/' '}"

                    declare -g store_config="GURU_BACKUP_${store_device^^}[@]"
                    store_config=(${!store_config})
                    break
                fi
        done

    # fill source location variables
    if echo $from_string | grep -q ":" ; then
            # source is remote location
            declare -g from_user=$(echo $from_string | cut -d ":" -f1)
            declare -g from_domain=$(echo $from_string | cut -d ":" -f2)
            declare -g from_port=$(echo $from_string | cut -d ":" -f3)
            declare -g from_location=$(echo $from_string | cut -d ":" -f4)
        else
            # source is local drive
            declare -g from_location=$(echo $from_string | cut -d ":" -f3)
        fi

    # fill store location variables
    if echo ${store[@]} | grep -q ":" ; then
            # store is remote drive
            declare -g store_user=$(echo ${store_config[1]} | cut -d ":" -f1)
            declare -g store_domain=$(echo ${store_config[1]} | cut -d ":" -f2)
            declare -g store_port=$(echo ${store_config[1]} | cut -d ":" -f3)
            declare -g store_location=$(echo ${store_config[1]} | cut -d ":" -f4)
        else
            # store is local drive
            store_is_local=true
            declare -g store_device_file=${store_config[0]}
            declare -g store_file_system=${store_config[1]}
            declare -g store_mount_point=${store_config[2]}
            declare -g store_folder=${store_config[3]}

            [[ ${store_mount_point: -1} == '/' ]] \
                && declare -g store_location="$store_mount_point$store_folder" \
                || declare -g store_location="$store_mount_point/$store_folder"
        fi

        [[ $store_is_local ]] \
            && declare -g backup_stat_file="$store_mount_point/$store_folder/$backup_name/backup.stat" \
            || declare -g backup_stat_file="$GURU_SYSTEM_MOUNT/backup/$backup_name.stat"

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

    local backup_data_folder=$GURU_SYSTEM_MOUNT/backup

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_BACKUP_ENABLED ]] ; then
            gr.msg -n -v1 -c green -k $GURU_BACKUP_INDICATOR_KEY "enabled, "
        else
            gr.msg -v1 -c black -k $GURU_BACKUP_INDICATOR_KEY "disabled"
            return 1
        fi

    if ! [[ -f $backup_data_folder/next ]] ; then
            gr.msg -v1 -c green -k $GURU_BACKUP_INDICATOR_KEY \
                "no scheduled backups"
            return 0
        fi

    local epic_backup=$(cat $backup_data_folder/next)
    local diff=$(( $epic_backup - $(date '+%s') ))

    # indicate backup time
    if [[ $diff -lt 7200 ]] ; then
        # indicate that backup will be done soon
        gr.msg -n -v1 -c aqua_marine -k $GURU_BACKUP_INDICATOR_KEY \
            "scheduled backup at $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        # indicate that that backup is very soon, ~minutes
        [[ $diff -lt $GURU_DAEMON_INTERVAL ]] && gr.msg -n -v1 -c deep_pink -k $GURU_BACKUP_INDICATOR_KEY \ "($diff seconds)"
        echo
        return 0
    else
        # all fine, no scheduled backup in few hours
        gr.msg -n -v1 -c green -k $GURU_BACKUP_INDICATOR_KEY "on service "
        gr.msg -v1 "next backup $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        return 0
    fi
}


backup.ls () {
    # list available backups and its status

    gr.msg -v2 "last run time"
    gr.msg -v3 -c todo "TBD last time backed up per entry table"

    gr.msg -v2 "schedule"
    gr.msg -n -c white "daily: "
    gr.msg -c light_blue "${GURU_BACKUP_SCHEDULE_DAILY[@]}"

    gr.msg -n -c white "weekly: "
    gr.msg -c light_blue "${GURU_BACKUP_SCHEDULE_WEEKLY[@]}"

    gr.msg -n -c white "monthly: "
    gr.msg -c light_blue "${GURU_BACKUP_SCHEDULE_MONTHLY[@]}"

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
        gr.msg "that is past, try again"
        return 1
    fi

    echo $epic_backup > "$backup_data_folder/next"

    # if daemon is not running (computer sleeping) backup is not run
    # overdue backups shall be run at next start
    return 0
}


backup.restore_wekan () {
    # TBD

    gr.msg -c light_blue "docker stop wekan"
    gr.msg -c light_blue "docker exec wekan-db rm -rf /data/dump"
    gr.msg -c light_blue "docker cp dump wekan-db:/data/"
    gr.msg -c light_blue "docker exec wekan-db mongorestore --drop --dir=/data/dump"
    gr.msg -c light_blue "docker start wekan"
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
        *)      gr.msg -c yellow "unknown method '$backup_method'"
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
    gr.msg -v2 -n "stopping docker container.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan"

    if ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan >/dev/null ; then
            gr.msg -v2 -c green "ok"
        else
            gr.msg -c yellow "error $?"
            return 128
        fi

    # delete current dump
    gr.msg -v2 -n "delete last dump.. "
    gr.msg -v3 -N -c deep_pink "${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump"
    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump >/dev/null ; then
            gr.msg -v2 -c green "ok"
        else
            gr.msg -c yellow "error $?"
            return 129
        fi

    # take a dump
    gr.msg -v2 -n "take a dump /data/dump.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump"
    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump 2>/dev/null ; then
            gr.msg -c green "ok"
        else
            gr.msg -c yellow "error $?"
            return 130
        fi

    # copy to where to rsyck it to final location
    gr.msg -v2 -n "copy to ${_location}.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- [[ -d ${_location} ]] || mkdir -p ${_location}"

    if ssh ${_user}@${_domain} -p ${_port} -- docker cp wekan-db:/data/dump ${_location} >/dev/null ; then
            gr.msg -v2 -c green "ok"
        else
            gr.msg -c yellow "error $?"
            return 131
        fi

    # start container
    gr.msg -v2 -n "starting docker container.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker start wekan"
    if ssh ${_user}@${_domain} -p ${_port} -- docker start wekan >/dev/null ; then
            gr.msg -v2 -c green "ok"
        else
            gr.msg -c yellow "error $?"
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

    server_to_local () {

            # build remote to local command variables
            command_param="-a -e 'ssh -p $from_port' --progress --update"

            # check is target location mounted and try to mount if not
            if ! mount | grep $store_mount_point >/dev/null ; then

                if [[ $DISPLAY ]] && [[ $store_device_file ]] ; then
                        gr.msg -v2 -n "mounting store media $store_device_file.. "
                        gr.msg -v3 -N -c deep_pink "gio mount -d $store_device_file"
                        gio mount -d $store_device_file \
                            && gr.msg -v1 -c green "ok" \
                            || gr.msg -v1 -c yellow "error: $?" -k $GURU_BACKUP_INDICATOR_KEY
                    else
                        gr.msg -c white "to mount -t $store_file_system $store_device_file $store_mount_point sudo needed"
                        [[ -d $store_mount_point ]] || sudo mkdir -p $store_mount_point
                        gr.msg -v3 -N -c deep_pink "sudo mount -t $store_file_system $store_device_file $store_mount_point"
                        if sudo mount -t $store_file_system $store_device_file $store_mount_point ; then
                                gr.msg -v1 -c green "ok"
                            else
                                gr.msg -v1 -c yellow "error: $?" -k $GURU_BACKUP_INDICATOR_KEY
                                # echo "last_backup_error=32" >>$backup_stat_file
                                return 32
                            fi
                    fi
                    # no rush my friend
                    sleep 3
                fi

            # if ignores set add arguments
            if [[ $backup_ignore ]] ; then
                for _ignore in  ${backup_ignore[@]} ; do
                    command_param="$command_param --exclude '*$_ignore'"
                done
            fi

            from_param="$from_user@$from_domain:$from_location"

            # TBD remove these local variables and use global store_location. yes, messed me up again..
            [[ ${store_location: -1} == '/' ]] \
                && store_param="$store_location$backup_name" \
                || store_param="$store_location/$backup_name"

            gr.msg -v3 "location: $store_location folder: $store_folder param: $store_param "
    }


    local_to_local () {

        if ! mount | grep $store_mount_point >/dev/null ; then
                if [[ $DISPLAY ]] && [[ $store_device_file ]] ; then
                        gr.msg -v2 -n "mounting store media $store_device_file.. "
                        gr.msg -v3 -N -c deep_pink "gio mount -d $store_device_file"
                        gio mount -d $store_device_file \
                            && gr.msg -v1 -c green "ok" \
                            || gr.msg -v1 -c yellow "error: $?" -k $GURU_BACKUP_INDICATOR_KEY
                    fi
            fi
        command_param="-a --progress --update"
        from_param="$from_location"

        if [[ $backup_ignore ]] ; then
                for _ignore in  ${backup_ignore[@]} ; do
                        command_param="$command_param --exclude '*$_ignore'"
                    done
            fi

        [[ ${store_location: -1} == '/' ]] \
            && store_param="$store_location$backup_name" \
            || store_param="$store_location/$backup_name"

    }


    local_to_server () {
            # build local to remote command variables
            gr.ask "local to server NEVER TESTED!! continue? " || return 1
            command_param="-a -e 'ssh -p $store_port'"
            store_param="$store_user@$store_domain:$store_location"
        # # ..else local to local
        # else
        #     command_param="-a --progress --update"
        #     store_param="$store_location"
        #     from_param="$from_location"
    }

    server_to_server ()  {
            # build server to server copy command variables
            gr.msg -c deep_pink "$from_domain:$store_domain"
            gr.ask "server to server NEVER TESTED!! continue? " || return 1
            from_param="$from_user@$from_domain 'rsync -ave ssh $from_location $store_user@$store_domain:$from_port:$store_location'"
            store_param=
        }


### 1) get config for backup name
    [[ $backup_name ]] || backup.config $1
    local from_param="$from_location"
    local store_param="$store_location"
    local command_param="-a --progress --update"
    gr.msg -v3 "backup active" -c aqua_marine -k $GURU_BACKUP_INDICATOR_KEY

### 2) check and plase variables for rsynck based on user.cfg

    if [[ $from_domain ]] && [[ $store_domain ]] ; then
            server_to_server
        elif [[ $from_domain ]] ; then
            server_to_local
        elif [[ $store_domain ]] ; then
            local_to_server
        else
            local_to_local
        fi

    # make dir if not exist (like when year changes)
    if ! [[ $store_domain ]] && [[ $store_location ]] ; then
            gr.msg -v3 -c deep_pink "mkdir -p $store_location"
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
                                    gr.msg -c red -k $GURU_BACKUP_INDICATOR_KEY \
                                        "POTENTIAL VIRUS: wannacry tracks detected!"
                                    gr.msg -c light_blue "$file"
                                    gr.msg -c yellow "backup of $from_location canceled"
                                    # echo "last_backup_error=101" >>$backup_stat_file
                                    # echo "### POTENTIAL VIRUS: wannacry tracks detected!" >>$backup_stat_file
                                    return 101
                                    ;;

                             *WORM*)
                                    gr.msg -c tbd "TBD other virus track marks here"
                                    # echo "last_backup_error=102" >>$backup_stat_file
                                    return 102
                                    ;;
                            esac
                done

            # check if honeypot file exists
            if ssh $from_user@$from_domain "test -e $honeypot_file" ; then
                    [[ -f /tmp/honeypot.txt ]] && rm -f /tmp/honeypot.txt
                    gr.msg -v2 -n "getting honeypot file.. "
                    # get honeypot file

                    gr.msg -v3 -N -c deep_pink "eval rsync $command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null"
                    if eval rsync "$command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null" ; then
                            gr.msg -v2 -c green "ok"
                        else
                            gr.msg -c yellow "cannot get honeypot file "
                        fi
                fi
        fi

    # check is text in honeypot.txt file changed
    if [[ -f /tmp/honeypot.txt ]] ; then
            gr.msg -v2 -n "checking honeypot file.. "
            local contain=($(cat /tmp/honeypot.txt))
            rm -f /tmp/honeypot.txt

            gr.msg -n -v3 "expecting 'honeypot' got '${contain[3]}' "

            if ! [[ ${contain[3]} == "honeypot" ]] ; then
                    gr.msg -c yellow \
                         "honeypot file changed! got '${contain[3]}' when 'honeypot' expected."
                    gr.msg -c light_blue "${contain[@]}"
                    gr.msg -c red -k $GURU_BACKUP_INDICATOR_KEY \
                         "backup canceled cause of potential crypto virus action detected!"
                    export GURU_BACKUP_ENABLED=

                    # echo "last_backup_error=104" >>$backup_stat_file
                    # echo "### backup canceled cause of potential crypto virus action detected!" >>$backup_stat_file
                    return 104
                fi
            gr.msg -v2 -c green "ok"
        fi

### 5) perform copy

    local _error=$?
    gr.msg -v3 -c deep_pink "eval rsync $command_param $from_param $store_param"
    eval rsync $command_param $from_param $store_param

    if [[ $_error -gt 0 ]] ; then
            gr.msg "$from_location error: $backup_method $_error" \
                 -c red -k $GURU_BACKUP_INDICATOR_KEY
                 echo "last_backup_error=120" >>$backup_stat_file
            return 120
        else
            echo "### $backup_name $(date '+%d.%m.%Y %H:%M')" >$backup_stat_file
            echo "last_backup_version='$(head -n1 $GURU_BIN/version)'" >>$backup_stat_file
            echo "last_backup_name=$backup_name" >>$backup_stat_file
            echo "last_backup_time=$(date +%s)" >>$backup_stat_file
            echo "last_backup_error=$_error" >>$backup_stat_file
            gr.msg -v3 "$from_location ok" -c green -k $GURU_BACKUP_INDICATOR_KEY
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
    local entry=

    case $schedule in
            hourly|daily|weekly|monthly|yearly|all|panic)
                    entries=($(eval echo '${GURU_BACKUP_SCHEDULE_'"${schedule^^}[@]}"))
                    ;;
            "")
                    gr.msg -c yellow "unknown schedule '$schedule'"
                    return 11
                    ;;
            *)      # try if its set in user.cfg
                    variable="GURU_BACKUP_SCHEDULE_${schedule^^}[@]"
                    entries=($(eval echo ${!variable}))
                    if ! [[ $entries ]] ; then
                            gr.msg -c yellow "unknown schedule '$schedule'"
                            return 12
                        fi
                    ;;
        esac

    if ! [[ $entries ]] ; then
            gr.msg "no entries"
            return 0
        fi

    gr.msg -v3 -c light_blue "entries: ${entries[@]}"

    for (( i = 0; i < ${#entries[@]}; i++ )); do
            entry=${entries[$i]}
            gr.msg -n -c dark_golden_rod "backing up $entry $(( $i + 1 ))/${#entries[@]}.. "

            backup.config $entry

            # check is last backup old enough
            if [[ -f $backup_stat_file ]] ; then
                    source $backup_stat_file

                    case $schedule in
                             hourly)  add_seconds=3600 ;;
                             daily)   add_seconds=86400 ;;
                             weekly)  add_seconds=604800 ;;
                             monthly) add_seconds=2629743 ;;
                             yearly)  add_seconds=31556926 ;;
                        esac

                    next_backup=$(( last_backup_time + add_seconds ))
                    # gr.msg "next_backup: $next_backup last_backup_time: $last_backup_time add_seconds: $add_seconds"

                    if [[ $(date +%s) -lt $next_backup ]] && ! [[ $GURU_FORCE ]]; then
                            gr.msg -c dark_grey "waiting $(date -d @$next_backup '+%d.%m.%Y %H:%M')"
                            continue
                        fi
                fi

            backup.now $entry || (( _error++ ))
        done

    if [[ $_error -gt 0 ]] ; then
            gr.msg "$_error warnings, check log above" -c yellow -k $GURU_BACKUP_INDICATOR_KEY
            gr.ind say -m "$_error warnings during $schedule backup"
            return 12
        else
            #gr.msg -v3 -c green "$schedule done"
            gr.ind done -m "$schedule backup" -k $GURU_BACKUP_INDICATOR_KEY
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
        local now=$(date +%s)

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
        echo $(( $(date +%s) + 86400 )) > $backup_data_folder/next
        #next_time=$(( now + till_next ))

        # $GURU_SYSTEM_MOUNT/<entry_name>.stat
        # $next_time > $backup_data_folder/next
        #echo "next_time=$next_time" > $backup_stat_file
        #last_time=1645715582
        # last_note="last time got $_error"

        local rechedule="next backup scheduled to $(date -d @$(cat $backup_data_folder/next) '+%d.%m.%Y %H:%M')"
        gr.msg -c white $rechedule
        gr.ind say -m "next backup scheduled for tomorrow"

        return $_error
    fi
}


backup.poll () {
    # poll functions

    local _cmd="$1" ; shift

    case $_cmd in
            start )
                gr.msg -v1 -t -c black "${FUNCNAME[0]}: backup status polling started" -k $GURU_BACKUP_INDICATOR_KEY
                ;;
            end )
                gr.msg -v1 -t -c reset "${FUNCNAME[0]}: backup status polling ended" -k $GURU_BACKUP_INDICATOR_KEY
                ;;
            status )
                backup.status
                backup.scheduled daily
                ;;
            *)  gr.msg -c dark_grey "function not written"
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

    gr.msg "no point to remove so basic tools.."
    return 0
}

backup.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    # backup.debug

    [[ -f ~/.gururc ]] && source ~/.gururc


    backup.main "$@"
    exit "$?"
fi

