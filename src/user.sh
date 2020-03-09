#!/bin/bash
# user settings for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/remote.sh"

user_main() {

	command="$1"; shift

	case "$command" in
		add )
			
			[ "$1" == "cloud" ] && add_user_server "$@" || add_user "$@"
			;;

		add )
			add_user "$@"
			;;
		rm )
			rm_user "$@"
			;;
		help)
			;;
		change|*)
			change_user "$@"
			;;

	esac


}

set_value () {

	[ -f "$GURU_USER_RC" ] && target_rc="$GURU_USER_RC" || target_rc="$HOME/.gururc" 		# 
	#[ $3 ] && target_rc=$3
	sed -i -e "/$1=/s/=.*/=$2 $3 $4/" "$target_rc"

}


add_user () {
	
	[ "$1" ] && new_user="$1" || read -p "user name to change to : " new_user
	echo "adding $new_user"
	# ask/get user name
	# make config folder
	# copy user config template to user name
	# add user add request to server
	# add keys to server	
	# change_user
	return 0 
}

add_user_server () {
	# Run this only at accesspoint server for now
	echo "add user to access point server TBD"
	[ "$1" ] && new_user="$1" || read -p "user name to add : " new_user
	echo sudo adduser "$new_user"
	echo mkdir -p "usr/cfg"
}

change_user () {

	[ "$1" ] && new_user="$1" || read -p "user name to change to : " new_user
	
	new_user_rc=$GURU_CFG/$new_user/userrc

	if [ -d "$new_user_rc" ]; then 
		echo "user exist"
		set_value GURU_USER "${new_user,,}" 			# set user to en
		source "$new_user_rc" 							# get user configuration on use
		pull_config_files 								# get newest configurations from server
	else
		read -p "user do not exist, create it? : " answer
		[ "${answer,,}" == "y" ] && add_user "$new_user" || return 1
	fi
	
	# pull onfig files (just overwrite)
	# change environment values
	return 0
}





# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    user_main "$@"
    exit 0
fi


