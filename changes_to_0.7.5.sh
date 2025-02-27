#!/bin/bash
source common.sh

gr.msg "This will change GRBL_ to GURU_ and 'grbl' to 'guru, not clean but should produce functional output."
gr.msg "There is obvious risk if files or folders contains 'grbl/guru' word, specially when cross module file names are used."
gr.ask "Continue" || exit 0

module_file=$(readlink -f $1)
shift

if ! [[ $module_file ]]; then
	gr.msg "no such file"
	return 0
fi

temp="/tmp/${module_file##*/}"

[[ -f $temp ]] && rm $temp
[[ -f $module_file ]] || exit 1

cp $module_file $temp

sed -i -e 's/grbl/guru/g' $temp
sed -i -e 's/GRBL_/GURU_/g' $temp

git checkout release/0.7.5 || exit 2

gr.msg "saving original release/0.7.5 branch file to to '${temp}_original'.."
cp $module_file "${temp}_original" || exit 1

gr.msg "please go trough all 'guru' words manually and check that changes are valid'. "
subl $temp

if gr.ask "make changes and when ready, replace $module_file with $temp"; then
	gr.ask "really OVERWRITE $module_file" \
		&& cp $temp $module_file \
		|| gr.msg -e1 "not performed"
else
	gr.msg "canceling.."
fi

