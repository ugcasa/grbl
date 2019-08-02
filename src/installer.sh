#!/bin/bash
# install functions for giocon client ujo.guru / juha.palm 2019

conda_install () {

	conda list && return 13 || echo "no conda installed"

	sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6

	[ "$1" ] && conda_version=$1 || conda_version="2019.03"
	conda_installer="Anaconda3-$conda_version-Linux-x86_64.sh"
	conda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

	curl -O https://repo.anaconda.com/archive/$conda_installer
	sha256sum $conda_installer >installer_sum
	printf "checking sum, if exit it's invalid: "
	cat installer_sum |grep $conda_sum && echo "ok" || return 11

	chmod +x $conda_installer
	bash $conda_installer -u && rm $conda_installer installer_sum || return 12
	source ~/.bashrc 
	echo "conda install done, next run setup by typping: guru set conda"
	return 0
}


kaldi_install(){
	
	if [  $1 == ""  ]; then
		read -p "how many cores you like to use for compile?  : " cores
	    cores=8		
	fi
	echo "installing kaldi.."
	sudo apt install g++ subversion
	cd git 
	mkdir speech 
	cd speech
	git clone https://github.com/kaldi-asr/kaldi.git kaldi --origin upstream
	cd tools
	./extras/check_dependencies.sh # || kato mitä palauttaa, nyt testaan ensin. Interlillä äly hidas repo ~10min/220MB
	sudo ./extras/install_mkl.sh -sp debian intel-mkl-64bit-2019.2-057 # Onko syytä pointtaa noi tiukasti versioon?
	make -j $cores
	cd ../src/
	./configure --shared
	make depend -j $cores
	make -j $cores
	return $?
}


command="$1" 
shift

case "$command" in 
	
	
	basic)
		sudo apt install xterm
		;;

	conda|anaconda|letku)
		conda_install $@
		error_code="$?"			
		[ -z $error_code ] || echo "conda install failed with code: $error_code"
		exit $error_code
		;;

	django|freeman)
		conda install django
		conda list |grep django 
		exit $?
		;;

	programmer|pk2)
		command=$GURU_BIN/install-pk2.sh
		gnome-terminal --geometry=80x28 -- /bin/bash -c "$command; exit; $SHELL; "
		;;

	mpsyt|player|play)
		sudo apt-get -y install mplayer python3-pip
		sudo -H pip3 install --upgrade pip
		sudo -H pip3 install setuptools mps-youtube
		sudo -H pip3 install --upgrade youtube_dl 
		pip3 install mps-youtube --upgrade 
		error=$?
		sudo ln -s  /usr/local/bin/mpsyt /usr/bin/mpsyt 
		exit $error
		;;

	kaldi|listener)
		kaldi_install 4
		exit $?
		;;

	edoypts|edi)
		echo "TODO"
		exit $?
		;;

	help|-h|--help|*) 		# hardly never updated help printout
	 	printf "usage: guru install [MODULE] \nmobules: \n"
		printf 'conda           anaconda python environment manger \n'
		printf 'django          web framework for python people\n'
		printf 'kaldi           the ears, brains and.. lot of learning \n'
		printf 'mpsyt|player    players for terminal, music, video, youtube \n'
		printf 'programmer|pk2  pickit2 pic mcu programmer \n'		
esac


