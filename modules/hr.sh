#!/bin/bash
# Human resources database
# casa@ujo.guru 2023

# datqabase file is in Google contact csv format
export GURU_VENV="$HOME/guru/env"
export GURU_HR_DATA="$GURU_DATA/hr"
target_base="contacts"


hr.main () {

	local command=$1
	shift
	[[ $target_base ]] || target_base=$1
	shift

	case $command in

		open|add|remove|edit|append)
			# open virtual environment and run command
			[[ -d "$GURU_VENV/hr/bin" ]] || hr.install
			source "$GURU_VENV/hr/bin/activate"
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
	[[ -d "$GURU_VENV" ]] || mkdir -p "$GURU_VENV"

	# check virtual environment is set, setup if not
	if ! [[ -d "$GURU_VENV/hr/bin" ]] ; then
		virtualenv -p python3 "$GURU_VENV/hr"
		# install requirements in virtual env.
		source "$GURU_VENV/hr/bin/activate"
		pip3 install pandas
		deactivate
	fi

	# place empty table
	[[ -d $GURU_HR_DATA ]] || mkdir "$GURU_HR_DATA"
	[[ -f "$GURU_HR_DATA/database.csv" ]] || cp "$GURU_CFG/hr_database_temp.csv" "$GURU_HR_DATA/database.csv"

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    hr.main $@
    exit $?
fi
