#!/bin/bash
# guru-client vpn functions

# load module configuration
declare -g original_ip_file='/tmp/vpn-original-ip'
declare -g tunneled_ip_file='/tmp/vpn-tunneled-ip'
declare -A vpn

if [[ -f $GURU_CFG/vpn.cfg ]] ; then
        source $GURU_CFG/vpn.cfg \
        && gr.debug "sourcing $GURU_CFG/vpn.cfg" \
        || gr.msg -c yellow "failed to source $GURU_CFG/vpn.cfg"
    fi

if [[ -f $GURU_CFG/$GURU_USER/vpn.cfg ]] ; then
        source $GURU_CFG/$GURU_USER/vpn.cfg \
        && gr.debug "sourcing $GURU_CFG/$GURU_USER/vpn.cfg" \
        || gr.msg -c yellow "failed to source $GURU_CFG/$GURU_USER/vpn.cfg"
    fi


vpn.help () {
# general help

    gr.msg -v1 "guru-cli vpn help " -h
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL vpn status|poll|close|install|uninstall|toggle|check|ip|help|kill|update "
    gr.msg -v1 "          $GURU_CALL vpn open <city>|<country_code> "
    gr.msg -v2
    gr.msg -v1 "commands:" -c white
    gr.msg -v1 "  status               vpn status "
    gr.msg -v2 "  ls                   list of cities where vpn servers available"
    gr.msg -v1 "  open <city|country>  vpn tunnel to default location"
    gr.msg -v1 "  close                close vpn connection"
    gr.msg -v1 "  kill                 force kill open vpn client"
    gr.msg -v2 "  toggle               toggle vpn connection"
    gr.msg -v2 "  check                return zero if vpn connection is active"
    gr.msg -v2 "  ip                   display ip if vpn is active"
    gr.msg -v1 "  install              install requirements "
    gr.msg -v1 "  change               change provider and set server list files "
    gr.msg -v1 "  uninstall            remove installed requirements "
    gr.msg -v2
    gr.msg -v1 "example:" -c white
    gr.msg -v1 "  $GURU_CALL vpn open jp                # open connection to first server in Japan"
    gr.msg -v1 "  $GURU_CALL vpn open new orleans -f    # close previous connection and open connection to Louisiana"
    gr.msg -v2
}


vpn.main () {
# main command parser

    local cmd=$1
    shift

    case $cmd in
        status|poll|close|install|uninstall|toggle|check|ip|help|kill|change)
            vpn.$cmd "$@"
            return $?
            ;;
        open)
            if [[ $1 ]] ; then
                connect_to="$@"
            else
                [[ ${vpn[default]} ]] && connect_to=${vpn[default]}
            fi
            vpn.open $connect_to
            return $?
            ;;
        "")
            vpn.toggle
            return $?
            ;;
        *)
            gr.msg "unknown vpn command '$cmd' "
            return 1
    esac
}


vpn.kill () {
# kill vpn connection
    while ps auxf | grep openvpn | grep -q -v grep ; do
        sudo pkill openvpn \
            && gr.msg -c green "connection killed" \
            || gr.msg -c red "kill failed"
        sleep 0.5
    done
    return 0
}


vpn.ip () {
# get current ip and report connection status

    local ip_now="$(curl -s https://ipinfo.io/ip)"

    if vpn.check ; then
        gr.msg "$ip_now"
        return 0
    else
        gr.msg -v2 "not connected"
        return 1
    fi

}


vpn.check () {
# check is vpn active

    if ps auxf | grep openvpn | grep -q -v grep ; then
            return 0
        else
            curl -s https://ipinfo.io/ip >$original_ip_file
            return 1
        fi
}


vpn.toggle () {
# shortcut toggling

    if vpn.check ; then
            gr.msg -v2 "session found, closing.."
            vpn.close
        else
            gr.msg -v2 "session not found, opening.."
            vpn.open ${vpn[default]}
        fi
}


vpn.status () {
# printout status with timestamp

    source net.sh
    net.status >/dev/null || return 99

    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    if [[ -f /usr/sbin/openvpn ]] ; then
        gr.msg -n -v1 -c green "installed, "
    else
        gr.msg -c red "application not installed"
        gr.msg -v2 -c white "try to '$GURU_CALL vpn install'"
        return 100
    fi

    if [[ ${vpn[enabled]} ]] ; then
        gr.msg -n -v1 -c green "enabled, "
    else
        gr.msg -v1 -c black "disabled" -k ${vpn[indicator_key]}
        return 0
    fi

    if [[ -d /etc/openvpn/tcp ]] ; then
        gr.msg -n -v2 -c green "server list ok, "
    else
        gr.msg -c red "server list not found" -k ${vpn[indicator_key]}
        return 101
    fi

    #gr.msg -n -v1 "credentials: "
    if [[ -f /etc/openvpn/credentials ]] ; then
        gr.msg -n -v1 -c green "and credentials ok, "
    else
        gr.msg -c red "credentials not found" -k ${vpn[indicator_key]}
        return 102
    fi

    if ! ping google.com -q -c1 -W 1 >/dev/null ; then
        gr.msg -n -v1 "vpn session is "
        gr.msg -c yellow "stalled "
        gr.msg -v2 "..or damn too slow "
        return 103
    fi

    if [[ -f $tunneled_ip_file ]] ; then
        local tunneled_ip="$(cat $tunneled_ip_file)"
    fi

    if [[ -f $original_ip_file ]] ; then
        local original_ip="$(cat $original_ip_file)"
    fi

    local current_ip=$(curl -s https://ipinfo.io/ip)
    local current_city=$(curl -s https://ipinfo.io/city)
    local current_country=$(curl -s https://ipinfo.io/country)

    if vpn.check && [[ $current_ip != $original_ip ]] ; then
        gr.msg -n -v2 "connected to "
        gr.msg -c aqua "$current_ip, $current_city, $current_country " -k ${vpn[indicator_key]}
        return 0
    else
        gr.msg -n -v2 "native ip "
        gr.msg -c green "$current_ip $current_city, $current_country " -k ${vpn[indicator_key]}
        return 1
    fi
}


vpn.open () {
# open vpn connection

    local user_input="${@,,}"
    local connect_to_country=
    local connect_to_city=

    # check software is installed and contains config folder
    if ! [[ -d /etc/openvpn/tcp ]] ; then
            gr.msg -c yellow "no open vpn configuration found" -k ${vpn[indicator_key]}
            gr.msg -v2 "run '$GURU_CALL vpn install' first"
            return 101
        fi

    if ! [[ ${vpn[enabled]} ]] ; then
        gr.msg -v2 -c black "disabled" -k ${vpn[indicator_key]}
        return 1
    fi

    local ifs=$IFS
    IFS=$'\n'
    local file_list=($(ls /etc/openvpn/tcp))
    local server_found_in_list=

    if [[ $user_input ]] ; then
        for (( i = 0; i < ${#file_list[@]}; i++ )); do
            # gr.debug "${file_list[$i],,}"


            case ${vpn[provider]} in

                namecheap|fastvpn)
                    # NCVPN-US-Cincinnati-UDP.ovpn
                    connect_to_country="$(echo ${file_list[$i],,} | cut -f 2 -d '-' )"
                    connect_to_city="$(echo ${file_list[$i],,} | cut -f 3 -d '-' )"
                    ;;
                protonvpn|protonmail)
                    # jp-free-118016.protonvpn.tcp.ovpn
                    connect_to_country="$(echo ${file_list[$i],,} | cut -f 1 -d '-' )"
                    connect_to_city="$(echo ${file_list[$i],,} | cut -f 1 -d '.' )"
                    connect_to_city="$(echo $connect_to_city | cut -f 3 -d '-' )"
                    ;;

                esac

            if [[ "$connect_to_country" == "$user_input" ]] || [[ "$connect_to_city" == "$user_input" ]] ; then
                    gr.debug "server_found_in_list '$connect_to_city' at '$connect_to_country'"
                    server_found_in_list=true
                    break
                fi
        done
        gr.debug "connect_to_city: $connect_to_city"
        gr.debug "connect_to_country: $connect_to_country"

        # return separator settings
        IFS=$ifs
    fi

    if [[ -z $server_found_in_list ]] ; then
        gr.msg -c yellow "no server in '$user_input' "

        case ${vpn[provider]} in
            namecheap|fastvpn) local server_list=$(ls /etc/openvpn/tcp | cut  -f 3 -d '-' | sort) ;;
            proton*) local server_list=$(ls /etc/openvpn/tcp | cut  -f 1 -d '.' | sort) ;;
        esac

        gr.msg -c light_blue "$(sed -z 's/\n/, /g' <<<$server_list)"
        return 102
    fi

    # check is user service provider credentials saved to openvpn configuration
    if [[ -f /etc/openvpn/credentials ]] ; then
        [[ ${vpn[username]} ]] || vpn[username]="$(sudo head -n1 /etc/openvpn/credentials)"
        [[ ${vpn[password]} ]] || vpn[password]="$(sudo tail -n1 /etc/openvpn/credentials)"
        # else
        #     gr.msg -c yellow "no credentials found, make sure that you have vpn service provider"
        #     gr.msg -v2 "add username as first and password to second line to file '/etc/openvpn/credentials'"
        #     return 102
    fi

    # change words to upcase (yes there is bash 4.1+ native method)
     case ${vpn[provider]} in
        namecheap|fastvpn) connect_to_city=$(sed -e 's/^./\U&/g; s/ ./\U&/g' <<<$connect_to_city) ;;
        # proton*)  true;;
    esac



    local original_ip=$(head -n1 $original_ip_file)
    local tunneled_ip=

    # if there is tunneled ip file, connection may be active
    [[ -f $tunneled_ip_file ]] && tunneled_ip=$(head -n1 $tunneled_ip_file)
    if ! ping google.com -q -c1 -W 1 >/dev/null ; then
        gr.msg -n "killing stalled vpn session.. "
        if ! vpn.kill ; then
            return 103
        fi
    fi

    [[ $GURU_FORCE ]] && vpn.kill

    # get current connection details
    local current_ip=$(curl -s https://ipinfo.io/ip)
    local current_city=$(curl -s https://ipinfo.io/city)
    local current_country=$(curl -s https://ipinfo.io/country)

    gr.debug "original_ip: $original_ip, current_ip: $current_ip"

    # check is vpn connection already open
    if vpn.check && [[ "$original_ip" != "$current_ip" ]] ; then
        gr.msg -v1 -n "already connected to "
        gr.msg -c aqua "$current_ip, $current_city, $current_country " -k ${vpn[indicator_key]}
        gr.msg -v2 "close connection first to change server by '$GURU_CALL vpn close' or 'kill"
        return 0
    fi

    # place credentials to clipboard (yes, but guru trust local)
    gr.msg -c white -v2 "vpn username and password copied to clipboard, paste it to 'Enter Auth Username:' field"
    printf "%s\n%s\n" "${vpn[username]}" "${vpn[password]}" | xclip -i -selection clipboard

   case ${vpn[provider]} in
        namecheap|fastvpn) sudo openvpn --config "/etc/openvpn/tcp/NCVPN-${connect_to_country^^}-"$connect_to_city"-TCP.ovpn" --daemon ;;
        proton*)  sudo openvpn --config "/etc/openvpn/tcp/${connect_to_country}-free-${connect_to_city}.protonvpn.tcp.ovpn" --daemon ;;
    esac

    for (( i = 0; i < 10; i++ )); do
        current_ip="$(curl -s https://ipinfo.io/ip)"
        gr.debug "original_ip: '$original_ip', current_ip: '$current_ip'"
        [[ "$current_ip" == "$original_ip" ]] || break
        sleep 1
    done

    if [[ "$current_ip" == "$original_ip" ]] ; then
        gr.msg -c yellow "error during vpn connection " -k ${vpn[indicator_key]}

        gr.msg -c red "connection failed" -k ${vpn[indicator_key]}
        gr.msg -v2 "ip is still $current_ip, $current_city, $current_country"
        return 103
    fi

    local current_city=$(curl -s https://ipinfo.io/city)
    local current_country=$(curl -s https://ipinfo.io/country)
    gr.msg -n -v2 "connected to "
    gr.msg -c aqua "$current_ip, $current_city, $current_country " -k ${vpn[indicator_key]}
    echo "$current_ip" >$tunneled_ip_file

    return 0
}

vpn.allow-ssh () {

    gr.debug "${FUNCNAME[0]}: $@ TBD"
    # https://www.cyberciti.biz/faq/ufw-allow-incoming-ssh-connections-from-a-specific-ip-address-subnet-on-ubuntu-debian/
    # export VPN_IP="139.1.2.3"  # VPN server/client address
    # export SERVER_PUB_IP="198.74.55.33"  # server IPv4 address
    # export SSH_PUB_PORT="22"   # server ssh port number
    # sudo ufw allow from "$VPN_IP" to "$SERVER_PUB_IP" port "$SSH_PUB_PORT" proto tcp comment 'Only allow VPN IP to access SSH port'
}


vpn.close () {
# close vpn connection (if exist)

    local tunneled_ip=$(head -n1 $tunneled_ip_file)
    local original_ip=$(head -n1 $original_ip_file)
    # gr.msg -V2 -n "$tunneled_ip "

    if ! ps auxf | grep openvpn | grep -q -v grep ; then
        gr.msg -v1 "no vpn client running"
        return 0
    fi

    if vpn.kill ; then
        gr.msg -c green -v2 "kill success" -k ${vpn[indicator_key]}
    else
        gr.msg -v1 -c red "kill failed" -k ${vpn[indicator_key]}
        return 0
    fi

    sleep 2

    local current_ip="$(timeout 5 curl -s https://ipinfo.io/ip)"

    if [[ "$current_ip" == "$original_ip" ]] ; then
        gr.msg -c green "returned ip: $tunneled_ip "
        rm $tunneled_ip_file
        return 0
    elif [[ "$current_ip" == "$tunneled_ip" ]] ; then
        gr.msg -c red "failed, still $tunneled_ip" -k ${vpn[indicator_key]}
        return 100
    else
        gr.msg -c yellow "hmm.. weird ip but it changed: $tunneled_ip" -k ${vpn[indicator_key]}
        return 1
    fi

}

# vpn.close () {
# # closes vpn connection if exitst

#     local current_ip="$(curl -s https://ipinfo.io/ip)"
#     gr.msg "our ip was: $current_ip"

#     if sudo pkill openvpn ; then
#             gr.msg -v2 "kill success"
#         else
#             gr.msg "no vpn client running"
#             vpn.rm_original_file
#             return 0
#         fi

#     local new_ip="$(curl -s https://ipinfo.io/ip)"

#     if [[ "$current_ip" == "$new_ip" ]] ; then
#             gr.msg -c red "kill failed"
#             return 100
#         fi
#     gr.msg "our ip is now: $new_ip"

#     vpn.rm_original_file

#     return 0
# }

vpn.poll () {
# daemon poller will run this

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: polling started" -k ${vpn[indicator_key]}
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: polling ended" -k ${vpn[indicator_key]}
            ;;
        status )
           vpn.status $@
            ;;
        *) vpn.help
            ;;
        esac

}


vpn.install () {
# uninstall and set configuration

    [[ -f /usr/sbin/openvpn ]] || apt-get install openvpn

    if [[ -d /etc/openvpn/tcp ]] ; then
            gr.msg "server list found"
        else
            vpn.change
        fi

    gr.msg -Nh "update account details"
    gr.msg "1) get providers vpn username and password"
    gr.msg "2) edit file '$GURU_CFG/$GURU_USER/vpn.cfg'"
    gr.msg "3) change provider to protonvpn 'vpn[provider]=protonvpn'"
    gr.msg "4) copy username to 'vpn[username]=' and passwod to 'vpn[password]='"
    gr.msg "5) save file"

    if [[ -f /etc/openvpn/credentials ]] ; then
            gr.msg "credentials found"
        else
            [[ ${vpn[username]} ]] \
                || read -p "vpn auth username: " vpn[username]
            [[ ${vpn[password]} ]] \
                || read -p "vpn auth password: " vpn[password]

            echo "${vpn[username]}" | sudo tee /etc/openvpn/credentials
            echo "${vpn[password]}" | sudo tee -a /etc/openvpn/credentials
        fi
}


vpn.change () {
# change vpn provider and update server list
# only Protonmail's protonVPN and Namecheap's fastVPN supported for now

    local provider=$1

    if [[ -z $provider ]] ; then
        read -p "please input vpn provider name, 'fastvpn' or 'protonvpn': " provider
    fi

    [[ -d /tmp/vpn ]] && rm -r /tmp/vpn
    mkdir -p /tmp/vpn
    cd /tmp/vpn

    [[ -d /etc/openvpn ]] || sudo mkdir -p /etc/openvpn
    [[ -d /etc/openvpn/tcp ]] || sudo mkdir -p /etc/openvpn/tcp
    [[ -d /etc/openvpn/udp ]] || sudo mkdir -p /etc/openvpn/udp
    [[ -f $GURU_CFG/$GURU_USER/vpn.cfg ]] || cp $GURU_CFG/vpn.cfg $GURU_CFG/$GURU_USER/vpn.cfg

    case $provider in

        protonvpn|protonmail)

            gr.msg -Nh "update account details"
            gr.msg "1) go to https://account.protonvpn.com/account#openvpn"
            gr.msg "2) edit file '$GURU_CFG/$GURU_USER/vpn.cfg'"
            gr.msg "3) change provider to protonvpn 'vpn[provider]=protonvpn'"
            gr.msg "4) copy username to 'vpn[username]=' and passwod to 'vpn[password]='"
            gr.msg "5) save file"

            read -p "continue by pressing enter: " ans

            if gr.ask "remove current openvpn server files? (sudo needed)" ; then
                sudo rm "/etc/openvpn/tcp/*.protonvpn.tcp.ovpn"
                sudo rm "/etc/openvpn/udp/*.protonvpn.udp.ovpn"
            fi

            gr.msg -Nh "copy server files"
            gr.msg "1) go to https://account.protonvpn.com/downloads#openvpn-configuration-files"
            gr.msg "2) login or make account "
            gr.msg "3) select platform 'GNU/Linux' and protocol TCP"
            gr.msg "4) download tcp and udp configuration files you like to use"
            gr.msg "5) select protocol UDP and download files again (optional)"
            gr.msg "6) go folder where files ovpn files were downloaded (often $HOME/Download"
            gr.msg "7) run: 'sudo cp *tcp.ovpn /etc/openvpn/tcp' "
            gr.msg "        'sudo cp *udp.ovpn /etc/openvpn/udp' (optional)"

            read -p "continue by pressing enter: " ans

            if [[ -f /etc/openvpn/credentials ]] ; then
                gr.ask "remove current openvpn credentials file?" && rm /etc/openvpn/credentials
            fi

            if gr.ask "update newly updated credentials to openvpn config (optional) "; then
                source $GURU_CFG/$GURU_USER/vpn.cfg
                echo "${vpn[username]}" | sudo tee /etc/openvpn/credentials
                echo "${vpn[password]}" | sudo tee -a /etc/openvpn/credentials
            fi

            gr.msg -Nh "test"
            gr.msg "try to connect by 'gr vpn open jp' (or other downloaded country code"
            gr.msg "if fails, check configs in $GURU_CFG/$GURU_USER/vpn.cfg "
            gr.msg "          check files in /etc/openvpn/tcp/ "
            ;;

        namecheap|fastvpn)

            gr.msg -Nh "update account details"
            gr.msg "1) go to https://account.fastvpn.com/login/ and log in and "
            gr.msg "   navigate to page where credentials are shown"
            gr.msg "2) edit file '$GURU_CFG/$GURU_USER/vpn.cfg'"
            gr.msg "3) change provider to fastvpn 'vpn[provider]=fastvpn'"
            gr.msg "4) copy username to 'vpn[username]=' and passwod to 'vpn[password]='"
            gr.msg "5) save file"

            read -p "continue by pressing enter: " ans

            if gr.ask "remove current openvpn server files? (sudo needed)" ; then
                sudo rm "/etc/openvpn/tcp/NCVPN-*.ovpn"
                sudo rm "/etc/openvpn/udp/NCVPN-*.ovpn"
            fi

            gr.msg -Nh "copying server lists.."
            wget https://vpn.ncapi.io/groupedServerList.zip
            unzip groupedServerList.zip
            sudo mv tcp /etc/openvpn
            sudo mv udp /etc/openvpn
            rm -f groupedServerList.zip
            ;;

        *)
            gr.msg -e1 "'${vpn[provider]}' is not proper provider, please fill 'vpn[provider]=' to $GURU_CFG/$GURU_USER/vpn.cfg."
            return 100
            ;;
    esac
}


vpn.uninstall () {
# uninstall and remove configuration

    if gr.ask "remove current openvpn server files and credentials? (sudo needed)" ; then
        sudo rm "/etc/openvpn/tcp/*.ovpn"
        sudo rm "/etc/openvpn/udp/*.ovpn"
        sudo rm "/etc/openvpn/credentials"
    fi

    [[ -f /usr/sbin/openvpn ]] && apt-get remove openvpn
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    vpn.main "$@"
    exit $?
fi

