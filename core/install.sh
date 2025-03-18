#!/bin/bash
# install applications casa@ujo.guru 2019-2021
# module or module adapter scripts should have install and remove functions called by <module>.main install/remove
# these are stand alone installers for application no worth to make module (or adapter script)
source /etc/os-release
source /etc/upstream-release/lsb-release

source $GRBL_BIN/common.sh

install.main () {
    if [[ "$1" ]] ; then
            argument="$1"
            shift
        fi

    # architecture selection TODO os.sh can this shit
    case $(uname -m) in
        aarch64|arm64) SYSTEM_ARCHITECTURE="arm64" ;;
        amd64|x86_64) SYSTEM_ARCHITECTURE="amd64" ;;
        *) gr.msg -c red "unknown architecture" -k caps
           return 100
           ;;
    esac

    # this change is not tested, should work dough
    case "$argument" in \
        dropbox|\
        steam|\
        status|\
        earth|\
        help|\
        minecraft|\
        unity|\
        virtualbox|\
        tiv|\
        django|\
        java|\
        hackrf|\
        fosphor|\
        spectrumanalyzer|\
        radio|\
        webmin|\
        anaconda|\
        kaldi|\
        python|\
        vscode|\
        teams|\
        fail2ban)
            gr.msg -v1 "installing $argument.."
            install.$argument "$@"
            ;;
        *)
            gr.msg -v dark_grey "no installer for '$argument'"
            install.help
    esac
}

install.status () {
    gr.msg -t "${FUNCNAME[0]}: available "
}

install.help () {
    gr.msg -v1 -c white "grbl installer help "
    gr.msg -v2
    gr.msg -v0  "usage:    $GRBL_CALL install application_name "
    gr.msg -v2
    gr.msg -v1 -c white  "application list:"
    gr.msg -v1 " anaconda             anaconda dev tool"
    gr.msg -v1 " django               django framework "
    gr.msg -v2 " fosphor              "
    gr.msg -v2 " hackrf               "
    gr.msg -v1 " java                 java runtime "
    gr.msg -v1 " kaldi                speech recognize AI "
    gr.msg -v1 " python               python3 and venv "
    gr.msg -v1 " radio                gnuradio, HackRF, spectrumanalyzer and fosphor "
    gr.msg -v2 " spectrumanalyzer     "
    gr.msg -v1 " tiv                  tiv text mode picture viewer "
    gr.msg -v1 " virtualbox           virtualbox "
    gr.msg -v1 " vscode               ms visual code "
    gr.msg -v1 " webmin               webmin tools "
    gr.msg -v1 " minecraft            minecraft block game"
    gr.msg -v1 " dropbox              install: headless daemon, control script or gui app"
    gr.msg -v2 " unity                TBD unity "
    gr.msg -v2 " mqtt                 TBD mopsquitto MQTT client "
    gr.msg -v2 " mqtt-server          TBD mopsquitto MQTT server "
    gr.msg -v2
}

install.dropbox () {
# install dropbox daemon, control script and gui client app

    # for Ubuntu (18.04, 20.04, 22.04, 23.04) or equivalent (Linux Mint 19+, Pop!_OS)
    # tested once

    # get os module functions in use
    source os.sh
    source /etc/os-release
    source /etc/upstream-release/lsb-release
    gr.msg "$NAME $VERSION_ID '$VERSION_CODENAME' based on $DISTRIB_ID $DISTRIB_RELEASE '$DISTRIB_CODENAME' $HOME_URL"

    if [[ $DISTRIB_ID != "Ubuntu" ]] ; then
        gr.msg "Ubuntu based systems only!"
        return 2
    fi

    case $DISTRIB_RELEASE in
        # 22.10 or higher
        22.10|23*|24*)
            newist="22024.04.17"
            ;;
        # 18.04 - 22.04
        18*|19*|20*|22.04)
            newist="2020.03.04"
            ;;
        *) gr.msg -e0 "not supported"
            return 3
    esac

    gr.msg "$newist"

    if gr.ask "install frontend client"; then
        [[ -d ~/apps ]] && cd ~/apps
        if ! [[ -f dropbox_${newist}_amd64.deb ]]; then
            app_deb_url=https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_${newist}_amd64.deb
            wget -q $app_deb_url
        fi
        sudo dpkg -i "dropbox_${newist}_amd64.deb"
    fi

    if gr.ask "install headless daemon"; then
        # daemon
        cd ~
        wget -q -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
        ln -s ~/.dropbox-dist/dropboxd ~/apps/dropboxd
        gr.msg -h "run daemon by './apps/dropboxd &'"
    fi

    if gr.ask "get control script"; then
        ## control script
        cd apps
        if ! [[ -f dropbox.py ]]; then
            wget https://www.dropbox.com/download?dl=packages/dropbox.py -O dropbox.py
        fi
        chmod +x dropbox.py
        gr.msg -h "run script by '~/apps/dropbox.py'"
    fi

    if gr.ask "run daemon?"; then
        ./dropboxd &
    fi
}

install.earth () {
    clear
    gr.msg -h "Installing Google Earth.. "

    sudo apt install google-earth-pro-stable || return 12

    gr.msg -c green "ok"

    gr.ask "open it?" && google-earth-pro
}


install.minecraft () {

    if [[ "$1" == "uninstall" ]] ; then
        sudo apt-get --purge remove minecraft-launcher
        rm -r ~/.minecraf
        return $?
    fi

    cd /tmp
    wget https://launcher.mojang.com/download/Minecraft.deb
    sudo dpkg -i Minecraft.deb
    sudo apt-get -f install
}


install.unity () {
    # install unity 3D

    if [[ "$1" == "uninstall" ]] ; then
        gr.ask "remove unity?" || return 0
        sudo apt-get remove unityhub
        return $?
    fi

    # if tiv -help >/tmp/$USER/tiv.help ; then
    #     gr.msg "already installed: $(head -n1 /tmp/$USER/tiv.help) "
    #     gr.ask "force reinstall" || return 0
    # fi

    sudo sh -c 'echo "deb https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'
    wget -qO - https://hub.unity3d.com/linux/keys/public | sudo apt-key add - || return 101
    sudo apt-get update || return 102
    sudo apt-get install unityhub || return 103

    return 0
}

install.signal () {
# install signal app to Ubuntu/Mint desktop

    # NOTE: These instructions only work for 64-bit Debian-based
    # Linux distributions such as Ubuntu, Mint etc.

    gr.msg $DISTRIB_CODENAME

    # 1. Install our official public software signing key:
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
    cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

    # 2. Add our repository to your list of repositories:
    # echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt $DISTRIB_CODENAME main" |\
    #   sudo tee /etc/apt/sources.list.d/signal-$DISTRIB_CODENAME.list
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
        sudo tee /etc/apt/sources.list.d/signal-xenial.list

    # 3. Update your package database and install Signal:
    sudo apt update && sudo apt install signal-desktop

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
    $GRBL_PREFERRED_BROWSER https://download.virtualbox.org/virtualbox/6.1.16/VirtualBoxSDK-6.1.16-140961.zip
    sudo usermod -aG vboxusers $USER
}


install.tiv () {
    #install text mode picture viewer

    if [[ "$1" == "uninstall" ]] ; then
        gr.ask "remove tiv?" || return 0
        rm /usr/local/bin/tiv

        gr.ask "remove imagemagick?" || return 0
        sudo apt-get remove imagemagick
        return $?
    fi

    if tiv -help ; then
        gr.ask "already installed force reinstall?" || return 0
    fi

    [[ -d /tmp/$USER/TerminalImageViewer ]] && rm /tmp/$USER/TerminalImageViewer -rf
    cd /tmp
    sudo apt-get update && OK "update"
    sudo apt-get install imagemagick && OK "imagemagick"
    git clone https://github.com/stefanhaustein/TerminalImageViewer.git && OK "git clone"
    cd TerminalImageViewer/src/main/cpp
    make && OK "compile"
    sudo make install && OK "install"
    rm /tmp/$USER/TerminalImageViewer -rf && OK "clean"
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
    sudo apt-get update && eval sudo apt-get "$action" "$require" && printf "\n grbl is now ready to script java\n\n"
}



# combined to radio
install.hackrf () {
    # full
    # sudo apt-get install hackrf
    read -r -p "Connect HacrkRF One and press anykey: " nouse
    hackrf_info && echo "successfully installed" || echo "HackrRF One not found, pls. re-plug or re-install"
    mkdir -p $HOME/git/labtools/radio
    cd $HOME/git/labtools/radio
    git clone https://github.com/mossmann/hackrf.git
    git clone https://github.com/mossmann/hackrf.wiki.git
    git clone https://ujogrbl@bitbucket.org/ugdev/radlab.git
    echo "Documentation file://$HOME/git/labtools/radio/hackrf.wiki"
    printf "\n grbl is now ready to radio\n\n"
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
    make && printf "\n grbl is now ready to analyze some radio\n\n"
    sudo make install
    sudo ldconfig
    #rm -fr glfw
}


install.spectrumanalyzer () {

    [[ -f /usr/local/bin/qspectrumanalyzer ]] && return 0

    sudo add-apt-repository -y ppa:myriadrf/drivers
    sudo apt-get update

    sudo apt-get install -y python3-pip python3-pyqt5 python3-numpy python3-scipy soapysdr python3-soapysdr
    sudo apt-get install -y soapysdr-module-rtlsdr soapysdr-module-airspy soapysdr-module-hackrf soapysdr-module-lms7
    cd /tmp
    git clone https://github.com/xmikos/qspectrumanalyzer.git
    cd qspectrumanalyzer
    pip3 install --user .
    qspectrumanalyzer && printf "\n grbl is now ready to analyze some radio\n\n"
    return 0
}


install.radio () {

    if ! gnuradio-companion --help >/dev/null ; then
            sudo apt-get install -y \
                "build-essential python3-dev libqt4-dev gnuradio gqrx-sdr hackrf \
                gr-osmosdr libusb-dev python-qwt5-qt4"
        fi
    install.hackrf || gr.msg -v yellow "hackrf isntall error"
    install.spectrumanalyzer || gr.msg -v yellow "spectrumanalyzer isntall error"
    install.fosphor || gr.msg -v yellow "fosphor isntall error"

    # launch
    [[ $GRBL_FORCE ]] && gnuradio-companion &
}


install.webmin () {

    cat /etc/apt/sources.list |grep "download.webmin.com" >/dev/null
    if ! [[ $? ]] ; then
        sudo sh -c "echo 'deb [arch=$SYSTEM_ARCHITECTURE] http://download.webmin.com/download/repository sarge contrib' >> /etc/apt/sources.list"
        wget http://www.webmin.com/jcameron-key.asc #&&\
        sudo apt-key add jcameron-key.asc #&&\
        rm jcameron-key.asc
    fi

    cat /etc/apt/sources.list |grep "webmin" >/dev/null
    if ! [[ $? ]] ; then
        sudo apt-get update
        sudo apt-get install webmin
        echo "webmin installed, connect http://localhost:10000"
        echo "if using ssh tunnel try http://localhost.localdomain:100000)"
    else
        echo "already installed"
    fi
}


install.anaconda () {

    conda list && return 13 || echo "no anaconda installed"

    sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6

    [[ "$1" ]] && anaconda_version=$1 || anaconda_version="2019.03"
    anaconda_installer="Anaconda3-$anaconda_version-Linux-x86_64.sh"
    anaconda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

    curl -O https://repo.anaconda.com/archive/$anaconda_installer
    sha256sum $anaconda_installer >installer_sum
    printf "checking sum, if exit it's invalid: "
    cat installer_sum | grep $anaconda_sum && echo "ok" || return 11

    chmod +x $anaconda_installer
    bash $anaconda_installer -u && rm $anaconda_installer installer_sum || return 12
    source ~/.bashrc
    gr.msg -c green  "anaconda install done"
    gr.msg -c1 "run setup by typing: '$GRBL_CALL anaconda set'"
    return 0
}


install.kaldi (){

    local cores=8
    echo "installing kaldi.."
    sudo apt-get install g++ subversion
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
    make -j $cores && printf "\n grbl is now ready to analyze some audio\n\n"
    return $?
}


install.python () {
    # raw install python tools
    sudo apt-get update
    if python -V ; then
            gr.msg -c green "python2.7 installed"
        else
            sudo apt-get install python2 || gr.msg -c yellow "error $? during python2.7 install"
        fi

    if python3 -V ; then
            gr.msg -c green "python3 installed"
        else
            sudo apt-get install -y python3.9 python3-pip python3-venv python3-dev \
            || gr.msg -c yellow "error $? during python3.9 install"
        fi

    sudo apt-get install build-essential libssl-dev libffi-dev
}


install.vscode () {
    # install ms visual code editor

    gr.msg "installing vscode.."
    sudo apt-get update
    sudo apt-get install software-properties-common apt-transport-https wget

    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt-get update

    if sudo apt-get install code ; then
            gr.msg -c green "installed"
            return 0
        else
            gr.msg -c yellow "error $? during install"
            return $?
        fi

    # code --version >>/dev/null && return 1
    # curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    # sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
    # sudo sh -c 'echo "deb [arch=$SYSTEM_ARCHITECTURE signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    # sudo apt-get install apt-transport-https                    # https://whydoesaptnotusehttps.com/
    # sudo apt-get update
    # sudo apt-get install code && printf "\n grbl is now ready to code \n\n"
}


install.teams () {

    # Step 1 make temp
    temp_folder="/tmp/$USER/teams"
    mkdir -p $temp_folder && cd $temp_folder

    # Step 2 get package
    if wget https://go.microsoft.com/fwlink/p/?LinkID=2112886 -O "$temp_folder/teams.deb" ; then
        gr.msg -c yellow "unable to download package from https://go.microsoft.com/fwlink/p/?LinkID=2112886"
        return 102
    fi

    # Step 3 install package
    if sudo dpkg -i $temp_folder/teams.deb ; then
        gr.msg -c yellow "Pachage installation failed"
        return 103
    fi

    gr.msg -c green "teams installed"
    gr.msg "type 'teams' to test installation"
    return 0
}


install.fail2ban () {
       # install and setup ssh brute force protection
       if sudo apt-get update && sudo apt-get -y install fail2ban ; then
              gr.msg -c green "installation ok"
       else
              gr.msg -c red "failed to install"
              return 100
       fi

       sudo systemctl enable fail2ban.service

       jail_conf='/etc/fail2ban/jail.local'

       if [[ -f $jail_conf ]] && grep '[sshd]' $jail_conf ; then
              gr.msg "already configured"
       else
              printf "\n[sshd] \nenables = true \nport = ssh \nfilter = sshd \nlogpath = /var/log/auth.log \nmaxretry = 3 \nfindtime = 300 \nbantime = 3600 \n" \
                     | sudo tee -a $jail_conf
       fi
       sudo systemctl start fail2ban.service
       sudo fail2ban-client status sshd && gr.msg -c green "setup ok" || gr.msg -c red "failed to setup"
}

install.steam () {
# install steam (tested once)
    sudo add-apt-repository multiverse
    sudo apt update
    sudo apt install -y wget gdebi-core libgl1-mesa-dri:i386 libgl1-mesa-glx:i386 libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 steam-libs-amd64:amd64 steam-libs-i386:i386
    cd /tmp
    wget https://cdn.akamai.steamstatic.com/client/installer/steam.deb
    sudo gdebi -y steam.deb
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GRBL_RC"
    install.main "$@"
    exit $?
fi

