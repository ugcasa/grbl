#!/bin/bash
# guru-client backup system
# casa@ujo.guru 2021
source $GURU_BIN/common.sh

backup.help () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@ "
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


backup.check_space () {
    # check free space of server disk

    declare -l mount_point=$GURU_SYSTEM_MOUNT
    [[ $1 ]] && mount_point=$1
    declare -l column=4
    if [[ $2 ]] ; then
        case $2 in
            u|used)
            column=3
            ;;
            '%'|usage)
            column=5
            ;;
            a|available|free|*)
            column=4
            ;;
        esac
    fi

    # df with parameters
    declare -g server_free_space=$(df \
        | grep $GURU_SYSTEM_MOUNT \
        | tr -s " " \
        | cut -d " " -f $column \
        | sed 's/[^0-9]*//g')

    # printout
    echo "$server_free_space"
}


backup.main () {
    gmsg -n -v3 -c pink "${FUNCNAME[0]} $@ "
    # command parser
    backup_indicator_key="f$(daemon.poll_order backup)"

    local command="$1" ; shift
    case "$command" in

                ls|list|status|help|install|poll)
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


backup.status () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # check latest backup is reachable and returnable.
    gmsg -n -t -v1 "${FUNCNAME[0]}: "

    if [[ -f $GURU_BACKUP_CONFIG ]] ; then
            gmsg -v1 -c green "ok" -k $backup_indicator_key
            return 0
        else
            gmsg -v1 -c red "configuration not found! " -k $backup_indicator_key
            return 1
        fi
}


backup.list () {

    local ifs=$IFS
    local tall=0
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"


    # (/home/casa/porn)
    # list available backups and its status
    return 0
}


backup.ls () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # alias for list
    backup.list $@
    return $?
}


backup.at () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # set of cron like launcher based on daemon
    # if daemon is not running (computer sleeping) backup is not run
    # overdue backups shall be run at next start
    return 0
}


backup.now () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # run backup
    # input list of backup
    return 0
}


backup.poll () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # poll functions
    # TBD: write cooperative standard function for timed processes

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
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    # install needed tools
    sudo apt update && \
    sudo apt install ssh scp rsync sshfs pv
    return $?
}


backup.remove () {
    gmsg -v3 -c pink "${FUNCNAME[0]} $@"
    #sudo apt remove xxx
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    backup.main "$@"
    exit "$?"
fi

