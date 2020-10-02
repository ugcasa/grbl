#!/bin/bash
uninstalling_version=$($GURU_BIN/core.sh version)

uninstall_main () {

	command="$1" ; shift
	case "$command" in
		config) uninstall "$@" ; [[ "$GURU_CFG" ]] && rm -rf "$GURU_CFG" ;;
			 *) uninstall "$@"
				exit "$?"
	esac
}


uninstall () {

	if [ ! -f "$HOME/.bashrc.giobackup" ]; then
		echo "not installed, aborting.."
		return 135
	fi

	if [ -f "$HOME/.gururc2" ]; then
		 source "$HOME/.gururc2"
	else
		echo "${BASH_SOURCE[0]} no setup file exists, aborting.."
		return 136
	fi

	if [ "$GURU_BIN" == "" ]; then
		echo "no environment variables set, aborting.."
		return 137
	fi

	mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"
	rm -f "$HOME/.gururc2"
	rm -f "$GURU_BIN/$GURU_CALL"
	[ "$GURU_CFG" ] && rm -f "$GURU_CFG/*"

	if [[ -f "$HOME/.kbbind.backup.cfg" ]]; then
		dconf load /org/cinnamon/desktop/keybindings/ < "$GURU_CFG/$GURU_USER_NAME/kbbind.backup.cfg"
	fi

	echo "$uninstalling_version removed"
	return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	source "$HOME/.gururc2"
	uninstall_main "$@"
fi

