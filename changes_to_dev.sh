#!/bin/bash
source common.sh

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

sed -i -e 's/guru-client/grbl/g' $temp
sed -i -e 's/guru-cli/grbl/g' $temp
sed -i -e 's/guru/grbl/g' $temp
sed -i -e 's/GURU/GRBL/g' $temp
sed -i -e 's/ujo.grbl/ujo.guru/g' $temp

git checkout dev || exit 2

gr.msg "saving original dev branh file to to ${temp}_original.."
cp $orig "${temp}_original" || exit 1

if gr.ask "replace $orig with $temp"; then
	gr.ask "OVERWRITE $orig" \
		&& cp $temp $orig \
		|| gr.msg -e1 "not performed"
else
	gr.msg "canceling.."
fi

