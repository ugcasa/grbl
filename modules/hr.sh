#!/bin/bash
# Human resources database
# casa@ujo.guru 2023

# datqabase file is in Google contact csv format
export GRBL_VENV="$HOME/grbl/env"
export GRBL_HR_DATA="$GRBL_DATA/hr"
target_base="contacts"


hr.main () {

	local command=$1
	shift
	[[ $target_base ]] || target_base=$1
	shift

	case $command in

		open|add|remove|edit|append)
			# open virtual environment and run command
			[[ -d "$GRBL_VENV/hr/bin" ]] || hr.install
			source "$GRBL_VENV/hr/bin/activate"
			python3 hr.py $target_base $@
			deactivate
			;;

		install)
			hr.install $@
			;;
	esac


}




hr.install () {
# install needed stuff

	sudo apt install virtualenv python3-pip

	# create virtual environment base folder
	[[ -d "$GRBL_VENV" ]] || mkdir -p "$GRBL_VENV"

	# check virtual environment is set, setup if not
	if ! [[ -d "$GRBL_VENV/hr/bin" ]] ; then
		virtualenv -p python3 "$GRBL_VENV/hr"
		# install requirements in virtual env.
		source "$GRBL_VENV/hr/bin/activate"
		pip3 install pandas
		deactivate
	fi

	# place empty table
	[[ -d $GRBL_HR_DATA ]] || mkdir "$GRBL_HR_DATA"
	[[ -f "$GRBL_HR_DATA/database.csv" ]] || cp "$GRBL_CFG/hr_database_temp.csv" "$GRBL_HR_DATA/database.csv"

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    hr.main $@
    exit $?
fi
