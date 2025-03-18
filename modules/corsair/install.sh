################# get, patching, compile, install and setup functions ######################
# relies on corsair variables, source only from corsair module

corsair.clone () {
# get ckb-next source
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    cd /tmp
    [[ -d ckb-next ]] && rm -rf ckb-next

    if git clone https://github.com/ckb-next/ckb-next.git ; then
        gr.msg -c green "ok"
    else
        gr.msg -x 101 -c yellow "cloning error"
    fi
}

corsair.patch () {
# patch corsair k68 to avoid long daemon stop time
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    cd /tmp/$USER/ckb-next

    case $1 in
        K68|k68|keyboard)
            gr.msg -c white "1) find 'define NEEDS_UNCLEAN_EXIT(kb)' somewhere near line ~195"
            gr.msg -c white "2) add '|| (kb)->product == P_K68_NRGB' to end of line before ')'"
            subl src/daemon/usb.h
            ;;
        IRONCLAW|ironclaw|mouse)
            gr.msg "no patches yet needed for ironclaw mice"
            ;;
        *)  gr.msg -c yellow "unknown patch"
    esac

    read -p "press any key to continue"
}

corsair.compile () {
# compile ckb-next and ckb-next-daemon
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    [[ -d /tmp/$USER/ckb-next ]] || corsair.clone
    cd /tmp/$USER/ckb-next
    gr.msg -c white "running installer.."
    ./quickinstall && gr.msg -c green "ok" || gr.msg -x 103 -c yellow "quick installer error"
}

corsair.requirements () {
# install required libs and apps
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    # https://github.com/ckb-next/ckb-next/wiki/Linux-Installation#build-from-source
    local _needed="git
                   cmake
                   build-essential
                   pavucontrol
                   ibudev-dev
                   qt5-default
                   zlib1g-dev
                   libappindicator-dev
                   libpulse-dev
                   libquazip5-dev
                   libqt5x11extras5-dev
                   libxcb-screensaver0-dev
                   libxcb-ewmh-dev
                   libxcb1-dev qttools5-dev
                   libdbusmenu-qt5-2
                   libdbusmenu-qt5-dev"

    gr.msg -c white "installing needed software: $_needed "

    sudo apt-get install -y $_needed \
            || gr.msg -x 101 -c yellow "apt-get error $?" \
            && gr.msg -c green "ok"
}


corsair.install () {
# install essentials, driver and application
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if corsair.check && ! [[ $GRBL_FORCE ]] ; then
        gr.msg -v1 "corsair seems to be working. use force flag '-f' to re-install"
        return 0
    fi

    if ! lsusb | grep "Corsair" ; then
        echo "no corsair devices connected, exiting.."
        return 100
    fi

    source /etc/os-release
    source /etc/upstream-release/lsb-release
    # gr.msg "$NAME $VERSION_ID '$VERSION_CODENAME' based on $DISTRIB_ID $DISTRIB_RELEASE '$DISTRIB_CODENAME' $HOME_URL" ;;
    # Ubuntu (18.04, 20.04, 22.04, 23.04) or equivalent (Linux Mint 19+, Pop!_OS)
    if [[ $DISTRIB_ID != "Ubuntu" ]] ; then
        gr.msg "Ubuntu based systems only!"
        return 2
    fi

    case $DISTRIB_RELEASE in
        18.*|19.*|20.*|22.*|23.*)
            # There is PPA but K68 dows not work with it, need patch source code, then compile
            corsair.requirements && \
            corsair.clone && \
            corsair.patch K68 && \
            corsair.compile && \

            corsair.systemd_setup
            corsair.systemd_daemon start
            corsair.systemd_app start

            # make backup of .service file
            cp -f $corsair_daemon_service $GRBL_CFG
        ;;
        24.*)
            # Trying with re-compiled version
            # https://launchpad.net/~tatokis/+archive/ubuntu/ckb-next
            sudo add-apt-repository ppa:tatokis/ckb-next
            sudo apt update
            sudo apt install ckb-next
        ;;
    esac
    return 0
}

corsair.remove () {
# get rid of driver and shit
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug
    # https://github.com/ckb-next/ckb-next/wiki/Linux-Installation#uninstallation
    gr.ask "really remove corsair" || return 100

    if [[ /tmp/$USER/ckb-next ]] ; then
        cd /tmp/$USER/ckb-next
        sudo cmake --build build --target uninstall
    else
        # if source is not available anymore re clone it to build uninstall method
        cd /tmp
        git clone https://github.com/ckb-next/ckb-next.git
        cd ckb-next
        cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release -DSAFE_INSTALL=ON -DSAFE_UNINSTALL=ON -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBEXECDIR=lib
        cmake --build build --target all -- -j 4
        sudo cmake --build build --target install       # The compilation and installation steps are required because install target generates an install manifest that later allows to determine which files to remove and what is their location.
        sudo cmake --build build --target uninstall
    fi

    rm -f $suspend_script
    return $?
}

