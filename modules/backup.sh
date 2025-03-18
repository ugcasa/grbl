#!/bin/bash
# grbl backup system module casa@ujo.guru 2021 - 2025
# automated backups from server to local, local to local or server to server based on rsync archiving functionalities.
# launching is based on grbl daemon.sh poll request, not on crond mainly to avoid permission issues and shit.
# can be run individually but needs specific set of environment variables (~/.grblrc).
# more of bash shit github.com/ugcasa/grbl
__backup_color="light_blue"
__backup=$(readlink --canonicalize --no-newline $BASH_SOURCE) # debug

declare -g backup_data_folder="$GRBL_SYSTEM_MOUNT/backup"
declare -g backup_rc="/tmp/$USER/grbl_backup.rc"
declare -g backup_config="$GRBL_CFG/$GRBL_USER/backup.cfg"
declare -g backup_log_file="$GRBL_DATA/backup/backup.log"
declare -g backup_schedule="direct"
declare -g backup_running="/tmp/$USER/backup.running"

! [[ -d $backup_data_folder ]] && [[ -f $GRBL_SYSTEM_MOUNT/.online ]] && mkdir -p $backup_data_folder

backup.help () {
# general help

    gr.msg -v1 -c white "grbl backup help "
    gr.msg -v2
    gr.msg -v0 "usage:  $GRBL_CALL backup <entry_name> at <YYYYMMDD> <HH:MM> "
    gr.msg -v1 "        $GRBL_CALL backup status|ls|restore|poll|install|remove  "
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 "                          make daily backup now "
    gr.msg -v1 " <schelude>               backup events in shedule list right away "
    gr.msg -v2 "    at <YYMMDD> <H:M>     make backup at date and time    "
    gr.msg -v1 " <event>                  backup given event right away "
    gr.msg -v2 "    at <YYMMDD> [<H:M>]   make backup at date and time  hours and minutes optinal  "
    gr.msg -v1 " check                    check varies status information"
    gr.msg -v1 "    status mount          check what mountponts are backuped "
    gr.msg -v1 "    status cloud          check what cloud folders are backuped "
    gr.msg -v1 " ls                       list of backups "
    gr.msg -v1 " status                   printout module status "
    gr.msg -v2 " restore                  not clear hot to be done  "
    gr.msg -v2 " install                  install client requirements "
    gr.msg -v2 " remove                   remove installed requirements "
    gr.msg -v1 " help                     printout this help "
    gr.msg -v3 " poll start|end           start or end module status polling "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 " $GRBL_CALL backup status           # printout current backup status"
    gr.msg -v1 " $GRBL_CALL backup git              # backup entry_name 'git' now"
    gr.msg -v2 " $GRBL_CALL backup family at 21:00  # backup family stuff at evening "
    gr.msg -v2 " $GRBL_CALL backup photos at Monday # backup family stuff next Monday"
    gr.msg -v2
}

backup.main () {
# command parser
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local command=$1 ; shift
    local _error=0

    case $command in

        check|ls|restore|status|help|install|poll|at|debug|config)
        # something else than really backup
            backup.$command $@
            return $?
            ;;

        hourly|daily|weekly|monthly|yearly)
        # scheduled
            backup.plan $command
            backup.log_write $?
            return $?
            ;;

        all)
            backup.all $@
            backup.log_write $?
            return $?
            ;;

        log)
            backup.log_read
            ;;
        "")
        # default is daily backup
            backup.plan daily
            backup.log_write $?
            return $?
            ;;
        *)
            # if given command is entry name
            if backup.entry_exist $command ; then
                backup_schedule="now"
                backup.now $command
                backup.log_write $?
                return $?
            fi

            gr.msg -e1 "unknown '$command'"
            backup.help
            return 1
            ;;
        esac
    return 0
}

backup.variables () {
# backup variable printout
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -N -v3 -c white "backup_name: '$backup_name'"
    gr.msg -v3 -c light_blue "from_config: '${from_config[@]}'"
    gr.msg -v3 -c light_green "store_device: '$store_device'"
    gr.msg -v3 -c light_pink "from_location: '$from_location'"
    gr.msg -v3 -c light_pink "from_user (o): '$from_user'"
    gr.msg -v3 -c light_pink "from_domain (o): '$from_domain'"
    gr.msg -v3 -c light_pink "from_port (o): '$from_port'"
    gr.msg -v3 -c light_pink "from_size: '$from_size' ($(numfmt $from_size --to=iec))"
    gr.msg -v3 -c light_blue "store_config: '${store_config[@]}'"
    gr.msg -v3 -c light_green "store_device_file: '$store_device_file'"
    gr.msg -v3 -c light_green "store_mount_point: '$store_mount_point'"
    gr.msg -v3 -c light_green "store_file_system: '$store_file_system'"
    gr.msg -v3 -c light_green "store_folder: '$store_folder'"
    gr.msg -v3 -c light_green "store_location (o): '$store_location'"
    gr.msg -v3 -c light_green "store_user (o): '$store_user'"
    gr.msg -v3 -c light_green "store_domain (o): '$store_domain'"
    gr.msg -v3 -c light_green "store_port (o): '$store_port'"
    gr.msg -v3 -c light_green "store_size: '$store_size' ($(numfmt $store_size --to=iec))"
    gr.msg -v3 -c grey "backup_ignore: '$backup_ignore'"
    gr.msg -v3 -c grey "backup_method: '$backup_method'"
    gr.msg -v3 -c grey "honeypot_file: '$honeypot_file'"
    gr.msg -v3 -c grey "GRBL_BACKUP_INDICATOR_KEY: '$GRBL_BACKUP_INDICATOR_KEY'"
    gr.msg -v3 -c grey "backup_stat_file: '$backup_stat_file'"
    [[ -f $backup_stat_file ]] && source $backup_stat_file
    gr.msg -v3 -c grey "last_backup_name: '$last_backup_type'"
    gr.msg -v3 -c grey "last_backup_time: '$last_backup_time'"
    gr.msg -v3 -c grey "last_backup_version: '$last_backup_version'"
    gr.msg -v3 -c grey "last_backup_error: '$last_backup_error'"
    gr.msg -v3 -c light_blue "active_list: '${active_list[@]}'"
}

backup.log_write () {
# write log to file (multi exit cituation) bypass return value
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if [[ $backup_log ]]; then
        echo $backup_log >> $backup_log_file
        backup_log=
    fi
    return $1
}

backup.log_get_event () {
# log what?
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if ! [[ -f $backup_log_file ]]; then
        return 1
    fi

    local event_name=$1
    shift
    local column=$1

    local event_line=$(grep $backup_log_file -e "$event_name;" | tail -1)
    IFS=';'
    read -r -a list <<< "$event_line"
    ifs=$IFS

    case $column in
        time)
            echo "${list[0]}"
            ;;
        error)
            echo "${list[8]}"

        #what else is needed?
    esac
}

backup.log_read () {
# list log events
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if ! [[ -f $backup_log_file ]]; then
        gr.msg "no log events"
        return 0
    fi

    ifs=$IFS

    while read -r line; do
        # cut to parts
        IFS=';'
        read -r -a list <<< "$line"
        ifs=$IFS

        _epic=${list[0]}
        _name=${list[1]}
        _sche=${list[2]}
        _from=${list[3]}
        _size=${list[4]}
        _to=${list[5]}
        _space=${list[6]}
        _cmd=${list[7]}
        _er=${list[8]}

        gr.msg -v4 -n -w 11 "$_epic "
        gr.msg -n -w 10 "$_name " -c light_blue
        gr.msg -n -w 2 "${_sche:0:1} " -c white
        gr.msg -V3 -n -w 11 "$(date -d @$_epic +%Y.%m.%d) "
        gr.msg -n -w 6 "$(date -d @$_epic +%H:%M) "
        gr.msg -v1 -n -w 5 "$_size " -c light_blue
        gr.msg -n -w 45 "$_from " -c aqua_marine
        gr.msg -v2 -V3 -n -w 5 "$_space " -c light_blue
        gr.msg -v2 -V3 -n -w 45 "$_to " -c aqua_marine

        if [[ "${_er:0:1}" == "0" ]]; then
            gr.msg -n -w 27 "$_er " -c green
        else
            gr.msg -n -w 27 "$_er " -c yellow
        fi
        gr.msg -v3 -n "$_cmd " -c dark_grey
        echo

    done < $backup_log_file
}

backup.cloud_status () {
# check what cloud folders are in backup program
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -h "checking status of backup entries and cloud folders"

    local _server="$GRBL_CLOUD_USERNAME@$GRBL_CLOUD_DOMAIN -p $GRBL_CLOUD_PORT"
    local _folder_list=($(ssh $_server -- "ls $GRBL_CLOUD_FILE_BASE"))
    local _entry_var local _entry_val local _cloud_str local _cloud_flr local _entry_flr

    # go trough folder names found cloud location given in mount.cfg
    for (( i = 0; i < ${#_folder_list[@]}; i++ )); do

        gr.msg -n -w 13 -c light_blue "${_folder_list[$i]}"
        # add location to folder name
        _cloud_flr=$GRBL_CLOUD_FILE_BASE/${_folder_list[$i]}

        # make backup entry variable name out of listed folder
        _entry_var="GRBL_BACKUP_${_folder_list[$i]^^}[@]"
        # evaluate variable
        _entry_val=($(eval echo ${!_entry_var}))
        # if empty no entry
        if ! [[ $_entry_val ]]; then
            gr.msg -c dark_grey "   no backup entry"
            continue
        fi
        # get location string from backup configuration line
        _entry_str=${_entry_val[2]}
        # separate folder name from server information
        _entry_flr=$(echo $_entry_str | rev | cut -d ":" -f1 | rev )
        # remove folder separator (rsync make difference with these)
        _entry_flr=${_entry_flr%/*}

        if [[ "${GRBL_BACKUP_SCHEDULE_DAILY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -h "d "
        elif [[ "${GRBL_BACKUP_SCHEDULE_WEEKLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c white "w "
        elif [[ "${GRBL_BACKUP_SCHEDULE_MONTHLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c grey "m "
        elif [[ "${GRBL_BACKUP_SCHEDULE_YEARLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c dark_grey "y "
        else
            gr.msg -n -w 3 -c black "  "
        fi

        # printout last time backup done
        last_time=$(backup.log_get_event ${_folder_list[$i]} time)
        if [[ $last_time ]]; then

            if [[ $last_time -gt $(date -d 'today 00:00:00' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%H:%M) " -c white
            elif [[ $last_time -gt $(date -d 'last week' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) "
            elif [[ $last_time -gt $(date -d 'last month' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) " -c dark_grey
            else
                if  [[ $last_time -gt $(date -d "Jan 1 00:00:00" +%s) ]]; then
                    gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) " -c yellow
                else
                    gr.msg -n -w 7 "$(date -d @$last_time +%y/%m) " -c red
                fi
            fi
        else
            gr.msg -n -w 7 "never" -c black
        fi

        # printout folder patch
        # if mount.online ${_mount_val[0]}; then
        #     gr.msg -n -h "$_entry_flr"
        # else
            gr.msg -n "$_entry_flr"
        # fi

        # check that folders match, printout mismatch if not
        if ! [[ "$_entry_flr" == "$_cloud_flr" ]]; then
            gr.msg -n -c red " != "
            gr.msg -n "$_cloud_flr"
        fi

        # check last error for status
        _error=$(backup.log_get_event ${_folder_list[$i]} error)

        # printout status
        if [[ -f $backup_running ]]; then
            # backup is running right now
            if [[ ${_folder_list[$i]} == $(cat $backup_running) ]]; then
                gr.msg -n -c aqua " running!"
            fi
        # no errors last time
        elif [[ ${_error:0:1} == "0" ]]; then
            gr.msg -n -c green " success"
        # some errors last time
        elif [[ $_error ]]; then
            gr.msg -n -e2 " $(cut -d':' -f2 <<<$_error)"
        # no clue
        else
            gr.msg -n -c dark_gray " unknown"
        fi
        echo
    done
}

backup.mount_status () {
# check what mount points are in backup program
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -h "checking status of backup entries and mount points"

    local _folder_list=($(\
        grep "export GRBL_MOUNT_" $mount_rc | \
        grep -ve '_LIST' -ve '_ENABLED' -ve '_PROXY' -ve 'INDICATOR_KEY' | \
        sed 's/^.*MOUNT_//' | \
        cut -d '=' -f1))
        _folder_list=(${_folder_list[@],,}) ## NOT TESTED

    local _entry_var local _entry_val local _cloud_str local _cloud_flr local _entry_flr

    # go trough folder names found cloud location given in mount.cfg
    for (( i = 0; i < ${#_folder_list[@]}; i++ )); do
        gr.msg -n -w 13 -c light_blue "${_folder_list[$i]}"

        # make mount entry variable name out of listed folder
        _mount_var="GRBL_MOUNT_${_folder_list[$i]^^}[@]"
        # evaluate variable
        _mount_val=($(eval echo ${!_mount_var}))
        # add location to folder name
        _mount_flr=${_mount_val[1]}

        # make backup entry variable name out of listed folder
        _entry_var="GRBL_BACKUP_${_folder_list[$i]^^}[@]"
        # evaluate variable
        _entry_val=($(eval echo ${!_entry_var}))
        # if empty no entry
        if ! [[ $_entry_val ]]; then
            gr.msg -c dark_grey "no backup entry"
            continue
        fi

        # get location string from backup configuration line
        _entry_str=${_entry_val[2]}
        # separate folder name from server information
        _entry_flr=$(echo $_entry_str | rev | cut -d ":" -f1 | rev )
        # remove folder separator (rsync make difference with these)
        _entry_flr=${_entry_flr%/*}

        if [[ "${GRBL_BACKUP_SCHEDULE_DAILY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -h "d "
        elif [[ "${GRBL_BACKUP_SCHEDULE_WEEKLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c white "w "
        elif [[ "${GRBL_BACKUP_SCHEDULE_MONTHLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c grey "m "
        elif [[ "${GRBL_BACKUP_SCHEDULE_YEARLY[*]}" =~ ${_folder_list[$i]} ]]; then
            gr.msg -n -w 3 -c dark_grey "y "
        else
            gr.msg -n -w 3 -c black "  "
        fi

       # printout last time backup done
        last_time=$(backup.log_get_event ${_folder_list[$i]} time)
        if [[ $last_time ]]; then

            if [[ $last_time -gt $(date -d 'today 00:00:00' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%H:%M) " -c white
            elif [[ $last_time -gt $(date -d 'last week' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) "
            elif [[ $last_time -gt $(date -d 'last month' +%s) ]]; then
                gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) " -c dark_grey
            else
                if  [[ $last_time -gt $(date -d "Jan 1 00:00:00" +%s) ]]; then
                    gr.msg -n -w 7 "$(date -d @$last_time +%d.%m.) " -c yellow
                else
                    gr.msg -n -w 7 "$(date -d @$last_time +%y/%m) " -c red
                fi
            fi
        else
            gr.msg -n -w 7 "never" -c black
        fi

        # printout folder patch
        if mount.online ${_mount_val[0]}; then
            gr.msg -n -h "$_entry_flr"
        else
            gr.msg -n "$_entry_flr"
        fi

        # check that folders match, printout mismatch if not
        if ! [[ "$_entry_flr" == "$_mount_flr" ]]; then
            gr.msg -n -c red " != "
            gr.msg -n "$_mount_flr"
        fi

        # check last error for status
        _error=$(backup.log_get_event ${_folder_list[$i]} error)

        # printout status
        if [[ -f $backup_running ]]; then
            # backup is running right now
            if [[ ${_folder_list[$i]} == $(cat $backup_running) ]]; then
                gr.msg -n -c aqua " running!"
            fi
        # no errors last time
        elif [[ ${_error:0:1} == "0" ]]; then
            gr.msg -n -c green " success"
        # some errors last time
        elif [[ $_error ]]; then
            gr.msg -n -e2 " $(cut -d':' -f2 <<<$_error)"
        # no clue
        else
            gr.msg -n -c dark_gray " unknown"
        fi
        echo
    done

}

backup.check_status () {
# check are all mountable
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _entity="mount"

    if [[ $1 ]] ; then
        _entity=$1
        shift
    fi

    source mount.sh
    source backup.sh

    case $_entity in
        cloud|mount)
            backup.${_entity}_status
            return $?
            ;;
        "")
            backup.cloud_status
            backup.mount_status
            return $?
            ;;
    esac
}

backup.check () {
# check things
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _what="status"

    if [[ $1 ]]; then
        _what=$1
        shift
    fi

    case $_what in
        status)
            backup.check_${_what} $@
            return $?
        ;;
    esac
}

backup.entry_exist() {
# Input entry name, return true if it exist in configuration.
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local entry=$1
    shift


    local variable_name="GRBL_BACKUP_${entry^^}[@]"
    local value=($(eval echo ${!variable_name}))

    if ! [[ $value ]] ; then
        gr.msg -v2 -e1 "unknown entry '$entry'"
        return 122
    fi
    return 0
}

backup.debug () {
# debug entrypoint
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    export GRBL_VERBOSE=3
    local name=${GRBL_BACKUP_ACTIVE[0]}
    [[ $1 ]] && name=$1
    backup.config $name
}

backup.config () {
# get tunnel configuration an populate common variables
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    # start to collect log for possible early exits
    local _epicdate=$(date +%s)
    backup_log="$_epicdate"

    # check is enabled
    if ! [[ $GRBL_BACKUP_ENABLED ]] ; then
        gr.msg -c black "backup module disabled"
        backup_log="$backup_log;;;;;;;exited before execution;1:module disabled"
        return 1
    fi

    # declare of global variables
    local store_is_local=
    declare -ga backup_name=$1
    declare -ga active_list=(${GRBL_BACKUP_ACTIVE[@]})
    local header=(store method from ignore)
    backup_log="$_epicdate;$backup_name"

    # exit if not in active list
    if ! echo "${active_list[@]}" | grep -q $backup_name ; then
        gr.msg -e0 "no '$backup_name' in active backup list"
        backup_log="$backup_log;;;;;;exited before execution;2:not in active list"
        return 2
    fi

    # go trough active backups and find match
    for bu_name in ${active_list[@]} ; do
        if [[ "$bu_name" == "$backup_name" ]] ; then
                local from_config="GRBL_BACKUP_${bu_name^^}[@]"

                from_config=(${!from_config})
                declare -g store_device=${from_config[0]}
                local method=${from_config[1]}
                local from_string=${from_config[2]}
                local ignore="${from_config[3]//:/' '}"

                declare -g store_config="GRBL_BACKUP_${store_device^^}[@]"
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
        declare -g from_size=$(ssh ${from_user}@${from_domain} -p ${from_port} -- du -hsb $from_location 2>/dev/null)
        from_size=$(cut -f1 <<<$from_size)

    else
        # source is local drive
        declare -g from_location=$(echo $from_string | cut -d ":" -f3)
        declare -g from_size=$(du -hsb $from_location)
    fi

    # fill store location variables
    if echo ${store[@]} | grep -q ":" ; then
        # store is remote drive
        declare -g store_user=$(echo ${store_config[1]} | cut -d ":" -f1)
        declare -g store_domain=$(echo ${store_config[1]} | cut -d ":" -f2)
        declare -g store_port=$(echo ${store_config[1]} | cut -d ":" -f3)
        declare -g store_location=$(echo ${store_config[1]} | cut -d ":" -f4)
        #declare -g store_size=$(ssh ${store_user}@${store_domain} -p ${store_port} -- stat -f -c '%f' $store_location 2>/dev/null)
        declare -g store_size=$(ssh ${store_user}@${store_domain} -p ${store_port} -- df --output=avail -B 1 $store_location | tail -n 1)
    else
        # store is local drive
        store_is_local=true
        declare -g store_device_file=${store_config[0]}
        declare -g store_file_system=${store_config[1]}
        declare -g store_mount_point=${store_config[2]}
        declare -g store_folder=${store_config[3]}
        # declare -g store_size=$(stat -f -c '%f' $store_mount_point) # gives wrong amount
        declare -g store_size=$(df --output=avail -B 1 $store_mount_point | tail -n 1 )

        if [[ ${store_mount_point: -1} == '/' ]]; then
            declare -g store_location="$store_mount_point$store_folder"
        else
            declare -g store_location="$store_mount_point/$store_folder"
        fi
    fi
        [[ $store_is_local ]] \
            && declare -g backup_stat_file="$store_mount_point/$store_folder/$backup_name/backup.stat" \
            || declare -g backup_stat_file="$GRBL_SYSTEM_MOUNT/backup/$backup_name.stat"

        declare -ga backup_ignore=($ignore)
        declare -g backup_method=$method

        [[ ${from_location: -1} == '/' ]] \
                && declare -g honeypot_file=$from_location"honeypot.txt" \
                || declare -g honeypot_file="$from_location/honeypot.txt"

        backup.variables

        # just for logging, this if filled in backup.now for rsync
        if [[ ${store_location: -1} == '/' ]] ; then
            local for_log="$store_location$backup_name"
        else
            local for_log="$store_location/$backup_name"
        fi
        backup_log="$backup_log;$backup_schedule;$from_domain:$from_location;$(numfmt $from_size --to=iec);$for_log;$(numfmt $store_size --to=iec)"

    return 0
}

backup.status () {
# check latest backup is reachable and returnable.
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local backup_data_folder=$GRBL_SYSTEM_MOUNT/backup

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GRBL_BACKUP_ENABLED ]] ; then
            gr.msg -n -v1 -c green -k $GRBL_BACKUP_INDICATOR_KEY "enabled, "
        else
            gr.msg -v1 -c black -k $GRBL_BACKUP_INDICATOR_KEY "disabled"
            return 1
        fi

    if ! [[ -f $backup_data_folder/next ]] ; then
            gr.msg -v1 -c green -k $GRBL_BACKUP_INDICATOR_KEY \
                "no scheduled backups"
            return 0
        fi

    local epic_backup=$(cat $backup_data_folder/next)
    local diff=$(( $epic_backup - $(date '+%s') ))

    # indicate backup time
    if [[ $diff -lt 7200 ]] ; then
        # indicate that backup will be done soon
        gr.msg -n -v1 -c aqua_marine -k $GRBL_BACKUP_INDICATOR_KEY \
            "scheduled backup at $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        # indicate that that backup is very soon, ~minutes
        [[ $diff -lt $GRBL_DAEMON_INTERVAL ]] && gr.msg -n -v1 -c deep_pink -k $GRBL_BACKUP_INDICATOR_KEY \ "($diff seconds)"
        echo
        return 0
    else
        # all fine, no scheduled backup in few hours
        gr.msg -n -v1 -c green -k $GRBL_BACKUP_INDICATOR_KEY "on service "
        gr.msg -v1 "next backup $(date -d @$epic_backup '+%d.%m.%Y %H:%M')"
        return 0
    fi
}

backup.ls () {
# list available backups and its status
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -v2 "last run time"
    gr.msg -v3 -c todo "TBD last time backed up per entry table"

    gr.msg -v2 "schedule"
    gr.msg -n -c white "daily: "
    gr.msg -c light_blue "${GRBL_BACKUP_SCHEDULE_DAILY[@]}"

    gr.msg -n -c white "weekly: "
    gr.msg -c light_blue "${GRBL_BACKUP_SCHEDULE_WEEKLY[@]}"

    gr.msg -n -c white "monthly: "
    gr.msg -c light_blue "${GRBL_BACKUP_SCHEDULE_MONTHLY[@]}"

    return 0
}

backup.at () {
# set date and time for next backup
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    [[ $1 ]] && local backup_date=$1 || read -p "backup date (YYMMDD): " backup_date
    shift
    [[ $1 ]] && local backup_time=$1 || read -p "backup time (H:M): " backup_time
    shift

    local backup_data_folder="$GRBL_SYSTEM_MOUNT/backup"

    [[ -d $backup_data_folder ]] || mkdir -p $backup_data_folder

    # TBD all kind of checks for user input

    local epic_now=$(date '+%s')
    local epic_backup=$(date -d "$backup_date $backup_time" '+%s')

    if [[ $epic_now -ge $epic_backup ]] ; then
        gr.msg "that is past, try again"
        return 1
    fi

    ## CHANGE
    echo $epic_backup > "$backup_data_folder/next"

    # if daemon is not running (computer sleeping) backup is not run
    # overdue backups shall be run at next start
    return 0
}

backup.restore_wekan () {
# docker restore instructions
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg -c light_blue "docker stop wekan"
    gr.msg -c light_blue "docker exec wekan-db rm -rf /data/dump"
    gr.msg -c light_blue "docker cp dump wekan-db:/data/"
    gr.msg -c light_blue "docker exec wekan-db mongorestore --drop --dir=/data/dump"
    gr.msg -c light_blue "docker start wekan"
    return 127
}

backup.restore () {
# restore entry point
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

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
        *)      gr.msg -e1 "unknown method '$backup_method'"
                return 127
    esac
}

backup.wekan () {
# take a database dump and copy it to location set in user.cfg where normal process can copy it to local
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

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
        gr.msg -e1 "error $?"
        return 128
    fi

    # delete current dump
    gr.msg -v2 -n "delete last dump.. "
    gr.msg -v3 -N -c deep_pink "${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump"

    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump >/dev/null ; then
        gr.msg -v2 -c green "ok"
    else
        gr.msg -e1 "error $?"
        return 129
    fi

    # take a dump
    gr.msg -v2 -n "take a dump /data/dump.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump"

    if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump 2>/dev/null ; then
        gr.msg -c green "ok"
    else
        gr.msg -e1 "error $?"
        return 130
    fi

    # copy to where to rsyck it to final location
    gr.msg -v2 -n "copy to ${_location}.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- [[ -d ${_location} ]] || mkdir -p ${_location}"

    if ssh ${_user}@${_domain} -p ${_port} -- docker cp wekan-db:/data/dump ${_location} >/dev/null ; then
        gr.msg -v2 -c green "ok"
    else
        gr.msg -e1 "error $?"
        return 131
    fi

    # start container
    gr.msg -v2 -n "starting docker container.. "
    gr.msg -v3 -N -c deep_pink "ssh ${_user}@${_domain} -p ${_port} -- docker start wekan"

    if ssh ${_user}@${_domain} -p ${_port} -- docker start wekan >/dev/null ; then
        gr.msg -v2 -c green "ok"
    else
        gr.msg -e1 "error $?"
        return 132
    fi

    return 0
}

backup.now () {
# check things and if pass then make backup
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

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
                    || gr.msg -v1 -e1 "error: $?" -k $GRBL_BACKUP_INDICATOR_KEY
            else
                gr.msg -c white "to mount -t $store_file_system $store_device_file $store_mount_point sudo needed"
                [[ -d $store_mount_point ]] || sudo mkdir -p $store_mount_point
                gr.msg -v3 -N -c deep_pink "sudo mount -t $store_file_system $store_device_file $store_mount_point"

                if sudo mount -t $store_file_system $store_device_file $store_mount_point ; then
                        gr.msg -v1 -c green "ok"
                else
                    gr.msg -v1 -e1 "error: $?" -k $GRBL_BACKUP_INDICATOR_KEY
                    backup_log="$backup_log;exited before execution;32:unable to mount store"
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
        if [[ ${store_location: -1} == '/' ]] ; then
            store_param="$store_location$backup_name"
        else
            store_param="$store_location/$backup_name"
        fi

        gr.debug "location: $store_location folder: $store_folder param: $store_param "
    }


    local_to_local () {
    # make fonfigure for local to local backup

        if ! mount | grep $store_mount_point >/dev/null ; then
            if [[ $DISPLAY ]] && [[ $store_device_file ]] ; then
                gr.msg -v2 -n "mounting store media $store_device_file.. "
                gr.debug "gio mount -d $store_device_file"
                gio mount -d $store_device_file \
                    && gr.msg -v1 -c green "ok" \
                    || gr.msg -v1 -e1 "error: $?" -k $GRBL_BACKUP_INDICATOR_KEY
            fi
        fi
        command_param="-a --progress --update"
        from_param="$from_location"

        if [[ $backup_ignore ]] ; then
            for _ignore in  ${backup_ignore[@]} ; do
                command_param="$command_param --exclude '*$_ignore'"
            done
        fi

        if [[ ${store_location: -1} == '/' ]]; then
            store_param="$store_location$backup_name"
        else
            store_param="$store_location/$backup_name"
        fi
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
    gr.msg -v3 "backup active" -c aqua_marine -k $GRBL_BACKUP_INDICATOR_KEY

    ### 2) check and place variables for rsynck based on user.cfg
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

        if ! [[ -d $store_location ]]; then
            if mkdir -p $store_location; then
                gr.msg -e1 "unable create store location folder"
                backup_log="$backup_log;exited before execution;111:unable create folder"
                return 111
            fi
        fi
    fi

    ### 3) check backup method get files out of service containers based settings in user.cfg
    case $backup_method in
        wekan)
            if ! [[ $from_domain ]] ; then
                gr.msg -e1 "empty server variables"
                backup_log="$backup_log;exited before execution;113:empty server variables"
                return 113
            fi

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
                        gr.msg -c red -k $GRBL_BACKUP_INDICATOR_KEY \
                            "POTENTIAL VIRUS: wannacry tracks detected!"
                        gr.msg -c light_blue "$file"
                        gr.msg -e1 "backup of $from_location canceled"
                        backup_log="$backup_log;exited before execution;101:wannacry detected"
                        return 101
                        ;;

                 *WORM*)
                        gr.msg "TBD other virus track marks here"
                        # echo "last_backup_error=102" >>$backup_stat_file
                        backup_log="$backup_log;exited before execution;102:virus track marks"
                        return 102
                        ;;
            esac
        done

        # check if honeypot file exists
        if ssh $from_user@$from_domain "test -e $honeypot_file" ; then
            [[ -f /tmp/$USER/honeypot.txt ]] && rm -f /tmp/$USER/honeypot.txt
            gr.msg -v2 -n "getting honeypot file.. "
            # get honeypot file

            gr.msg -v3 -N -c deep_pink "eval rsync $command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null"
            if eval rsync "$command_param $from_user@$from_domain:$honeypot_file /tmp >/dev/null" ; then
                gr.msg -v2 -c green "ok"
            else
                gr.msg -e1 "cannot get honeypot file "
            fi
        fi
    fi

    # check is text in honeypot.txt file changed
    if [[ -f /tmp/$USER/honeypot.txt ]] ; then
        gr.msg -v2 -n "checking honeypot file.. "
        local contain=($(cat /tmp/$USER/honeypot.txt))
        rm -f /tmp/$USER/honeypot.txt

        gr.msg -n -v3 "expecting 'honeypot' got '${contain[3]}' "

        if ! [[ ${contain[3]} == "honeypot" ]] ; then
            gr.msg -e1 \
                 "honeypot file changed! got '${contain[3]}' when 'honeypot' expected."
            gr.msg -c light_blue "${contain[@]}"
            gr.msg -c red -k $GRBL_BACKUP_INDICATOR_KEY \
                 "backup canceled cause of potential crypto virus action detected in source destination!"
            export GRBL_BACKUP_ENABLED=

            # echo "last_backup_error=104" >>$backup_stat_file
            # echo "### backup canceled cause of potential crypto virus action detected!" >>$backup_stat_file
            backup_log="$backup_log;exited before execution;104:potential crypto virus"
            return 104
        fi
        gr.msg -v2 -c green "ok"
    fi

    ### 5) check size
    if [[ $from_size -gt $store_size ]] ; then
        gr.msg -e1 "not enough space in target device. ($(numfmt $store_size --to=iec) < $(numfmt $from_size --to=iec))"
        backup_log="$backup_log;exited before execution;105:no space on store"
        return 105
    fi

    ### 6) perform copy
    local _error=$?
    #gr.debug "$FUNCNAME: eval rsync $command_param $from_param $store_param"

    # make command
    local _command="rsync $command_param $from_param $store_param"

    # re-fill log
    #local _epicdate=$(date +%s)
    backup_log="$backup_log;$_command"

    # do the thing
    if [[ $backup_dryrun ]]; then
        gr.msg -h "$backup_name>$backup_running"
        gr.msg -h "eval $_command"
        _error=4
        gr.msg -h "rm $backup_running"
    else
        echo $backup_name>$backup_running
        eval $_command
        _error=$?
        rm $backup_running
    fi

    if [[ $_error -eq 4 ]] ; then
        gr.msg "dryrun, no changes made"
        return 4
    elif [[ $_error -gt 0 ]] ; then
        gr.msg "$from_location error: $backup_method $_error" \
        -c red -k $GRBL_BACKUP_INDICATOR_KEY
        echo "last_backup_error=120" >>$backup_stat_file
        # add error to log
        backup_log="$backup_log;$_error:backup failed"
        return 120
    else
        echo "### $backup_name $(date '+%d.%m.%Y %H:%M')" >$backup_stat_file
        echo "last_backup_version='$(head -n1 $GRBL_BIN/version)'" >>$backup_stat_file
        echo "last_backup_name=$backup_name" >>$backup_stat_file
        echo "last_backup_time=$(date +%s)" >>$backup_stat_file
        echo "last_backup_error=$_error" >>$backup_stat_file
        gr.msg -v3 "$from_location ok" -c green -k $GRBL_BACKUP_INDICATOR_KEY

        # add error to log
        backup_log="$backup_log;$_error:ok"
        return 0
    fi
}

backup.plan () {
# backup all in active list
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local schedule='daily'
    [[ $1 ]] && schedule=$1
    local _item=1;
    local _error=
    local entries=()
    local entry=

    case $schedule in
        hourly|daily|weekly|monthly|yearly)
            backup_schedule=$schedule
            entries=($(eval echo '${GRBL_BACKUP_SCHEDULE_'"${schedule^^}[@]}"))
            ;;
        "")
            gr.msg -e1 "unknown schedule '$schedule'"
            return 11
            ;;
        *)
            variable="GRBL_BACKUP_SCHEDULE_${schedule^^}[@]"
            entries=($(eval echo ${!variable}))
            if ! [[ $entries ]] ; then
                gr.msg -e1 "unknown schedule '$schedule'"
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
        gr.msg -n "backing up $entry $(( $i + 1 ))/${#entries[@]}.. "

        backup.config $entry

        # check is last backup old enough
        if [[ -f $backup_stat_file ]] ; then
            source $backup_stat_file

            case $schedule in
                 hourly)
                    add_seconds=3600
                    ;;
                 daily)
                    add_seconds=86400
                    ;;
                 weekly)
                    add_seconds=604800
                    ;;
                 monthly)
                    add_seconds=2629743
                    ;;
                 yearly)
                    add_seconds=31556926
                    ;;
            esac

            next_backup=$(( last_backup_time + add_seconds ))
            # gr.msg "next_backup: $next_backup last_backup_time: $last_backup_time add_seconds: $add_seconds"

            if [[ $(date +%s) -lt $next_backup ]] && ! [[ $GRBL_FORCE ]]; then
                gr.msg -c dark_grey "waiting $(date -d @$next_backup '+%d.%m.%Y %H:%M')"
                continue
            fi
        fi

        backup.now $entry || (( _error++ ))
        backup.log_write $?
    done

    if [[ $_error -gt 0 ]] ; then
        gr.msg "$_error warnings, check log above" -e1 -k $GRBL_BACKUP_INDICATOR_KEY
        [[ $GRBL_BACKUP_VERBOSE ]] && gr.ind say -m "$_error warnings during $schedule backup"
        return 12
    else
        #gr.msg -v3 -c green "$schedule done"
        [[ $GRBL_BACKUP_VERBOSE ]] && gr.ind done -m "$schedule backup" -k $GRBL_BACKUP_INDICATOR_KEY
        return 0
    fi
}


backup.scheduled () {
# run an set scheduled backup
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local schedule='daily'
    [[ $1 ]] && schedule=$1

    local backup_data_folder=$GRBL_SYSTEM_MOUNT/backup
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

        # $GRBL_SYSTEM_MOUNT/<entry_name>.stat
        # $next_time > $backup_data_folder/next
        #echo "next_time=$next_time" > $backup_stat_file
        #last_time=1645715582
        # last_note="last time got $_error"

        local rechedule="next backup scheduled to $(date -d @$(cat $backup_data_folder/next) '+%d.%m.%Y %H:%M')"
        gr.msg -c white $rechedule
        [[ $GRBL_BACKUP_VERBOSE ]] && gr.ind say -m "next backup scheduled for tomorrow"

        return $_error
    fi
}


backup.poll () {
# poll functions
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: backup status polling started" -k $GRBL_BACKUP_INDICATOR_KEY
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: backup status polling ended" -k $GRBL_BACKUP_INDICATOR_KEY
            ;;
        status )
            backup.status
            backup.scheduled daily
            ;;
        *)  gr.msg -c dark_grey "function not written"
            return 0
    esac
}


backup.rc () {
# source configurations
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if ! [[ -f $backup_rc ]] || [[ $(( $(stat -c %Y $backup_config) - $(stat -c %Y $backup_rc) )) -gt 0 ]] ; then
        backup.make_rc && \
        gr.msg -v1 -c dark_gray "$backup_rc updated"
    fi

    source $backup_rc
}


backup.make_rc () {
# make core module rc file out of configuration file
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if ! source config.sh ; then
        gr.msg -e1 "unable to load configuration module"
        return 100
    fi

    if [[ -f $backup_rc ]] ; then
        rm -f $backup_rc
    fi

    if ! config.make_rc "$backup_config" $backup_rc ; then
        gr.msg -e1 "configuration failed"
        return 101
    fi

    chmod +x $backup_rc

    if ! source $backup_rc ; then
        gr.msg -c red "unable to source configuration"
        return 202
    fi
}


backup.install () {
# install needed tools
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    sudo apt update && \
    sudo apt install ssh scp rsync sshfs pv
    return $?
}


backup.remove () {
# remove stuff
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    gr.msg "no point to remove so basic tools.."
    return 0
}

# update configurations
backup.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup.main "$@"
    exit "$?"
else
    gr.msg -v4 -n -c $__backup_color "$__backup [$LINENO] sourced  " >&2 # debug
fi
