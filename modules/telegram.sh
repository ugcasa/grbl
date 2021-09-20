#!/bin/bash
# guru telegram integration based on telegram-cli casa@ujo.guru 2021

crypto_method="libcrypto"
telegram_indicator_key="f$(daemon.poll_order telegram)"
public_server_key="/etc/telegram-cli/tg-server.pub"

telegram.main () {
	# teleram command parser

    local command="$1" ; shift

    case "$command" in

			enabled|connect|sub|poll|install)
                    telegram.$command "$@"
                    return $?
                    ;;
            ping)
					telegram.my_server_down $@
                    return $?
                    ;;

               *)   gmsg -c yellow "${FUNCNAME[0]}: unknown command: $command"

                    return 2
        esac
}


telegram.enabled () {
	# check is telegram enabled in user.cfg

	if [[ $GURU_TELEGRAM_ENABLED ]] ; then
			gmsg -v1 -c green "enabled"
			return 0
		else
			gmsg -v1 -c yellow "telegram module disabled in user.cfg"
			return 1
		fi
}


telegram.my_server_down () {
	# send warning to channel that server is down
	local channel="server-watchdog"
	local domain="elena.ujo.guru" ; [[ $1 ]] && domain=$1
	local send_log="/tmp/ug-tg-log.json"
	local warn_msg="$domain is down, I repeat: $domain is down - actions needed!"
	local timeout=300

	gmsg  "starting server-watchdog $domain, warning send to $channel, interval $timeout logged to $send_log "
	telegram-cli --json -W -e "msg $channel starting server-watchdog for $domain (interval $timeout).. " >>$send_log

	while true ; do
		if ping -q -W 3 -c 3 $domain >/dev/null ; then
				gmsg -n "."
				sleep $timeout
			else
				gmsg -c deep_pink "server down!"
				telegram-cli --json -W -e "msg $channel $warn_msg" >>$send_log
				sleep 60
			fi
	done
}


telegram.connect () {
	# connect to server with given key

	[[ $1 ]] && public_server_key=$1 ; shift

	/bin/telegram-cli -k $public_server_key
}


telegram.sub () {
	# subscribe to telegram channel, output to str or file
	echo TBD
}


telegram.poll () {
	# deamon poll interface

	local action="$1" ; shift

    case $action in
        start )
            gmsg -v1 -t -c black \
                -k $telegram_indicator_key \
                "${FUNCNAME[0]}: telegram status polling started"
            ;;
        end )
            gmsg -v1 -t -c reset \
                -k $telegram_indicator_key \
                "${FUNCNAME[0]}: telegram status polling ended"
            ;;
        status )
            telegram.status
            ;;
        *)  telegram.help
            ;;
        esac
}


telegram.install () {

	# does not compile cause ubuntu does not contain openssl1.0*-dev (obsolete)
	local crypto_method=libcrypto

	[[ $1 ]] && crypto_method=$1

	if sudo apt-get install -y make build-essential checkinstall \
							libreadline-dev libconfig-dev libconfig-dev \
							lua5.2 liblua5.2-dev libevent-dev libjansson-dev
			then
				gmsg -c green "installed"
			else
				gmsg -c yellow "installation error $?"
				return 100
			fi

	# clone source to temp
	cd /tmp
	if ! [[ -d /tmp/tg ]] ; then
			if git clone --recursive https://github.com/vysheng/tg.git ; then
					gmsg -c green "clone OK"
				else
					gmsg -c yellow "cloning error $?"
					return 100
				fi
			fi
	cd tg

	# crypto method selection
	case $crypto_method in
		openssl )
				sudo apt-get install -y libssl-dev
				if ./configure ; then
						gmsg -c green "OK"
					else
						gmsg -x 103 -c red "openssl configure error"
					fi

			;;
		libcrypto )
				sudo apt-get install -y libgcrypt20 libgcrypt20-dev libssl-dev
				if ./configure --disable-openssl --prefix=/usr CFLAGS="$CFLAGS -w"
					then
					gmsg -c green "OK"
				else
					gmsg -x 103 -c red "libcrypto configure error"
				fi
				;;
		esac

	# compile

	if make ; then
			gmsg -N -v1 -c green "$GURU_CALL is ready to telegram messaging"
	 	else
	 		gmsg -c yellow "error $? during make"
	 	fi

	 # copy server key
	if ! [[ -d ${public_server_key%/*} ]] ; then
			sudo mkdir /etc/telegram-cli
		fi

	if ! [[ -f $public_server_key ]] ; then
	 		sudo cp ${public_server_key##*/} ${public_server_key}
	 	fi

 	# make install
	sudo cp telegram-cli /usr/local/bin
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    #source common.sh
    telegram.main "$@"
    exit "$?"
fi




# Supported commands
# Messaging

#     msg <peer> Text - sends message to this peer
#     fwd <user> <msg-seqno> - forward message to user. You can see message numbers starting client with -N
#     chat-with-peer <peer> starts one on one chat session with this peer. /exit or /quit to end this mode.
#     add_contact <phone-number> <first-name> <last-name> - tries to add contact to contact-list by phone
#     rename_contact <user> <first-name> <last-name> - tries to rename contact. If you have another device it will be a fight
#     mark_read <peer> - mark read all received messages with peer
#     delete_msg <msg-seqno> - deletes message (not completly, though)
#     restore_msg <msg-seqno> - restores delete message. Impossible for secret chats. Only possible short time (one hour, I think) after deletion

# Multimedia

#     send_photo <peer> <photo-file-name> - sends photo to peer
#     send_video <peer> <video-file-name> - sends video to peer
#     send_text <peer> <text-file-name> - sends text file as plain messages
#     load_photo/load_video/load_video_thumb/load_audio/load_document/load_document_thumb <msg-seqno> - loads photo/video/audio/document to download dir
#     view_photo/view_video/view_video_thumb/view_audio/view_document/view_document_thumb <msg-seqno> - loads photo/video to download dir and starts system default viewer
#     fwd_media <msg-seqno> send media in your message. Use this to prevent sharing info about author of media (though, it is possible to determine user_id from media itself, it is not possible get access_hash of this user)
#     set_profile_photo <photo-file-name> - sets userpic. Photo should be square, or server will cut biggest central square part

# Group chat options

#     chat_info <chat> - prints info about chat
#     chat_add_user <chat> <user> - add user to chat
#     chat_del_user <chat> <user> - remove user from chat
#     rename_chat <chat> <new-name>
#     create_group_chat <chat topic> <user1> <user2> <user3> ... - creates a groupchat with users, use chat_add_user to add more users
#     chat_set_photo <chat> <photo-file-name> - sets group chat photo. Same limits as for profile photos.

# Search

#     search <peer> pattern - searches pattern in messages with peer
# X   global_search pattern - searches pattern in all messages

# Secret chat

#     create_secret_chat <user> - creates secret chat with this user
#     visualize_key <secret_chat> - prints visualization of encryption key. You should compare it to your partner's one
#     set_ttl <secret_chat> <ttl> - sets ttl to secret chat. Though client does ignore it, client on other end can make use of it
#     accept_secret_chat <secret_chat> - manually accept secret chat (only useful when starting with -E key)

# Stats and various info

#     user_info <user> - prints info about user
#     history <peer> [limit] - prints history (and marks it as read). Default limit = 40
#     dialog_list - prints info about your dialogs
#     contact_list - prints info about users in your contact list
#     suggested_contacts - print info about contacts, you have max common friends
#     stats - just for debugging
#     show_license - prints contents of GPLv2
#     help - prints this help
#     get_self - get our user info

# Card

#     export_card - print your 'card' that anyone can later use to import your contact
#     import_card <card> - gets user by card. You can write messages to him after that.

# Other

#     quit - quit
#     safe_quit - wait for all queries to end then quit
