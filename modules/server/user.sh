#!/bin/bash
# user backend configurator for guru tool-kit
source $GURU_BIN/common.sh

user.main () {
	# user management tool command parser
    local _cmd="$1" ; shift
    case "$_cmd" in
 	       ls|add|rm|help|status)  user.$_cmd "$@" 				; return 0  ;;
		           *)  gmsg -e "user: unkown command: $_cmd" 	; return 0  ;;
		esac
}


user.ls () {
	cat /etc/passwd |grep -v nologin |grep bin/bash|grep -v root | cut -f 1 -d ":"
}


user.status () {
	gmsg -v1 -v "list of users:"
	gmsg -c light_blue "$(user.ls)"
}


user.add () {
	local _user="$1"
	[[ $_user ]] ||read -p "user name:" _user
	if sudo adduser "$_user" ; then
		# user database
		sudo mkdir /home/$_user/.data
		sudo touch /home/$_user/.data/online
		sudo mkdir -p /home/$_user/.cfg/$_user
	fi

}


user.rm () {
	local _user="$1"
	[[ $_user ]] ||read -p "user name:" _user
	user.ls | grep $_user && sudo userdel "$_user"
	if ! [[ -d /home/$_user ]] ; then echo "no user $_user folder" ; return 100 ; fi
	if read -p "remove user files [y/n]: " _input; then
		[[ $_user ]] && sudo rm /home/$_user -fr
	fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    user.main "$@"
    exit "$?"
fi