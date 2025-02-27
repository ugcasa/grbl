#!/bin/bash
source common.sh

gr.msg "This will change 'GURU_' to 'GRBL_' and 'guru-client' 'guru-cli', 'guru' to 'grl'"
gr.msg "not clean but should produce functional output. There is obvious risk if files or "
gr.msg "folders contains 'grbl/guru', specially when cross module file names are used."
gr.ask "Continue" || exit 0

module_file=$(readlink -f $1)
shift

if ! [[ $module_file ]]; then
	gr.msg "no such file"
	exit 0
fi

branch="dev"
[[ $1 ]] && branch=$1

if ! git branch | grep -q $branch; then
	gr.msg "available branches:"
	git branch
	exit 1
fi

temp="/tmp/${module_file##*/}"

[[ -f $temp ]] && rm $temp
[[ -f $module_file ]] || exit 1

cp $module_file $temp

sed -i -e 's/guru-client/grbl/g' $temp
sed -i -e 's/guru-cli/grbl/g' $temp
sed -i -e 's/guru/grbl/g' $temp
sed -i -e 's/GURU/GRBL/g' $temp
sed -i -e 's/ujo.grbl/ujo.guru/g' $temp

git checkout $branch || exit 2

gr.msg "saving original $branch branch file to to '${temp}_original'.."
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
