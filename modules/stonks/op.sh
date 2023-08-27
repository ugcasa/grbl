#!/bin/bash
# guru-cli OP bank csv importer (and later bank api client)
# casa@ujo.guru 2023

op.main () {
# main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in

        import)
            op.$_cmd "$@"
            return $?
        ;;

        *)
            op.status
            return $?
        ;;
    esac
}


op.status() {
# printout staus of this op part of module

	gr.debug "$FUNCNAME: TBD"
    return $?
}


op.import () {
# read bank csv and remove non important columns

	local account_csv=$1
    local account_name=
    local account_number=
    local database="/tmp/account_database"
    [[ $account_csv ]] || read -p "account data file to import: " account_csv

    sed 's/"//g' $account_csv | sed 's/[ ][ ]*/ /g' | sed 's/Ä/A/g'| sed 's/ä/a/g'| sed 's/Ö/O/g' | sed 's/ö/o/g' >/tmp/account_data

    account_csv="/tmp/account_data"

    [[ -f "/tmp/account_id" ]] && id=$(head -n1 "/tmp/account_id") || id=1000000
    while IFS=';' read -r date1 date2 amount type description got_paid account bic viite message shit
    do
        let id++
        echo "$id;$date1;$amount;$got_paid;$account$message"
        # gr.msg -n -w9 "$id"
        # gr.msg -n -w12 "$date1 "
        # gr.msg -n -w12 "€ $amount "
        # gr.msg -n -w35 "$got_paid  "
        # gr.msg -n -w80 "$account$message"
    done < $account_csv >> $database

    echo $id>/tmp/account_id
    echo $database

    return $?
}


op.install() {

    gr.debug "$FUNCNAME: TBD"
    # sudo apt install bash-builtins
    # enable -f /usr/lib/bash/csv csv
}

# soursing this file you will get preset functions in use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # run entry function only is colled from terminal
    # other modules should source this first, then call <module>.main function
    op.main "$@"
fi
