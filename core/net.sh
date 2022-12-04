#!/bin/bash
# guru-client network module casa@ujo.guru 2022

## include needed libraries
source common.sh
## declare run wide global variables
# declare -g temp_file="/tmp/guru-net.tmp"
declare -g net_indicator_key="f$(gr.poll net)"
declare -g net_log_folder="$HOME/.log"

## functions, keeping help at first position it might be even updated
net.help () {
    # user help
    gr.msg -n -v2 -c white "guru-cli net help "
    gr.msg -v1 "guru-cli network control module"
    gr.msg -v2
    gr.msg -v0 -c white  "usage:    net check|status|help"
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " status     return network status "
    gr.msg -v1 " check      check internet is reachable "
    gr.msg -v1 " server     check accesspoint is reachable "
    gr.msg -v1 " cloud      fileserver is reachable"
    gr.msg -v2 " help       printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "examples:  "
    gr.msg -v1 "$GURU_CALL net      textual status info"
    gr.msg -v2
}


net.main () {
# main command parser

    local function="$1" ; shift
    ## declare one shot variables here only if really needed
    ## declare -g bubble_gum=̈́true

    case "$function" in
            ## add functions called from outside on this list
            check|status|help|poll)
                net.$function $@
                return $?
                ;;
            server|accesspoint|access)
                net.check_server $@
                return $?
                ;;
            cloud|fileserver|files)
                net.check_server $GURU_CLOUD_DOMAIN
                return $?
                ;;

            *)
                net.check_server && gr.msg -c green "server reachable" || gr.msg -c orange "server offline"
                net.check && gr.msg -c green "internet available" || gr.msg -c orange "internet unreachable"
                ;;
        esac
}


net.check_server () {
# quick check accesspoint connection, no analysis

    local _server=$GURU_ACCESS_DOMAIN
    [[ $1 ]] && _server=$1

    gr.msg -n -t -v3 "ping $_server.. "
    if timeout 2 ping $_server -W 2 -c 1 -q >/dev/null 2>/dev/null ; then
        gr.msg -v3 "ok "
        gr.end $net_indicator_key
        return 0
    else
        gr.msg -v3 "$_server unreachable! "
        gr.ind offline -m "$_server unreachable" -k $net_indicator_key
        return 127
    fi
}



net.check () {
# quick check network connection, no analysis
    gr.msg -n -t -v3 "ping google.com.. "
    if timeout 3 ping google.com -W 2 -c 1 -q >/dev/null 2>/dev/null ; then

        gr.msg -v3 "ok "
        gr.end $net_indicator_key
        return 0
    else
        gr.msg -v3 "unreachable! "
        gr.ind offline -m "network offline" -k $net_indicator_key
        return 127
    fi
}


## following function is used as daemon polling interface
net.status () {
# output net status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # check net is enabled
    if [[ $GURU_NET_ENABLED ]] ; then
            gr.msg -n -v1 \
            -c green "enabled, " \
            -k $net_indicator_key
        else
            gr.msg -v1 \
            -c black "disabled"  \
            -k $net_indicator_key
            return 1
        fi

    # other tests with output, return errors
    if net.check ; then
            gr.msg -n -v1 \
                -c aqua_marine "connected, " \
                -k $net_indicator_key
        else
            gr.msg -v1 \
                -c orange "offline" \
                -k $net_indicator_key

            if [[ $GURU_NET_LOG ]] ; then

                    if ! [[ -d $net_log_folder ]] ; then
                        ehco mkdir -p "$net_log_folder"
                        touch "$net_log_folder/net.log"
                    fi

                    gr.msg "$(date "+%Y-%m-%d %H:%M:%S") network offline" >>"$net_log_folder/net.log"

                fi

            return 2
        fi

    gr.msg -v1 -c green "available " -k $net_indicator_key
    return 0
    }


net.poll () {
# daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $net_indicator_key ]] || \
        net_indicator_key="f$(gr.poll net)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $net_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $net_indicator_key
            ;;
        status)
            net.status $@
            ;;
        *)  net.help
            ;;
        esac
}


## if net requires tools or libraries to work installation is done here
net.install () {

    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gr.msg "nothing to install"
    return 0
}

## instructions to remove installed tools.
## DO NOT remove any tools that might be considered as basic hacker tools even net did those install those install
net.remove () {

    # sudo apt remove -y ...
    # pip3 remove --user ...
    gr.msg "nothing to remove"
    return 0
}

# if called net.sh file configuration is sourced and main net.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    net.main "$@"
    exit "$?"
fi

