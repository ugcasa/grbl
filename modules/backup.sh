#!/bin/bash
# guru client backup functions
# casa@ujo.guru 2020
source $GURU_BIN/common.sh
#backup_indicator_key="f$(poll_order backup)"

backup.help () {
    gmsg -v1 -c white "guru-client backup help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL backup  status|poll|install|remove "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " now                      make backup now "
    gmsg -v1 " at <H:M>                 make backup at time, 24h time only "
    gmsg -v1 " at <YYYYMMDD> <H:M>      make backup at date, 'tomorrow' is valid "
    gmsg -v1 " list|ls                  list of backups "
    gmsg -v1 " restore                  not clear hot to be done  "
    gmsg -v1 " install                  install client requirements "
    gmsg -v1 " remove                   remove installed requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v3 " poll start|end           start or end module status polling "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 " $GURU_CALL backup status    # printout current backup
                                           # list of backups"
    gmsg -v2
}



backup.run () {
}

backup.list () {
}

backup.ls () {
}




backup.main () {
    # command parser
    backup_indicator_key="f$(poll_order backup)"

    local _cmd="$1" ; shift
    case "$_cmd" in

                now|at|list)
                            backup.$_cmd "$@" ; return $? ;;
                status|help|install|poll)
                            backup.$_cmd "$@" ; return $? ;;
                *)          echo "${FUNCNAME[0]}: unknown command"
        esac

    return 0
}



backup.status () {
    # check backup broker is reachable.
    # printout and signal by corsair keyboard indicator led - if available

    if backup.online ; then
            gmsg -v1 -t -c green "${FUNCNAME[0]}: backups available " -k $backup_indicator_key
            return 0
        else
            gmsg -v1 -t -c red "${FUNCNAME[0]}: backups access not available " -k $backup_indicator_key
            return 1
        fi
}



backup.poll () {

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
            ;;
        *)  backup.help
            ;;
        esac

}


backup.install () {
    sudo apt update && \
    sudo apt install <<<<<<<<<<<<<
    return 0
}


backup.remove () {
    sudo apt remove <<<<<<
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    backup.main "$@"
    exit "$?"
fi

