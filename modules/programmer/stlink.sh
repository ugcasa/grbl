#!/bin/bash
# TODO: re-written non tested

source common.sh

stlink.main () {
    # command parser
    program_indicator_key="f$(poll_order program)"

    local _cmd="$1" ; shift
    case "$_cmd" in
               status|help|install|remove)
                    stlink.$_cmd "$@" ; return $? ;;
               *)
                    gmsg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 127
        esac

    return 0
}


stlink.help () {
    gmsg -v1 -c white "guru-client st-link help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL st-link start|end|status|help|install|remove"
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 " install                  install st-link programmer for st mcu "
    gmsg -v1 " remove                   remove installationa and requirements "
    gmsg -v2 " help                     printout this help "
    gmsg -v2
    gmsg -v1 -c white "example: "
    gmsg -v1 "         $GURU_CALL programmer st-link status "
    gmsg -v2
}


stlink.status () {

    if st-flash --version >>/dev/null ; then
        gmsg -c green "installed" -k $program_indicator_key
        return 0
    else
        gmsg -c red "not installed" -k $program_indicator_key
        return 1
    fi
}


stlink.install () {

    # check installation
    if st-flash -v ; then
        gmsg -c green "already installed"
        gmsg -v2 "to reinstall perform 'remove' first"
        return 0
    fi


    cd /tmp ; mkdir st-link ; cd st-link

    # did not work properly - not mutch testing done
    st-flash --version && exit 0

    cmake >>/dev/null || sudo apt install cmake
    sudo apt install --reinstall build-essential -y

    dpkg -l libusb-1.0-0-dev >>/dev/null || sudo apt-get install libusb-1.0-0-dev

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
    gmsg -c green "guru is now ready to program st mcu's"
    gmsg -v1 "usage: st-flash --reset read test.bin 0x8000000 4096"

}


stlink.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: st-link programmer polling started" -k $program_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: st-link programmer polling ended" -k $program_indicator_key
            ;;
        status )
            stlink.status
            ;;
        esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    ok2.main "$@"
    exit $?
fi

