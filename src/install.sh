#!/bin/bash
# install functions for giocon client ujo.guru / juha.palm 2019

main () {

	case "$argument" in
		
			all)
				guru tag install 
				guru note install 
				guru yle install 
				guru play install 
				;;


			basic)
				sudo apt install xterm
				exit $?
				;;

			mqtt-client|mosquitto-client|mosquitto-pub|mosquitto-sub)
				install_mosquitto_client "$@"
				exit $?
				;;

			mqtt-server|mosquitto-server)
				install_mosquitto_server "$@"
				exit $?
				;;

			conda|anaconda|letku)
				install_conda "$@"
				error_code="$?"         
				[ -z $error_code ] || echo "conda install failed with code: $error_code"
				exit $error_code
				exit $?
				;;

			django|freeman)
				conda install django
				conda list |grep django 
				exit $?
				;;

			alpine|pine|email)
				install_alpine "$@"
				exit $?
				;;

			pk2)
				argument=$GURU_BIN/install-pk2.sh
				gnome-terminal --geometry=80x28 -- /bin/bash -c "$argument; exit; $SHELL; "
				exit $?
				;;

			st-link)
				install_st-link "$@"                
				exit $?
				;;

			mpsyt|player|play)          
				$GURU_CALL play install "$@"
				exit $error
				;;

			kaldi|listener)
				install_kaldi 4
				exit $?
				;;

			tor|tor-browser|tor-firrefox)
				install_tor_browser
				exit $?
				;;

			webmin)
				install_webmin
				exit $?
				;;

			scanner|DS30)
				$GURU_CALL scan install
				exit $?
				;;

			hackrf|gnuradio|rf-tools)
				install_hackrf "$@"
				exit $?
				;;

			spectrumanalyzer|SA)
				install_spectrumanalyzer "$@"
				install_fosphor "$@"
				exit $?
				;;

			edoypts|edi)
				echo "TODO"
				exit $?
				;;

			pictures)
				set_up_dropbox_pictures "$@"
				exit $?
				;;

			visual-code|vsc|code)
				code --version >>/dev/null || install_vsc "$@"
				;;

			help|-h|--help|*)       # hardly never updated help printout
				printf "usage: guru install [MODULE] \nmobules: \n"
				printf 'mqtt-client                 mosquitto client \n'
				printf 'mqtt-server                 mosquitto server \n'
				printf 'conda|anaconda              anaconda environment tool for python \n'
				printf 'django|freeman              django platform for python web \n'
				printf 'alpine|pine|email           email client install \n'
				printf 'pk2                         pickit2 programmer interface \n'
				printf 'st-link                     st-link programmer for SM32 \n'
				printf 'mpsyt|player|play           text based youtube player \n'
				printf 'kaldi|listener              speech to text ai \n'
				printf 'tor|tor-browser             tor browser \n'
				printf 'webmin                      webmin tool for server configuration\n'
				printf 'scanner|DS30                Epson DS30 + scanner tools (mint19 only) \n'
				printf 'edoypts|edi                 hmm. no clue\n'
				printf 'pictures                    set ~/Pictures point to dropbox \n'
				;;
	esac

}


yes_no () {
	[ "$1" ] || return 2
	read -p "$1 [y/n]: " answer
	[ $answer ] || return 1
	[ $answer == "y" ]  && return 0 
	return 1
}

install_tor_browser () { # fised to 8.5.4_en-US
	
	echo "installing version 8.5.4_en-US, there might be more reacent release available"
	[ -f /tmp/tor-browser-linux64-8.5.4_en-US.tar.xz ] || wget https://www.torproject.org/dist/torbrowser/8.5.4/tor-browser-linux64-8.5.4_en-US.tar.xz -P /tmp
	[ -d $GURU_APP ] || mkdir -p $GURU_APP
	[ -d $GURU_APP/tor-browser_en-US ] &&rm -rf $GURU_APP/tor-browser_en-US
	tar xf /tmp/tor-browser-linux64-8.5.4_en-US.tar.xz -C $GURU_APP 
	sh -c '"$(dirname "$*")"/Browser/start-tor-browser --detach || ([ ! -x "$(dirname "$*")"/Browser/start-tor-browser ] && "$(dirname "$*")"/start-tor-browser --detach)' dummy %k X-TorBrowser-ExecShell=./Browser/start-tor-browser --detach
}

install_mosquitto_client () {   #not tested

	echo "install client"
	# sudo apt-get update && sudo apt-get upgrade || return $?
	# sudo apt install mosquitto-clients || return $?
	# sudo add-apt-repository ppa:certbot/certbot || return $?
	# sudo apt-get update || return $?
	# sudo apt-get install certbot || return $?
	# sudo ufw allow http

	#continue: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-16-04
	return 0
}


install_mosquitto_server () {   #not tested

	# sudo apt-get update && sudo apt-get upgrade || return $?
	# sudo apt install mosquitto mosquitto-clients || return $?
	
	ln -s /etc/mosquitto/conf.d/default.conf $GURU_CFG/mosquitto.default.conf

	if yes_no "setup password login?"; then 
		pass=1
		echo "setting up password login"
		read -p "mqtt client username :" username
		[ "$username" ] || return 668
		# sudo mosquitto_passwd -c /etc/mosquitto/passwd $username && printf "allow_anonymous false\npassword_file /etc/mosquitto/passwd\n" >>/etc/mosquitto/conf.d/default.conf || return 668
		# sudo systemctl restart mosquitto || return $?

		read -p "password for testing :" password
		[ "$password" ] || return 671
		# mosquitto_pub -h localhost -t "test" -m "hello login" -p 1883 -u $username -P $password && echo "loalhost 1883 passed" || echo "failed loalhost 8883 "
	fi

	if yes_no "setup encryption?"; then 
		enc=1
		echo "setting up ssl encryption"
		# sudo ufw allow 8883
		# printf '# ujo.guru mqtt setup \nlistener 1883 localhost\n\nlistener 8883\ncertfile /etc/letsencrypt/live/mqtt.ujo.guru/cert.pem\ncafile /etc/letsencrypt/live/mqtt.ujo.guru/chain.pem\nkeyfile /etc/letsencrypt/live/mqtt.ujo.guru/privkey.pem' >/etc/mosquitto/conf.d/default.conf
		# sudo systemctl restart mosquitto
		if [ $pass ]; then 
			echo "pass"
			# mosquitto_pub -h localhost -t "test" -m "hello encryption" -u $username P $password -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
		else  
			echo "pass"
			# mosquitto_pub -h localhost -t "test" -m "hello encryption" -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
		fi
	fi
	
	if yes_no "setup certificates?"; then 
		cert=1
		echo "setting up certificate login"
		# sudo add-apt-repository ppa:certbot/certbot || return $?
		sudo apt-get update || return $?
		# sudo apt-get install certbot || return $?
		# sudo ufw allow http
		# sudo certbot certonly --standalone --standalone-supported-challenges http-01 -d mqtt.ujo.guru
		echo "to renew certs automatically add following line to crontab (needs to be done manually)"
		echo '15 3 * * * certbot renew --noninteractive --post-hook "systemctl restart mosquitto"'
		read -p "press any key to continue.. "
		# sudo crontab -e   

		if [ $enc ]; then 
			echo "pass"
		# mosquitto_pub -h localhost -t "test" -m "hello 8883" -p 8883 --capath /etc/ssl/certs/ && echo "loalhost 8883 passed" || echo "failed loalhost 8883 "
		fi
	fi
	# Testing 
	echo "mosquitto server successfully installed"

	return 0
}


install_hackrf () {

		gnuradio-companion --help >/dev/null ||sudo apt-get install gnuradio gqrx-sdr hackrf gr-osmosdr -y
		read -r -p "Connect HacrkRF One and press anykey: " nouse
		hackrf_info && echo "successfully installed" ||echo "HackrRF One not found, pls. re-plug or re-install"
		mkdir -p $HOME/git/labtools/radio 
		cd $HOME/git/labtools/radio 
		git clone https://github.com/mossmann/hackrf.git
		git clone https://github.com/mossmann/hackrf.wiki.git
		git clone https://ujoguru@bitbucket.org/ugdev/radlab.git
		echo "Documentation file://$HOME/git/labtools/radio/hackrf.wiki"		
		read -r -p "to start GNU radio press anykey (or CTRL+C to exit): " nouse
		gnuradio-companion 
		return 0
}


install_fosphor () {

	#[ -f /usr/local/bin/qspectrumanalyzer ] && exit 0

	sudo apt-get install cmake xorg-dev libglu1-mesa-dev
	cd ~/tmp
	git clone https://github.com/glfw/glfw
	cd glfw
	mkdir build
	cd build
	cmake ../ -DBUILD_SHARED_LIBS=true
	make
	sudo make install
	sudo ldconfig
	#rm -fr glfw

}

install_spectrumanalyzer () {

		[ -f /usr/local/bin/qspectrumanalyzer ] && return 0

		sudo add-apt-repository -y ppa:myriadrf/drivers
		sudo apt-get update

		sudo apt-get install -y python3-pip python3-pyqt5 python3-numpy python3-scipy soapysdr python3-soapysdr
		sudo apt-get install -y soapysdr-module-rtlsdr soapysdr-module-airspy soapysdr-module-hackrf soapysdr-module-lms7
		cd /tmp
		git clone https://github.com/xmikos/qspectrumanalyzer.git
		cd qspectrumanalyzer
		pip3 install --user .
		qspectrumanalyzer
		return 0
}


install_webmin() {

	cat /etc/apt/sources.list |grep "download.webmin.com" >/dev/null
	if ! [ $? ]; then 
		sudo sh -c "echo 'deb http://download.webmin.com/download/repository sarge contrib' >> /etc/apt/sources.list"
		wget http://www.webmin.com/jcameron-key.asc #&&\
		sudo apt-key add jcameron-key.asc #&&\
		rm jcameron-key.asc 
	fi
	
	cat /etc/apt/sources.list |grep "webmin" >/dev/null
	if ! [ $? ]; then 
		sudo apt update
		sudo apt install webmin 
		echo "webmin installed, connect http://localhost:10000"
		echo "if using ssh tunnel try http://localhost.localdomain:100000)"
	else
		echo "already installed" 
	fi
}


install_conda () {

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
	echo 'conda install done, next run setup by typing: "'$GURU_CALL' set conda"'
	return 0
}


install_kaldi(){
	
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



install_st-link () {
	# did not work properly - not mutch testing done dow
	st-flash --version && exit 0
	cmake >>/dev/null ||sudo apt install cmake
	sudo apt install --reinstall build-essential -y
	dpkg -l libusb-1.0-0-dev >>/dev/null ||sudo apt-get install libusb-1.0-0-dev
	cd /tmp 
	[ -d stlink ] && rm -rf stlink
	git clone https://github.com/texane/stlink
	cd stlink
	make release
	#install binaries:
	sudo cp build/Release/st-* /usr/local/bin -f
	#install udev rules
	sudo cp etc/udev/rules.d/49-stlinkv* /etc/udev/rules.d/ -f
	#and restart udev
	sudo udevadm control --reload
	echo "installed"
	echo "usage: st-flash --reset read test.bin 0x8000000 4096"
	exit 0
}


install_alpine () {

	target_cfg=$HOME/.pinerc    
	if ! $(alpine -v >>/dev/null); then 
		echo "installing alpine"
		sudo apt install alpine
	else
		echo "installed"            
	fi
	
	echo "setting up alpine: TODO"
	return 0
	
	# [ -f $target_cfg ] && mv -f $target_cfg $GURU_CFG/.pinerc.original
	
	# echo "personal-name=$GURU_USER"               >$target_cfg
	# echo "user-domain=ujo.guru"                   >$target_cfg

	# read -p "imput "
	# imap.gmail.com/ssl/user=YOURUSERNAME@GMAIL.COM

	# export GURU_EMAIL="juha.palm@ujo.guru casa@ujo.guru" 
	# export GURU_GMAIL="juha.palm@gmail.com regressio@gmail.com" 
	# export GURU_PMAIL="juha.palm@protonmail.com regressio@protonmail.com" 
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	argument="$1" 
	shift
	main $@
fi



set_up_dropbox_pictures () {

	[ -d "$GURU_PICTURE" ] || exit 123

	if [ -d "$HOME/Pictures" ]; then 
		read -p "copy your current $HOME/Pictures to $GURU_PICTURE?"
		[ "$answer"=="y" ] || exit 124
		cp -r "$HOME/Pictures" "$GURU_PICTURE" && echo "success" || exit 125
	fi

	rm -rf $HOME/Pictures
	ln -s $GURU_PICTURE $HOME/Pictures

}

install_vsc () {

	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
	sudo apt-get install apt-transport-https 					# https://whydoesaptnotusehttps.com/
	sudo apt-get update
	sudo apt-get install code
	#code &
}

