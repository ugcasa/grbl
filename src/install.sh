#!/bin/bash
# install functions for giocon client ujo.guru / juha.palm 2019
# TODO: move all these to guru-install

install.main () {
    [ "$1" ] && argument="$1" || read -r -p "input module name: " argument
    case "$argument" in
        tiv|java|webmin|conda|hackrf|st-link|mqtt-server|mqtt-client|visual-code|tor|django|help)
                                      install.$argument "$@" ;;
        kaldi|listener)               install.kaldi 4 ;; # number of cores used during compiling
        pk2|pickit2|pickit|pic)       gnome-terminal --geometry=80x28 -- /bin/bash -c "$GURU_BIN/lib/install-pk2.sh; exit; $SHELL; " ;;
        spectrumanalyzer|SA)          install.spectrumanalyzer "$@"; install.fosphor "$@" ;;
        all)                          echo "TBD" ;;
        *)                            echo "no installer for '$argument'"; install.help
    esac
}


install.help () {
    echo "-- guru tool-kit tool install help -----------------------------------------------"
    printf "usage: %s install [keyword] \n" "$GURU_CALL"
    printf "\nkeywords:\n"
    echo " mqtt-client                 mosquitto client"
    echo " mqtt-server                 mosquitto server"
    echo " conda                       anaconda environment tool for python"
    echo " django                      django platform for python web"
    echo " pk2                         pickit2 programmer interface"
    echo " st-link                     st_link programmer for SM32"
    echo " kaldi                       speech to text ai"
    echo " tor                         tor browser"
    echo " webmin                      webmin tool for server configuratio"
}

install.tiv () {
    #install text mode picture viewer
    GURU_VERBOSE=true
    [[ -d /tmp/TerminalImageViewer ]] && rm /tmp/TerminalImageViewer -rf
    cd /tmp
    sudo apt update && OK "update" &&
    sudo apt install imagemagick && OK "imagemagick" &&
    git clone https://github.com/stefanhaustein/TerminalImageViewer.git && OK "git clone" &&
    cd TerminalImageViewer/src/main/cpp &&
    make && OK "compile" &&
    sudo make install && OK "install" &&
    rm /tmp/TerminalImageViewer -rf && OK "clean" &&
    SUCCESS "installation" || FAILED "something fucked up"
    GURU_VERBOSE=
}


install.django () {
        echo "TODO find it, written already"
}


install.question () {
    [ "$1" ] || return 2
    read -p "$1 [y/n]: " answer
    [ $answer ] || return 1
    [ $answer == "y" ]  && return 0
    return 1
}


install.tor () {     
    unset _url _dir _file _form _lang
    [[ $GURU_APP ]] || GURU_APP="$HOME"             # if run outside of guru tool-kit
    local _url="https://dist.torproject.org/torbrowser"
    local _file="tor-browser-linux64-"
    local _form=".tar.xz"
    local _lang="_en-US" ; [[ "$1" ]] && _lan="_$1"
    local _dir="/tmp/guru/tor" 
    
    # enter to temp folder
    [[ -d "$_dir" ]] ||mkdir -p "$_dir" 
    cd "$_dir"                                      

    # get verion folder list
    [[ -f torbrowser ]] && rm -fr torbrowser
    wget "$_url"                                    
    
    # get version and generate file and url 
    local _ver=$(cat torbrowser | grep "/icons/folder.gif" | cut -d " " -f 5 )
    _ver=${_ver%%'/"'*} 
    _ver=${_ver#*'="'}                              #; echo $_ver    
    _file="$_file$_ver$_lang$_form"                 #; echo $_file    
    _url="$_url/$_ver/$_file"                       #; echo $_url    
    
    # get browser 
    [[ -f "$_file" ]] && rm -fr "$_file"
    wget "$_url"

    # install browser
    [[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"
    [[ -d "$GURU_APP/tor-browser$_lang" ]] && rm -rf "$GURU_APP/tor-browser$_lang"
    tar xf "$_file" -C "$GURU_APP"
    
    printf "guru is ready to tor, type 'guru tor' to run browser\n\n"
}


install.java () {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    local require="nodejs"

    [ "$action" ] || read -r -p "install or remove?: " action
    printf "need to install $require, ctrl+c or enter local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to script java\n\n"
}


install.mqtt-client () {   #not tested
    echo "TBD install client"           #whaat.. thod these were in use at some point, what happened?
    # sudo apt-get update && sudo apt-get upgrade || return $?
    # sudo apt install mosquitto-clients || return $?
    # sudo add-apt-repository ppa:certbot/certbot || return $?
    # sudo apt-get update || return $?
    # sudo apt-get install certbot || return $?
    # sudo ufw allow http
    #continue: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-16-04
    #&& printf "\n guru is now ready to message\n\n"
    return 0
}


install.mqtt-server () {   #not tested

    # sudo apt-get update && sudo apt-get upgrade || return $?
    # sudo apt install mosquitto mosquitto-clients || return $?

    ln -s /etc/mosquitto/conf.d/default.conf $GURU_CFG/mosquitto.default.conf

    if install.question "setup password login?"; then
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

    if install.question "setup encryption?"; then
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

    if install.question "setup certificates?"; then
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
    printf "\n guru is now ready to service any message\n\n"

    return 0
}


install.hackrf () {
    # full
    # sudo apt install hackrf
    gnuradio-companion --help >/dev/null ||sudo apt-get install build-essential python3-dev libqt4-dev gnuradio gqrx-sdr hackrf gr-osmosdr libusb-dev python-qwt5-qt4 -y
    read -r -p "Connect HacrkRF One and press anykey: " nouse
    hackrf_info && echo "successfully installed" ||echo "HackrRF One not found, pls. re-plug or re-install"
    mkdir -p $HOME/git/labtools/radio
    cd $HOME/git/labtools/radio
    git clone https://github.com/mossmann/hackrf.git
    git clone https://github.com/mossmann/hackrf.wiki.git
    git clone https://ujoguru@bitbucket.org/ugdev/radlab.git
    echo "Documentation file://$HOME/git/labtools/radio/hackrf.wiki"
    printf "\n guru is now ready to radio\n\n"
    read -r -p "to start GNU radio press anykey (or CTRL+C to exit): " nouse
    gnuradio-companion &
    return 0
}


install.fosphor () {
    #[ -f /usr/local/bin/qspectrumanalyzer ] && exit 0
    sudo apt-get install cmake xorg-dev libglu1-mesa-dev
    cd ~/tmp
    git clone https://github.com/glfw/glfw
    cd glfw
    mkdir build
    cd build
    cmake ../ -DBUILD_SHARED_LIBS=true
    make && printf "\n guru is now ready to analyze some radio\n\n"
    sudo make install
    sudo ldconfig
    #rm -fr glfw
}


install.spectrumanalyzer () {

    [ -f /usr/local/bin/qspectrumanalyzer ] && return 0

    sudo add-apt-repository -y ppa:myriadrf/drivers
    sudo apt-get update

    sudo apt-get install -y python3-pip python3-pyqt5 python3-numpy python3-scipy soapysdr python3-soapysdr
    sudo apt-get install -y soapysdr-module-rtlsdr soapysdr-module-airspy soapysdr-module-hackrf soapysdr-module-lms7
    cd /tmp
    git clone https://github.com/xmikos/qspectrumanalyzer.git
    cd qspectrumanalyzer
    pip3 install --user .
    qspectrumanalyzer && printf "\n guru is now ready to analyze some radio\n\n"
    return 0
}


install.webmin() {

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


install.conda () {

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


install.kaldi(){

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
    make -j $cores && printf "\n guru is now ready to analyze some audio\n\n"
    return $?
}


install.st_link () {
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
    printf "\n guru is now ready to program st mcu's\n\n"
    echo "usage: st-flash --reset read test.bin 0x8000000 4096"
    exit 0
}


install.visual_code () {
    code --version >>/dev/null && return 1
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get install apt-transport-https                    # https://whydoesaptnotusehttps.com/
    sudo apt-get update
    sudo apt-get install code && printf "\n guru is now ready to code \n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    source "$GURU_BIN/lib/common.sh"
    #source "$GURU_BIN/lib/deco.sh"
    install.main "$@"
    exit $?
fi

