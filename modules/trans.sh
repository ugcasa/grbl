#!/bin/bash
# ujo.guru 2019

trans.main() {
    # command paerser

    local _cmd="$1"
    shift

    case "$_cmd" in
        get|help|status)
            trans.$_cmd $@
            return $?
            ;;

        "") trans.looper
            ;;

        *)
            trans.get "$_cmd"
            return $?
            ;;
    esac
}


trans.help () {
    gr.msg -c white "usage:    $GURU_CALL trans source_lang:targed_lang <text>"
    return 0
}


trans.looper ()
# tranlator looper for quick key
{
    while true
    do
        read -p  "translate: " input
        [[ $input ]] || continue

        case $input in
            q) break ;;
        esac

        echo "-------------------------"
        trans "$input"
        echo "-------------------------"
    done
}


trans.status () {
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    gr.msg -v1 -c dark_gray "no status information"
    return 0
}


trans.get () {
     # terminal based translator
     # TODO: bullshit, re-write (handy shit dow, in daily use)

     if ! [ -f $GURU_BIN/trans ]; then
        cd $GURU_BIN
        wget git.io/trans
        chmod +x ./trans
    fi

    if [[ $1 == *"-"* ]]; then
        argument1=$1
        shift
    else
        argument1=""
    fi

    if [[ $1 == *"-"* ]]; then
        argument2=$1
        shift
    else
        argument2=""
    fi

    if [[ $1 == *":"* ]]; then
        #echo "iz variable: $variable"
        variable=$1
        shift
        word=$@

    else
        #echo "iz word: $word"
        word=$@
        variable=""
    fi

    $GURU_BIN/trans $argument1 $argument2 $variable "$word"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trans.main "$@"
    return $?
fi