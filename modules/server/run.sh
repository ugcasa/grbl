#!/bin/bash

gsource () {
	# source only wanted functions. slow ~0,03 sec, but saves environment space

	local file=$1 ; shift
	local functions=($@)

	# use ram disk as a temp to avoid ssd wear out and might be little faster?
	if df -T | grep /dev/shm >/dev/null; then
			gtemp=/dev/shm/guru
		else
			gtemp=/tmp/guru
		fi

	if ! [[ -d $gtemp ]] ; then
			mkdir -p $gtemp
		fi

	for function in ${functions[@]} ; do
		sed -n "/$function ()/,/}/p" $file >> $gtemp/functions.sh
	done

	source $gtemp/functions.sh
	rm $gtemp/functions.sh
}


gsource lib.sh hello hallo lada
hello
hallo


