#!/bin/bash

# This script copies module/template/template.sh and modifies 'module' and 'MODULE' to given module name.
# Run in module/template folder
# This file not meant to run after install and shall not include to installation
set -e
source common.sh

module_name=$1
existing_modules=$(< $GURU_CFG/installed.modules)

# input module name is not given as parameter
if [[ -z $1 ]] ; then
	gr.msg -n "new module name: "
	read module_name
fi

# check is it in module list
case $existing_modules in
	*" $module_name "*)
		gr.msg -c yellow "module '$module_name.sh' already exist, select another name"
		exit
	;;
esac

# ask to be sure
gr.ask  "want to create module named '$module_name'?" || exit

[[ -f "../$module_name.sh" ]] && \
	gr.ask "file '$module_name.sh' exists, overwrite?" || exit

# read template file
module=$(cat shell-template.sh)

# modify template file
module=${module//module/$module_name}
module=${module//MODULE/${module_name^^}}
module=${module//mudule/module}
echo "$module" >"../$module_name.sh"
sed -i '/\###/d' "../$module_name.sh"
chmod +x "../$module_name.sh"

# git
gr.ask "add '$module_name.sh' to git and make initial commit?" || exit

git add "../$module_name.sh"
git commit "../$module_name.sh" -m "initial commit"

