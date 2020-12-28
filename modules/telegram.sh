#!/bin/bash

source common.sh

telegram.requirements=(make build-essential checkinstall libreadline-dev libconfig-dev libconfig-dev lua5.2 liblua5.2-dev libevent-dev libjansson-dev)


telegram.install () {

	local crypto_method=libcrypto ##openassl does not compile cause ubuntu does not contain openssl1.0*-dev (obsolete)
	[[ $1 ]] && crypto_method=$1

	for **** continue at office

	sudo apt-get install -y make build-essential checkinstall libreadline-dev libconfig-dev libconfig-dev lua5.2 liblua5.2-dev libevent-dev libjansson-dev  || gmsg -c yellow "require install error $?" && gmsg -c green "OK"

	# clone source
	cd /tmp
	git clone --recursive https://github.com/vysheng/tg.git || gmsg -c 102 -c red "clone error $?" && gmsg -c green "OK"

	# crypto method selection
	case $crypto_method in
		openssl )
			sudo apt-get install -y libssl-dev
			./configure || gmsg -x 103 -c red "openssl configure error" && gmsg -c green "OK"
			;;
		libcrypto )
			sudo apt-get install -y libgcrypt20 libgcrypt20-dev
			/configure --disable-openssl || gmsg -x 103 -c red "libcrypto configure error" && gmsg -c green "OK"
			;;
		esac

	# compile
	cd tg
	make || gmsg -c yellow "error $? during make" && gmsg -N -v1 -c green "$GURU_CALL is ready to telegram messaging"

}