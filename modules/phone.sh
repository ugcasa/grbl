#!/bin/bash
# phone tools for guru-client casa@ujo.guru 2017-2022
source mount.sh
source config.sh

__phone=$(readlink --canonicalize --no-newline $BASH_SOURCE)

declare -g phone_rc=/tmp/$USER/guru-cli_phone.rc
declare -g phone_config="$GURU_CFG/$GURU_USER/phone.cfg"
declare -g require=(kdeclient-cli)
declare -g phone_name="unknown"


phone.help () {
# phones help printout
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2
    gr.msg -v1 -c white "guru-client phone help "
    gr.msg -v2
    gr.msg -v0 "Usage:    $GURU_CALL phone ping|pair|check|config|install|uninstall|help "
    gr.msg -v1 -c white "Commands:"
    gr.msg -v2
    gr.msg -v1 " config         add firewall rule etc "
    gr.msg -v1 " check          check connection with phone "
    gr.msg -v1 " pair <name>    pair device (optional name)"
    gr.msg -v1 " ping <msg>     ping phone with optional message "
    gr.msg -v1 " ring           make phone to ring "
    gr.msg -v1 " find           alias for above "
    gr.msg -v1 " install        install needed software"
    gr.msg -v1 " uninstall      remove installed software"
    gr.msg -v2
}

phone.main () {
# main command parser
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    local command="$1" ; shift

    case "$command" in

        ring|find|ping|pair|unpair|check|config|install|uninstall|help)
        # share|ls|sms|msg|id
                phone.$command "$@"
                return $?
                ;;

         "")
                phone.check
                return $?
                ;;
          *)
                phone.check "$command $@"
                return $?
                ;;
    esac
}

phone.config() {
# config firewall to able kdeclient to connect to phone

    if ! [[ $GURU_PHONE_PORT_RANGE ]] || ! [[ $GURU_PHONE_LAN_IP ]]; then
        gr.msg -e1 "please set values to 'port_range' and 'lan_ip' to '$phone_config'"
        return 100
    fi

    # add firewall rule
    gr.msg -h "need sudo rights to check firewall status"
    if  sudo ufw status | grep $GURU_PHONE_LAN_IP -q ; then
        gr.msg -c green "phone rule already added"
        return 0
    else
        gr.msg -n "adding firewall rule to able kdeconnect to communicate with phone.. "
        sudo ufw allow from $GURU_PHONE_LAN_IP to any port $GURU_PHONE_PORT_RANGE proto tcp >/dev/null && \
        sudo ufw allow from $GURU_PHONE_LAN_IP to any port $GURU_PHONE_PORT_RANGE proto udp >/dev/null && \
            gr.msg -c green "ok" || gr.msg -e2 "failed"
    fi
}


phone.rc () {
# source configurations (to be faster)
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    if [[ ! -f $phone_rc ]] || [[ $(( $(stat -c %Y $phone_config) - $(stat -c %Y $phone_rc) )) -gt 0 ]]; then
        phone.make_rc && gr.msg -v1 -c dark_gray "$phone_rc updated"
    fi

    source $phone_rc
}

phone.make_rc () {
# configure phone module
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    source config.sh

    # make rc out of config file and run it
    if [[ -f $phone_rc ]] ; then
            rm -f $phone_rc
        fi

    # check user configuration file exist
    if ! [[ -f $phone_config ]]; then
        if [[ -f $GURU_CFG/phone.cfg ]]; then
            gr.msg -e1 "copying default configuration to $phone_config.."
            cp $GURU_CFG/phone.cfg $phone_config
        else
            gr.msg -e2 "no default configurations found from $GURU_CFG/phone.cfg, fatal"
            return 100
        fi
    fi

    config.make_rc "$phone_config" $phone_rc
    chmod +x $phone_rc
    source $phone_rc
}

phone.check_pair(){

    gr.msg -n "checking pair.. "
    phone_name=$(kdeconnect-cli --l --name-only 2>/dev/null)

    # check phone status
    if kdeconnect-cli --l 2>/dev/null | grep -q paired; then
    # paired
        gr.msg -c aqua "$phone_name "
        config.set $phone_rc phone_paired yes
        return 0
    else
    # reachable but not paired
        gr.msg -c dark_gray "no pair "
        config.set $phone_rc phone_paired no
        return 1
    fi
}

phone.pair() {
# pair device with id

    # check is paired already
    phone.check_pair && return 0

    gr.msg -n  "checking availability.. "
    if kdeconnect-cli --l  2>/dev/null | grep -q reachable ; then
        gr.msg -c green "reachable"
    else
        gr.msg -e2 "unreachable"
        return 106
    fi

    gr.msg -n "pairing.. "
    kdeconnect-cli --pair -d $GURU_PHONE_ID 2>/dev/null >/dev/null

    gr.msg -nh "please accept.. "
    for (( i = 0; i < 25; i++ )); do
        read -r -s -n1 -t1 ans
        case $ans in q) gr.msg "[canceled]" ; break ; esac

        if kdeconnect-cli  -n horror --ping 2>/dev/null >/dev/null; then
            gr.msg -n -c green "paired with "
            gr.msg -c aqua "$phone_name "
            config.set $phone_rc phone_paired yes
            return 0
        fi
    done
    [[ $ans ]] || gr.msg -e1 "timeout"
    return 1

}

phone.unpair() {

    gr.msg -n "un-pairing.. "
    if kdeconnect-cli -n $GURU_PHONE_NAME --unpair 2>/dev/null >/dev/null; then
        gr.msg -c green "ok"
        config.set $phone_rc phone_paired no
    else
        gr.msg -c dark_gray "no pair"
        return 101
    fi
}

phone.check () {
# check that given date phone file exist
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    local _input="$@"

    # check installation
    gr.msg -n "checking installation.. "
    if hash kdeconnect-cli 2>/dev/null ; then
        gr.msg -c green "ok"
    else
        gr.msg -e1 "kdeconnect needed, please '$GURU_CALL phone install'"
        return 101
    fi

    # check basic configuration
    if ! [[ $GURU_PHONE_PORT_RANGE ]] || ! [[ $GURU_PHONE_LAN_IP ]]; then
        gr.msg -e1 "please set values to 'port_range' and 'lan_ip' to '$phone_config'"
        return 102
    fi

    ## requirements checked, continue with no returns

    # check phone id
    gr.msg -n "checking my id.."
    local _my_id=$(kdeconnect-cli --my-id 2>/dev/null)
    if [[ $? != 0 ]]; then
        gr.msg -e1 "unable to fetch my id '$_my_id'"
        #gr.msg -c white "please connect your phone with 'kdeconnect-settings'"
        #kdeconnect-settings
        return 103
    else
        gr.msg -c aqua "$_my_id "
    fi

    gr.msg -n "checking phone id.. "
    if [[ $GURU_PHONE_ID ]]; then
        gr.msg -c aqua "$GURU_PHONE_ID"
    else
        gr.msg -e2 "missing id '$GURU_PHONE_ID'"
        return 106
    fi

    # check pairing
    if ! phone.check_pair ; then
        gr.msg -v2 "please check phone is connected to local wifi"
        return 105
    fi

    # testing
    gr.msg -n "testing.. "
    if kdeconnect-cli -n horror --ping >/dev/null; then
        gr.msg -c green "passed"
        return 0
    else
        gr.msg -c red "failed"
        return 200
    fi
}

phone.ping () {

    local _message="$GURU_CALL says hello!"
    [[ $1 ]] && _message="$@"

    [[ $GURU_PHONE_PAIRED ]] || phone.check_pair

    if [[ $GURU_PHONE_PAIRED == "yes" ]]; then
        kdeconnect-cli -n $GURU_PHONE_NAME --ping-msg "$_message"
    else
        gr.msg -e1 "phone not paired"
    fi
}

phone.ring () {

    [[ $GURU_PHONE_PAIRED ]] || phone.check_pair

    if [[ $GURU_PHONE_PAIRED == "yes" ]]; then
        kdeconnect-cli -n $GURU_PHONE_NAME --ring
    else
        gr.msg -e1 "phone not paired"
    fi
}

phone.find(){
    phone.ring
    return $?
}

phone.install() {
# Install needed tools
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    for install in ${require[@]} ; do
        hash $install 2>/dev/null && continue

        gr.ask -h "install $install" || continue

        sudo apt-get -y install $install
    done
}

phone.uninstall() {
# Install needed tools
    gr.msg -v4 -c blue "$__phone [$LINENO] $FUNCNAME '$1'" >&2

    for remove in ${require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove
    done
}

phone.rc

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    phone.main $@
    exit $?
fi


# metodi tallentaa pysyviä asetuksia listätty config.sh
# if [[ $_id != $GURU_PHONE_ID ]] ; then
#     gr.msg -e1 "phone id mismatch: $_id != $GURU_PHONE_ID"
#     source config.sh
#     if config.save $phone_config id $_id; then
#         gr.msg -c dark_gray "setting updated"
#     else
#         gr.msg -c white "please edit phone 'id=$_id' in '$phone_config' manually"
#         return 104
#     fi
# else
#   pass
# fi