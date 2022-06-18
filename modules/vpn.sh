#!/bin/bash
# guru-client vpn functions

#source $GURU_RC
source common.sh


vpn.main () {

	case $1 in
		open|close|install|uninstall )
			;;
	esac
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
        else
            gr.msg -c yellow "error during vpn connection"
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

