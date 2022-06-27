#!/bin/bash
# guru-client vpn functions

source common.sh

vpn.main () {

	local cmd=$1
    shift

    case $cmd in
		status|open|close|install|uninstall|toggle|check )
            vpn.$cmd
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
    gr.msg -v1 " open             open vpn connection to Helsinki "
    gr.msg -v1 " close            close vpn connection"
    gr.msg -v1 " install          install requirements "
    gr.msg -v1 " remove           remove installed requirements "

    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL vpn open "
    gr.msg -v2
}


vpn.check () {

    if ps u | grep openvpn | grep -v grep ; then
            return 0
        else
            return 100
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


vpn.open () {
    # open vpn connection set in user.cfg
    local original_ip="$(curl -s https://ipinfo.io/ip)"

    if [[ -f /etc/openvpn/credentials ]] ; then
        [[ $GURU_VPN_USERNAME ]] || GURU_VPN_USERNAME="$(sudo head -n1 /etc/openvpn/credentials)"
        [[ $GURU_VPN_PASSWORD ]] || GURU_VPN_PASSWORD="$(sudo tail -n1 /etc/openvpn/credentials)"
    fi
    GURU_VPN_DEFAULT_OVPN="NCVPN-FI-Helsinki-TCP"
    gr.msg "original ip: $original_ip"
    gr.msg -v2 "vpn username and password copied to clipboard, paste it to 'Enter Auth Username:' field"
    printf "%s\n%s\n" "$GURU_VPN_USERNAME" "$GURU_VPN_PASSWORD" | xclip -i -selection clipboard

    if sudo openvpn \
        --config /etc/openvpn/tcp/$GURU_VPN_DEFAULT_OVPN.ovpn \
        --daemon
        then
            sleep 3
            local new_ip="$(curl -s https://ipinfo.io/ip)"

            if [[ "$original_ip" == "$new_ip" ]] ; then
                    gr.msg -c red "connection failed"
                    return 100
                fi
            gr.msg "our external ip is: $new_ip"
            echo "$new_ip" >/tmp/guru.vpn.ip
        else
            gr.msg -c yellow "error during vpn connection"
            return 101
        fi

    return 0
}


vpn.close () {
    # closes vpn connection if exitst
    local original_ip="$(curl -s https://ipinfo.io/ip)"
    gr.msg "our ip was: $original_ip"

    if sudo pkill openvpn ; then
            gr.msg -v2 "kill success"
        else
            gr.msg "no vpn client running"
            return 0
        fi

    local new_ip="$(curl -s https://ipinfo.io/ip)"

    if [[ "$original_ip" == "$new_ip" ]] ; then
            gr.msg -c red "kill failed"
            return 100
        fi
    gr.msg "our ip is now: $new_ip"

    if [[ -f /tmp/guru.vpn.ip ]] ; then
            rm -f §/tmp/guru.vpn.ip
        fi

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
    source $GURU_RC
    vpn.main "$@"
    exit $?
fi

