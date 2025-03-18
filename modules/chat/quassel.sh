#!/usr/bin/bash
# quick quassel buildscript (draft) edited by casa@ujo.guru 2023

# initialize your local git-repository once with this command
declare -g source_folder="$GRBL_APP/quassel"




quassel.install () {

	cd $source_folder
	git clone https://github.com/quassel/quassel.git $source_folder

	# updating latest contributions:
	cd $source_folder
	git pull origin || gr.msg -x 100 -c red "unable to pull source"

	# make a new build directory with a suffix containing the date
	export date=$(date +%y%m%d%H%M%S)
	mkdir build_$date

	# cmake: Optionen siehe ~/quassel/INSTALL
	cd build_$date
	cmake ~/quassel -DWANT_CORE=ON -DWANT_QTCLIENT=ON -DWANT_MONO=ON -DWITH_KDE=ON -DWITH_OPENSSL=ON -DWITH_DBUS=ON -DWITH_PHONON=ON -DWITH_WEBKIT=OFF -DLINGUAS="de en_US"
	make

	# avoid the classic 'make install', prefer generating a package with checkinstall
	# please execute as root via copy & paste in the directory
	cd $source_folder/build_$date

	# first to remove old package:
	dpkg -r quassel-all

	# then to install new package:
	checkinstall -D --pkgname quassel-all --pkgversion 0.5.0 --pkgrelease $date make install
}


# qaessel.install () {

# 	sudo add-apt-repository ppa:mamarley/quassel-git
# 	sudo apt update
# 	sudo apt install quassel
# }