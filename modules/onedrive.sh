# grbl ms onedrive syck and other ms tools casa@ujo.guru 2025

# debug shit
# __onedrive_color="light_blue" # debug
# __onedrive=$(readlink --canonicalize --no-newline $BASH_SOURCE) # debug

onedrive_name=("home" "school")
onedrive_sync_dir=("$HOME/onedrive" "$HOME/skuledrive")
onedrive_config_file="$HOME/.config/onedriver/config.yml"
onedrive_select=0
onedrive_rc=/tmp/$USER/grbl_onedrive.rc

[[ -f $onedrive_rc ]] && source $onedrive_rc
export SERVICE_NAME=$(systemd-escape --template onedriver@.service --path ${onedrive_sync_dir[$onedrive_select]})

# https://thelinuxcode.com/install-and-use-onedrive-on-linux-mint/
onedrive.install() {
# install needed software to get ms tools work

	# Option 1: oldshit not worky -> dangero
	# sudo apt install onedrive

	# option 2: compie // weird compiler -> not worky
	# cd /tmp
	# sudo apt update
	# sudo apt install libnotify-dev
	# git clone https://github.com/abraunegg/onedrive.git && gr.msg -c green "ok"
	# cd onedrive
	# ./configure && gr.msg -c green "ok" || gr.msg -e1 "configure fucked up"
	# sudo make && gr.msg -c green "ok" || gr.msg -e1 "make fucked up"
	# sudo make install && gr.msg -c green "ok" || gr.msg -e1 "make install fucked up"
	# cd

	# option 3 clean up and use opensuse repo
	# https://github.com/abraunegg/onedrive/blob/master/docs/INSTALL.md
	# https://github.com/abraunegg/onedrive/blob/master/docs/ubuntu-package-install.md#distribution-ubuntu-2004
	# sudo apt remove onedrive
	# sudo add-apt-repository --remove ppa:yann1ck/onedrive
	# local _rm_me="/etc/systemd/user/default.target.wants/onedrive.service"
	# [[ -f  $_rm_me ]] && sudo rm $_rm_me

	# source /etc/upstream-release/lsb-release
	# gr.msg "getting deps for $DISTRIB_DESCRIPTION, $DISTRIB_ID, $DISTRIB_RELEASE "
	# wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/x$DISTRIB_ID_$DISTRIB_RELEASE/Release.key | sudo apt-key add -
	# echo "deb https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/x$DISTRIB_ID_$DISTRIB_RELEASE/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list

	# sudo apt-get update
	# sudo apt install --no-install-recommends --no-install-suggests onedrive

	# option 4. - not worky
	# https://community.linuxmint.com/software/view/onedrive

	# option 5 - another client
	# https://software.opensuse.org/download.html?project=home%3Ajstaf&package=onedriver

	source /etc/upstream-release/lsb-release
	gr.msg "getting deps for $DISTRIB_DESCRIPTION, $DISTRIB_ID, $DISTRIB_RELEASE "
	echo "deb http://download.opensuse.org/repositories/home:/jstaf/x${DISTRIB_ID}_${DISTRIB_RELEASE}/ /" | sudo tee /etc/apt/sources.list.d/home:jstaf.list
	curl -fsSL "https://download.opensuse.org/repositories/home:jstaf/x${DISTRIB_ID}_${DISTRIB_RELEASE}/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg > /dev/null
	sudo apt update
	sudo apt install onedriver
}

onedrive.rm_confs() {
# remove config file (for re-configure)

	if [[ -f  $onedrive_config_file ]]; then
		rm -rf $onedrive_config_file
		firefox.main backup
		firefox.main rm
	else 
		gr.msg "no config file found"
	fi
}

onedrive.save_config () {
# save configurations to file
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug
	gr.varlist "debug $onedrive_select $onedrive_rc"

	[[ -f $onedrive_rc ]] || touch $onedrive_rc
	source config.sh
	config.save $onedrive_rc onedrive_select $onedrive_select
}

onedrive.mount() {
# mount drive
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	export SERVICE_NAME=$(systemd-escape --template onedriver@.service --path ${onedrive_sync_dir[$onedrive_select]})
	systemctl --user stop $SERVICE_NAME
	systemctl --user daemon-reload
	systemctl --user start $SERVICE_NAME
	#systemctl --user enable $SERVICE_NAME
}

onedrive.config () {
# set up configuration
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	[[ -d ${onedrive_sync_dir[$onedrive_select]} ]] || mkdir -p ${onedrive_sync_dir[$onedrive_select]}
	[[ -d ${onedrive_config_file%/*} ]] || mkdir -p ${onedrive_config_file%/*}
	[[ -f $onedrive_config_file ]] || touch $onedrive_config_file
	#onedriver -an  # to use web browser to login
	onedriver -a ${onedrive_sync_dir[$onedrive_select]}
}

onedrive.check () {
# check is running
## TODO: for now just tail of service status
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	systemctl --user status $SERVICE_NAME | tail
}

onedrive.stop () {
# check is runnin
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	systemctl --user stop $SERVICE_NAME
	systemctl --user daemon-reload
	fusermount -uz ${onedrive_sync_dir[$onedrive_select]}
}

onedrive.test () {
# try syncing
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	journalctl --user -u $SERVICE_NAME
}

onedrive.select () {
# select drive
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug

	if [[ $1 ]]; then

		## TODO more checks pls
		[[ $1 -lt ${#onedrive_sync_dir[@]} ]] && _selection=$1

	else

		while true ; do
			for (( i = 0; i < ${#onedrive_sync_dir[@]}; i++ )); do
				gr.msg -n -w 3 -h "$i "
				gr.msg -n -w 10 -c light_blue "${onedrive_name[$i]}"
				gr.msg -c gray "${onedrive_sync_dir[$i]}"
			done
			read -p "select: " _selection

			if [[ $_selection -lt ${#onedrive_sync_dir[@]} ]]; then
				break
			elif [[ $_selection == "q" ]]; then
				return 0
			else
				gr.msg "please select 0..${#onedrive_sync_dir[@]} or 'q' "
			fi
		done

	fi

	onedrive_select=$_selection
	onedrive.save_config
	export SERVICE_NAME=$(systemd-escape --template onedriver@.service --path ${onedrive_sync_dir[$onedrive_select]})
}

onedrive.main () {
# onedrive main stuff
	# gr.msg -v4 -n -c $__onedrive_color "$__onedrive [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 ## debug
	gr.varlist "debug onedrive_sync_dir onedrive_config_file"

	local _first=$1
	shift

	case $_first in
		# commands
		install|config|test|test|mount|select|check|stop)
			onedrive.$_first $@
			return $?
		;;
		# aliases
		unmount|umount)
			onedrive.stop
		;;
		*) 
			gr.msg -e1 "unknown action"
		;;
	esac	
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    onedrive.main "$@"
    exit "$?"
# else
    #gr.msg -v4 -c $__onedrive_color "$__onedrive [$LINENO] sourced " >&2 # debug
fi

