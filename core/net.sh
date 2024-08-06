#!/bin/bash
# guru-client network module casa@ujo.guru 2022

declare -g net_rc="/tmp/guru-cli_net.rc"
declare -g tunneled_flag="/tmp/guru-cli_service_tunnel.flag"

net.help () {
# network module user help

    gr.msg -v2 -c white "guru-cli network control module help "
    gr.msg -v2
    gr.msg -v1 -c white -n "usage:  "
    gr.msg -v0 " $GURU_CALL net check|status|host|server|cloud|type|ip|listen|help <optional_information>"
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " status                         return network status "
    gr.msg -v1 " check                          check internet is reachable "
    gr.msg -v1 " host <command>                 set or check /etc/hosts domain redirection "
    gr.msg -v2 "      check|direct|tunnel|basic    "
    gr.msg -v1 " server                         check access point is reachable "
    gr.msg -v2 "      domain_name|ip            check is specific server is reachable"
    gr.msg -v1 " cloud                          file server is reachable"
    gr.msg -v2 "      domain_name|ip            check is specific server is reachable"
    gr.msg -v2 " type                           information of server connection"
    gr.msg -v1 " help                           printout this help "
    gr.msg -v2 " ip <domain>                    get ip of specified service"
    gr.msg -v2 " listen                         listen ip traffic of local computer"
    gr.msg -v2 "      netstat_options           by default '-nputwc' is in use  "
    gr.msg -v2
    gr.msg -v1 -c white "examples:  "
    gr.msg -v1 " $GURU_CALL net status           info of network and server connection"
    gr.msg -v1 " $GURU_CALL net host tunnel      set ujo.guru to point local host"
    gr.msg -v1 " $GURU_CALL net check loop       check net status every 10'th second"
    gr.msg -v2
    gr.msg -v1 "list all commands and options by increasing verbosity by '-v2' " -V2
}


net.main () {
# main command parser

    local function="$1" ; shift
    ## declare one shot variables here only if really needed
    ## declare -g bubble_gum=̈́true

    case "$function" in
            ## add functions called from outside on this list
            check|status|help|poll|host|listen)
                net.$function $@
                return $?
                ;;
            server|accesspoint|access)
                net.check_server $@
                return $?
                ;;
            cloud)
                net.check_server $GURU_CLOUD_DOMAIN
                return $?
                ;;
            type)
                net.check_service_type
                return $?
                ;;
            *)
                net.check
                return $?
                ;;
        esac
}


net.ip () {
# get ip of SERVICE domain*, return \n reparated list of found ip's

# service domain is new for this purpose added variable to point services,
# like wekan, dokuwiki on access point server. services can be accessed trough
# tunnel and therefore use of same variable fucks things up lit try to make ssh
# tunnel to sever domain set to localhost .
# GURU_SERVICE_DOMAIN allows point service domain to localhost when services are tunneled.

    local domain=$GURU_SERVICE_DOMAIN
    [[ $1 ]] && domain=$1
    [[ $domain ]] || return 127
    dig $domain A +short
}


net.check_service_type () {
# check is access domain set to /etc/hosts point to localhost

    if [[ $(net.ip) == $(net.ip localhost) ]] ; then
        gr.debug "$FUNCNAME: services are accessed trough tunnel"
        touch $tunneled_flag
    else
        gr.debug "$FUNCNAME: services are accessed from LAN"
        [[ -f $tunneled_flag ]] && rm $tunneled_flag
    fi
}


net.host () {
# check and set domain name to /etc/hosts to point url of services globally to right server

    local command=$1
    local target_file="/tmp/hosts"
    local line=

    # Copy original file for modifications
    cp /etc/hosts $target_file

    check_direct_rule () {
    # check is ujo.guru pointed directly to server
        line=$(grep $GURU_ACCESS_LAN_IP $target_file | grep $GURU_SERVICE_DOMAIN | grep -v "#" | head -n1 )
        [[ $line ]] || return 1
        gr.debug "$FUNCNAME: exist $line"
        return 0
    }

    check_tunnel_rule () {
    # check is ujo.guru and localhost pointed to 127.0.0.1
        line=$(grep "127.0.0.1" $target_file | grep "localhost" | grep -v $GURU_SERVICE_DOMAIN | grep -v "#" | head -n1 )
        [[ $line ]] || return 1
        gr.debug "$FUNCNAME: exist '$line'"
        return 0
    }

    check_basic_rule () {
    # check is there localhost without ujo.guru domain point (basic setup)
        line=$(grep "127.0.0.1" $target_file | grep $GURU_SERVICE_DOMAIN | grep -v "#" | head -n1 )
        [[ $line ]] || return 1
        gr.debug "$FUNCNAME: exist $line"
        return 0
    }

    check_all () {
        check_basic_rule && gr.msg "${GURU_SERVICE_DOMAIN} points to localhost but tunnel needed to access ${GURU_ACCESS_DOMAIN} services"

        if check_direct_rule; then
            gr.msg "${GURU_ACCESS_DOMAIN} access from LAN ${GURU_SERVICE_DOMAIN} > $GURU_ACCESS_LAN_IP"
            return 0
        fi

        check_tunnel_rule && gr.msg "${GURU_ACCESS_DOMAIN} access trough ssh tunnel or from web"
        return 0
    }

    set_direct () {
        check_basic_rule && sed -i "/${line}/d" $target_file
        check_tunnel_rule || sed -i '1s/^/127.0.0.1\tlocalhost\n/' $target_file
        check_direct_rule || sed -i "1s/^/${GURU_ACCESS_LAN_IP}\t${GURU_SERVICE_DOMAIN}\n/" $target_file
    }

    set_basic () {
        check_tunnel_rule && sed -i "/${line}/d" $target_file
        check_direct_rule && sed -i "/${line}/d" $target_file
        check_basic_rule || sed -i "1s/^/127.0.0.1\tlocalhost ${GURU_SERVICE_DOMAIN}\n/" $target_file
    }

    set_clean () {
        check_basic_rule && sed -i "/${line}/d" $target_file
        check_direct_rule && sed -i "/${line}/d" $target_file
        check_tunnel_rule || sed -i '1s/^/127.0.0.1\tlocalhost\n/' $target_file
    }

    set_tunnel () {
        source tunnel.sh
        if ! tunnel.check ; then
            if gr.ask "you might like to establish tunnels first?"; then
                set_clean
                tunnel.main open
            fi
        fi
        check_tunnel_rule && sed -i "/${line}/d" $target_file
        check_direct_rule && sed -i "/${line}/d" $target_file
        check_basic_rule || sed -i "1s/^/127.0.0.1\tlocalhost ${GURU_SERVICE_DOMAIN}\n/" $target_file
    }

    case $command in
        direct|tunnel|basic|clean)
            set_$command
            ;;
        check|"")
            check_all
            return $?
            ;;
        *)
            gr.msg -e1 "please check, local, tunnel or basic"
            return 0
            ;;
    esac

    sudo cp $target_file /etc/hosts
}


net.rc () {
# source configurations

    if  [[ ! -f $net_rc ]] || \
        [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/net.cfg) - $(stat -c %Y $net_rc) )) -gt 0 ]]
        then
            net.make_rc && \
                gr.msg -v1 -c dark_gray "$net_rc updated"
        fi

    source $net_rc
}


net.make_rc () {
# make core module rc file out of configuration file

    if ! source config.sh ; then
            gr.msg -c yellow "unable to load configuration module"
            return 100
        fi

    if [[ -f $net_rc ]] ; then
            rm -f $net_rc
        fi

    if ! config.make_rc "$GURU_CFG/$GURU_USER/net.cfg" $net_rc ; then
            gr.msg -c yellow "configuration failed"
            return 101
        fi

    chmod +x $net_rc

    if ! source $net_rc ; then
            gr.msg -c red "unable to source configuration"
            return 202
        fi
}


net.listen () {
# printout list of used out pond ports
    netstat -nputwc $@
}


# net.listen () {

# # usage: tcpflow [-aBcCDhIpsvVZ] [-b max_bytes] [-d debug_level]
# #      [-[eE] scanner] [-f max_fds] [-F[ctTXMkmg]] [-h|--help] [-i iface]
# #      [-l files...] [-L semlock] [-m min_bytes] [-o outdir] [-r file] [-R file]
# #      [-S name=value] [-T template] [-U|--relinquish-privileges user] [-v|--verbose]
# #      [-w file] [-x scanner] [-X xmlfile] [-z|--chroot dir] [expression]
# #    -a: do ALL post-processing.
# #    -b max_bytes: max number of bytes per flow to save
# #    -d debug_level: debug level; default is 1
# #    -f: maximum number of file descriptors to use
# #    -H: print detailed information about each scanner
# #    -i: network interface on which to listen
# #    -I: write for each flow another file *.findx to provide byte-indexed timestamps
# #    -g: output each flow in alternating colors (note change!)
# #    -l: treat non-flag arguments as input files rather than a pcap expression
# #    -L  semlock - specifies that writes are locked using a named semaphore
# #    -p: don't use promiscuous mode
# #    -q: quiet mode - do not print warnings
# #    -r file      : read packets from tcpdump pcap file (may be repeated)
# #    -R file      : read packets from tcpdump pcap file TO FINISH CONNECTIONS
# #    -v           : verbose operation equivalent to -d 10
# #    -V           : print version number and exit
# #    -w  file     : write packets not processed to file
# #    -o  outdir   : specify output directory (default '.')
# #    -X  filename : DFXML output to filename
# #    -m  bytes    : specifies skip that starts a new stream (default 16777216).
# #    -F{p} : filename prefix/suffix (-hh for options)
# #    -T{t} : filename template (-hh for options; default %A.%a-%B.%b%V%v%C%c)
# #    -Z       do not decompress gzip-compressed HTTP transactions

# # Security:
# #    -U user  relinquish privleges and become user (if running as root)
# #    -z dir   chroot to dir (requires that -U be used).

# # Control of Scanners:
# #    -E scanner   - turn off all scanners except scanner
# #    -S name=value  Set a configuration parameter (-hh for info)
#     return 0
# }

net.portmap () {
# check open ports of domain $1
    return 0
}


net.proxy (){
# listen localhost port $1 and proxy to destnation domain $2 and port $3
# optional log_file_location $4
    return 0
}


net.check_server () {
# quick check accesspoint connection, no analysis

    local _server=$GURU_ACCESS_DOMAIN
    [[ $1 ]] && _server=$1

    #gr.msg -t -n "server.status "
    gr.debug "ping $_server.. "
    if timeout 2 ping $_server -W 2 -c 1 -q >/dev/null 2>/dev/null ; then
        gr.msg -v3 -c green "$_server available "
        gr.end $GURU_NET_INDICATOR_KEY
        return 0
    else
        #gr.msg -t -n "server.status "
        gr.msg -v3 -c orange "$_server unreachable! "
        gr.ind offline -m "$_server unreachable" -k $GURU_NET_INDICATOR_KEY
        return 127
    fi
}


net.check () {
# quick check network connection, no analysis
    gr.debug "ping google.com.. "
    if timeout 3 ping google.com -W 2 -c 1 -q >/dev/null 2>/dev/null ; then

        gr.end $GURU_NET_INDICATOR_KEY
        gr.msg -v1 -c green "online " -k $GURU_NET_INDICATOR_KEY
        return 0
    else
        gr.msg -v1 -c red "offline "
        gr.ind offline -m "network offline" -k $GURU_NET_INDICATOR_KEY
        return 127
    fi
}

## call mqtt module to perform checks
# net.mqtt_check () {
# # check that mqtt server connection works

#     source mqtt.sh

#     send_message () {
#         (sleep 2) ; (mqtt.main pub check hello &)
#     }

#     # check mqtt is enabled
#     if ! [[ $GURU_MQTT_ENABLED ]] ; then
#         gr.msg -v1 -c black "disabled" -k $GURU_MQTT_INDICATOR_KEY
#         return 1
#     fi

#     send_message

#     if (mqtt.single check1 >/dev/null) ; then
#         gr.msg -c green "online "
#         return 0
#     else
#         gr.msg -c red "offline "
#         return 127
#     fi

# }

net.status_loop () {
# do loop test till connection gets available.
# Positional variables: timeout in seconds and optional exit-on-pass flag

    local interval=10
    local break_set=

    [[ $1 ]] && interval=$1
    shift

    [[ $1 ]] && break_set=true

    source mqtt.sh

    while true ; do
        if net.status && mqtt.status; then
            gr.blink $GURU_NET_INDICATOR_KEY available
            [[ $break_set ]] && break
        else
            gr.blink $GURU_NET_INDICATOR_KEY error
        fi

        # sleep $interval
        read -s -n1 -t $interval ans
        case ans in q|Q|x|X) break ;; esac
    done

}


net.status () {
# output net status
    local _return=0
    local _sub_command=$1
    shift

    case $_sub_command in
        loop)
            net.status_loop $@
            return 0
            ;;
    esac

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # check net is enabled
    if [[ $GURU_NET_ENABLED ]] ; then
        gr.msg -n -v1 -c green "enabled, "
    else
        gr.msg -v1 -c black "disabled" -k $GURU_NET_INDICATOR_KEY
        return 1
    fi

    # other tests with output, return errors

    if net.check >/dev/null; then
        gr.msg  -c aqua "online "
    else
        if [[ $GURU_NET_LOG ]] ; then
                gr.msg -v1  -c red "offline "
                [[ -d $GURU_NET_LOG_FOLDER ]] || mkdir -p "$GURU_NET_LOG_FOLDER"
                gr.msg "$(date "+%Y-%m-%d %H:%M:%S") network offline" >>"$GURU_NET_LOG_FOLDER/net.log"
            fi
        _return=101
    fi

    gr.msg -v1 -n -t "net.server "
    if net.check_server >/dev/null; then
        gr.msg -v1 -n -c green "available, "
        if ps auxf | grep $GURU_DATA | grep -v grep -q ; then
            gr.msg -v1 -c aqua "connected "
        else
            gr.msg -v1 -c black "not connected "
        fi

    else
        gr.msg -v1 -c orange "unreachable"
        _return=102
    fi

    # if [[ $GURU_MQTT_ENABLED ]] ; then
    #       source mqtt.sh
    #       mqtt.status
    # fi

    return $_return
}


net.poll () {
# daemon interface

    # check is indicator set (should be, but wanted to be sure)
    [[ $GURU_NET_INDICATOR_KEY ]] || \
        GURU_NET_INDICATOR_KEY="f$(gr.poll net)"

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $GURU_NET_INDICATOR_KEY
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $GURU_NET_INDICATOR_KEY
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
    sudo apt-get install -y portmap tcpflow
    # pip3 install --user ...
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

net.rc

# if called net.sh file configuration is sourced and main net.main called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    net.main "$@"
    exit "$?"
fi

