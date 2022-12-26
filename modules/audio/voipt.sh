#!/bin/bash
# phone bridge voip tunnel POC
# assuming /git/trx is place for trx stuff

# host variables
app_udb_port=1350
remote_tcp_port=10001
sender_address=127.0.0.1
sender_tcp_port=10000

voipt.main () {
    voipt.arguments $@
    local function=$1 ; shift
    case $function in
            install|open|close|ls|help )
                        voipt.$function $@
                        return $? ;;
                    *)  [[ $verbose ]] && echo "unknown command $function"
                        return 1 ;;
        esac
}

voipt.arguments () {

    remote_ssh_port=22
    remote_user=$USER

    TEMP=`getopt --long -o "vh:u:p:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -v ) verbose=true        ; shift ;;
            -h ) remote_address=$2   ; shift 2 ;;
            -u ) remote_user=$2      ; shift 2 ;;
            -p ) remote_ssh_port=$2  ; shift 2 ;;
             * ) break
        esac
    done

    [[ $remote_address ]] || read -p "remote address: " remote_address

    # check message
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"
}


voipt.open () {
    voipt.start_listener || return 100
    voipt.start_sender || return 101
}


voipt.close () {
    voipt.close_sender || return 102
    voipt.close_listener || return 103
}


voipt.close_listener () {

    gr.msg -n -v1 "closing remote rx and socat.. "
    if ssh -p "$remote_ssh_port" "$remote_user@$remote_address" "pkill rx; pkill socat" ; then
            gr.msg -v2 -c green -v1 "ok"
        else
            gr.msg -c red "remote pkill rx/socat failed"
        fi

}


voipt.close_sender () {

    #gnome-terminal -t --geometry=40x4 --hide-menubar  --
    gr.msg -n -v1 "closing local rc and socat sender.. "
    pkill tx
    pkill socat
    local pid=$(ps aux | grep ssh | grep "$sender_tcp_port" | tr -s " " | cut -f2 -d " ")
    if [[ $pid ]] ; then
            kill $pid && gr.msg -c green -v1 "ok"
        else
            gr.msg -c green -v1 "not running"
        fi
    return 0
}


voipt.start_listener () {
    # assuming listener is remote and sender is local

    gr.msg -n -v1 "starting remote audio device.. "
    # check listener, lauch if not running
    if ! ssh -p $remote_ssh_port $remote_user@$remote_address ps auxf | grep "rx -h 127.0.0.1" | grep -v grep >/dev/null ; then
            gnome-terminal -t "listener rx" \
                --geometry=40x4 --hide-menubar \
                -- ssh -p $remote_ssh_port $remote_user@$remote_address \
                $HOME/git/trx/rx -h $sender_address -p $app_udb_port
            gr.msg -v1 -c green "started"

            # test listener
            sleep 1
            if ! ssh -p $remote_ssh_port $remote_user@$remote_address ps auxf | grep "rx -h 127.0.0.1" | grep -v grep >/dev/null ; then
                    gr.msg -c yellow "$FUNCNAME: listener rx error occured "
                    return 100
                fi
        else
            gr.msg -v1 -c green "ok"
        fi

    gr.msg -n -v1 "start to pull udp from tcp.. "
    # check socat running
    if ! ssh -p $remote_ssh_port $remote_user@$remote_address ps auxf | grep "socat tcp4-listen:10001" | grep -v grep >/dev/null ; then
            # launch socat
            gr.msg -v2 "remote_addres:$remote_tcp_port.. "
            gnome-terminal -t "listener tcp>udp $remote_addres:$remote_tcp_port" \
                    --geometry=40x4 --hide-menubar \
                    -- ssh -p $remote_ssh_port $remote_user@$remote_address \
                    socat tcp4-listen:$remote_tcp_port,reuseaddr,fork UDP:$sender_address:$app_udb_port

            # test socat
            sleep 1
            if ssh -p $remote_ssh_port $remote_user@$remote_address ps auxf | grep "socat tcp4-listen:10001" | grep -v grep >/dev/null ; then
                    gr.msg -v1 -c green "started"
                else
                    gr.msg -c red "$FUNCNAME: listener tcp>udp error occured "
                    return 100
                fi
        else
            gr.msg -v1 -c green "ok"
        fi

    return 0
}


voipt.start_sender () {
    #run listener first**
    gr.msg -n -v1 "tunnel to $remote_address.. "
    # check is tunnel active, start and test if not
    if ! ps auxf | grep "ssh -L 10000:127.0.0.1:10001" | grep -v grep >/dev/null ; then

            gnome-terminal -t "sender tunnel $remote_address" \
                --geometry=40x4 --hide-menubar -- \
                ssh -L $sender_tcp_port:$sender_address:$remote_tcp_port $remote_user@$remote_address -p $remote_ssh_port

            sleep 2

            if ps auxf | grep "ssh -L 10000:127.0.0.1:10001" >/dev/null  ; then
                    gr.msg -v1 -c green "created"
                else
                    gr.msg -c red "$FUNCNAME: sender tx error occured "
                    return 100
                fi
        else
           gr.msg -v1 -c green "ok"
        fi


    gr.msg -n -v1 "voip audio sender.. "
    # check transmitter
    if ! ps auxf | grep trx/tx | grep -v grep  >/dev/null ; then
            # sterting is not running
            gnome-terminal -t "sender tx $sender_address" \
                --geometry=40x4 --hide-menubar -- \
                /tmp/trx/tx -h $sender_address -p $app_udb_port

            # test
            if ps auxf | grep trx/tx >/dev/null ; then
                    gr.msg -v1 -c green "started"
                else
                    gr.msg -c red "$FUNCNAME: sender tx error occured "
                    return 100
                fi
        else
            gr.msg -v1 -c green "ok"
        fi

    gr.msg -n -v1 "start to push udp to tcp.. "
    # test sender sice udb to tcp
    if ! ps auxf | grep "socat udp4-listen:1350" | grep -v grep >/dev/null ; then

            gnome-terminal -t "sender udp>tcp $sender_address:$sender_tcp_port" \
                --geometry=40x4 --hide-menubar -- \
                socat udp4-listen:$app_udb_port,reuseaddr,fork tcp:$sender_address:$sender_tcp_port

            if ps auxf | grep "socat udp4-listen:1350" | grep -v grep >/dev/null ; then
                    gr.msg -v1 -c green "started"
                else
                    gr.msg -c red "$FUNCNAME: udp>tcp error occured "
                    return 100
                fi
        else
            gr.msg -v1 -c green "ok"
        fi
    return 0
}


voipt.help () {
    echo  "voipt help "
    echo
    echo   "usage:    $GURU_CALL voipt [ls|open|close|help|install]"
    echo  "commands:"
    echo
    echo  " ls           list of active tunnels "
    echo  " open         open voip tunnel to host "
    echo  " close        close voip tunnel "
    echo  " install      install trx "
    echo  " help         this help "
    echo
    return 0
}


voipt.install () {
    # assume debian
    sudo apt-get install -y libasound2-dev libopus-dev libopus0 libortp-dev libopus-dev libortp-dev wireguard socat || return $?
    cd /tmp
    git clone http://www.pogo.org.uk/~mark/trx.git || return $?
    cd trx
    sed -i 's/ortp_set_log_level_mask(NULL, ORTP_WARNING|ORTP_ERROR);/ortp_set_log_level_mask(ORTP_WARNING|ORTP_ERROR);/g' tx.c
    make && [[ $verbose ]] && echo "success" || return $?
    return 0
}


voipt.remove () {
    # assume debian
    gr.msg -v1 "removing libasound2-dev libopus-dev libopus0 libortp-dev libopus-dev libortp-dev wireguard socat.."
    sudo apt-get remove -y libasound2-dev libopus-dev libopus0 libortp-dev libopus-dev libortp-dev wireguard socat || return $?
    #make uninstall && [[ $verbose ]] && echo "success" || return $? ??
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        voipt.main $@
        exit $?
    fi


