#!/bin/bash
# is my server down standalone

#source telegram.sh


telegram.msg () {
    # send message to user or to channel. input <channel> <message>

    local channel=$1 ; shift
    local msg=$@

    if telegram-cli -D -W -e "msg $channel $msg" >/dev/null ; then
            return 0
        else
            echo "unable to send telegram message"
            return 100
        fi
}


mqtt.online () {
    # check mqtt is functional, no printout

    mqtt.online_send () {
        # if mqtt message takes more than 2 seconds to return from closest mqtt server there is something wrong

        sleep 2
        timeout 1 mosquitto_pub \
            -u "watchdog" \
            -h "$1" \
            -p "$2" \
            -t "watchdog" \
            -m "$(hostname) $(date +$GURU_FORMAT_DATE) $(date +$GURU_FORMAT_TIME)" \
             >/dev/null 2>&1 \
        || echo "timeout or mqtt publish issue: $?"
    }

    # delayed publish
    mqtt.online_send $1 $2 &

    # subscribe to channel no output

    if timeout 3 mosquitto_sub -C 1 \
                    -u "watchdog" \
                    -h "$1" \
                    -p "$2" \
                    -t "watchdog" \
                    $_options >/dev/null
        then

            return 0
        else
            echo "mqtt subscribe issue: $?"
            return 1
    fi
}



server.check_service () {
    # get domain from list and remove it

    # list of services: (domain protocol url_end url_end url_end ..)
    local telegram_channel="server-watchdog"

    local url_list=($@)

    local domain=${url_list[0]}
    unset 'url_list[0]'

    # unset makes [position] empty, does not remove the array item
    local protocol=${url_list[1]}
    unset 'url_list[1]'

    # get protocol from list and remove it

    case $protocol in

        ping)
            printf "pinging $domain.. "
            if ping -q -W 2 -c 2 $domain >/dev/null ; then
                    echo "OK"
                    return 0
                else
                    echo "OFFLINE (or ping disabled)"
                    telegram.msg "server-watchdog" "$(hostname) cannot ping $domain, or ping disabled"
                    return 102
                fi
            ;;

        ssh)
            local port=${url_list[2]}
            local user=${url_list[3]}
            printf "connecting to $user@$domain:$port.. "
            if ssh -q -o "BatchMode=yes" -o "ConnectTimeout=3" -p $port $user@$domain -- "exit" ; then
                    echo "OK"
                    return 0
                else
                    echo "NO ACCESS"
                    telegram.msg "server-watchdog" "$user@$(hostname) cannot access $user@$domain by ssh"
                    return 101
                fi
            ;;

        http|https)

            for url in ${url_list[@]} ; do
                printf "checking $protocol://$domain/$url.. "
                reply_code=$(timeout 3 curl -s -o /dev/null -w '%{http_code}' "$protocol://$domain/$url")

                case $reply_code in
                        200)    echo " OK" ;;
                        301)    echo " Moved" ;;
                        *)      echo " OFFLINE"
                                telegram.msg "server-watchdog" "from $(hostname) point of view, the service $protocol://$domain/$url is unreachable"
                                (( issues++ ))
                    esac
            done
            return $issues
            ;;

        mqtt)
            local port=${url_list[2]}
            printf "checking $protocol at $domain.. "
            if mqtt.online $domain $port ; then
                    echo " OK"
                else
                    echo " OFFLINE"
                    telegram.msg "server-watchdog" "from $(hostname) point of view, the $protocol server at $domain is unreachable"
                fi
            ;;

           *)   echo "unknown protocol"
                return 103
        esac

}

while true ; do
    server.check_service zeukkari.dev ping
    server.check_service zeukkari.dev https wekan wiki/wiki gitea/explore/repos
    server.check_service zeukkari.dev ssh 22 casa
    server.check_service 192.168.10.106 mqtt 1883
    # server.check_service 192.168.1.10 ping
    # server.check_service localhost:8282 http wekan
    # server.check_service 192.168.1.10 ssh 22 casa
    sleep 300
done


# skit
# # send warning to telegram_channel that server is down
# local domain="elena.ujo.guru" ; [[ $1 ]] && domain=$1
# local send_log="/tmp/ug-tg-log.json"
# local warn_msg="$domain is down, I repeat: $domain is down - actions needed!"
# local timeout=300

# echo "starting server-watchdog $domain, warning send to $telegram_channel, interval $timeout logged to $send_log "
# telegram-cli --json -W -e "msg $telegram_channel starting server-watchdog at $(hostname) for $domain (interval $timeout).. " >>$send_log

# while true ; do
#     if ping -q -W 3 -c 3 $domain >/dev/null ; then
#             printf "."
#             sleep $timeout
#         else
#             echo "server down!"
#             telegram-cli --json -W -e "msg $telegram_channel $warn_msg" >>$send_log
#             sleep 60
#         fi
# done