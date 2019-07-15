# Some simple functions not complicate enough to write separate scripts
# ujo.guru 2019 

project () {

	if [ ! $GURU_EDITOR == "subl" ]; then 
		echo 'works only with sublime. Set preferred editor by typing: "guru set editor subl"'		
		return 15
	fi

	if ! [ -z "$1" ]; then 
		subl --project "$HOME/Dropbox/Notes/casa/project/$1.sublime-project" -a 
		subl --project "$HOME/Dropbox/Notes/casa/project/$1.sublime-project" -a 	#Sublime bug
		return 0
	else
		echo "enter project, and optional file name"
		return 1
	fi
}

set_value () {
	sed -i -e "/$1=/s/=.*/=$2/" $HOME/.gururc
}



settings () {

	case "$1" in 
			
			editor)
				if [ ! "$2" ]; then 
					read -p "input preferred editor : " new_value
				else
					new_value=$2
				fi		
				set_value GURU_EDITOR $new_value	
				#sed -i -e "/GURU_EDITOR=/s/=.*/=$new_value/" $HOME/.gururc
				;;

			audio)
				if [ "$2" ]; then 
					new_value=$2
				else
					read -p "new value (true/false) : " new_value
				fi				
				set_value GURU_AUDIO_ENABLED $new_value
				#sed -i -e "/GURU_AUDIO_ENABLED=/s/=.*/=$new_value/" $HOME/.gururc
				;;

			conda)
				conda_setup
				return $?
				;;
	
			status|stat)
				echo "Current settings:"
				cat $HOME/.gururc |grep "export"| cut -c13-
				;;

			*)
				set_value GURU_${1^^} $2
				echo "setting GURU_${1^^} to $2"
	esac
}

dozer () {

	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1 
	pandoc "$1" --reference-odt="$notes/$USER/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
	return 0
}


disable () {

	if [ -f "$HOME/.gururc" ]; then 
		mv -f "$HOME/.gururc" "$HOME/.gururc.disabled" 
		echo "giocon.client disabled"
		return 0
	else		
		echo "disabling failed"
		return 21
	fi	
}


upgrade () {

	temp_dir="/tmp/guru"
	source="https://ujoguru@bitbucket.org/ugdev/giocon.client.git"
	
	[ -d $temp_dir ] && rm -rf $temp_dir
	mkdir $temp_dir 
	cd $temp_dir
	git clone $source

	guru uninstall 
	cd $temp_dir/giocon.client
	bash install.sh
	#rm -rf $temp_dir
}

uninstall () {	 

	if [ -f "$HOME/.bashrc.giobackup" ]; then 
		mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"		
		rm -f "$HOME/.gururc"
		dconf load /org/cinnamon/desktop/keybindings/ < $HOME/.kbbind.backup.cfg		
		sudo rm -fr /opt/gio
		rm -fr "$HOME/.config/gio"
		echo "giocon.client uninstalled"
		return 0
	else		
		echo "uninstall failed"
		return 22
	fi	
}


status () {

	printf "\e[1mTimer\e[0m: $(guru timer status)\n" 
	#printf "\e[1mConnect\e[0m: $(guru connect status)\n" 
	return 0
}


test_guru () {

	printf "var: $#: $*\nuser: $GURU_USER \n"
	return 10
}


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


conda_setup(){

	cat ~/.bashrc |grep "__conda_setup" || cat "$GURU_BIN/conda_launcher.sh" >>$HOME/.bashrc
	source ~/.bashrc
	conda list >>/dev/null || return 14 && 	echo "conda installation found"
	conda config --set auto_activate_base false
	echo "to create and activate environment type: "
	echo "conda create --name my_env python=3"
	echo "conda activate my_env"
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

install () {

	command="$1" 
	shift

	case "$command" in 
		
		conda|anaconda|letku)
			conda_install $@
			error_code="$?"			
			[ -z $error_code ] || echo "conda install failed with code: $error_code"
			return $error_code
			;;

		django|freeman)
			conda install django
			conda list |grep django 
			return $?
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
			return $error
			;;

		kaldi|listener)
			kaldi_install 4
			return $?
			;;

		*)
			echo "nothing to install"
			return 22
	esac
}


