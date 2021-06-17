#!/bin/bash
# install applications casa@ujo.guru 2019-2021
# module or module adapter scripts should have install and remove functions called by <module>.main install/remove
# these are stand alone installers for application no worth to make module (or adapter script)

source $GURU_BIN/common.sh


install.main () {
    [ "$1" ] && argument="$1" && shift || read -r -p "input module name: " argument

    # architecture selection
    case $(uname -m) in
        aarch64|arm64) SYSTEM_ARCHITECTURE="arm64" ;;
        amd64|x86_64) SYSTEM_ARCHITECTURE="amd64" ;;
        *) gmsg -c red "unknown architecture" -k esc
    esac

    case "$argument" in
        help|pk2|virtualbox|tiv|django|java| \
        client|hackrf|fosphor|spectrumanalyzer| \
        radio|webmin|anaconda|kaldi|link|vscode )
                    install.$argument "$@" ;;
        status|poll|start|stop)
                    gmsg -v dark_grey "no polling functions" ;;
        *)          gmsg -v dark_grey "no installer for '$argument'"; install.help
    esac
}


install.help () {
    gmsg -v1 -c white "guru-client installer help "
    gmsg -v2
    gmsg -v0  "usage:    $GURU_CALL install [keyword] "
    gmsg -v2
    gmsg -v1 -c white  "keywords:"
    gmsg -v1 " vscode               ms visual code "
    gmsg -v1 " virtualbox           virtualbox "
    gmsg -v1 " kaldi                speech recognize AI "
    gmsg -v1 " java                 java runtime "
    gmsg -v1 " python               python3 and venv "
    gmsg -v1 " anaconda             anaconda dev tool"
    gmsg -v1 " django               django framework "
    gmsg -v1 " mqtt-client          mopsquitto MQTT clients "
    gmsg -v1 " webmin               webmin tools "
    gmsg -v1 " pk2                  pickit2 programmer interface for PIC mcu "
    gmsg -v1 " st-link              st-link programmer SM32 mcu "
    gmsg -v1 " radio                gnuradio, HackRF, spectrumanalyzer and fosphor "
    gmsg -v2 " gnuradio             install radio software separately: "
    gmsg -v2 " hackrf               "
    gmsg -v2 " spectrumanalyzer     "
    gmsg -v2 " fosphor              "
    gmsg -v1 " tiv                  tiv text mode picture viewer "
    gmsg -v2

}


install.question () {
    [ "$1" ] || return 2
    read -p "$1 [y/n]: " answer
    [ $answer ] || return 1
    [ $answer == "y" ]  && return 0
    return 1
}



install.virtualbox () {
    # add to sources list
    if [[ -f /etc/apt/sources.list.d/virtualbox.list ]] ; then
            echo "already in sources list"
        else
            #  According to your distribution, replace '<mydist>' with 'eoan', 'bionic', 'xenial', 'buster', 'stretch', or 'jessie'
            # ulyssa <- $(lsb_release -cs) not worky
            # not possible to get ubuntu release name out of mint :/
            source /etc/os-release
            echo "deb [arch=$SYSTEM_ARCHITECTURE] http://download.virtualbox.org/virtualbox/debian $UBUNTU_CODENAME contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list

        fi
    # get key
    wget https://www.virtualbox.org/download/oracle_vbox_2016.asc
    # add key
    sudo apt-key add oracle_vbox_2016.asc

    # install
    sudo apt-get update
    sudo apt-get install -y virtualbox virtualbox-ext-pack

    # full screen
    sudo apt-get install -y build-essential module-assistant
    sudo m-a prepare

    # install usb support
    echo "file > preferences > extencions > [+]"
    $GURU_PREFERRED_BROWSER https://download.virtualbox.org/virtualbox/6.1.16/VirtualBoxSDK-6.1.16-140961.zip
    sudo usermod -aG vboxusers $USER
}


install.tiv () {
    #install text mode picture viewer
    [[ -d /tmp/TerminalImageViewer ]] && rm /tmp/TerminalImageViewer -rf
    cd /tmp
    sudo apt update && OK "update"
    sudo apt install imagemagick && OK "imagemagick"
    git clone https://github.com/stefanhaustein/TerminalImageViewer.git && OK "git clone"
    cd TerminalImageViewer/src/main/cpp
    make && OK "compile"
    sudo make install && OK "install"
    rm /tmp/TerminalImageViewer -rf && OK "clean"
}


install.django () {
        echo "TODO find it, written already"
}


install.java () {
    #install and remove needed applications. input "install" or "remove"
    local action=$1
    local require="nodejs"w

    [ "$action" ] || read -r -p "install or remove?: " action
    printf "need to install $require, ctrl+c or enter local "
    sudo apt update && eval sudo apt "$action" "$require" && printf "\n guru is now ready to script java\n\n"
}



# combined to radio
install.hackrf () {
    # full
    # sudo apt install hackrf
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


isntall.radio () {

    if !gnuradio-companion --help >/dev/null ; then
            sudo apt-get install -y \
                "build-essential python3-dev libqt4-dev gnuradio gqrx-sdr hackrf \
                gr-osmosdr libusb-dev python-qwt5-qt4"
        fi
    install.hackrf || gmsg -v yellow "hackrf isntall error"
    install.spectrumanalyzer || gmsg -v yellow "spectrumanalyzer isntall error"
    install.fosphor || gmsg -v yellow "fosphor isntall error"

    # launch
    [[ $GURU_FORCE ]] && gnuradio-companion &
}


install.webmin () {

    cat /etc/apt/sources.list |grep "download.webmin.com" >/dev/null
    if ! [ $? ]; then
        sudo sh -c "echo 'deb [arch=$SYSTEM_ARCHITECTURE] http://download.webmin.com/download/repository sarge contrib' >> /etc/apt/sources.list"
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


install.anaconda () {

    conda list && return 13 || echo "no anaconda installed"

    sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6

    [ "$1" ] && anaconda_version=$1 || anaconda_version="2019.03"
    anaconda_installer="Anaconda3-$anaconda_version-Linux-x86_64.sh"
    anaconda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

    curl -O https://repo.anaconda.com/archive/$anaconda_installer
    sha256sum $anaconda_installer >installer_sum
    printf "checking sum, if exit it's invalid: "
    cat installer_sum |grep $anaconda_sum && echo "ok" || return 11

    chmod +x $anaconda_installer
    bash $anaconda_installer -u && rm $anaconda_installer installer_sum || return 12
    source ~/.bashrc
    gmsg -c green  "anaconda install done"
    gmsg -c1 "run setup by typing: '$GURU_CALL anaconda set'"
    return 0
}


install.kaldi (){

    local cores=8
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


install.st-link () {
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


install.vscode () {
    code --version >>/dev/null && return 1
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=$SYSTEM_ARCHITECTURE signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get install apt-transport-https                    # https://whydoesaptnotusehttps.com/
    sudo apt-get update
    sudo apt-get install code && printf "\n guru is now ready to code \n\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    install.main "$@"
    exit $?
fi

