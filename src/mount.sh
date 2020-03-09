#!/bin/bash
# mount tools for guru tool-kit
# casa@ujo.guru 2020

source "$(dirname "$0")/remote.sh"

mount_main() {

	help() {
		printf "help/n"
		echo 
	}

	command="$1"; shift

	case "$command" in
		mount )
			;;
		umount )
			;;
		help )
			help "$@"
			;;
		*)	echo "unknown command"
	esac
}




if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then		# if sourced only import functions
    source "$HOME/.gururc"
    mount_main "$@"
    exit "$?"
fi


