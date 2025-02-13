#!/bin/bash flag.sh is for soursing only
declare -g flag_list=(running fast pause cancel ok stop next prev skip suspend audio_stop audio_hold)

flag.help () {
# flag help

    gr.msg -v1 "grbl flag help" -h
    gr.msg -v2
    gr.msg -v1 "way to setup and control non inteface processes (like grbl daemon)"
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL system flag set|rm|ls|toggle|check|status|help"
    gr.msg -v1 "          $GRBL_CALL <flag_name>         return flag status"
    gr.msg -v2
    gr.msg -v1 "commands:" -c white
    gr.msg -v2
    gr.msg -v1 " check <flag>   return flag status"
    gr.msg -v1 " ls             list of flags with status"
    gr.msg -v1 " set <flag>     set flag"
    gr.msg -v1 " rm <flag>      remove flag"
    gr.msg -v2 " help           this help"
    gr.msg -v2
}


flag.main () {
# set flags

    local cmd=$1 ; shift
    case $cmd in

        set|get|rm|ls|toggle|check|status|help)
                flag.$cmd $@
                return $?
                ;;
        rise|lift|brace)
                flag.set $@
                return $?
                ;;
        reset|unset|remove|disable)
                flag.rm $@
                return $?
                ;;
        "")     flag.ls
                return $?
                ;;
        *)      flag.check $cmd
                return $?

    esac
}


flag.check () {
# returen true if flag is set, no printout

    if [[ -f /tmp/$USER/grbl-$1.flag ]] ; then
        return 0
    else
        return 1
    fi
}


flag.get () {
# return flag status
    local flag_name=${1//'_'/' '}
    if flag.check $1 ; then
        gr.msg -v1 -c green "$flag_name is set"
        return 0
    else
        gr.msg -v4 -c dark_grey "$flag_name not set"
        return 1
    fi
}



flag.ls () {
# return true if flag is set, no printout
    for flag in ${flag_list[@]} ; do

        [[ $flag == ${flag_list[0]} ]] || gr.msg -n ", "
        gr.msg -n "$flag:"

        if flag.check $flag ; then
            gr.msg -n "set"
        else
            gr.msg -n "unset"
        fi
    done
    gr.msg
}


flag.status () {
# list of flags

    gr.msg -v2 -c white "grbl flag status:"
    local flag=

    for flag in ${flag_list[@]} ; do

        gr.msg -n "$flag: "

        if flag.check $flag ; then
            gr.msg -c aqua "set"
        else
            gr.msg -c dark_grey "unset"
        fi
    done
}


flag.set () {
# set flag

    local flag="$1"

    if ! [[ $flag ]] ; then
        gr.msg -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
        return 0
    fi

    if [[ -f /tmp/$USER/grbl-$flag.flag ]] ; then
        gr.msg -t -v3 "$flag flag already set"
        return 0
    else
        touch /tmp/$USER/grbl-$flag.flag && gr.msg -v3 -t "$flag flag set"
    fi
}


flag.rm () {
# release flag

    local flag="$1"

    if ! [[ $flag ]] ; then
        gr.msg  -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
        return 0
    fi

    if [[ -f /tmp/$USER/grbl-$flag.flag ]] ; then
        rm -f /tmp/$USER/grbl-$flag.flag && gr.msg -v3 -t "$flag flag removed"
        return 0
    else
        gr.msg -t -v3 "$flag flag not set"
    fi
}


flag.toggle () {
# toggle flag status

    local flag="$1"

    if ! [[ $flag ]] ; then
        gr.msg -c yellow "${FUNCNAME[0]}: unknown flag '$flag'"
        return 0
    fi

    if [[ -f /tmp/$USER/grbl-$flag.flag ]] ; then
        rm -f /tmp/$USER/grbl-$flag.flag && gr.msg -v3 -t "$flag flag disabled"
        return 0
    else
        touch /tmp/$USER/grbl-$flag.flag && gr.msg -v3 -t "$flag flag set"
    fi
}
