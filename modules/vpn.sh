#!/bin/bash
# guru-client vpn functions

source common.sh

original_ip_file='/tmp/vpn-original-ip'

vpn.main () {

    local cmd=$1
    shift

    case $cmd in
        status|open|close|install|uninstall|toggle|check|ip|help)
            vpn.$cmd "$@"
            ;;
    esac
}


vpn.help () {
    # genereal help
    gr.msg -v1 -c white "guru-client vpn help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL vpn status|open|close|install|uninstall] "
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " status           vpn status "
    gr.msg -v1 " ip               display ip if vpn is active"
    gr.msg -v2 " check            return zero if vpn connection is active"
    gr.msg -v1 " toggle           toggle vpn connection"
    gr.msg -v1 " open             vpn tunnel to default location" -V2
    gr.msg -v2 " open <country> <city> <protocol>"
    gr.msg -v2 "                  vpn tunnel to given server"
    gr.msg -v3 " ls               TBD list of available vpn out "
    gr.msg -v1 " close            close vpn connection"
    gr.msg -v1 " kill             kill open vpn client"
    gr.msg -v1 " install          install requirements "
    gr.msg -v1 " uninstall        remove installed requirements "
    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL vpn open "
    gr.msg -v2
}


vpn.ip () {

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

    if ps auxf | grep openvpn | grep -v grep >/dev/null ; then
            return 0
        else
            return 1
        fi
}


vpn.toggle () {

    if vpn.check ; then
            gr.msg -v2 "session found, closing.."
            vpn.close
        else
            gr.msg -v2 "session not found, opening.."
            vpn.open
        fi
}


vpn.status () {

    gr.msg -v1 -n "vpn status: "

    if [[ -f /usr/sbin/openvpn ]] ; then
            gr.msg -n -v2 -c green "installed "
        else
            gr.msg -c red "application not installed"
            gr.msg -v2 -c white "try to '$GURU_CALL vpn install'"
            return 100
        fi

    gr.msg -n -v2 "server list: "
    if [[ -d /etc/openvpn/tcp ]] ; then
            gr.msg -n -v2 -c green "ok "
        else
            gr.msg -c red "not found"
            return 101
        fi

    gr.msg -n -v2 "credentials: "
    if [[ -f /etc/openvpn/credentials ]] ; then
            gr.msg -n -v2 -c green "ok "
        else
            gr.msg -c red "not found"
            return 102
        fi

    local ip_now="$(curl -s https://ipinfo.io/ip)"

    gr.msg -n -v2 "ip: "
    gr.msg -n -v2 -c green "$ip_now "

    if [[ -f /tmp/guru.vpn.ip ]] ; then
            local ip_last="$(cat /tmp/guru.vpn.ip)"
            gr.msg -n -v3 -c dark_crey "$ip_last "
        fi

    gr.msg -n -v2 "currently: "
    if [[ $ip_now == $ip_last ]] ; then
            gr.msg -c aqua_marine "active"
            return 0
        else
            gr.msg -c green "available"
            return 0
        fi
}

vpn.rm_original_file () {
    if [[ $original_ip_file ]] && [[ -f $original_ip_file ]] ; then
        rm -f if $original_ip_file && gr.msg -v2 "$original_ip_file deleted"
        fi
}


vpn.open () {
# open vpn connection set in user.cfg

    local country=fi
    local city=Helsinki
    [[ $GURU_VPN_DEFAULT ]] && city="$GURU_VPN_DEFAULT"

    # check configurations done
    if ! [[ -d /etc/openvpn/tcp ]] ; then
            gr.msg -c yellow "no open vpn configuration found"
            gr.msg -v2 "run '$GURU_CALL vpn install' first"
            return 101
        fi

    local ifs=$IFS
    IFS=$'\n'
    local user_input=(${@,,})
    local got=
    local file_list=($(ls /etc/openvpn/tcp))

    if [[ $1 ]] ; then
        for (( i = 0; i < ${#file_list[@]}; i++ )); do
                # gr.msg "${file_list[$i],,}"
                country="$(echo ${file_list[$i],,} | cut -f 2 -d '-' )"
                city="$(echo ${file_list[$i],,} | cut -f 3 -d '-' )"

                if [[ $country == $user_input ]] || [[ $city == $user_input ]] ; then
                        # gr.msg -c deep_pink "got '$city' at '$country'"
                        got=true
                        break
                    fi
            done
        fi

    # return separator settings
    IFS=$ifs

    if ! [[ $got ]] ; then
            gr.msg -c yellow "no server in '$user_input' "
            gr.msg -c white "city list: "
            local server_list=$(ls /etc/openvpn/tcp | cut  -f 3 -d '-')
            gr.msg -c light_blue "$(sed -z 's/\n/, /g' <<<$server_list)"
            return 101
        fi

    if [[ -f /etc/openvpn/credentials ]] ; then
            [[ $GURU_VPN_USERNAME ]] || GURU_VPN_USERNAME="$(sudo head -n1 /etc/openvpn/credentials)"
            [[ $GURU_VPN_PASSWORD ]] || GURU_VPN_PASSWORD="$(sudo tail -n1 /etc/openvpn/credentials)"
        # else
        #     gr.msg -c yellow "no credentials found, make sure that you have vpn service provider"
        #     gr.msg -v2 "add username as first and password to second line to file '/etc/openvpn/credentials'"
        #     return 102
        fi

    # us case
    city=$(sed -e 's/^./\U&/g; s/ ./\U&/g' <<<$city)

    local current_ip=$(curl -s https://ipinfo.io/ip)

    # check is original ip saved meaning that connection is already active
    if [[ -f $original_ip_file ]] ; then
            original_ip=$(head -n1 $original_ip_file)
            current_server=$(tail -n1 $original_ip_file)
            gr.msg -c aqua_marine "already connected to $current_server"
            gr.msg -v2 "close connection first to change server by '$GURU_CALL vpn close'"
            return 12
        else
            echo $current_ip >$original_ip_file
            echo $city, ${country^^} >>$original_ip_file
        fi

    gr.msg "original ip is: $current_ip"
    gr.msg "connecting to $city"
    gr.msg -c white -v2 "vpn username and password copied to clipboard, paste it to 'Enter Auth Username:' field"
    printf "%s\n%s\n" "$GURU_VPN_USERNAME" "$GURU_VPN_PASSWORD" | xclip -i -selection clipboard


    if sudo openvpn \
        --config /etc/openvpn/tcp/NCVPN-${country^^}-"$city"-TCP.ovpn \
        --daemon
        then
            sleep 4
            local new_ip="$(curl -s https://ipinfo.io/ip)"

            if [[ "$current_ip" == "$new_ip" ]] ; then
                    gr.msg -c red "connection failed"
                    gr.msg "ip is still $new_ip"
                    return 100
                fi
            gr.msg "our external ip is now: $new_ip"
            echo "$new_ip" >/tmp/guru.vpn.ip
        else
            gr.msg -c yellow "error during vpn connection"
            vpn.rm_original_file
            return 101
        fi

    return 0
}




vpn.close () {
# close vpn connection (if exitst)
    local current_ip="$(curl -s https://ipinfo.io/ip)"
    gr.msg "our ip was: $current_ip"

    if sudo pkill openvpn ; then
            gr.msg -v2 "kill success"
        else
            gr.msg "no vpn client running"
            vpn.rm_original_file
            return 0
        fi

    local new_ip="$(curl -s https://ipinfo.io/ip)"

    if [[ "$current_ip" == "$new_ip" ]] ; then
            gr.msg -c red "kill failed"
            return 100
        fi
    gr.msg "our ip is now: $new_ip"

    vpn.rm_original_file

    return 0
}



vpn.close () {
# closes vpn connection if exitst
    local current_ip="$(curl -s https://ipinfo.io/ip)"
    gr.msg "our ip was: $current_ip"

    if sudo pkill openvpn ; then
            gr.msg -v2 "kill success"
        else
            gr.msg "no vpn client running"
            vpn.rm_original_file
            return 0
        fi

    local new_ip="$(curl -s https://ipinfo.io/ip)"

    if [[ "$current_ip" == "$new_ip" ]] ; then
            gr.msg -c red "kill failed"
            return 100
        fi
    gr.msg "our ip is now: $new_ip"

    vpn.rm_original_file

    return 0
}


vpn.install () {

    [[ -f /usr/sbin/openvpn ]] || apt-get install openvpn

    if [[ -d /etc/openvpn/tcp ]] ; then
            gr.msg "server list found"
        else
            cd /tmp
            wget https://vpn.ncapi.io/groupedServerList.zip
            unzip groupedServerList.zip
            [[ -d /etc/openvpn ]] || sudo mkdir -p /etc/openvpn
            sudo mv tcp /etc/openvpn
            sudo mv udp /etc/openvpn
            rm -f groupedServerList.zip
        fi


    if [[ -f /etc/openvpn/credentials ]] ; then
            gr.msg "credentials found"
        else
            [[ $GURU_VPN_USERNAME ]] \
                || read -p "vpn auth username: " GURU_VPN_USERNAME
            [[ $GURU_VPN_PASSWORD ]] \
                || read -p "vpn auth password: " GURU_VPN_PASSWORD

            echo "$GURU_VPN_USERNAME" | sudo tee /etc/openvpn/credentials
            echo "$GURU_VPN_PASSWORD" | sudo tee -a /etc/openvpn/credentials
        fi
}


vpn.uninstall () {

    [[ -f /usr/sbin/openvpn ]] || apt-get install openvpn
    # /etc/openvpn
    # /etc/openvpn/credentials
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source $GURU_RC
    vpn.main "$@"
    exit $?
fi

