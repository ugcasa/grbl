#!/bin/bash
source common.sh

gr.msg "This will change GRBL_ to GURU_ but not grbl to guru*, not clean but should produce functional output"
gr.msg "please go trough all 'grlb' words manually and change them to 'guru' or 'guru-client'. No automation cause"
gr.msg "of obvious risk if files or folders contains 'grbl' words, specially when cross module file names are used."
gr.ask "Continue" || exit 0

_moduleName=$1 
shift

_moduleType="modules"
[[ $1 ]] && _moduleType=$1 

[[ $_moduleName ]] || return 0

temp="/tmp/$_moduleName.sh"
orig=$(pwd)/$_moduleType/$_moduleName.sh

[[ -f $temp ]] && rm $temp
[[ -f $orig ]] || exit 1

cp $orig $temp

#sed -i -e 's/guru-client/grbl/g' $temp
#sed -i -e 's/guru-cli/grbl/g' $temp
sed -i -e 's/guru/grbl/g' $temp
sed -i -e 's/GRBL_/GURU_/g' $temp
#sed -i -e 's/ujo.grbl/ujo.guru/g' $temp

git checkout release/0.7.5 || exit 2

gr.msg "saving original release/0.7.5 branch file to to ${temp}_original.."
cp $orig "${temp}_original" || exit 1

if gr.ask "replace $orig with $temp"; then
	subl $temp
	gr.ask "make changes and when ready, OVERWRITE $orig" \
		&& cp $temp $orig \
		|| gr.msg -e1 "not performed"
else
	gr.msg "canceling.."
fi

